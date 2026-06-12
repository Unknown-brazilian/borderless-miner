import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Double SHA-256 (SHA256(SHA256(x))) — o coração da prova de trabalho do Bitcoin.
Uint8List sha256d(Uint8List data) {
  final first = sha256.convert(data).bytes;
  final second = sha256.convert(first).bytes;
  return Uint8List.fromList(second);
}

/// hex -> bytes
Uint8List hexToBytes(String hex) {
  final clean = hex.length.isOdd ? '0$hex' : hex;
  final out = Uint8List(clean.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

/// bytes -> hex
String bytesToHex(List<int> bytes) {
  final sb = StringBuffer();
  for (final b in bytes) {
    sb.write(b.toRadix16padded());
  }
  return sb.toString();
}

extension on int {
  String toRadix16padded() => toRadixString(16).padLeft(2, '0');
}

/// Inteiro de 32 bits -> 4 bytes LITTLE-ENDIAN.
/// Usado para version, ntime, nbits e nonce no cabeçalho do bloco.
Uint8List le32(int value) {
  final b = Uint8List(4);
  b[0] = value & 0xFF;
  b[1] = (value >> 8) & 0xFF;
  b[2] = (value >> 16) & 0xFF;
  b[3] = (value >> 24) & 0xFF;
  return b;
}

/// Inverte os bytes DENTRO de cada palavra de 4 bytes (mantém a ordem das
/// palavras). É a transformação clássica que o Stratum exige no prevhash.
Uint8List swapWords(Uint8List input) {
  final out = Uint8List(input.length);
  for (var i = 0; i < input.length; i += 4) {
    out[i] = input[i + 3];
    out[i + 1] = input[i + 2];
    out[i + 2] = input[i + 1];
    out[i + 3] = input[i];
  }
  return out;
}

/// Interpreta 32 bytes como inteiro de 256 bits em LITTLE-ENDIAN.
/// (É assim que o hash do cabeçalho é comparado contra o alvo.)
BigInt bytesToBigIntLE(Uint8List bytes) {
  var result = BigInt.zero;
  for (var i = bytes.length - 1; i >= 0; i--) {
    result = (result << 8) | BigInt.from(bytes[i]);
  }
  return result;
}

/// Interpreta 32 bytes como inteiro de 256 bits em BIG-ENDIAN (ordem de
/// exibição). É o formato que o núcleo nativo devolve.
BigInt bytesToBigIntBE(Uint8List bytes) {
  var result = BigInt.zero;
  for (var i = 0; i < bytes.length; i++) {
    result = (result << 8) | BigInt.from(bytes[i]);
  }
  return result;
}

/// Converte um BigInt em 32 bytes BIG-ENDIAN (preenchendo com zeros à esquerda).
Uint8List bigIntToBE32(BigInt value) {
  final out = Uint8List(32);
  var v = value;
  for (var i = 31; i >= 0; i--) {
    out[i] = (v & BigInt.from(0xff)).toInt();
    v = v >> 8;
  }
  return out;
}

/// "Dificuldade 1" do Stratum: alvo de referência para calcular a dificuldade
/// de qualquer hash. (0x00000000FFFF0000...0000)
final BigInt diff1Target = BigInt.parse(
  '00000000FFFF0000000000000000000000000000000000000000000000000000',
  radix: 16,
);

/// Dificuldade de um hash = diff1Target / valor_do_hash.
double hashDifficulty(BigInt hashValueLE) {
  if (hashValueLE == BigInt.zero) return double.infinity;
  // Usa divisão de BigInt e converte com perda mínima para double.
  final q = (diff1Target * BigInt.from(1000000)) ~/ hashValueLE;
  return q.toDouble() / 1000000.0;
}

/// Converte nBits compacto (ex.: 0x17030ecd) no alvo da REDE (256 bits).
BigInt nbitsToTarget(int nbits) {
  final exponent = nbits >> 24;
  final mantissa = BigInt.from(nbits & 0x007FFFFF);
  if (exponent <= 3) {
    return mantissa >> (8 * (3 - exponent));
  }
  return mantissa << (8 * (exponent - 3));
}
