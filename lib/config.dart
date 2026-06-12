/// Configuração central do minerador.
///
/// Troque [bitcoinAddress] pelo SEU endereço Bitcoin (bc1... de preferência).
/// QUALQUER bloco encontrado é pago direto para esse endereço pela public-pool
/// (pool sem custódia / sem taxa). Ninguém mais toca no prêmio.
class MinerConfig {
  MinerConfig._();

  // ---------------------------------------------------------------------------
  // ENDEREÇO DE RECOMPENSA (PADRÃO / FALLBACK)
  // ---------------------------------------------------------------------------
  // O endereço de destino agora pode ser definido no app ESCANEANDO um QR code
  // (botão "Escanear endereço de destino"), e fica salvo no aparelho.
  // Este valor é só o padrão inicial enquanto nada foi escaneado — troque pelo
  // SEU endereço para não minerar para um endereço de exemplo.
  static const String bitcoinAddress =
      'bc1qexampleexampleexampleexampleexampleexa'; // <-- SEU ENDEREÇO (padrão)

  /// Nome do worker. Bom usar o modelo do aparelho p/ identificar no dashboard.
  static const String workerName = 'velho-celular-01';

  // ---------------------------------------------------------------------------
  // POOL  (public-pool.io oficial)
  // ---------------------------------------------------------------------------
  static const String stratumHost = 'public-pool.io';
  static const int stratumPort = 3333;        // Stratum V1 (texto puro)
  // Porta alternativa antiga (ainda referenciada por alguns tutoriais): 21496
  // TLS: porta 4333 (este app usa TCP puro p/ simplicidade).

  /// API REST que alimenta o dashboard oficial.
  static const String apiBase = 'https://public-pool.io:40557/api';

  /// Identificação enviada no mining.subscribe (user-agent do minerador).
  static const String userAgent = 'BorderlessMiner/1.0';

  // ---------------------------------------------------------------------------
  // LINK DE COMPRA DE BITCOIN (referral do Arthur)
  // ---------------------------------------------------------------------------
  static const String binanceRefUrl =
      'https://account.binance.com/register?ref=LNBOT&registerChannel=user_center';

  static const String mempoolExplorer = 'https://mempool.space/address/';
}
