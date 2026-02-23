import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../game/pgn_parser.dart';
import '../game/xiangqi_model.dart';
import 'board/board_widget.dart';
import '../bloc/game_bloc.dart';
import '../bloc/analysis_bloc.dart';
import '../services/sound_manager.dart';
import '../engine/ucci_controller.dart';

class PgnBrowserScreen extends StatefulWidget {
  const PgnBrowserScreen({super.key});

  @override
  State<PgnBrowserScreen> createState() => _PgnBrowserScreenState();
}

class _PgnBrowserScreenState extends State<PgnBrowserScreen> {
  List<PgnGame> _games = [];
  bool _loading = true;
  PgnGame? _selectedGame;
  XiangqiBoard _board = XiangqiBoard.startingPosition();
  int _moveIndex = -1;

  // --- Trial Mode State ---
  bool _isTrialMode = false;
  BoardPos? _selectedPos;
  List<BoardPos> _validMoves = [];

  @override
  void initState() {
    super.initState();
    _loadPgn();
  }

  Future<void> _loadPgn() async {
    try {
      final content =
          await rootBundle.loadString('assets/puzzles/official_database.pgn');
      final games = PgnParser.parse(content);
      setState(() {
        _games = games;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi nạp dữ liệu: $e')),
        );
      }
    }
  }

  void _selectGame(PgnGame game) {
    setState(() {
      _selectedGame = game;
      _board = XiangqiBoard.startingPosition();
      _moveIndex = -1;
      _isTrialMode = false;
      _selectedPos = null;
      _validMoves = [];

      // Reset and trigger initial analysis
      context.read<AnalysisBloc>().add(ResetAnalysisEvent());
      UcciController.instance.analyzePosition(_board.toFen());
      context.read<AnalysisBloc>().add(ChangeTabEvent(3));
    });
  }

  void _handleBoardTap(BoardPos pos) {
    setState(() {
      final piece = _board.at(pos);

      // 1. Handle Selection
      if (piece?.color == _board.sideToMove) {
        if (_selectedPos == pos) {
          _selectedPos = null;
          _validMoves = [];
        } else {
          _selectedPos = pos;
          _validMoves = _board.getValidMoves(pos);
        }
        return;
      }

      // 2. Handle Move Execution
      if (_selectedPos != null && _validMoves.contains(pos)) {
        final move = '${_selectedPos!.toUcci()}${pos.toUcci()}';

        // Check if this move matches the NEXT move in the PGN
        bool isOfficial = false;
        if (!_isTrialMode &&
            _selectedGame != null &&
            _moveIndex < _selectedGame!.moves.length - 1) {
          if (_selectedGame!.moves[_moveIndex + 1] == move) {
            isOfficial = true;
          }
        }

        if (isOfficial) {
          _nextMove(); // Just advance the official PGN
        } else {
          // Trigger Trial Mode
          _isTrialMode = true;
          _board = _board.applyMove(move);
          _selectedPos = null;
          _validMoves = [];

          // Trigger Analysis
          UcciController.instance.analyzePosition(_board.toFen());
          context.read<AnalysisBloc>().add(ChangeTabEvent(3));
          SoundManager().playMove();
        }
      } else {
        _selectedPos = null;
        _validMoves = [];
      }
    });
  }

  void _exitTrialMode() {
    if (_selectedGame == null) return;
    setState(() {
      _isTrialMode = false;
      _selectedPos = null;
      _validMoves = [];

      // Restore board to the official move index
      _board = XiangqiBoard.startingPosition();
      for (int i = 0; i <= _moveIndex; i++) {
        _board = _board.applyMove(_selectedGame!.moves[i]);
      }

      UcciController.instance.analyzePosition(_board.toFen());
      context.read<AnalysisBloc>().add(ChangeTabEvent(3));
    });
  }

  void _nextMove() {
    if (_selectedGame == null || _moveIndex >= _selectedGame!.moves.length - 1)
      return;
    if (_isTrialMode) _exitTrialMode();

    setState(() {
      _moveIndex++;
      final move = _selectedGame!.moves[_moveIndex];
      _board = _board.applyMove(move);

      // Trigger Analysis
      context.read<AnalysisBloc>().add(UpdateAnalysisEvent(
          const EngineOutput(raw: 'info score cp 0'), _board));
      SoundManager().playMove();
    });
  }

  void _prevMove() {
    if (_selectedGame == null || _moveIndex < 0) return;
    if (_isTrialMode) _exitTrialMode();

    setState(() {
      _moveIndex--;
      _board = XiangqiBoard.startingPosition();
      for (int i = 0; i <= _moveIndex; i++) {
        _board = _board.applyMove(_selectedGame!.moves[i]);
      }
      // Trigger Analysis
      context.read<AnalysisBloc>().add(UpdateAnalysisEvent(
          const EngineOutput(raw: 'info score cp 0'), _board));
      SoundManager().playMove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5DC),
      appBar: AppBar(
        title: const Text('NGÂN HÀNG KỲ PHỔ'),
        backgroundColor: const Color(0xFF8B4513),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _selectedGame == null
              ? _buildGameList()
              : _buildGameViewer(),
    );
  }

  Widget _buildGameList() {
    return ListView.builder(
      itemCount: _games.length,
      itemBuilder: (context, index) {
        final game = _games[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: const Color(0xFFFFF8DC),
          child: ListTile(
            title: Text('${game.red} vs ${game.black}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF8B4513))),
            subtitle: Text(
                '${game.event} • ${game.date}\nKết quả: ${game.result}',
                style: const TextStyle(fontSize: 12)),
            trailing:
                const Icon(Icons.play_circle_fill, color: Color(0xFF8B4513)),
            onTap: () => _selectGame(game),
          ),
        );
      },
    );
  }

  Widget _buildGameViewer() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF8B4513).withOpacity(0.05),
          child: Column(
            children: [
              Text(
                  '${_selectedGame!.red} (Đỏ) vs ${_selectedGame!.black} (Đen)',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8B4513))),
              const SizedBox(height: 4),
              Text(
                  '${_selectedGame!.event} • Số nước: ${_selectedGame!.moves.length}',
                  style: const TextStyle(
                      fontSize: 14, fontStyle: FontStyle.italic)),
              const SizedBox(height: 8),
              BlocBuilder<AnalysisBloc, AnalysisState>(
                builder: (context, state) {
                  final score = state.latestOutput?.scoreCp ?? 0;
                  final scoreText = (score / 100.0).toStringAsFixed(2);
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.analytics,
                          size: 16, color: Color(0xFF8B4513)),
                      const SizedBox(width: 4),
                      Text('Đánh giá: $scoreText',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF8B4513))),
                      const Spacer(),
                      TextButton.icon(
                        icon: state.isGeminiLoading
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Color(0xFF8B4513)),
                              )
                            : const Icon(Icons.psychology,
                                size: 18, color: Color(0xFF8B4513)),
                        label: const Text('Hỏi Mentor',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B4513))),
                        onPressed: state.isGeminiLoading
                            ? null
                            : () {
                                context.read<AnalysisBloc>().add(
                                      RequestGeminiAnalysisEvent(
                                        fen: _board.toFen(),
                                        topMoves:
                                            state.multiPvs.values.toList(),
                                      ),
                                    );
                              },
                      ),
                    ],
                  );
                },
              ),
              BlocBuilder<AnalysisBloc, AnalysisState>(
                builder: (context, state) {
                  if (state.geminiExplanation == null &&
                      !state.isGeminiLoading) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: const Color(0xFF8B4513).withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome,
                                size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text('VU DUC DU MENTOR:',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                    letterSpacing: 1.1)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        state.isGeminiLoading && state.geminiExplanation == null
                            ? const LinearProgressIndicator()
                            : Text(
                                state.geminiExplanation ?? '',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black87,
                                    height: 1.4),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        if (_isTrialMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            color: Colors.orange.withOpacity(0.15),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Bạn đang ở Chế độ Thử nghiệm (Trial Mode). Các nước đi hiện tại không nằm trong ván gốc.',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.brown,
                        fontStyle: FontStyle.italic),
                  ),
                ),
                TextButton.icon(
                  onPressed: _exitTrialMode,
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('Về ván chính',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF8B4513),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: BlocBuilder<AnalysisBloc, AnalysisState>(
              builder: (context, analysisState) {
                return BoardWidget(
                  gameState: GameState(
                    board: _board,
                    selectedPos: _selectedPos,
                    validMoves: _validMoves,
                    lastMove: _moveIndex >= 0 && !_isTrialMode
                        ? _selectedGame!.moves[_moveIndex]
                        : null,
                  ),
                  analysisState: analysisState,
                  onTap: _handleBoardTap,
                );
              },
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.first_page, size: 36),
                onPressed: () => _selectGame(_selectedGame!),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_before, size: 36),
                onPressed: _prevMove,
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    '${_moveIndex + 1} / ${_selectedGame!.moves.length}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next, size: 36),
                onPressed: _nextMove,
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 36, color: Colors.blue),
                onPressed: () => setState(() => _selectedGame = null),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
