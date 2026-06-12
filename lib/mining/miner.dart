import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import '../config.dart';
import '../l10n/l10n.dart';
import '../services/address_store.dart';
import 'job.dart';
import 'mining_isolate.dart';
import 'stratum_client.dart';

/// Orquestra o pool (Stratum) + N isolates de mineração (um por núcleo),
/// agregando as estatísticas para a UI.
class Miner extends ChangeNotifier {
  final StratumClient _stratum = StratumClient();

  final List<Isolate> _isolates = [];
  final List<SendPort> _workerPorts = [];
  ReceivePort? _fromWorkers;
  final Map<int, double> _hashrates = {};

  StreamSubscription? _jobSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _logSub;

  // estado exposto à UI
  bool running = false;
  int threads = 0; // 0 = automático (todos os núcleos)
  int activeThreads = 0;
  String address = MinerConfig.bitcoinAddress; // destino do prêmio
  StratumState connection = StratumState.disconnected;
  double hashrate = 0; // soma de todos os núcleos (H/s)
  double bestDifficulty = 0;
  int acceptedShares = 0;
  int blocksFound = 0;
  MiningJob? currentJob;
  final List<double> hashrateHistory = [];
  final List<String> log = [];

  int get coreCount => Platform.numberOfProcessors;

  /// Carrega o endereço de destino salvo (ou o padrão).
  Future<void> loadAddress() async {
    address = await AddressStore.load();
    _stratum.address = address;
    notifyListeners();
  }

  /// Define um novo endereço de destino (vindo do QR) e persiste.
  /// Se estiver minerando, reinicia para reconectar com o novo endereço.
  Future<void> setAddress(String newAddress) async {
    address = newAddress;
    _stratum.address = newAddress;
    await AddressStore.save(newAddress);
    notifyListeners();
    if (running) {
      await stop();
      await start(threadCount: threads);
    }
  }

  void _addLog(String s) {
    log.insert(0, s);
    if (log.length > 200) log.removeLast();
    notifyListeners();
  }

  Future<void> start({int threadCount = 0}) async {
    if (running) return;
    running = true;
    threads = threadCount;
    _stratum.address = address;
    final n = threadCount > 0 ? threadCount : coreCount;
    activeThreads = n.clamp(1, 32);
    notifyListeners();

    _logSub = _stratum.logs.listen(_addLog);
    _stateSub = _stratum.state.listen((s) {
      connection = s;
      notifyListeners();
    });

    _fromWorkers = ReceivePort();
    _fromWorkers!.listen(_onWorkerMessage);

    for (var i = 0; i < activeThreads; i++) {
      final iso = await Isolate.spawn(miningIsolate, _fromWorkers!.sendPort);
      _isolates.add(iso);
    }

    _jobSub = _stratum.jobs.listen((job) {
      currentJob = job;
      for (final p in _workerPorts) {
        _dispatchWork(p, job);
      }
      notifyListeners();
    });

    await _stratum.connect();
  }

  void _dispatchWork(SendPort port, MiningJob job) {
    port.send({
      'type': 'work',
      ...job.toMap(),
      'extranonce1': _stratum.extranonce1,
      'extranonce2Size': _stratum.extranonce2Size,
      'difficulty': _stratum.difficulty,
    });
  }

  void _onWorkerMessage(dynamic msg) {
    final map = msg as Map;
    switch (map['type']) {
      case 'ready':
        final port = map['port'] as SendPort;
        final id = _workerPorts.length;
        _workerPorts.add(port);
        port.send({'type': 'init', 'id': id});
        final j = currentJob;
        if (j != null) _dispatchWork(port, j);
        break;
      case 'stats':
        final id = map['id'] as int;
        final hps = (map['hps'] as num).toDouble();
        if (hps > 0) {
          _hashrates[id] = hps;
          hashrate = _hashrates.values.fold(0.0, (a, b) => a + b);
          hashrateHistory.add(hashrate);
          if (hashrateHistory.length > 60) hashrateHistory.removeAt(0);
        }
        final bd = (map['bestDiff'] as num).toDouble();
        if (bd > bestDifficulty) bestDifficulty = bd;
        notifyListeners();
        break;
      case 'share':
        final isBlock = map['isBlock'] == true;
        _stratum.submit(
          jobId: map['jobId'],
          extranonce2: map['extranonce2'],
          ntime: map['ntime'],
          nonce: map['nonce'],
        );
        acceptedShares++;
        if (isBlock) {
          blocksFound++;
          _addLog(tr.logBlockFound(map['diff'] as num));
        } else {
          _addLog(tr.logShareSent((map['diff'] as num).toStringAsFixed(0)));
        }
        notifyListeners();
        break;
    }
  }

  Future<void> stop() async {
    running = false;
    for (final p in _workerPorts) {
      p.send({'type': 'stop'});
    }
    for (final iso in _isolates) {
      iso.kill(priority: Isolate.immediate);
    }
    _isolates.clear();
    _workerPorts.clear();
    _hashrates.clear();
    _fromWorkers?.close();
    await _stratum.close();
    await _jobSub?.cancel();
    await _stateSub?.cancel();
    await _logSub?.cancel();
    hashrate = 0;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    _stratum.dispose();
    super.dispose();
  }
}
