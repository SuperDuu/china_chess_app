import 'package:flutter_bloc/flutter_bloc.dart';
import '../game/xiangqi_model.dart';
import '../game/analysis_model.dart';
import '../game/notation_translator.dart';
import '../engine/ucci_controller.dart';

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

class DismissHintEvent extends AnalysisEvent {}

// ─── State ───────────────────────────────────────────────────────────────────

class AnalysisState {
  final EngineOutput? latestOutput;
  final List<ThreatInfo> threats;
  final OpponentIntent? opponentIntent;
  final bool showingHint;
  final String? hintQuestion;
  final String? opponentBestMove;
  final PositionalAnalysis? positionAnalysis;
  final Map<int, EngineOutput> multiPvs;
  final Map<int, List<String>> translatedPvs;
  final String? pvExplanation;

  const AnalysisState({
    this.latestOutput,
    this.threats = const [],
    this.opponentIntent,
    this.showingHint = false,
    this.hintQuestion,
    this.opponentBestMove,
    this.positionAnalysis,
    this.multiPvs = const {},
    this.translatedPvs = const {},
    this.pvExplanation,
  });

  AnalysisState copyWith({
    EngineOutput? latestOutput,
    List<ThreatInfo>? threats,
    OpponentIntent? opponentIntent,
    bool? showingHint,
    String? hintQuestion,
    String? opponentBestMove,
    PositionalAnalysis? positionAnalysis,
    Map<int, EngineOutput>? multiPvs,
    Map<int, List<String>>? translatedPvs,
    String? pvExplanation,
  }) =>
      AnalysisState(
        latestOutput: latestOutput ?? this.latestOutput,
        threats: threats ?? this.threats,
        opponentIntent: opponentIntent ?? this.opponentIntent,
        showingHint: showingHint ?? this.showingHint,
        hintQuestion: hintQuestion ?? this.hintQuestion,
        opponentBestMove: opponentBestMove ?? this.opponentBestMove,
        positionAnalysis: positionAnalysis ?? this.positionAnalysis,
        multiPvs: multiPvs ?? this.multiPvs,
        translatedPvs: translatedPvs ?? this.translatedPvs,
        pvExplanation: pvExplanation ?? this.pvExplanation,
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

  AnalysisBloc({UcciController? controller})
      : _ctrl = controller ?? UcciController.instance,
        super(const AnalysisState()) {
    on<UpdateAnalysisEvent>(_onUpdate);
    on<RequestHintEvent>(_onHint);
    on<DismissHintEvent>(_onDismiss);
  }

  String? _lastAnalyzedFen;

  void _onUpdate(UpdateAnalysisEvent e, Emitter<AnalysisState> emit) async {
    final output = e.output;
    final currentPlayer = e.board.sideToMove;
    final fen = e.board.toFen();

    // 1) Clear multiPvs/translatedPvs if FEN changed
    final Map<int, EngineOutput> currentMultiPvs =
        (_lastAnalyzedFen != fen) ? {} : Map.from(state.multiPvs);
    final Map<int, List<String>> currentTranslatedPvs =
        (_lastAnalyzedFen != fen) ? {} : Map.from(state.translatedPvs);
    _lastAnalyzedFen = fen;

    if (output.multiPv != null) {
      currentMultiPvs[output.multiPv!] = output;

      // Translate PV moves
      if (output.pvMoves != null) {
        final moves = output.pvMoves!;
        final translated = <String>[];
        var tempBoard = e.board;
        for (final m in moves.take(12)) {
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
    if (output.isBestMove && output.bestMove != null) {
      // However, we must ensure it matches the actual side to move.
      if (currentPlayer == e.board.sideToMove) {
        intent = AnalysisModel.parseOpponentIntent(
          output.bestMove,
          e.board,
          currentPlayer == PieceColor.red ? PieceColor.black : PieceColor.red,
        );
      }
    }

    // --- Positional analysis ---
    PositionalAnalysis? posAnalysis = state.positionAnalysis;
    if (output.scoreCp != null) {
      final materialScore = AnalysisModel.calculateMaterialScore(e.board);
      // materialDiff from perspective of sideToMove
      final diff =
          currentPlayer == PieceColor.red ? materialScore : -materialScore;
      final engineScore = output.scoreCp!;
      // Positional bonus is how much engine likes the position BEYOND mere material
      final posBonus = engineScore - diff;

      // Has the material dropped, but engine score stayed strong (meaning positional bonus spiked)?
      bool isSacrifice = false;
      if (state.positionAnalysis != null) {
        final prevMat = state.positionAnalysis!.materialDiff;
        final prevBonus = state.positionAnalysis!.positionalBonus;
        // Sacrificed material but gained positional compensation
        if (diff < prevMat && posBonus > prevBonus + 100) {
          isSacrifice = true;
        }
      }

      posAnalysis = PositionalAnalysis(
        materialDiff: diff,
        engineScore: engineScore,
        positionalBonus: posBonus,
        isSacrifice: isSacrifice,
        tempoAnalysis: _analyzeTempo(e.board, currentPlayer),
      );
    }

    String? pvExpl;
    if (output.pvMoves != null &&
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
      pvExpl =
          'Vũ Đức Du Mentor: Nước đi này tối ưu vì nó trực tiếp uy hiếp quân mạnh nhất của đối phương sau ${moves.length} nhịp.';
    }

    emit(state.copyWith(
      latestOutput: output,
      threats: threats,
      opponentIntent: intent ?? state.opponentIntent,
      opponentBestMove:
          output.isBestMove ? output.bestMove : state.opponentBestMove,
      positionAnalysis: posAnalysis,
      multiPvs: currentMultiPvs,
      translatedPvs: currentTranslatedPvs,
      pvExplanation: pvExpl,
    ));

    // If score dropped significantly, also run opponent intent analysis
    if (output.isBestMove && output.bestMove != null && scoreDrop < -150) {
      // The engine just found a bestmove for us; now get opponent response
      final enemyFen = _flipFen(output, e.board);
      // 5) Trigger opponent intent analysis (ONLY if it's a new position)
      if (enemyFen != null && enemyFen != _lastAnalyzedFen) {
        _lastAnalyzedFen = enemyFen;
        _ctrl.analyzeOpponent(enemyFen);
      }
    }
  }

  void _onHint(RequestHintEvent e, Emitter<AnalysisState> emit) {
    final q =
        _selectHintQuestion(e.board, state.threats, state.positionAnalysis);
    emit(state.copyWith(showingHint: true, hintQuestion: q));
  }

  void _onDismiss(DismissHintEvent e, Emitter<AnalysisState> emit) {
    emit(state.copyWith(showingHint: false));
  }

  String? _flipFen(EngineOutput o, XiangqiBoard b) {
    if (o.bestMove == null) return null;

    // Flip side to move to see what the opponent would do
    final fen = b.toFen(); // Current position
    final parts = fen.split(' ');
    if (parts.length < 2) return null;

    final boardPart = parts[0];
    final side = parts[1] == 'w' ? 'b' : 'w';

    return '$boardPart $side';
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
