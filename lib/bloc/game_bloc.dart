import 'package:flutter_bloc/flutter_bloc.dart';
import '../game/xiangqi_model.dart';
import '../game/analysis_model.dart';
import '../services/sound_manager.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class GameEvent {}

class ResetGameEvent extends GameEvent {
  final PieceColor startingSide;
  ResetGameEvent({this.startingSide = PieceColor.red});
}

class SelectPieceEvent extends GameEvent {
  final BoardPos pos;
  SelectPieceEvent(this.pos);
}

class MakeMoveEvent extends GameEvent {
  final String ucciMove;
  MakeMoveEvent(this.ucciMove);
}

class PreviewMoveEvent extends GameEvent {
  final String ucciMove; // preview PV move on board
  PreviewMoveEvent(this.ucciMove);
}

class ClearPreviewEvent extends GameEvent {}

class UndoMoveEvent extends GameEvent {}

class StartFromFenEvent extends GameEvent {
  final String fen;
  final PieceColor playerColor;
  StartFromFenEvent({required this.fen, required this.playerColor});
}

// ─── State ───────────────────────────────────────────────────────────────────

class GameState {
  final XiangqiBoard board;
  final List<String> moveHistory; // UCCI moves
  final BoardPos? selectedPos;
  final List<BoardPos> validMoves;
  final String? previewMove;
  final String? lastMove;
  final PositionalAnalysis? positionAnalysis;

  /// Current FEN string (simplified, for engine).
  String get fen => board.toFen();

  const GameState({
    required this.board,
    this.moveHistory = const [],
    this.selectedPos,
    this.validMoves = const [],
    this.previewMove,
    this.lastMove,
    this.positionAnalysis,
  });

  GameState copyWith({
    XiangqiBoard? board,
    List<String>? moveHistory,
    BoardPos? selectedPos,
    List<BoardPos>? validMoves,
    String? previewMove,
    String? lastMove,
    PositionalAnalysis? positionAnalysis,
    bool clearSelected = false,
    bool clearPreview = false,
  }) =>
      GameState(
        board: board ?? this.board,
        moveHistory: moveHistory ?? this.moveHistory,
        selectedPos: clearSelected ? null : (selectedPos ?? this.selectedPos),
        validMoves: clearSelected ? const [] : (validMoves ?? this.validMoves),
        previewMove: clearPreview ? null : (previewMove ?? this.previewMove),
        lastMove: lastMove ?? this.lastMove,
        positionAnalysis: positionAnalysis ?? this.positionAnalysis,
      );
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class GameBloc extends Bloc<GameEvent, GameState> {
  // Keep board stack for undo
  final List<XiangqiBoard> _boardHistory = [];

  GameBloc() : super(GameState(board: XiangqiBoard.startingPosition())) {
    on<ResetGameEvent>(_onReset);
    on<SelectPieceEvent>(_onSelect);
    on<MakeMoveEvent>(_onMove);
    on<PreviewMoveEvent>(_onPreview);
    on<ClearPreviewEvent>(_onClearPreview);
    on<UndoMoveEvent>(_onUndo);
    on<StartFromFenEvent>(_onStartFromFen);
  }

  void _onReset(ResetGameEvent e, Emitter<GameState> emit) {
    _boardHistory.clear();
    emit(GameState(
      board: XiangqiBoard.startingPosition(sideToMove: e.startingSide),
    ));
  }

  void _onSelect(SelectPieceEvent e, Emitter<GameState> emit) {
    final piece = state.board.at(e.pos);
    if (piece?.color == state.board.sideToMove) {
      if (state.selectedPos == e.pos) {
        // Deselect
        emit(state.copyWith(clearSelected: true, clearPreview: true));
      } else {
        final moves = state.board.getValidMoves(e.pos);
        emit(state.copyWith(
            selectedPos: e.pos, validMoves: moves, clearPreview: true));
      }
    } else {
      emit(state.copyWith(clearSelected: true));
    }
  }

  void _onMove(MakeMoveEvent e, Emitter<GameState> emit) {
    final toPos = BoardPos.fromUcci(e.ucciMove.substring(2, 4));
    final isCapture = state.board.at(toPos!) != null;

    _boardHistory.add(state.board);
    final newBoard = state.board.applyMove(e.ucciMove);

    // Play Sound
    if (newBoard.isCheck(newBoard.sideToMove)) {
      SoundManager().playCheck();
    } else if (isCapture) {
      SoundManager().playCapture();
    } else {
      SoundManager().playMove();
    }

    emit(state.copyWith(
      board: newBoard,
      moveHistory: [...state.moveHistory, e.ucciMove],
      lastMove: e.ucciMove,
      clearSelected: true,
      clearPreview: true,
    ));
  }

  void _onPreview(PreviewMoveEvent e, Emitter<GameState> emit) {
    emit(state.copyWith(previewMove: e.ucciMove));
  }

  void _onClearPreview(ClearPreviewEvent e, Emitter<GameState> emit) {
    emit(state.copyWith(clearPreview: true));
  }

  void _onUndo(UndoMoveEvent e, Emitter<GameState> emit) {
    if (_boardHistory.isEmpty) return;
    final prevBoard = _boardHistory.removeLast();
    final newHistory = [...state.moveHistory];
    if (newHistory.isNotEmpty) newHistory.removeLast();

    emit(state.copyWith(
      board: prevBoard,
      moveHistory: newHistory,
      lastMove: newHistory.isNotEmpty ? newHistory.last : null,
      clearSelected: true,
      clearPreview: true,
    ));
  }

  void _onStartFromFen(StartFromFenEvent e, Emitter<GameState> emit) {
    _boardHistory.clear();
    emit(GameState(
      board: XiangqiBoard.fromFen(e.fen),
      moveHistory: const [],
    ));
  }
}
