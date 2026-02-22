import 'package:flutter/material.dart';
import 'game_screen.dart';
import 'lessons/lessons_screen.dart';
import '../game/xiangqi_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _startGame(BuildContext context, int? skillLevel) {
    /* if (skillLevel == null) {
      // Analyze mode
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => const GameScreen(skillLevel: null),
      ));
      return;
    } */

    showDialog<PieceColor>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Chọn Quân',
            style: TextStyle(
                color: Color(0xFF8B4513), fontWeight: FontWeight.bold)),
        content: const Text(
            'Bạn muốn cầm quân Đỏ (Đi trước) hay quân Đen (Đi sau)?'),
        backgroundColor: const Color(0xFFFFF8DC),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(PieceColor.red),
            child: const Text('Đỏ',
                style: TextStyle(
                    color: Color(0xFFCC3333), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(PieceColor.black),
            child: const Text('Đen',
                style: TextStyle(
                    color: Color(0xFF4A4A5A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).then((selectedColor) {
      if (!context.mounted) return;
      if (selectedColor != null) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GameScreen(
            skillLevel: skillLevel,
            playerColor: selectedColor,
          ),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5DEB3), // Wheat / Beige
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'CỜ TƯỚNG',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B4513),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tác giả: VŨ ĐỨC DU',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF556B2F),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 60),
            _buildMenuButton(
              context,
              'Đánh Máy (Dễ)',
              Icons.sentiment_satisfied_rounded,
              () => _startGame(context, 5),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Đánh Máy (Trung Bình)',
              Icons.sentiment_neutral_rounded,
              () => _startGame(context, 12),
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Đánh Máy (Khó)',
              Icons.local_fire_department_rounded,
              () => _startGame(context, 20),
            ),
            const SizedBox(height: 32),
            _buildMenuButton(
              context,
              'Luyện Tập (Phân Tích)',
              Icons.analytics_rounded,
              () => _startGame(context, null),
              isAnalysis: true,
            ),
            const SizedBox(height: 16),
            _buildMenuButton(
              context,
              'Bí Kíp (Bài Học)',
              Icons.menu_book_rounded,
              () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LessonsScreen())),
              isAnalysis: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
      BuildContext context, String title, IconData icon, VoidCallback onTap,
      {bool isAnalysis = false}) {
    return SizedBox(
      width: 280,
      height: 56,
      child: ElevatedButton.icon(
        icon: Icon(icon,
            color: isAnalysis ? const Color(0xFF8B4513) : Colors.white),
        label: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isAnalysis ? const Color(0xFF8B4513) : Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isAnalysis ? const Color(0xFFFFF8DC) : const Color(0xFF8B4513),
          side: isAnalysis
              ? const BorderSide(color: Color(0xFF8B4513), width: 2)
              : BorderSide.none,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onTap,
      ),
    );
  }
}
