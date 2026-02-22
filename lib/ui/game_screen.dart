import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/engine_bloc.dart';
import '../bloc/game_bloc.dart';
import '../bloc/analysis_bloc.dart';
import '../engine/ucci_controller.dart';
import '../ui/board/board_widget.dart';
import '../ui/analysis/analysis_dashboard.dart';
import '../ui/hint/hint_button.dart';
import '../game/xiangqi_model.dart';
import '../ui/analysis/mentor_panel.dart';

/// Main game screen combining board, controls, and analysis dashboard.
class GameScreen extends StatefulWidget {
  final int? skillLevel;
  final PieceColor? playerColor;
  const GameScreen({super.key, this.skillLevel, this.playerColor});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize the engine and reset board on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGame();
      context.read<EngineBloc>().add(InitializeEngineEvent());
    });
  }

  void _initGame() {
    final startColor = widget.playerColor ?? PieceColor.red;
    context.read<GameBloc>().add(ResetGameEvent(startingSide: startColor));
    _triggerAnalysis(XiangqiBoard.startingPosition(sideToMove: startColor));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A15),
      appBar: _buildAppBar(context),
      body: BlocListener<EngineBloc, EngineState>(
        listener: (ctx, es) {
          if (es is EngineReady) {
            // Apply skill level if combat mode
            if (widget.skillLevel != null) {
              UcciController.instance.setSkillLevel(widget.skillLevel!);
            } else {
              // Study Mode / Analysis -> Max Power
              UcciController.instance.setMaxPower();
            }
            final fen = ctx.read<GameBloc>().state.fen;
            ctx.read<EngineBloc>().add(AnalyzePositionEvent(fen));
          } else if (es is EngineAnalyzingState) {
            final output = es.latestOutput;
            final gameState = ctx.read<GameBloc>().state;
            final board = gameState.board;

            ctx.read<AnalysisBloc>().add(
                  UpdateAnalysisEvent(output, board),
                );

            // Bot Auto-Move logic
            if (widget.playerColor != null &&
                board.sideToMove != widget.playerColor &&
                output.isBestMove &&
                output.bestMove != null) {
              ctx.read<GameBloc>().add(MakeMoveEvent(output.bestMove!));

              Future.delayed(const Duration(milliseconds: 300), () {
                if (!ctx.mounted) return;
                final newFen = ctx.read<GameBloc>().state.fen;
                ctx.read<EngineBloc>().add(AnalyzePositionEvent(newFen));
              });
            }
          }
        },
        child: Column(
          children: [
            // Engine status bar
            _EngineStatusBar(),

            // Board
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: BlocBuilder<GameBloc, GameState>(
                  builder: (ctx, gameState) =>
                      BlocBuilder<AnalysisBloc, AnalysisState>(
                    builder: (ctx, analysisState) => BoardWidget(
                      gameState: gameState,
                      analysisState: analysisState,
                      onTap: (pos) => _handleBoardTap(ctx, pos, gameState),
                    ),
                  ),
                ),
              ),
            ),

            // Controls row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  const Expanded(child: HintButton()),
                  const SizedBox(width: 8),

                  // LƯỢT ĐI & GEMINI BUTTON
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Turn Indicator
                        BlocBuilder<GameBloc, GameState>(
                          builder: (ctx, state) {
                            final sideToMove = state.board.sideToMove;
                            final isRedTurn = sideToMove == PieceColor.red;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isRedTurn
                                    ? const Color(0xFFCC3333)
                                    : const Color(0xFF4A4A5A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: const Color(0xFF8B4513)
                                        .withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildTurnIndicator(sideToMove),
                                  const SizedBox(width: 8),
                                  Text(
                                    isRedTurn
                                        ? 'ĐẾN LƯỢT: ĐỎ'
                                        : 'ĐẾN LƯỢT: ĐEN',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        // GEMINI TRIGGER BUTTON
                        BlocBuilder<AnalysisBloc, AnalysisState>(
                          builder: (ctx, state) {
                            final canAnalyze = state.latestOutput != null;
                            return IconButton(
                              icon: Icon(
                                Icons.lightbulb_circle_rounded,
                                color: state.isGeminiLoading
                                    ? const Color(0xFFE8B923)
                                    : (canAnalyze
                                        ? const Color(0xFF8B4513)
                                        : Colors.grey),
                                size: 32,
                              ),
                              onPressed: (canAnalyze && !state.isGeminiLoading)
                                  ? () {
                                      final out = state.latestOutput!;
                                      ctx
                                          .read<AnalysisBloc>()
                                          .add(RequestGeminiAnalysisEvent(
                                            fen: ctx.read<GameBloc>().state.fen,
                                            score: out.scoreCp ?? 0,
                                            bestMove: out.bestMove ?? '?',
                                            pvMoves: out.pvMoves ?? [],
                                          ));
                                    }
                                  : null,
                              tooltip: 'Hỏi Cố vấn Vũ Đức Du',
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: Icons.undo_rounded,
                    label: 'Hoàn',
                    onTap: () {
                      context.read<GameBloc>().add(UndoMoveEvent());
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (!context.mounted) return;
                        final fen = context.read<GameBloc>().state.fen;
                        context.read<EngineBloc>().add(AnalyzeUndoEvent(fen));
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _ControlButton(
                    icon: Icons.refresh_rounded,
                    label: 'Mới',
                    onTap: () {
                      _initGame();
                    },
                  ),
                ],
              ),
            ),

            // GEMINI MENTOR PANEL
            const MentorPanel(),

            // Analysis dashboard
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: AnalysisDashboard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0D0D20),
      elevation: 0,
      centerTitle: false,
      title: const Row(
        children: [
          Text(
            '象棋',
            style: TextStyle(
              color: Color(0xFFE8B923),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'Vũ Đức Du',
            style: TextStyle(
              color: Color(0xFF888AAA),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        BlocBuilder<EngineBloc, EngineState>(
          builder: (ctx, state) => IconButton(
            icon: Icon(
              Icons.analytics_rounded,
              color: state is EngineReady || state is EngineAnalyzingState
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF3A3A5A),
            ),
            onPressed: state is EngineReady
                ? () {
                    final fen = ctx.read<GameBloc>().state.fen;
                    ctx.read<EngineBloc>().add(AnalyzePositionEvent(fen));
                  }
                : null,
            tooltip: 'Phân tích vị trí',
          ),
        ),
      ],
    );
  }

  void _handleBoardTap(BuildContext ctx, BoardPos pos, GameState gameState) {
    // Ignore human taps when it's the bot's turn
    if (widget.playerColor != null &&
        gameState.board.sideToMove != widget.playerColor) {
      return;
    }

    final selected = gameState.selectedPos;
    final board = gameState.board;
    final piece = board.at(pos);

    if (selected == null) {
      // Select a piece
      if (piece?.color == board.sideToMove) {
        ctx.read<GameBloc>().add(SelectPieceEvent(pos));
      }
    } else if (selected == pos) {
      // Deselect
      ctx.read<GameBloc>().add(SelectPieceEvent(pos));
    } else {
      // Attempt a move
      if (gameState.validMoves.contains(pos)) {
        final move = '${selected.toUcci()}${pos.toUcci()}';
        ctx.read<GameBloc>().add(MakeMoveEvent(move));

        // Trigger engine analysis after move
        Future.delayed(const Duration(milliseconds: 300), () {
          if (!ctx.mounted) return;
          final fen = ctx.read<GameBloc>().state.fen;
          ctx.read<EngineBloc>().add(AnalyzePositionEvent(fen));
        });
      } else {
        // If we tapped another friendly piece, select it instead
        if (piece?.color == board.sideToMove) {
          ctx.read<GameBloc>().add(SelectPieceEvent(pos));
        } else {
          // Illegal move - deselect
          ctx.read<GameBloc>().add(SelectPieceEvent(selected));
        }
      }
    }
  }

  void _triggerAnalysis(XiangqiBoard board) {
    context.read<EngineBloc>().add(AnalyzePositionEvent(board.toFen()));
  }

  Widget _buildTurnIndicator(PieceColor turn) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: turn == PieceColor.red
            ? const Color(0xFFffeb3b) // bright highlight
            : const Color(0xFFE8B923),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }
}

class _EngineStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EngineBloc, EngineState>(
      builder: (ctx, state) {
        String text;
        Color color;
        IconData icon;

        if (state is EngineLoading) {
          text = 'Đang khởi động Pikafish...';
          color = const Color(0xFFE8B923);
          icon = Icons.hourglass_top_rounded;
        } else if (state is EngineReady) {
          text = 'Engine sẵn sàng';
          color = const Color(0xFF2E7D32); // Darker green for light bg
          icon = Icons.check_circle_outline_rounded;
        } else if (state is EngineAnalyzingState) {
          final depth = state.latestOutput.depth ?? 0;
          final score = state.latestOutput.scoreCp ?? 0;
          text =
              'Đang phân tích — Độ sâu $depth | Điểm: ${(score / 100.0).toStringAsFixed(1)}';
          color = const Color(0xFF1565C0); // Darker blue
          icon = Icons.memory_rounded;
        } else if (state is EngineErrorState) {
          text = '⚠ ${state.message}';
          color = const Color(0xFFFF4444);
          icon = Icons.error_outline_rounded;
        } else {
          text = 'Chưa khởi động';
          color = const Color(0xFF6B6B8A);
          icon = Icons.power_off_rounded;
        }

        return Container(
          width: double.infinity,
          color: const Color(0xFFFFF8DC), // Cornsilk
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              Icon(icon, color: color, size: 12),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: color, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: const Color(0xFFFFF8DC),
          border: Border.all(color: const Color(0xFF8B4513).withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF8B4513), size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF8B4513),
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
