import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config.dart';

/// Estatísticas vindas da API oficial da public-pool, usadas para mostrar um
/// dashboard parecido com o do site (web.public-pool.io).
class PoolStats {
  final double bestDifficulty; // melhor share da sessão (lado do pool)
  final int workersOnline;
  final double poolHashrate; // H/s estimado do worker conforme o pool
  final int? bestEver;

  PoolStats({
    required this.bestDifficulty,
    required this.workersOnline,
    required this.poolHashrate,
    this.bestEver,
  });
}

class PoolApi {
  /// GET /api/client/{address} -> dados dos workers desse endereço.
  static Future<PoolStats?> fetchClient(String address) async {
    try {
      final url = Uri.parse('${MinerConfig.apiBase}/client/$address');
      final res = await http.get(url).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;

      final workers = (data['workers'] as List?) ?? const [];
      double hashrate = 0;
      double best = 0;
      for (final w in workers) {
        hashrate += _toDouble(w['hashRate']);
        final b = _toDouble(w['bestDifficulty']);
        if (b > best) best = b;
      }
      return PoolStats(
        bestDifficulty: _toDouble(data['bestDifficulty'], fallback: best),
        workersOnline: workers.length,
        poolHashrate: hashrate,
        bestEver: null,
      );
    } catch (_) {
      return null;
    }
  }

  static double _toDouble(dynamic v, {double fallback = 0}) {
    if (v == null) return fallback;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? fallback;
  }
}
