import 'dart:async';

import 'engine_ffi.dart';
import 'nnue_deployer.dart';

export 'engine_ffi.dart' show EngineOutput;

enum EngineRunState { uninitialized, initializing, ready, analyzing, error }

/// High-level UCCI/UCI controller. Singleton managing engine lifecycle:
/// 1. Deploy NNUE from assets → DocumentsDirectory
/// 2. Detect dotprod → choose libpikafish_dotprod.so or libpikafish.so
/// 3. Get native lib path via MethodChannel → spawn Process
/// 4. Perform UCI handshake (uci → uciok → setoption EvalFile → isready → readyok)
class UcciController {
  static UcciController? _instance;
  static UcciController get instance => _instance ??= UcciController._();
  UcciController._();

  EngineRunState _state = EngineRunState.uninitialized;
  EngineRunState get state => _state;

  final _outputCtrl = StreamController<EngineOutput>.broadcast();
  Stream<EngineOutput> get outputStream => _outputCtrl.stream;

  final _process = PikafishProcess();
  int _lastScore = 0;
  int get lastScore => _lastScore;
  bool _isOpponentMode = false;

  /// Full initialization.
  Future<void> initialize() async {
    if (_state == EngineRunState.ready) return;
    _state = EngineRunState.initializing;

    // 1) Deploy NNUE file to filesystem
    final nnuePath = await NnueDeployer.deploy();

    // 2) Get native library path
    final libPath = await NativeLibResolver.getLibraryPath();

    // ignore: avoid_print
    print('[Engine] lib=$libPath  nnue=$nnuePath');

    // 3) Start engine FFI session
    await _process.start(libPath);

    // 4) Forward process output to our broadcast stream
    _process.outputStream.listen((out) {
      // ignore: avoid_print
      print('[Engine Output] ${out.raw}');
      if (out.scoreCp != null) _lastScore = out.scoreCp!;
      _outputCtrl.add(out.copyWith(isOpponentMode: _isOpponentMode));
    });

    // 5) UCI/UCCI handshake
    try {
      print('[Engine] Starting UCCI/UCI handshake...');
      final ucciOk = _waitFor(
          (o) => o.raw.contains('ucciok') || o.raw.contains('uciok'),
          seconds: 60); // Increased to 60s
      _send('ucci');
      _send('uci');
      await ucciOk;
      print('[Engine] Handshake OK (ucciok/uciok received)');

      _send('setoption name MultiPV value 4');
      _send('ucinewgame');
    } catch (e) {
      _state = EngineRunState.error;
      print('[Engine] Handshake timeout/error: $e');
      rethrow;
    }

    // 6) Configure NNUE evaluation file and performance options
    print('[Engine] Configuring options (EvalFile, Hash, Threads)...');
    _send('setoption name EvalFile value $nnuePath');
    _send('setoption name Hash value 64');
    _send('setoption name Threads value 2');

    // 7) isready → readyok (confirms option was accepted)
    final readyOk =
        _waitFor((o) => o.raw == 'readyok', seconds: 60); // Increased to 60s
    _send('isready');
    await readyOk;

    _state = EngineRunState.ready;
    print('[Engine] Ready for analysis.');
  }

  /// Configure for Max Power (Study Mode)
  void setMaxPower() {
    _send('setoption name Skill Level value 20');
    _send('setoption name Threads value 4');
    _send('setoption name Hash value 128'); // More hash for deep calc
  }

  void _send(String cmd) => _process.send(cmd);

  Future<void> _waitFor(bool Function(EngineOutput) predicate,
          {int seconds = 15}) =>
      outputStream.where(predicate).first.timeout(Duration(seconds: seconds));

  Future<void> analyzePosition(String fen,
      {int depth = 22, int movetime = 5000}) async {
    if (_state == EngineRunState.analyzing) stopAnalysis();
    _state = EngineRunState.analyzing;
    _isOpponentMode = false;
    _send('position fen $fen');
    _send('go depth $depth movetime $movetime');
  }

  /// Quick opponent analysis (e.g. 2 seconds).
  void analyzeOpponent(String fen, {int movetime = 2000}) {
    _isOpponentMode = true;
    _send('position fen $fen');
    _send('go movetime $movetime');
  }

  void stopAnalysis() {
    _send('stop');
    _state = EngineRunState.ready;
  }

  void setSkillLevel(int level) {
    _send('setoption name Skill Level value $level');
  }

  void dispose() {
    _process.dispose();
    _outputCtrl.close();
    _state = EngineRunState.uninitialized;
    _instance = null;
  }
}
