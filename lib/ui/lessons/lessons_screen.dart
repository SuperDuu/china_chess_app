import 'package:flutter/material.dart';
import '../../game/lessons_data.dart';

class LessonsScreen extends StatelessWidget {
  const LessonsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3),
      appBar: AppBar(
        title: const Text('BÍ KÍP CỜ TƯỚNG',
            style: TextStyle(
                color: Color(0xFFE8B923), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B4513),
        elevation: 4,
        iconTheme: const IconThemeData(color: Color(0xFFE8B923)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCategory(context, 'KHAI CUỘC', 'opening',
              Icons.auto_awesome_motion_rounded),
          const SizedBox(height: 16),
          _buildCategory(
              context, 'TRUNG CUỘC', 'middle', Icons.architecture_rounded),
          const SizedBox(height: 16),
          _buildCategory(context, 'TÀN CUỘC', 'endgame', Icons.flag_rounded),
        ],
      ),
    );
  }

  Widget _buildCategory(
      BuildContext context, String title, String category, IconData icon) {
    final lessons =
        LessonsRepository.all.where((l) => l.category == category).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF8B4513), size: 24),
            const SizedBox(width: 8),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                    letterSpacing: 1.5)),
          ],
        ),
        const Divider(color: Color(0xFF8B4513), thickness: 2),
        const SizedBox(height: 8),
        ...lessons.map((lesson) => _buildLessonTile(context, lesson)).toList(),
      ],
    );
  }

  Widget _buildLessonTile(BuildContext context, ChessLesson lesson) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFFFFF8DC),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF8B4513), width: 0.5)),
      child: ExpansionTile(
        title: Text(lesson.title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Color(0xFF8B4513))),
        leading: const Icon(Icons.menu_book_rounded, color: Color(0xFF8B4513)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              lesson.content,
              style: const TextStyle(
                  fontSize: 14, color: Color(0xFF556B2F), height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
