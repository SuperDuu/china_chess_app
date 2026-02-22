import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';

// --- FFI Typedefs ---
typedef EngineInitNative = Void Function();
typedef EngineInit = void Function();

typedef EngineMainLoopNative = Void Function();
typedef EngineMainLoop = void Function();

typedef EngineSendCommandNative = Void Function(Pointer<Utf8>);
typedef EngineSendCommand = void Function(Pointer<Utf8>);

typedef EngineReadLineNative = Pointer<Utf8> Function();
typedef EngineReadLine = Pointer<Utf8> Function();

// ─── Engine output model ─────────────────────────────────────────────────────

class EngineOutput {
  final String raw;
  final int? depth;
  final int? scoreCp;
  final bool isMate;
  final int? mateIn;
  final List<String>? pvMoves;
  final String? bestMove;
  final int? nps;
  final int? multiPv;
  final bool isOpponentMode;

  const EngineOutput({
    required this.raw,
    this.depth,
    this.scoreCp,
    this.isMate = false,
    this.mateIn,
    this.pvMoves,
    this.bestMove,
    this.nps,
    this.multiPv,
    this.isOpponentMode = false,
  });

  bool get isInfo =>
      depth != null || scoreCp != null || nps != null || pvMoves != null;
  bool get isBestMove => bestMove != null;

  factory EngineOutput.parse(String line) {
    final trimmed = line.trim();
    if (trimmed.startsWith('bestmove')) {
      final parts = trimmed.split(' ');
      final move = parts.length > 1 ? parts[1] : null;
      return EngineOutput(
          raw: trimmed, bestMove: move == '(none)' ? null : move);
    }
    if (!trimmed.startsWith('info')) return EngineOutput(raw: trimmed);

    int? depth, scoreCp, mateIn, nps, multiPv;
    bool isMate = false;
    List<String>? pvMoves;

    final parts = trimmed.split(' ');
    for (int i = 0; i < parts.length; i++) {
      switch (parts[i]) {
        case 'depth':
          if (i + 1 < parts.length) depth = int.tryParse(parts[i + 1]);
        case 'cp':
          if (i + 1 < parts.length) scoreCp = int.tryParse(parts[i + 1]);
        case 'mate':
          if (i + 1 < parts.length) {
            isMate = true;
            mateIn = int.tryParse(parts[i + 1]);
          }
        case 'nps':
          if (i + 1 < parts.length) nps = int.tryParse(parts[i + 1]);
        case 'multipv':
          if (i + 1 < parts.length) multiPv = int.tryParse(parts[i + 1]);
        case 'pv':
          pvMoves = parts
              .sublist(i + 1)
              .where((s) => s.isNotEmpty && !s.startsWith('string'))
              .toList();
      }
    }

    return EngineOutput(
      raw: trimmed,
      depth: depth,
      scoreCp: scoreCp,
      isMate: isMate,
      mateIn: mateIn,
      pvMoves: pvMoves,
      nps: nps,
      multiPv: multiPv,
      // isOpponentMode will be set by the controller using copyWith
    );
  }

  EngineOutput copyWith({bool? isOpponentMode}) => EngineOutput(
        raw: raw,
        depth: depth,
        scoreCp: scoreCp,
        isMate: isMate,
        mateIn: mateIn,
        pvMoves: pvMoves,
        bestMove: bestMove,
        nps: nps,
        multiPv: multiPv,
        isOpponentMode: isOpponentMode ?? this.isOpponentMode,
      );

  @override
  String toString() => raw;
}

// ─── Native library path resolver ────────────────────────────────────────────

class NativeLibResolver {
  static const _channel = MethodChannel('com.example.china_chess_app/engine');
  static String? _cachedDir;

  static Future<String> getNativeLibDir() async {
    if (!Platform.isAndroid) throw UnsupportedError('Android only');
    _cachedDir ??= await _channel.invokeMethod<String>('getNativeLibraryDir');
    return _cachedDir!;
  }

  static Future<String> getLibraryPath() async {
    final nativeDir = await getNativeLibDir();
    return '$nativeDir/libpikafish.so';
  }
}

// ─── FFI-based engine runner ─────────────────────────────────────────────────

class PikafishProcess {
  final _outputController = StreamController<EngineOutput>.broadcast();
  Stream<EngineOutput> get outputStream => _outputController.stream;

  DynamicLibrary? _lib;
  late EngineInit _engineInit;
  late EngineSendCommand _engineSendCommand;
  late EngineReadLine _engineReadLine;

  bool _running = false;
  bool get isRunning => _running;

  Future<void> start(String libPath) async {
    if (_running) {
      print('[Engine] Process already running, ignoring start request.');
      return;
    }
    print('[Engine] Loading FFI library: $libPath');
    _lib = DynamicLibrary.open(libPath);

    _engineInit =
        _lib!.lookupFunction<EngineInitNative, EngineInit>('engine_init');
    _engineSendCommand = _lib!
        .lookupFunction<EngineSendCommandNative, EngineSendCommand>(
            'engine_send_command');
    _engineReadLine = _lib!
        .lookupFunction<EngineReadLineNative, EngineReadLine>(
            'engine_read_line');

    print('[Engine] Initializing native bitboards...');
    _engineInit();

    // Start native main loop in a separate isolate or thread?
    // Stockfish loop is blocking. We must run it in a separate thread on the C++ side
    // or use a Dart Isolate. However, our bridge handles the thread safety.

    // Launch engine_main_loop in a background thread via C++ (easy way)
    // or Isolate (requires more FFI plumbing).
    // Let's use the C++ bridge we wrote which starts uci->loop().

    // We'll use a compute-like isolate to run the blocking loop
    _running = true;
    Isolate.spawn(_engineIsolate, libPath);

    // Start polling for output
    _startPolling();
  }

  static void _engineIsolate(String libPath) {
    final lib = DynamicLibrary.open(libPath);
    final loop = lib.lookupFunction<EngineMainLoopNative, EngineMainLoop>(
        'engine_main_loop');
    loop();
  }

  void _startPolling() {
    Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (!_running) {
        timer.cancel();
        return;
      }

      while (true) {
        final ptr = _engineReadLine();
        if (ptr == nullptr) break;

        final line = ptr.toDartString();
        if (line.isNotEmpty) {
          _outputController.add(EngineOutput.parse(line));
        }
      }
    });
  }

  void send(String cmd) {
    if (!_running) return;
    final ptr = cmd.toNativeUtf8();
    _engineSendCommand(ptr);
    malloc.free(ptr);
  }

  void dispose() {
    if (_running) {
      send('quit');
      _running = false;
    }
    _outputController.close();
  }
}
