import 'package:flutter/material.dart';
import '../../bloc/analysis_bloc.dart';
import '../../game/analysis_model.dart';

/// Tab 2: Opponent Intent — shows what the opponent is planning to do.
class OpponentIntentTab extends StatelessWidget {
  final AnalysisState state;

  const OpponentIntentTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final intent = state.opponentIntent;
    final bestMove = state.opponentBestMove;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Best move display
        if (bestMove != null)
          _BestMoveCard(bestMove: bestMove)
        else
          _WaitingCard(),

        const SizedBox(height: 12),

        // Intent analysis
        if (intent != null)
          _IntentCard(intent: intent)
        else
          const _PlaceholderCard(
            icon: Icons.psychology_outlined,
            text: 'Đang phân tích ý đồ...',
            subtitle: 'Chờ engine tính toán nước đi của đối thủ',
          ),

        const SizedBox(height: 12),

        // Danger level
        if (intent != null) _DangerLevelCard(intent: intent),
      ],
    );
  }
}

class _BestMoveCard extends StatelessWidget {
  final String bestMove;

  const _BestMoveCard({required this.bestMove});

  @override
  Widget build(BuildContext context) {
    final from =
        bestMove.length >= 2 ? bestMove.substring(0, 2).toUpperCase() : '?';
    final to =
        bestMove.length >= 4 ? bestMove.substring(2, 4).toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
        ),
        border: Border.all(color: const Color(0xFFCC3333).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.track_changes_rounded,
              color: Color(0xFFCC3333), size: 20),
          const SizedBox(width: 10),
          const Text('Nước tốt nhất của địch:',
              style: TextStyle(color: Color(0xFF6B6B8A), fontSize: 12)),
          const Spacer(),
          // Move display
          _MoveChip(label: from, color: const Color(0xFF888AA0)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded,
                color: Color(0xFFCC3333), size: 16),
          ),
          _MoveChip(label: to, color: const Color(0xFFCC3333)),
        ],
      ),
    );
  }
}

class _MoveChip extends StatelessWidget {
  final String label;
  final Color color;

  const _MoveChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFFFF8DC),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF8B4513),
            ),
          ),
          SizedBox(width: 10),
          Text('Đang tính toán nước đi của đối thủ...',
              style: TextStyle(color: Color(0xFF6B6B8A), fontSize: 12)),
        ],
      ),
    );
  }
}

class _IntentCard extends StatelessWidget {
  final OpponentIntent intent;

  const _IntentCard({required this.intent});

  @override
  Widget build(BuildContext context) {
    final intentType = intent.type.toString().split('.').last;
    final color = switch (intentType) {
      'checkKing' || 'threatMate' => const Color(0xFFFF4444),
      'capturePiece' => const Color(0xFFFF9800),
      _ => const Color(0xFF64B5F6),
    };
    final icon = switch (intentType) {
      'checkKing' => Icons.crisis_alert_rounded,
      'threatMate' => Icons.dangerous_rounded,
      'capturePiece' => Icons.sports_martial_arts,
      _ => Icons.psychology_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.2),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                'PHÂN TÍCH Ý ĐỒ',
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            intent.description,
            style: const TextStyle(
              color: Color(0xFF2F4F4F),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerLevelCard extends StatelessWidget {
  final OpponentIntent intent;

  const _DangerLevelCard({required this.intent});

  @override
  Widget build(BuildContext context) {
    final intentType = intent.type.toString().split('.').last;
    final level = switch (intentType) {
      'threatMate' => 5,
      'checkKing' => 4,
      'capturePiece' => 3,
      _ => 1,
    };
    final label = switch (level) {
      5 => '🔴 NGUY CẤP — Hành động ngay!',
      4 => '🟠 NGUY HIỂM — Bảo vệ Tướng!',
      3 => '🟡 CẦN CHÚ Ý — Quân có thể bị ăn',
      _ => '🟢 BÌNH THƯỜNG — Tiếp tục khai triển',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: const Color(0xFFFFF8DC),
      ),
      child: Row(
        children: [
          const Text('Mức độ nguy hiểm:',
              style: TextStyle(color: Color(0xFF6B6B8A), fontSize: 11)),
          const Spacer(),
          Text(label,
              style: const TextStyle(color: Color(0xFF2F4F4F), fontSize: 12)),
        ],
      ),
    );
  }
}

class _PlaceholderCard extends StatelessWidget {
  final IconData icon;
  final String text;
  final String subtitle;

  const _PlaceholderCard(
      {required this.icon, required this.text, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFFFF8DC),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3A3A5A), size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(text,
                  style:
                      const TextStyle(color: Color(0xFF6B6B8A), fontSize: 13)),
              Text(subtitle,
                  style:
                      const TextStyle(color: Color(0xFF3A3A5A), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
