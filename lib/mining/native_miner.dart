import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

typedef _MineBatchNative = Void Function(
  Pointer<Uint8> header,
  Uint32 startNonce,
  Uint32 count,
  Pointer<Uint8> shareTarget,
  Pointer<Uint8> bestHashOut,
  Pointer<Uint32> bestNonceOut,
  Pointer<Uint32> foundOut,
);

typedef _MineBatchDart = void Function(
  Pointer<Uint8> header,
  int startNonce,
  int count,
  Pointer<Uint8> shareTarget,
  Pointer<Uint8> bestHashOut,
  Pointer<Uint32> bestNonceOut,
  Pointer<Uint32> foundOut,
);

/// Resultado de um lote de hashing nativo.
class BatchResult {
  final Uint8List bestHashBE; // 32 bytes, ordem de exibição (big-endian)
  final int bestNonce;
  final bool found; // bestHash <= shareTarget

  BatchResult(this.bestHashBE, this.bestNonce, this.found);
}

/// Wrapper sobre o `mine_batch` em C. Cada isolate cria a sua instância
/// (buffers próprios) para não compartilhar memória entre threads.
class NativeMiner {
  late final _MineBatchDart _mineBatch;

  // buffers reutilizados a cada chamada (malloc<T>(n) aloca sizeOf<T>()*n bytes)
  final Pointer<Uint8> _header = malloc<Uint8>(80);
  final Pointer<Uint8> _target = malloc<Uint8>(32);
  final Pointer<Uint8> _bestHash = malloc<Uint8>(32);
  final Pointer<Uint32> _bestNonce = malloc<Uint32>(1);
  final Pointer<Uint32> _found = malloc<Uint32>(1);

  NativeMiner() {
    final lib = _open();
    _mineBatch =
        lib.lookupFunction<_MineBatchNative, _MineBatchDart>('mine_batch');
  }

  DynamicLibrary _open() {
    if (Platform.isAndroid) return DynamicLibrary.open('libminer.so');
    if (Platform.isLinux) return DynamicLibrary.open('libminer.so');
    if (Platform.isMacOS) return DynamicLibrary.open('libminer.dylib');
    if (Platform.isWindows) return DynamicLibrary.open('miner.dll');
    return DynamicLibrary.process();
  }

  /// Atualiza o template de cabeçalho (80 bytes) e o alvo de share (32 bytes BE).
  void setHeader(Uint8List header80) {
    final h = _header.asTypedList(80);
    h.setRange(0, 80, header80);
  }

  void setShareTarget(Uint8List targetBE32) {
    final t = _target.asTypedList(32);
    t.setRange(0, 32, targetBE32);
  }

  /// Roda [count] nonces a partir de [startNonce].
  BatchResult run(int startNonce, int count) {
    _mineBatch(_header, startNonce, count, _target, _bestHash, _bestNonce,
        _found);
    final best = Uint8List.fromList(_bestHash.asTypedList(32));
    return BatchResult(best, _bestNonce.value, _found.value == 1);
  }

  void dispose() {
    malloc.free(_header);
    malloc.free(_target);
    malloc.free(_bestHash);
    malloc.free(_bestNonce);
    malloc.free(_found);
  }
}
