import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'native_miner.dart';
import 'sha256d.dart';

/// Mensagens para o isolate (do main):
///   {type:'init', id:int}
///   {type:'work', ...job, extranonce1, extranonce2Size, difficulty}
///   {type:'stop'}
///
/// Mensagens do isolate (para o main):
///   {type:'ready', port: SendPort, id:int}
///   {type:'stats', id:int, hps:double, bestDiff:double}
///   {type:'share', id:int, jobId, extranonce2, ntime, nonce, diff, isBlock}

/// Entry point de cada isolate de mineração (um por núcleo).
void miningIsolate(SendPort mainSend) {
  final port = ReceivePort();
  final native = NativeMiner();
  final rng = Random.secure();
  int myId = 0;
  _Work? work;
  bool stopped = false;

  mainSend.send({'type': 'ready', 'port': port.sendPort});

  port.listen((msg) {
    final map = msg as Map;
    switch (map['type']) {
      case 'init':
        myId = map['id'] as int;
        break;
      case 'work':
        work = _Work.fromMap(map, rng);
        native.setHeader(work!.header);
        native.setShareTarget(work!.shareTargetBE);
        break;
      case 'stop':
        stopped = true;
        work = null;
        native.dispose();
        port.close();
        break;
    }
  });

  Future<void> loop() async {
    const batch = 200000; // nonces por chamada nativa
    var hashes = 0;
    var sw = Stopwatch()..start();
    var bestDiff = 0.0;
    var startNonce = 0;

    while (!stopped) {
      final w = work;
      if (w == null) {
        await Future.delayed(const Duration(milliseconds: 80));
        continue;
      }

      final res = native.run(startNonce, batch);
      hashes += batch;

      final value = bytesToBigIntBE(res.bestHashBE);
      final diff = hashDifficulty(value);
      if (diff > bestDiff) {
        bestDiff = diff;
        mainSend.send(
            {'type': 'stats', 'id': myId, 'hps': 0.0, 'bestDiff': bestDiff});
      }

      final isBlock = value <= w.networkTarget;
      if (res.found || isBlock) {
        mainSend.send({
          'type': 'share',
          'id': myId,
          'jobId': w.jobId,
          'extranonce2': w.extranonce2Hex,
          'ntime': w.ntimeHex,
          'nonce': res.bestNonce.toRadixString(16).padLeft(8, '0'),
          'diff': diff,
          'isBlock': isBlock,
        });
      }

      // avança o ponteiro de nonce (com wrap em 2^32); ao dar a volta,
      // troca o extranonce2 para um novo espaço de busca.
      startNonce += batch;
      if (startNonce > 0xFFFFFFFF) {
        startNonce = 0;
        w.rollExtranonce2();
        native.setHeader(w.header);
      }

      if (sw.elapsedMilliseconds >= 1000) {
        final hps = hashes * 1000 / sw.elapsedMilliseconds;
        mainSend.send(
            {'type': 'stats', 'id': myId, 'hps': hps, 'bestDiff': bestDiff});
        hashes = 0;
        sw = Stopwatch()..start();
      }

      await Future.delayed(Duration.zero); // cede ao event loop
    }
  }

  loop();
}

/// Trabalho atual, com o cabeçalho de 80 bytes pronto para o núcleo nativo.
class _Work {
  final String jobId;
  final int version;
  final int ntime;
  final int nbits;
  final Uint8List prevhashSwapped;
  final String coinb1;
  final String coinb2;
  final List<String> merkleBranches;
  final String extranonce1;
  final int extranonce2Size;
  final BigInt networkTarget;
  final Uint8List shareTargetBE;
  final Random rng;

  final Uint8List header = Uint8List(80);
  late String extranonce2Hex;
  late String ntimeHex;

  _Work({
    required this.jobId,
    required this.version,
    required this.ntime,
    required this.nbits,
    required this.prevhashSwapped,
    required this.coinb1,
    required this.coinb2,
    required this.merkleBranches,
    required this.extranonce1,
    required this.extranonce2Size,
    required this.networkTarget,
    required this.shareTargetBE,
    required this.rng,
  }) {
    ntimeHex = ntime.toRadixString(16).padLeft(8, '0');
    // partes fixas do cabeçalho
    header.setRange(0, 4, le32(version));
    header.setRange(4, 36, prevhashSwapped);
    header.setRange(68, 72, le32(ntime));
    header.setRange(72, 76, le32(nbits));
    // bytes 76..80 (nonce) ficam zerados; o C sobrescreve por iteração.
    rollExtranonce2();
  }

  factory _Work.fromMap(Map m, Random rng) {
    final nbits = int.parse(m['nbits'], radix: 16);
    final difficulty = (m['difficulty'] as num).toDouble();
    final scaled = (difficulty * 1000000).round().clamp(1, 1 << 53);
    final shareTargetBig =
        (diff1Target * BigInt.from(1000000)) ~/ BigInt.from(scaled);
    return _Work(
      jobId: m['jobId'],
      version: int.parse(m['version'], radix: 16),
      ntime: int.parse(m['ntime'], radix: 16),
      nbits: nbits,
      prevhashSwapped: swapWords(hexToBytes(m['prevhash'])),
      coinb1: m['coinb1'],
      coinb2: m['coinb2'],
      merkleBranches: (m['merkleBranches'] as List).cast<String>(),
      extranonce1: m['extranonce1'],
      extranonce2Size: m['extranonce2Size'],
      networkTarget: nbitsToTarget(nbits),
      shareTargetBE: bigIntToBE32(shareTargetBig),
      rng: rng,
    );
  }

  void rollExtranonce2() {
    final bytes = Uint8List(extranonce2Size);
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = rng.nextInt(256);
    }
    extranonce2Hex = bytesToHex(bytes);
    final merkle = _computeMerkleRoot();
    header.setRange(36, 68, merkle);
  }

  Uint8List _computeMerkleRoot() {
    final coinbase =
        hexToBytes(coinb1 + extranonce1 + extranonce2Hex + coinb2);
    var root = sha256d(coinbase);
    for (final branch in merkleBranches) {
      final combined = Uint8List(64)
        ..setRange(0, 32, root)
        ..setRange(32, 64, hexToBytes(branch));
      root = sha256d(combined);
    }
    return root;
  }
}
