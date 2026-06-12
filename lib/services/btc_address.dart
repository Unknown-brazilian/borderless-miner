import 'dart:typed_data';
import 'package:crypto/crypto.dart';

/// Validação de endereço Bitcoin. Importante: mineração solo paga o bloco
/// INTEIRO para este endereço, então um endereço inválido = moeda perdida.
/// Por isso validamos de verdade (checksum bech32/bech32m e base58check).
class BtcAddress {
  static const _charset = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
  static const _b58 =
      '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

  /// Extrai o endereço de um texto escaneado (aceita URI BIP21 "bitcoin:...").
  static String parse(String raw) {
    var s = raw.trim();
    if (s.toLowerCase().startsWith('bitcoin:')) {
      s = s.substring(8);
      final q = s.indexOf('?');
      if (q >= 0) s = s.substring(0, q);
    }
    return s.trim();
  }

  /// true se for um endereço Bitcoin de mainnet válido.
  static bool isValid(String raw) {
    final a = parse(raw);
    if (a.isEmpty) return false;
    final lower = a.toLowerCase();
    if (lower.startsWith('bc1')) return _validSegwit(a);
    if (a.startsWith('1') || a.startsWith('3')) return _validBase58Check(a);
    return false;
  }

  // ----------------------------- bech32 / bech32m ---------------------------
  static int _polymod(List<int> values) {
    const gen = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3];
    var chk = 1;
    for (final v in values) {
      final b = chk >> 25;
      chk = ((chk & 0x1ffffff) << 5) ^ v;
      for (var i = 0; i < 5; i++) {
        if (((b >> i) & 1) != 0) chk ^= gen[i];
      }
    }
    return chk;
  }

  static List<int> _hrpExpand(String hrp) {
    final a = <int>[];
    for (final c in hrp.codeUnits) {
      a.add(c >> 5);
    }
    a.add(0);
    for (final c in hrp.codeUnits) {
      a.add(c & 31);
    }
    return a;
  }

  static List<int>? _convertBits(List<int> data, int from, int to) {
    var acc = 0, bits = 0;
    final ret = <int>[];
    final maxv = (1 << to) - 1;
    for (final v in data) {
      acc = (acc << from) | v;
      bits += from;
      while (bits >= to) {
        bits -= to;
        ret.add((acc >> bits) & maxv);
      }
    }
    // sem padding (frm 5 -> 8): sobra precisa ser segura
    if (bits >= from || ((acc << (to - bits)) & maxv) != 0) return null;
    return ret;
  }

  static bool _validSegwit(String addr) {
    // rejeita maiúsculas/minúsculas misturadas (regra do BIP173)
    if (addr != addr.toLowerCase() && addr != addr.toUpperCase()) return false;
    final a = addr.toLowerCase();
    final pos = a.lastIndexOf('1');
    if (pos < 1) return false;
    final hrp = a.substring(0, pos);
    final dp = a.substring(pos + 1);
    if (hrp != 'bc') return false; // só mainnet
    final data = <int>[];
    for (final ch in dp.split('')) {
      final idx = _charset.indexOf(ch);
      if (idx == -1) return false;
      data.add(idx);
    }
    if (data.length < 7) return false;
    final chk = _polymod([..._hrpExpand(hrp), ...data]);
    final witver = data[0];
    if (witver == 0 && chk != 1) return false;
    if (witver >= 1 && chk != 0x2bc830a3) return false;
    if (witver > 16) return false;
    final prog = _convertBits(data.sublist(1, data.length - 6), 5, 8);
    if (prog == null) return false;
    if (prog.length < 2 || prog.length > 40) return false;
    if (witver == 0 && prog.length != 20 && prog.length != 32) return false;
    return true;
  }

  // ----------------------------- base58check -------------------------------
  static bool _validBase58Check(String addr) {
    var num = BigInt.zero;
    for (final ch in addr.split('')) {
      final idx = _b58.indexOf(ch);
      if (idx == -1) return false;
      num = num * BigInt.from(58) + BigInt.from(idx);
    }
    var bytes = _bigIntToBytes(num);
    final pad = addr.length - addr.replaceFirst(RegExp(r'^1+'), '').length;
    bytes = Uint8List.fromList([...List.filled(pad, 0), ...bytes]);
    if (bytes.length < 5) return false;
    final payload = bytes.sublist(0, bytes.length - 4);
    final check = bytes.sublist(bytes.length - 4);
    final d = sha256
        .convert(sha256.convert(payload).bytes)
        .bytes
        .sublist(0, 4);
    for (var i = 0; i < 4; i++) {
      if (d[i] != check[i]) return false;
    }
    return payload[0] == 0x00 || payload[0] == 0x05; // P2PKH / P2SH mainnet
  }

  static Uint8List _bigIntToBytes(BigInt v) {
    if (v == BigInt.zero) return Uint8List(0);
    final bytes = <int>[];
    var n = v;
    while (n > BigInt.zero) {
      bytes.insert(0, (n & BigInt.from(0xff)).toInt());
      n = n >> 8;
    }
    return Uint8List.fromList(bytes);
  }
}
