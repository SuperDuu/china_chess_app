import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/analysis_bloc.dart';
import '../../bloc/game_bloc.dart';

/// Bottom-sheet style hint button that shows Socratic questions instead of
/// immediately revealing the best move.
class HintButton extends StatelessWidget {
  const HintButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalysisBloc, AnalysisState>(
      builder: (ctx, state) {
        if (state.showingHint && state.hintQuestion != null) {
          return _HintDisplay(question: state.hintQuestion!);
        }

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final board = ctx.read<GameBloc>().state.board;
              ctx.read<AnalysisBloc>().add(RequestHintEvent(board));
            },
            icon: const Icon(Icons.lightbulb_outline,
                color: Color(0xFFE8B923), size: 18),
            label: const Text(
              '💡 Gợi ý tư duy',
              style: TextStyle(
                color: Color(0xFFE8B923),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              side: const BorderSide(color: Color(0xFFE8B923), width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HintDisplay extends StatelessWidget {
  final String question;

  const _HintDisplay({required this.question});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1A00), Color(0xFF2A230A)],
        ),
        border: Border.all(color: const Color(0xFFE8B923).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: Color(0xFFE8B923), size: 16),
              const SizedBox(width: 6),
              const Text(
                'GỢI Ý TƯ DUY',
                style: TextStyle(
                  color: Color(0xFFE8B923),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Builder(
                builder: (ctx) => GestureDetector(
                  onTap: () => ctx.read<AnalysisBloc>().add(DismissHintEvent()),
                  child: const Icon(Icons.close,
                      color: Color(0xFF6B6B8A), size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: const TextStyle(
              color: Color(0xFFF0E6D3),
              fontSize: 13,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
