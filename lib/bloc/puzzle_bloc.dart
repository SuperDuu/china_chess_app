import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/xiangqi_model.dart';
import '../game/puzzle.dart';
import '../game/notation_translator.dart';
import '../services/sound_manager.dart';

// --- Events ---
abstract class PuzzleEvent {}

class LoadPuzzlesEvent extends PuzzleEvent {}

class SelectPuzzleEvent extends PuzzleEvent {
  final int index;
  SelectPuzzleEvent(this.index);
}

class MakePuzzleMoveEvent extends PuzzleEvent {
  final String ucciMove;
  MakePuzzleMoveEvent(this.ucciMove);
}

class ShowHintEvent extends PuzzleEvent {}

class ShowSolutionEvent extends PuzzleEvent {}

class ResetPuzzleEvent extends PuzzleEvent {}

class NextPuzzleEvent extends PuzzleEvent {}

class PreviousPuzzleEvent extends PuzzleEvent {}

// --- State ---
class PuzzleState {
  final List<Puzzle> puzzles;
  final int currentIndex;
  final XiangqiBoard board;
  final List<String> movesMade;
  final Set<String> solvedPuzzleIds;
  final bool isSolved;
  final bool isFailed;
  final bool showHint;
  final bool showSolution;
  final String? hintText;
  final String? detailedExplanation;
  final BoardPos? hintFrom;
  final BoardPos? hintTo;
  final List<String> vietnameseHistory;
  final String? vietnameseSolution;

  PuzzleState({
    this.puzzles = const [],
    this.currentIndex = 0,
    required this.board,
    this.movesMade = const [],
    this.solvedPuzzleIds = const {},
    this.isSolved = false,
    this.isFailed = false,
    this.showHint = false,
    this.showSolution = false,
    this.hintText,
    this.detailedExplanation,
    this.hintFrom,
    this.hintTo,
    this.vietnameseHistory = const [],
    this.vietnameseSolution,
  });

  PuzzleState copyWith({
    List<Puzzle>? puzzles,
    int? currentIndex,
    XiangqiBoard? board,
    List<String>? movesMade,
    Set<String>? solvedPuzzleIds,
    bool? isSolved,
    bool? isFailed,
    bool? showHint,
    bool? showSolution,
    String? hintText,
    String? detailedExplanation,
    BoardPos? hintFrom,
    BoardPos? hintTo,
    List<String>? vietnameseHistory,
    String? vietnameseSolution,
    bool clearHint = false,
  }) =>
      PuzzleState(
        puzzles: puzzles ?? this.puzzles,
        currentIndex: currentIndex ?? this.currentIndex,
        board: board ?? this.board,
        movesMade: movesMade ?? this.movesMade,
        solvedPuzzleIds: solvedPuzzleIds ?? this.solvedPuzzleIds,
        isSolved: isSolved ?? this.isSolved,
        isFailed: isFailed ?? this.isFailed,
        showHint: showHint ?? this.showHint,
        showSolution: showSolution ?? this.showSolution,
        hintText: clearHint ? null : (hintText ?? this.hintText),
        detailedExplanation: clearHint
            ? null
            : (detailedExplanation ?? this.detailedExplanation),
        hintFrom: clearHint ? null : (hintFrom ?? this.hintFrom),
        hintTo: clearHint ? null : (hintTo ?? this.hintTo),
        vietnameseHistory: vietnameseHistory ?? this.vietnameseHistory,
        vietnameseSolution: vietnameseSolution ?? this.vietnameseSolution,
      );
}

// --- Bloc ---
class PuzzleBloc extends Bloc<PuzzleEvent, PuzzleState> {
  PuzzleBloc()
      : super(PuzzleState(
          board: XiangqiBoard.startingPosition(),
          hintFrom: null,
          hintTo: null,
          detailedExplanation: null,
        )) {
    on<LoadPuzzlesEvent>(_onLoad);
    on<SelectPuzzleEvent>(_onSelect);
    on<MakePuzzleMoveEvent>(_onMove);
    on<ShowHintEvent>(_onShowHint);
    on<ShowSolutionEvent>(_onShowSolution);
    on<ResetPuzzleEvent>(_onReset);
    on<NextPuzzleEvent>(_onNext);
    on<PreviousPuzzleEvent>(_onPrevious);
  }

  Future<void> _onLoad(LoadPuzzlesEvent e, Emitter<PuzzleState> emit) async {
    try {
      final jsonStr =
          await rootBundle.loadString('assets/puzzles/all_puzzles.json');
      final List<dynamic> jsonData = jsonDecode(jsonStr);
      final puzzles = jsonData.map((p) => Puzzle.fromJson(p)).toList();

      final prefs = await SharedPreferences.getInstance();
      final solved = prefs.getStringList('solved_puzzles')?.toSet() ?? {};

      emit(state.copyWith(
        puzzles: puzzles,
        solvedPuzzleIds: solved,
      ));

      if (puzzles.isNotEmpty) {
        add(SelectPuzzleEvent(0));
      }
    } catch (e) {
      print('Error loading puzzles: $e');
    }
  }

  void _onSelect(SelectPuzzleEvent e, Emitter<PuzzleState> emit) {
    if (e.index < 0 || e.index >= state.puzzles.length) return;

    final puzzle = state.puzzles[e.index];
    emit(state.copyWith(
      currentIndex: e.index,
      board: XiangqiBoard.fromFen(puzzle.fen),
      movesMade: [],
      isSolved: false,
      isFailed: false,
      showHint: false,
      showSolution: false,
      hintText: null,
      detailedExplanation: null,
      hintFrom: null,
      hintTo: null,
      vietnameseHistory: [],
      vietnameseSolution: _calculateVietnameseSolution(puzzle),
    ));
  }

  void _onMove(MakePuzzleMoveEvent e, Emitter<PuzzleState> emit) async {
    if (state.isSolved) return;

    final puzzle = state.puzzles[state.currentIndex];
    final solutionMoves = puzzle.solution.split(',');

    final currentStep = state.movesMade.length;
    if (currentStep >= solutionMoves.length) return;

    if (e.ucciMove == solutionMoves[currentStep]) {
      // Correct move
      final toPos = BoardPos.fromUcci(e.ucciMove.substring(2, 4));
      final isCapture = state.board.at(toPos!) != null;

      final vnMove = NotationTranslator.toVietnamese(e.ucciMove, state.board);
      final nextBoard = state.board.applyMove(e.ucciMove);
      final newMovesMade = [...state.movesMade, e.ucciMove];
      final newVnHistory = [...state.vietnameseHistory, vnMove];

      // Play Sound
      if (nextBoard.isCheck(nextBoard.sideToMove)) {
        SoundManager().playCheck();
      } else if (isCapture) {
        SoundManager().playCapture();
      } else {
        SoundManager().playMove();
      }

      final solved = newMovesMade.length == solutionMoves.length;

      emit(state.copyWith(
        board: nextBoard,
        movesMade: newMovesMade,
        vietnameseHistory: newVnHistory,
        isSolved: solved,
        isFailed: false,
        clearHint: true,
        showHint: false,
      ));

      if (solved) {
        final newSolvedIds = {...state.solvedPuzzleIds, puzzle.id};
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList('solved_puzzles', newSolvedIds.toList());
        emit(state.copyWith(solvedPuzzleIds: newSolvedIds));
      } else {
        // AUTO-PLAY OPPONENT MOVE if it's the next step in the solution
        final nextStep = newMovesMade.length;
        if (nextStep < solutionMoves.length) {
          await Future.delayed(const Duration(milliseconds: 600));
          if (!isClosed &&
              state.currentIndex == state.puzzles.indexOf(puzzle)) {
            final opponentMove = solutionMoves[nextStep];
            final vnMoveOpp =
                NotationTranslator.toVietnamese(opponentMove, nextBoard);
            final boardAfterOpponent = nextBoard.applyMove(opponentMove);
            final movesAfterOpponent = [...newMovesMade, opponentMove];
            final vnHistoryAfterOpp = [...newVnHistory, vnMoveOpp];

            final solvedAfterOpponent =
                movesAfterOpponent.length == solutionMoves.length;

            emit(state.copyWith(
              board: boardAfterOpponent,
              movesMade: movesAfterOpponent,
              vietnameseHistory: vnHistoryAfterOpp,
              isSolved: solvedAfterOpponent,
            ));

            if (solvedAfterOpponent) {
              final newSolvedIds = {...state.solvedPuzzleIds, puzzle.id};
              final prefs = await SharedPreferences.getInstance();
              await prefs.setStringList(
                  'solved_puzzles', newSolvedIds.toList());
              emit(state.copyWith(solvedPuzzleIds: newSolvedIds));
            }
          }
        }
      }
    } else {
      // Wrong move
      emit(state.copyWith(isFailed: true));
      // Auto reset after 1s
      await Future.delayed(const Duration(seconds: 1));
      if (!isClosed) {
        emit(state.copyWith(isFailed: false));
      }
    }
  }

  void _onShowHint(ShowHintEvent e, Emitter<PuzzleState> emit) {
    final puzzle = state.puzzles[state.currentIndex];
    final solutionMoves = puzzle.solution.split(',');
    final currentStep = state.movesMade.length;

    if (currentStep < solutionMoves.length) {
      final move = solutionMoves[currentStep];
      final from = BoardPos.fromUcci(move.substring(0, 2));
      final to = BoardPos.fromUcci(move.substring(2, 4));

      emit(state.copyWith(
        showHint: true,
        hintText:
            'Huấn luyện viên: Hãy chú ý quân ở vị trí ${move.substring(0, 2)}!',
        detailedExplanation: puzzle.detailedExplanation,
        hintFrom: from,
        hintTo: to,
      ));
    }
  }

  void _onShowSolution(ShowSolutionEvent e, Emitter<PuzzleState> emit) {
    emit(state.copyWith(showSolution: !state.showSolution));
  }

  void _onReset(ResetPuzzleEvent e, Emitter<PuzzleState> emit) {
    add(SelectPuzzleEvent(state.currentIndex));
  }

  void _onNext(NextPuzzleEvent e, Emitter<PuzzleState> emit) {
    if (state.currentIndex < state.puzzles.length - 1) {
      add(SelectPuzzleEvent(state.currentIndex + 1));
    }
  }

  void _onPrevious(PreviousPuzzleEvent e, Emitter<PuzzleState> emit) {
    if (state.currentIndex > 0) {
      add(SelectPuzzleEvent(state.currentIndex - 1));
    }
  }

  String _calculateVietnameseSolution(Puzzle puzzle) {
    try {
      XiangqiBoard board = XiangqiBoard.fromFen(puzzle.fen);
      final moves = puzzle.solution.split(',');
      final List<String> result = [];

      for (final move in moves) {
        result.add(NotationTranslator.toVietnamese(move, board));
        board = board.applyMove(move);
      }
      return result.join(' → ');
    } catch (e) {
      return puzzle.solution.replaceAll(',', ' → ');
    }
  }
}
