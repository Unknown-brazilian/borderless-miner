// Borderless Miner - núcleo de hashing nativo (SHA-256d) com midstate.
// Compilado para Android via NDK/CMake e chamado pelo Dart via dart:ffi.
//
// A prova de trabalho do Bitcoin = SHA256(SHA256(cabeçalho de 80 bytes)).
// O cabeçalho tem 80 bytes; só os 4 últimos (o nonce) mudam a cada tentativa.
// Os primeiros 64 bytes são constantes durante a varredura de um job, então
// pré-computamos o "midstate" (estado do SHA-256 após o 1º bloco) uma única vez
// e reaproveitamos a cada nonce -> ~33% menos trabalho por hash.

#include <stdint.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

#define ROTR(x, n) (((x) >> (n)) | ((x) << (32 - (n))))
#define CH(x, y, z) (((x) & (y)) ^ (~(x) & (z)))
#define MAJ(x, y, z) (((x) & (y)) ^ ((x) & (z)) ^ ((y) & (z)))
#define EP0(x) (ROTR(x, 2) ^ ROTR(x, 13) ^ ROTR(x, 22))
#define EP1(x) (ROTR(x, 6) ^ ROTR(x, 11) ^ ROTR(x, 25))
#define SIG0(x) (ROTR(x, 7) ^ ROTR(x, 18) ^ ((x) >> 3))
#define SIG1(x) (ROTR(x, 17) ^ ROTR(x, 19) ^ ((x) >> 10))

static const uint32_t K[64] = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1,
    0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786,
    0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147,
    0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b,
    0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a,
    0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};

static const uint32_t H0[8] = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
                               0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};

// Aplica a função de compressão do SHA-256 sobre UM bloco de 64 bytes,
// atualizando state[8] (entrada big-endian conforme o padrão).
static void sha256_transform(uint32_t state[8], const uint8_t block[64]) {
  uint32_t w[64];
  for (int i = 0; i < 16; i++) {
    w[i] = ((uint32_t)block[i * 4] << 24) | ((uint32_t)block[i * 4 + 1] << 16) |
           ((uint32_t)block[i * 4 + 2] << 8) | ((uint32_t)block[i * 4 + 3]);
  }
  for (int i = 16; i < 64; i++) {
    w[i] = SIG1(w[i - 2]) + w[i - 7] + SIG0(w[i - 15]) + w[i - 16];
  }
  uint32_t a = state[0], b = state[1], c = state[2], d = state[3];
  uint32_t e = state[4], f = state[5], g = state[6], h = state[7];
  for (int i = 0; i < 64; i++) {
    uint32_t t1 = h + EP1(e) + CH(e, f, g) + K[i] + w[i];
    uint32_t t2 = EP0(a) + MAJ(a, b, c);
    h = g; g = f; f = e; e = d + t1;
    d = c; c = b; b = a; a = t1 + t2;
  }
  state[0] += a; state[1] += b; state[2] += c; state[3] += d;
  state[4] += e; state[5] += f; state[6] += g; state[7] += h;
}

// SHA-256 de uma mensagem de 32 bytes (usado para o 2º hash do dSHA256).
// 32 bytes + 0x80 + zeros + comprimento(256 bits) cabem em 1 bloco de 64.
static void sha256_32(const uint8_t in[32], uint8_t out[32]) {
  uint8_t block[64];
  memcpy(block, in, 32);
  block[32] = 0x80;
  memset(block + 33, 0, 64 - 33 - 2);
  block[62] = 0x01; // 256 bits = 0x0100
  block[63] = 0x00;
  uint32_t st[8];
  memcpy(st, H0, sizeof(st));
  sha256_transform(st, block);
  for (int i = 0; i < 8; i++) {
    out[i * 4] = (st[i] >> 24) & 0xff;
    out[i * 4 + 1] = (st[i] >> 16) & 0xff;
    out[i * 4 + 2] = (st[i] >> 8) & 0xff;
    out[i * 4 + 3] = st[i] & 0xff;
  }
}

// Compara dois hashes de 32 bytes em ordem big-endian (display). a < b ?
static int hash_less(const uint8_t a[32], const uint8_t b[32]) {
  return memcmp(a, b, 32) < 0;
}

// ---------------------------------------------------------------------------
// API pública chamada via FFI.
//
// header       : 80 bytes do cabeçalho (o nonce nos bytes 76..79 é sobrescrito).
// start_nonce  : primeiro nonce a testar.
// count        : quantos nonces testar.
// share_target : 32 bytes big-endian. hash <= target  => share válida.
// best_hash_out: 32 bytes (big-endian) do MENOR hash encontrado no lote.
// best_nonce_out: nonce correspondente ao menor hash.
// found_out    : 1 se o menor hash <= share_target.
// ---------------------------------------------------------------------------
void mine_batch(const uint8_t *header, uint32_t start_nonce, uint32_t count,
                const uint8_t *share_target, uint8_t *best_hash_out,
                uint32_t *best_nonce_out, uint32_t *found_out) {
  // 1º bloco (bytes 0..63) é constante -> midstate calculado uma vez.
  uint32_t midstate[8];
  memcpy(midstate, H0, sizeof(midstate));
  sha256_transform(midstate, header);

  // 2º bloco: bytes 64..79 (16 bytes) + padding (mensagem total = 80 bytes = 640 bits).
  uint8_t block2[64];
  memcpy(block2, header + 64, 16);
  block2[16] = 0x80;
  memset(block2 + 17, 0, 64 - 17 - 2);
  block2[62] = 0x02; // 640 bits = 0x0280
  block2[63] = 0x80;

  uint8_t best[32];
  memset(best, 0xff, 32);
  uint32_t best_nonce = start_nonce;

  uint8_t h1[32];
  uint8_t h2[32];

  for (uint32_t i = 0; i < count; i++) {
    uint32_t nonce = start_nonce + i;
    // nonce ocupa os bytes 76..79 do cabeçalho = bytes 12..15 do 2º bloco,
    // em little-endian.
    block2[12] = nonce & 0xff;
    block2[13] = (nonce >> 8) & 0xff;
    block2[14] = (nonce >> 16) & 0xff;
    block2[15] = (nonce >> 24) & 0xff;

    uint32_t st[8];
    memcpy(st, midstate, sizeof(st));
    sha256_transform(st, block2);
    for (int k = 0; k < 8; k++) {
      h1[k * 4] = (st[k] >> 24) & 0xff;
      h1[k * 4 + 1] = (st[k] >> 16) & 0xff;
      h1[k * 4 + 2] = (st[k] >> 8) & 0xff;
      h1[k * 4 + 3] = st[k] & 0xff;
    }
    sha256_32(h1, h2); // h2 = dSHA256(header) em ordem "raw" (little-endian)

    // ordem de exibição (big-endian) = inverte os 32 bytes
    uint8_t be[32];
    for (int k = 0; k < 32; k++) be[k] = h2[31 - k];

    if (hash_less(be, best)) {
      memcpy(best, be, 32);
      best_nonce = nonce;
    }
  }

  memcpy(best_hash_out, best, 32);
  *best_nonce_out = best_nonce;
  *found_out = (memcmp(best, share_target, 32) <= 0) ? 1u : 0u;
}

#ifdef __cplusplus
}
#endif
