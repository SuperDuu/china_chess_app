import 'package:flutter/material.dart';
import '../../bloc/analysis_bloc.dart';

/// Tab 4: Position Map — Strategic Sacrifice Mentor
/// Displays control over files, tempo, and material vs positional tradeoffs.
class PositionMapTab extends StatelessWidget {
  final AnalysisState state;

  const PositionMapTab({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pos = state.positionAnalysis;

    if (pos == null) {
      return _buildEmptyState();
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // 1. Line Control (Lộ)
        _buildSectionHeader(Icons.map_rounded, 'KIỂM SOÁT LỘ QUAN TRỌNG',
            const Color(0xFF64B5F6)),
        const SizedBox(height: 8),
        _buildTempoCard(pos.tempoAnalysis ?? 'Đang tính toán nhịp...'),
        const SizedBox(height: 16),

        // 2. Material vs Positional evaluation
        _buildSectionHeader(Icons.balance_rounded, 'THẨM ĐỊNH THIỆT HƠN',
            const Color(0xFFE8B923)),
        const SizedBox(height: 8),
        _buildTradeoffCard(pos),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, color: Color(0xFF3A3A5A), size: 48),
          SizedBox(height: 16),
          Text(
            'Phân tích thế trận sư vương...',
            style: TextStyle(color: Color(0xFF6B6B8A), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildTempoCard(String tempoText) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_outlined, color: Color(0xFF888AA0), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tempoText,
              style: const TextStyle(
                  color: Color(0xFFD0D0E0), fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeoffCard(pos) {
    final bool isBadGrab = pos.materialDiff > 200 && pos.positionalBonus < -300;

    Color accentColor;
    String verdictTitle;
    String verdictSub;

    if (pos.isSacrifice) {
      accentColor = const Color(0xFF4CAF50); // Green
      verdictTitle = 'PHẾ QUÂN XUẤT SẮC';
      verdictSub =
          'Đáng đầu tư (Ưu thế ${(pos.positionalBonus / 100.0).toStringAsFixed(1)})';
    } else if (isBadGrab) {
      accentColor = const Color(0xFFFF4444); // Red
      verdictTitle = 'THAM ĂN QUÂN';
      verdictSub =
          'Mất thế trận (Điểm thế ${(pos.positionalBonus / 100.0).toStringAsFixed(1)})';
    } else {
      accentColor = const Color(0xFF64B5F6); // Blue
      verdictTitle = 'ĐỔI QUÂN CÂN BẰNG';
      verdictSub = 'Thế trận ổn định';
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF12122A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentColor.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          // Comparison row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildValueCol(
                    'Quân số', pos.materialDiff, Icons.person_rounded),
                Container(width: 1, height: 40, color: const Color(0xFF2A2A4A)),
                _buildValueCol(
                    'Thế trận', pos.positionalBonus, Icons.public_rounded),
                Container(width: 1, height: 40, color: const Color(0xFF2A2A4A)),
                _buildValueCol(
                    'Tổng điểm', pos.engineScore, Icons.score_rounded),
              ],
            ),
          ),
          // Verdict banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(7),
                bottomRight: Radius.circular(7),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.gavel_rounded, color: accentColor, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$verdictTitle: ',
                  style: TextStyle(
                      color: accentColor,
                      fontWeight: 'bold'.hashCode == 0
                          ? FontWeight.w400
                          : FontWeight.bold,
                      fontSize: 11),
                ),
                Text(
                  verdictSub,
                  style:
                      const TextStyle(color: Color(0xFFD0D0E0), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValueCol(String label, int val, IconData icon) {
    final color = val >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFFF4444);
    final sign = val > 0 ? '+' : '';
    final formatted = '$sign${(val / 100.0).toStringAsFixed(1)}';

    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6B6B8A), size: 14),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 10)),
          const SizedBox(height: 2),
          Text(formatted,
              style: TextStyle(
                  color: color,
                  fontWeight:
                      'bold'.hashCode == 0 ? FontWeight.w400 : FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
