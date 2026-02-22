import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../engine/ucci_controller.dart';

// ─── Events ─────────────────────────────────────────────────────────────────

abstract class EngineEvent {}

class InitializeEngineEvent extends EngineEvent {}

class AnalyzePositionEvent extends EngineEvent {
  final String fen;
  AnalyzePositionEvent(this.fen);
}

class AnalyzeUndoEvent extends EngineEvent {
  final String fen;
  AnalyzeUndoEvent(this.fen);
}

class StopAnalysisEvent extends EngineEvent {}

class _EngineAnalysisUpdateInternalEvent extends EngineEvent {
  final EngineAnalyzingState state;
  _EngineAnalysisUpdateInternalEvent(this.state);
}

// ─── States ─────────────────────────────────────────────────────────────────

abstract class EngineState {}

class EngineInitial extends EngineState {}

class EngineLoading extends EngineState {}

class EngineReady extends EngineState {}

class EngineAnalyzingState extends EngineState {
  final EngineOutput latestOutput;
  EngineAnalyzingState(this.latestOutput);
}

class EngineErrorState extends EngineState {
  final String message;
  EngineErrorState(this.message);
}

// ─── BLoC ────────────────────────────────────────────────────────────────────

class EngineBloc extends Bloc<EngineEvent, EngineState> {
  final UcciController _controller;
  StreamSubscription<EngineAnalyzingState>? _analysisSub;

  EngineBloc({UcciController? controller})
      : _controller = controller ?? UcciController.instance,
        super(EngineInitial()) {
    on<InitializeEngineEvent>(_onInitialize);
    on<AnalyzePositionEvent>(_onAnalyze);
    on<AnalyzeUndoEvent>(_onAnalyzeUndo);
    on<StopAnalysisEvent>(_onStop);
    on<_EngineAnalysisUpdateInternalEvent>(_onInternalUpdate);
  }

  Future<void> _onInitialize(
      InitializeEngineEvent event, Emitter<EngineState> emit) async {
    emit(EngineLoading());
    try {
      await _controller.initialize();
      emit(EngineReady());
    } catch (e) {
      emit(EngineErrorState('Không thể khởi động engine: $e'));
    }
  }

  Future<void> _onAnalyze(
      AnalyzePositionEvent event, Emitter<EngineState> emit) async {
    // 1) Stop previous analysis subscription
    await _analysisSub?.cancel();

    // 2) Trigger engine to analyze new position
    await _controller.analyzePosition(event.fen);

    // 3) Create new subscription for this position
    _analysisSub = _controller.outputStream
        .where((o) => o.isInfo || o.isBestMove)
        .map((out) => EngineAnalyzingState(out))
        .listen((state) {
      if (!isClosed) add(_EngineAnalysisUpdateInternalEvent(state));
    });
  }

  Future<void> _onAnalyzeUndo(
      AnalyzeUndoEvent event, Emitter<EngineState> emit) async {
    await _analysisSub?.cancel();
    // Stop current analysis explicitly to free CPU
    _controller.stopAnalysis();

    // Analyze with 2000ms exactly as requested
    await _controller.analyzePosition(event.fen, movetime: 2000);

    _analysisSub = _controller.outputStream
        .where((o) => o.isInfo || o.isBestMove)
        .map((out) => EngineAnalyzingState(out))
        .listen((state) {
      if (!isClosed) add(_EngineAnalysisUpdateInternalEvent(state));
    });
  }

  Future<void> _onStop(
      StopAnalysisEvent event, Emitter<EngineState> emit) async {
    await _analysisSub?.cancel();
    _controller.stopAnalysis();
    emit(EngineReady());
  }

  void _onInternalUpdate(
      _EngineAnalysisUpdateInternalEvent event, Emitter<EngineState> emit) {
    emit(event.state);
  }

  @override
  Future<void> close() {
    _analysisSub?.cancel();
    // Do NOT dispose the singleton controller here.
    // Pikafish native state is global; re-initializing crashes the thread.
    return super.close();
  }
}
