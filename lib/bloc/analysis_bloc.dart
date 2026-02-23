import 'package:flutter_bloc/flutter_bloc.dart';
import '../game/xiangqi_model.dart';
import '../game/analysis_model.dart';
import '../game/notation_translator.dart';
import '../engine/ucci_controller.dart';
import '../services/gemini_service.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class AnalysisEvent {}

class UpdateAnalysisEvent extends AnalysisEvent {
  final EngineOutput output;
  final XiangqiBoard board;
  UpdateAnalysisEvent(this.output, this.board);
}

class RequestHintEvent extends AnalysisEvent {
  final XiangqiBoard board;
  RequestHintEvent(this.board);
}

class RequestGeminiAnalysisEvent extends AnalysisEvent {
  final String fen;
  final List<EngineOutput> topMoves; // Store top 3 moves for comparison
  RequestGeminiAnalysisEvent({
    required this.fen,
    required this.topMoves,
  });
}

class ChangeTabEvent extends AnalysisEvent {
  final int index;
  ChangeTabEvent(this.index);
}

class DismissHintEvent extends AnalysisEvent {}

class ResetAnalysisEvent extends AnalysisEvent {}

class SetHumanColorEvent extends AnalysisEvent {
  final PieceColor? color;
  SetHumanColorEvent(this.color);
}

// ─── State ───────────────────────────────────────────────────────────────────

class AnalysisState {
  final XiangqiBoard board;
  final EngineOutput? latestOutput;
  final List<ThreatInfo> threats;
  final OpponentIntent? opponentIntent;
  final bool showingHint;
  final String? hintQuestion;
  final String? opponentBestMove;
  final PositionalAnalysis? positionAnalysis;
  final Map<int, EngineOutput> multiPvs;
  final Map<int, List<String>> translatedPvs;
  final PieceColor sideToAnalyze;
  final String? pvExplanation;
  final String? geminiExplanation;
  final bool isGeminiLoading;
  final String? lastGeminiFen;
  final Map<int, EngineOutput> pendingMultiPvs;
  final PieceColor? humanColor;
  final int activeTabIndex;

  AnalysisState({
    XiangqiBoard? board,
    this.latestOutput,
    this.threats = const [],
    this.opponentIntent,
    this.showingHint = false,
    this.hintQuestion,
    this.opponentBestMove,
    this.positionAnalysis,
    this.multiPvs = const {},
    this.translatedPvs = const {},
    this.sideToAnalyze = PieceColor.red,
    this.pvExplanation,
    this.geminiExplanation,
    this.isGeminiLoading = false,
    this.lastGeminiFen,
    this.pendingMultiPvs = const {},
    this.humanColor,
    this.activeTabIndex = 0,
  }) : board = board ?? XiangqiBoard.startingPosition();

  AnalysisState copyWith({
    EngineOutput? latestOutput,
    XiangqiBoard? board,
    List<ThreatInfo>? threats,
    OpponentIntent? opponentIntent,
    bool? showingHint,
    String? hintQuestion,
    String? opponentBestMove,
    PositionalAnalysis? positionAnalysis,
    Map<int, EngineOutput>? multiPvs,
    Map<int, List<String>>? translatedPvs,
    PieceColor? sideToAnalyze,
    String? pvExplanation,
    String? geminiExplanation,
    bool? isGeminiLoading,
    String? lastGeminiFen,
    Map<int, EngineOutput>? pendingMultiPvs,
    PieceColor? humanColor,
    int? activeTabIndex,
    bool clearGemini = false,
    bool clearHumanColor = false,
  }) =>
      AnalysisState(
        board: board ?? this.board,
        latestOutput: latestOutput ?? this.latestOutput,
        threats: threats ?? this.threats,
        opponentIntent: opponentIntent ?? this.opponentIntent,
        showingHint: showingHint ?? this.showingHint,
        hintQuestion: hintQuestion ?? this.hintQuestion,
        opponentBestMove: opponentBestMove ?? this.opponentBestMove,
        positionAnalysis: positionAnalysis ?? this.positionAnalysis,
        multiPvs: multiPvs ?? this.multiPvs,
        translatedPvs: translatedPvs ?? this.translatedPvs,
        sideToAnalyze: sideToAnalyze ?? this.sideToAnalyze,
        pvExplanation: pvExplanation ?? this.pvExplanation,
        geminiExplanation:
            clearGemini ? null : (geminiExplanation ?? this.geminiExplanation),
        isGeminiLoading: isGeminiLoading ?? this.isGeminiLoading,
        lastGeminiFen:
            clearGemini ? null : (lastGeminiFen ?? this.lastGeminiFen),
        pendingMultiPvs:
            pendingMultiPvs ?? (clearGemini ? {} : this.pendingMultiPvs),
        humanColor: clearHumanColor ? null : (humanColor ?? this.humanColor),
        activeTabIndex: activeTabIndex ?? this.activeTabIndex,
      );

  /// Generates the explanation message.
  String? get explanation {
    if (latestOutput == null || positionAnalysis == null) return null;

    // Sacrifice logic
    if (positionAnalysis!.isSacrifice) {
      return 'Chiến thuật Phế quân lấy thế: Chấp nhận bỏ quân để tạo sát cục/chiếm lộ sườn.';
    }

    // PV Logic
    if (pvExplanation != null) {
      return pvExplanation;
    }

    return null;
  }
}

// ─── Socratic question templates ─────────────────────────────────────────────

String _selectHintQuestion(
    XiangqiBoard board, List<ThreatInfo> threats, PositionalAnalysis? pos) {
  // Check for bad material capture ("tham ăn quân")
  if (pos != null) {
    // If material diff indicates a gain, but posBonus dropped severely
    // Note: The bloc hasn't saved the 'previous' state here easily, but we can look at the current posBonus.
    // However, if we just want a simple rule: if posBonus is highly negative despite being up material.
    if (pos.materialDiff > 200 && pos.positionalBonus < -300) {
      return '⚠️ Sai lầm! Bạn đang tham ăn quân mà hở thế trận. Điểm thế trận đang là ${pos.positionalBonus}.';
    }

    if (pos.isSacrifice) {
      return '🔥 Tuyệt vời! Bạn đang thực hiện một nước phế quân lấy thế. Bạn có thấy sát cục hoặc đường tấn công mở ra không?';
    }
  }

  if (threats.any(
      (t) => t.isUnprotected && t.threatenedPiece.type == PieceType.chariot)) {
    return '🔍 Hãy nhìn kỹ vào Xe của bạn — bạn có thấy quân nào đang bảo vệ nó không?';
  }
  if (threats.any((t) => t.isUnprotected)) {
    final t = threats.firstWhere((t) => t.isUnprotected);
    return '💡 ${t.threatenedPiece.vietnameseName} tại ${t.threatenedPiece.position.toUcci()} '
        'đang bị treo. Bạn có thể rút lui hoặc bổ sung quân bảo vệ không?';
  }
  if (threats.any((t) => t.threatenedPiece.type == PieceType.cannon)) {
    return '🎯 Hãy nhìn vào đường chéo Pháo đối phương — bạn thấy quân nào đang nguy hiểm không?';
  }
  return '🤔 Trước khi đi, hãy tự hỏi: "Nếu mình đi nước này, đối thủ có thể phản công như thế nào?"';
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class AnalysisBloc extends Bloc<AnalysisEvent, AnalysisState> {
  final UcciController _ctrl;
  final GeminiService _gemini = GeminiService();

  AnalysisBloc({UcciController? controller})
      : _ctrl = controller ?? UcciController.instance,
        super(AnalysisState()) {
    on<UpdateAnalysisEvent>(_onUpdate);
    on<RequestHintEvent>(_onHint);
    on<RequestGeminiAnalysisEvent>(_onGeminiAnalysis);
    on<DismissHintEvent>(_onDismiss);
    on<ResetAnalysisEvent>(_onReset);
    on<SetHumanColorEvent>(_onSetHumanColor);
    on<ChangeTabEvent>(_onChangeTab);
  }

  void _onChangeTab(ChangeTabEvent e, Emitter<AnalysisState> emit) {
    emit(state.copyWith(activeTabIndex: e.index));
  }

  void _onReset(ResetAnalysisEvent e, Emitter<AnalysisState> emit) {
    emit(state.copyWith(
      clearGemini: true,
      latestOutput: null,
      multiPvs: {},
      pendingMultiPvs: {},
      translatedPvs: {},
      showingHint: false,
    ));
    _lastAnalyzedFen = null;
  }

  String? _lastAnalyzedFen;

  void _onUpdate(UpdateAnalysisEvent e, Emitter<AnalysisState> emit) async {
    final output = e.output;
    final currentPlayer = e.board.sideToMove;
    final fen = e.board.toFen();

    final fenChanged = _lastAnalyzedFen != fen;

    // 1) Clear multiPvs if FEN changed
    final Map<int, EngineOutput> currentMultiPvs =
        fenChanged ? {} : Map.from(state.multiPvs);
    final Map<int, List<String>> currentTranslatedPvs =
        fenChanged ? {} : Map.from(state.translatedPvs);
    _lastAnalyzedFen = fen;

    if (!output.isOpponentMode && output.multiPv != null) {
      currentMultiPvs[output.multiPv!] = output;

      // Translate visible PVs immediately for real-time arrows
      if (output.pvMoves != null) {
        final translated = <String>[];
        var tempBoard = e.board;
        for (final m in output.pvMoves!.take(12)) {
          translated.add(NotationTranslator.toVietnamese(m, tempBoard));
          tempBoard = tempBoard.applyMove(m);
        }
        currentTranslatedPvs[output.multiPv!] = translated;
      }
    }

    final threats = AnalysisModel.detectThreats(e.board, currentPlayer);

    final prevScore = state.latestOutput?.scoreCp ?? 0;
    final scoreDrop = (output.scoreCp ?? 0) - prevScore;

    // Parse opponent intent if this is a bestmove line from opponent analysis
    OpponentIntent? intent;
    if (output.isOpponentMode && output.isBestMove && output.bestMove != null) {
      // In opponent mode, we are analyzing the state AFTER our best move.
      // So currentPlayer here is actually US (the side whose turn it was in the FEN we sent).
      final opponent =
          currentPlayer == PieceColor.red ? PieceColor.black : PieceColor.red;
      intent = AnalysisModel.parseOpponentIntent(
        output.bestMove,
        e.board,
        opponent,
      );
    }

    // --- Positional analysis ---
    PositionalAnalysis? posAnalysis = state.positionAnalysis;
    // Only update positional analysis for main analysis, not opponent mode
    if (!output.isOpponentMode && output.scoreCp != null) {
      final materialScore =
          AnalysisModel.calculateMaterialScore(e.board, currentPlayer);
      final engineScore = output.scoreCp!;
      // Positional bonus is how much engine likes the position BEYOND mere material
      final posBonus = engineScore - materialScore;

      // Has the material dropped, but engine score stayed strong (meaning positional bonus spiked)?
      bool isSacrifice = false;
      if (state.positionAnalysis != null) {
        final prevMat = state.positionAnalysis!.materialDiff;
        final prevBonus = state.positionAnalysis!.positionalBonus;
        // Sacrificed material but gained positional compensation
        if (materialScore < prevMat && posBonus > prevBonus + 100) {
          isSacrifice = true;
        }
      }

      posAnalysis = PositionalAnalysis(
        materialDiff: materialScore,
        engineScore: engineScore,
        positionalBonus: posBonus,
        isSacrifice: isSacrifice,
        tempoAnalysis: _analyzeTempo(e.board, currentPlayer),
      );
    }

    String? pvExpl;
    // Only update explanation for main analysis
    if (!output.isOpponentMode &&
        output.pvMoves != null &&
        output.pvMoves!.length >= 4 &&
        output.scoreCp != null) {
      // Simulate PV moves to translate them accurately
      final moves = output.pvMoves!.take(4).toList();
      final translatedMoves = <String>[];
      var tempBoard = e.board;
      for (final m in moves) {
        translatedMoves.add(NotationTranslator.toVietnamese(m, tempBoard));
        tempBoard = tempBoard.applyMove(m);
      }
      final sideName = currentPlayer == PieceColor.red ? 'Đỏ' : 'Đen';
      pvExpl =
          'Vũ Đức Du Mentor ($sideName): Nước đi này tối ưu vì nó trực tiếp uy hiếp quân mạnh nhất của đối phương sau ${moves.length} nhịp.';
    }

    emit(state.copyWith(
      board: e.board,
      latestOutput: output,
      threats: threats,
      opponentIntent: intent ?? state.opponentIntent,
      opponentBestMove:
          output.isBestMove ? output.bestMove : state.opponentBestMove,
      positionAnalysis: posAnalysis,
      multiPvs: currentMultiPvs,
      pendingMultiPvs: const {}, // No longer using pending system
      translatedPvs: currentTranslatedPvs,
      sideToAnalyze: currentPlayer,
      pvExplanation: pvExpl,
      clearGemini: fenChanged, // Clear if FEN changed
    ));

    // If score dropped significantly, also run opponent intent analysis
    // ONLY trigger this from main analysis (NOT when already in opponent mode)
    if (!output.isOpponentMode &&
        output.isBestMove &&
        output.bestMove != null &&
        scoreDrop < -150) {
      // The engine just found a bestmove for us; now get opponent response
      final nextBoard = e.board.applyMove(output.bestMove!);
      final enemyFen = nextBoard.toFen();
      // 5) Trigger opponent intent analysis
      if (enemyFen != _lastAnalyzedFen) {
        _ctrl.analyzeOpponent(enemyFen);
      }
    }
  }

  void _onHint(RequestHintEvent e, Emitter<AnalysisState> emit) {
    if (e.board.sideToMove != state.sideToAnalyze) return;

    final q =
        _selectHintQuestion(e.board, state.threats, state.positionAnalysis);
    emit(state.copyWith(showingHint: true, hintQuestion: q));
  }

  void _onDismiss(DismissHintEvent e, Emitter<AnalysisState> emit) {
    emit(state.copyWith(showingHint: false));
  }

  Future<void> _onGeminiAnalysis(
      RequestGeminiAnalysisEvent e, Emitter<AnalysisState> emit) async {
    // Side check: logic in UI handles this but safe to check here
    if (state.isGeminiLoading) return;
    // Cache check: if we already have the explanation for this position
    if (e.fen == state.lastGeminiFen && state.geminiExplanation != null) return;

    emit(state.copyWith(isGeminiLoading: true, clearGemini: true));

    final isCheck = state.board.isCheck(state.sideToAnalyze);
    final isMate = state.latestOutput?.isMate ?? false;

    // Translate the top 3 moves into Vietnamese notation
    final List<String> translatedTopMoves = [];
    for (var out in e.topMoves.take(3)) {
      if (out.pvMoves != null && out.pvMoves!.isNotEmpty) {
        final vn =
            NotationTranslator.toVietnamese(out.pvMoves![0], state.board);
        final score =
            out.isMate ? 'Sát cục' : '${(out.scoreCp ?? 0) / 100.0} điểm';
        translatedTopMoves.add('$vn ($score)');
      }
    }

    try {
      final stream = _gemini.analyzePositionStream(
        fen: e.fen,
        translatedTopMoves: translatedTopMoves,
        playerPerspective: state.humanColor ?? state.sideToAnalyze,
        isCheck: isCheck,
        isMate: isMate,
      );

      bool firstChunk = true;
      await for (final text in stream.timeout(const Duration(seconds: 30))) {
        if (firstChunk) {
          // Once we have the first bit of text, we can stop the overall loading indicator
          // although we might still be streaming.
          emit(state.copyWith(
            isGeminiLoading: false,
            geminiExplanation: text,
            lastGeminiFen: e.fen,
          ));
          firstChunk = false;
        } else {
          emit(state.copyWith(
            geminiExplanation: text,
          ));
        }
      }
    } catch (err) {
      emit(state.copyWith(
        isGeminiLoading: false,
        geminiExplanation: 'Lỗi phân tích: $err',
      ));
    }
  }

  void _onSetHumanColor(SetHumanColorEvent e, Emitter<AnalysisState> emit) {
    emit(state.copyWith(humanColor: e.color, clearHumanColor: e.color == null));
  }

  String _analyzeTempo(XiangqiBoard board, PieceColor currentPlayer) {
    // Simple tempo heuristic based on developed major pieces
    int developed = 0;
    final pieces = board.piecesOf(currentPlayer);
    for (final p in pieces) {
      if (p.type == PieceType.chariot || p.type == PieceType.horse) {
        final startRow = currentPlayer == PieceColor.red ? 9 : 0;
        if (p.position.row != startRow) developed++;
      }
    }
    if (developed >= 4) return 'Bạn đang áp đảo về tốc độ triển khai quân!';
    if (developed <= 2) {
      return 'Tốc độ ra quân chậm, cần tranh nhịp phát triển Xe/Mã.';
    }
    return 'Thế trận đang giằng co, hãy tìm cơ hội tranh tiên.';
  }
}
