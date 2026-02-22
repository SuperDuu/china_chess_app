import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../bloc/analysis_bloc.dart';
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
          return _buildContent(state.geminiExplanation!);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLoadingState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8DC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8B923).withOpacity(0.5)),
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
            'Đang suy ngẫm...',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Color(0xFF8B4513),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(String text) {
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
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFFE8B923), size: 20),
              SizedBox(width: 8),
              Text(
                'Cố vấn Vũ Đức Du',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
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
