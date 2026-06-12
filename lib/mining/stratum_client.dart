import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config.dart';
import '../l10n/l10n.dart';
import 'job.dart';

enum StratumState { disconnected, connecting, connected, authorized }

/// Cliente Stratum V1 (JSON-RPC sobre TCP, uma mensagem por linha).
class StratumClient {
  Socket? _socket;
  int _id = 1;
  final _buffer = StringBuffer();

  /// Endereço de recompensa e worker (podem ser trocados antes de conectar,
  /// ex.: após escanear um endereço por QR).
  String address = MinerConfig.bitcoinAddress;
  String worker = MinerConfig.workerName;

  String extranonce1 = '';
  int extranonce2Size = 4;
  double difficulty = 1.0;

  final _stateCtrl = StreamController<StratumState>.broadcast();
  final _jobCtrl = StreamController<MiningJob>.broadcast();
  final _logCtrl = StreamController<String>.broadcast();

  Stream<StratumState> get state => _stateCtrl.stream;
  Stream<MiningJob> get jobs => _jobCtrl.stream;
  Stream<String> get logs => _logCtrl.stream;

  void _log(String s) => _logCtrl.add(s);

  Future<void> connect() async {
    _stateCtrl.add(StratumState.connecting);
    _log(tr.logConnecting(MinerConfig.stratumHost, MinerConfig.stratumPort));
    _socket = await Socket.connect(
      MinerConfig.stratumHost,
      MinerConfig.stratumPort,
      timeout: const Duration(seconds: 15),
    );
    _stateCtrl.add(StratumState.connected);
    _log(tr.logConnected);

    _socket!.listen(
      _onData,
      onError: (e) {
        _log(tr.logSocketError(e));
        _stateCtrl.add(StratumState.disconnected);
      },
      onDone: () {
        _log(tr.logConnClosed);
        _stateCtrl.add(StratumState.disconnected);
      },
    );

    _send('mining.subscribe', [MinerConfig.userAgent]);
  }

  void _onData(List<int> data) {
    _buffer.write(utf8.decode(data));
    final content = _buffer.toString();
    final lines = content.split('\n');
    // a última parte pode estar incompleta; guarda de volta no buffer
    _buffer.clear();
    _buffer.write(lines.removeLast());
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      try {
        _handleMessage(jsonDecode(trimmed) as Map<String, dynamic>);
      } catch (e) {
        _log(tr.logParseError(e));
      }
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    // Respostas a requisições nossas têm "id"; notificações têm "method".
    if (msg['method'] != null) {
      _handleNotification(msg['method'] as String, msg['params'] as List? ?? []);
      return;
    }

    final id = msg['id'];
    final result = msg['result'];
    // id == 1 -> resposta do subscribe
    if (id == 1 && result is List) {
      // result = [ subscriptions, extranonce1, extranonce2_size ]
      extranonce1 = result[1] as String;
      extranonce2Size = result[2] as int;
      _log(tr.logSubscribeOk(extranonce1, extranonce2Size));
      // autoriza com endereço.worker
      _send('mining.authorize', ['$address.$worker', 'x']);
    } else if (id == 2) {
      if (result == true) {
        _log(tr.logAuthorized);
        _stateCtrl.add(StratumState.authorized);
      } else {
        _log(tr.logAuthRejected(msg['error']));
      }
    } else {
      // respostas de mining.submit
      if (result == true) {
        _log(tr.logShareAccepted);
      } else if (msg['error'] != null) {
        _log(tr.logShareRejected(msg['error']));
      }
    }
  }

  void _handleNotification(String method, List params) {
    switch (method) {
      case 'mining.set_difficulty':
        difficulty = (params[0] as num).toDouble();
        _log(tr.logNewDifficulty(difficulty));
        break;
      case 'mining.notify':
        final job = MiningJob.fromNotify(params);
        _log(tr.logNewJob(job.jobId, job.cleanJobs));
        _jobCtrl.add(job);
        break;
      case 'mining.set_extranonce':
        extranonce1 = params[0] as String;
        extranonce2Size = params[1] as int;
        break;
    }
  }

  /// Envia uma share encontrada de volta ao pool.
  void submit({
    required String jobId,
    required String extranonce2,
    required String ntime,
    required String nonce,
  }) {
    _send('mining.submit', [
      '$address.$worker',
      jobId,
      extranonce2,
      ntime,
      nonce,
    ]);
  }

  void _send(String method, List params) {
    final id = method == 'mining.subscribe'
        ? 1
        : method == 'mining.authorize'
            ? 2
            : ++_id + 2;
    final msg = jsonEncode({'id': id, 'method': method, 'params': params});
    _socket?.write('$msg\n');
  }

  Future<void> close() async {
    await _socket?.close();
    _socket = null;
    _stateCtrl.add(StratumState.disconnected);
  }

  void dispose() {
    _stateCtrl.close();
    _jobCtrl.close();
    _logCtrl.close();
  }
}
