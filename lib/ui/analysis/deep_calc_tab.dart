import 'package:flutter/material.dart';
import '../../bloc/analysis_bloc.dart';
import '../../engine/engine_ffi.dart';

/// Tab 3: Deep Calculation — PV line display with clickable move preview.
class DeepCalcTab extends StatelessWidget {
  final AnalysisState state;
  final void Function(String move) onPreviewMove;

  const DeepCalcTab({
    super.key,
    required this.state,
    required this.onPreviewMove,
  });

  @override
  Widget build(BuildContext context) {
    final sortedPvs = state.multiPvs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (sortedPvs.isEmpty)
          _PlaceholderPv()
        else
          for (var entry in sortedPvs.take(4)) ...[
            _PvHeader(
              index: entry.key,
              output: entry.value,
            ),
            const SizedBox(height: 8),
            _PvChain(
              pvMoves: entry.value.pvMoves ?? [],
              translatedMoves: state.translatedPvs[entry.key] ?? [],
              onTap: onPreviewMove,
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }
}

class _PvHeader extends StatelessWidget {
  final int index;
  final EngineOutput output;

  const _PvHeader({required this.index, required this.output});

  @override
  Widget build(BuildContext context) {
    final depth = output.depth ?? 0;
    final cp = output.scoreCp ?? 0;
    final scoreText = output.isMate
        ? 'M${output.mateIn}'
        : '${(cp / 100).toStringAsFixed(1)}';
    final color = index == 1 ? Colors.blue : Colors.red;

    return Row(
      children: [
        Icon(Icons.auto_awesome, color: color, size: 16),
        const SizedBox(width: 6),
        Text(
          'BIẾN #$index ($scoreText) — ĐỘ SÂU $depth',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _PvChain extends StatelessWidget {
  final List<String> pvMoves;
  final List<String> translatedMoves;
  final void Function(String) onTap;

  const _PvChain(
      {required this.pvMoves,
      required this.translatedMoves,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Show at least 6 plies (or all available)
    final displayMoves = pvMoves.take(12).toList();

    return Wrap(
      spacing: 4,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (int i = 0; i < displayMoves.length; i++) ...[
          _MoveButton(
            move: displayMoves[i],
            translatedMove:
                i < translatedMoves.length ? translatedMoves[i] : null,
            ply: i,
            onTap: () => onTap(displayMoves[i]),
          ),
          if (i < displayMoves.length - 1)
            const Icon(Icons.arrow_forward_rounded,
                color: Color(0xFF3A3A5A), size: 14),
        ],
      ],
    );
  }
}

class _MoveButton extends StatelessWidget {
  final String move;
  final String? translatedMove;
  final int ply;
  final VoidCallback onTap;

  const _MoveButton(
      {required this.move,
      this.translatedMove,
      required this.ply,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Determine the color of this move based on starting side and ply
    // We assume Red starts first if ply is even, unless we pass side context.
    // For simplicity, let's use the colors: Red is CC3333, Black is 4A4A5A
    final isRed = ply % 2 ==
        0; // This is a simplification; ideally we know the board start side.
    final color = isRed ? const Color(0xFFCC3333) : const Color(0xFF4A4A5A);
    final label = isRed ? 'Đỏ' : 'Đen';
    final moveFrom = move.length >= 2 ? move.substring(0, 2) : '?';
    final moveTo = move.length >= 4 ? move.substring(2, 4) : '?';

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.2),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                  color: color.withOpacity(0.2),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 2),
            Text(
              translatedMove ?? '$moveFrom→$moveTo',
              style: TextStyle(
                  color: color,
                  fontSize: translatedMove != null ? 13 : 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderPv extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFFFF8DC),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF8B4513)),
          ),
          const SizedBox(height: 10),
          const Text(
            'Đang tính chuỗi biến hóa...',
            style: TextStyle(color: Color(0xFF6B6B8A), fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Cần ít nhất 6 nước (độ sâu ≥ 3)',
            style: TextStyle(
                color: Color(0xFF6B6B8A).withOpacity(0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
