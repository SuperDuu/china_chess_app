import 'package:flutter/material.dart';
import '../../bloc/analysis_bloc.dart';
import '../../game/analysis_model.dart';
import '../../engine/ucci_controller.dart';

/// Tab 1: Blind Spot Detector — shows unprotected pieces and score-drop warnings.
class BlindSpotTab extends StatelessWidget {
  final AnalysisState state;

  const BlindSpotTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Score drop warning banner
        if (state.latestOutput != null) ...[
          _ScoreBar(latestOutput: state.latestOutput!),
          const SizedBox(height: 8),
        ],

        // Section header
        _SectionHeader(
          icon: Icons.visibility_off_rounded,
          label: 'SO TREO',
          color: const Color(0xFFFF4444),
          count: state.threats.where((t) => t.isUnprotected).length,
        ),

        // Unprotected pieces
        if (state.threats.isEmpty)
          const _EmptyCard(
            icon: Icons.shield_rounded,
            text: 'Không có quân nào bị treo. Tốt lắm! 💪',
          )
        else ...[
          for (final t in state.threats.where((t) => t.isUnprotected))
            _ThreatCard(threat: t, isUnprotected: true),
          if (state.threats.any((t) => !t.isUnprotected)) ...[
            const SizedBox(height: 12),
            _SectionHeader(
              icon: Icons.warning_rounded,
              label: 'BỊ ĐE DỌA',
              color: const Color(0xFFFF9800),
              count: state.threats.where((t) => !t.isUnprotected).length,
            ),
            for (final t in state.threats.where((t) => !t.isUnprotected))
              _ThreatCard(threat: t, isUnprotected: false),
          ],
        ],
      ],
    );
  }
}

class _ScoreBar extends StatelessWidget {
  final EngineOutput latestOutput;
  const _ScoreBar({required this.latestOutput});

  @override
  Widget build(BuildContext context) {
    final cp = latestOutput.scoreCp ?? 0;
    final depth = latestOutput.depth ?? 0;
    final nps = latestOutput.nps ?? 0;

    final isGood = cp >= 0;
    final scoreText = latestOutput.isMate
        ? ((latestOutput.mateIn ?? 0) > 0
            ? '+M${latestOutput.mateIn}'
            : '-M${(latestOutput.mateIn ?? 0).abs()}')
        : (cp >= 0
            ? '+${(cp / 100.0).toStringAsFixed(1)}'
            : (cp / 100.0).toStringAsFixed(1));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: isGood
              ? [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)]
              : [const Color(0xFFFFEBEE), const Color(0xFFFFCDD2)],
        ),
        border: Border.all(
          color: isGood ? const Color(0xFF4CAF50) : const Color(0xFFFF4444),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.trending_up : Icons.trending_down,
            color: isGood ? const Color(0xFF4CAF50) : const Color(0xFFFF4444),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            scoreText,
            style: TextStyle(
              color: isGood ? const Color(0xFF4CAF50) : const Color(0xFFFF4444),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            'Độ sâu: $depth',
            style: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 11),
          ),
          const SizedBox(width: 8),
          Text(
            '${(nps / 1000).toStringAsFixed(0)}K nps',
            style: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int count;

  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(color: color, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreatCard extends StatelessWidget {
  final ThreatInfo threat;
  final bool isUnprotected;

  const _ThreatCard({required this.threat, required this.isUnprotected});

  @override
  Widget build(BuildContext context) {
    final color =
        isUnprotected ? const Color(0xFFFF4444) : const Color(0xFFFF9800);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (threat.threatenedPiece.color.name == 'red'
                      ? const Color(0xFFCC3333)
                      : const Color(0xFF2F4F4F))
                  .withOpacity(0.1),
              border: Border.all(color: const Color(0xFF8B4513), width: 1.5),
            ),
            child: Center(
              child: Text(
                threat.threatenedPiece.hanzi,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              threat.description,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ),
          if (isUnprotected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'TREO',
                style: TextStyle(
                    color: Color(0xFFFF4444),
                    fontSize: 9,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyCard({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFF4CAF50).withOpacity(0.2),
        border: Border.all(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
