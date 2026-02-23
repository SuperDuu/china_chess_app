import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/analysis_bloc.dart';
import '../../game/xiangqi_model.dart';
import '../components/typewriter_text.dart';

class MentorPanel extends StatelessWidget {
  const MentorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalysisBloc, AnalysisState>(
      builder: (context, state) {
        if (state.isGeminiLoading) {
          return _buildLoadingState();
        }

        if (state.geminiExplanation != null) {
          return _buildContent(state.geminiExplanation!, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC).withOpacity(0.95), // Cornsilk
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B4513).withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Color(0xFF8B4513), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Cố vấn Vũ Đức Du',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      const Color(0xFF8B4513).withOpacity(0.5)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Shimmer.fromColors(
            baseColor: Colors.grey[400]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                    width: double.infinity, height: 10, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 200, height: 10, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chờ tôi 1 phút để suy nghĩ...',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF8B4513),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String text, AnalysisState state) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8B923)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome,
                  color: Color(0xFFE8B923), size: 20),
              const SizedBox(width: 8),
              const Text(
                'Cố vấn Vũ Đức Du',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: state.sideToAnalyze == PieceColor.red
                      ? const Color(0xFFCC3333)
                      : const Color(0xFF2F4F4F),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  state.sideToAnalyze == PieceColor.red ? 'ĐỎ' : 'ĐEN',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TypewriterText(
            text: text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4A4A4A),
              height: 1.5,
              fontFamily: 'serif',
            ),
          ),
        ],
      ),
    );
  }
}
