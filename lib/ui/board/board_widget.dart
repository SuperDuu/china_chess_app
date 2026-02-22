import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:china_chess_app/game/xiangqi_model.dart';
import 'package:china_chess_app/bloc/game_bloc.dart';
import 'package:china_chess_app/bloc/analysis_bloc.dart';

/// Draws the Xiangqi board and all pieces using CustomPainter.
/// Handles selection, valid move highlights, last move, and PV preview.
class BoardWidget extends StatelessWidget {
  final GameState gameState;
  final AnalysisState analysisState;
  final void Function(BoardPos) onTap;

  const BoardWidget({
    super.key,
    required this.gameState,
    required this.analysisState,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 9 / 10,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 8, 24),
        child: LayoutBuilder(builder: (context, constraints) {
          final size = constraints.biggest;
          return GestureDetector(
            onTapDown: (d) => _handleTap(d.localPosition, size),
            child: CustomPaint(
              size: size,
              painter: _BoardPainter(
                gameState: gameState,
                analysisState: analysisState,
              ),
            ),
          );
        }),
      ),
    );
  }

  void _handleTap(Offset localPos, Size size) {
    final cellW = size.width / 9;
    final cellH = size.height / 10;
    final col = (localPos.dx / cellW).floor().clamp(0, 8);
    final row = (localPos.dy / cellH).floor().clamp(0, 9);
    onTap(BoardPos(col, row));
  }
}

class _BoardPainter extends CustomPainter {
  final GameState gameState;
  final AnalysisState analysisState;

  _BoardPainter({required this.gameState, required this.analysisState});

  static const _gold = Color(0xFF8B4513); // Changed to Brown for light theme
  static const _boardBg = Color(0xFFF5DEB3); // Wheat
  static const _gridColor = Color(0xFF8B4513);
  static const _riverColor = Color(0xFF4682B4);

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / 9;
    final ch = size.height / 10;

    _drawBoardBackground(canvas, size);
    _drawGrid(canvas, size, cw, ch);
    _drawPalace(canvas, cw, ch);
    _drawRiverLabel(canvas, size, cw, ch);
    _drawCoordinates(canvas, size, cw, ch);
    _drawHighlights(canvas, cw, ch);
    _drawSuggestionArrows(canvas, cw, ch);
    _drawPieces(canvas, cw, ch);
  }

  void _drawCoordinates(Canvas canvas, Size size, double cw, double ch) {
    final textStyle = TextStyle(
      fontSize: size.width * 0.032,
      color: const Color(0xFF8B4513),
      fontWeight: FontWeight.bold,
    );

    // Bottom numbers 1-9 (from right to left)
    for (int c = 0; c <= 8; c++) {
      final x = c * cw + cw / 2;
      // Position clearly below the board
      final y = size.height - 12;
      final text = (9 - c).toString();
      _drawText(canvas, text, Offset(x, y),
          fontSize: textStyle.fontSize!,
          color: textStyle.color!,
          fontWeight: FontWeight.bold);
    }

    // Side letters a-j (0-9 rows)
    final letters = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'];
    for (int r = 0; r <= 9; r++) {
      // Position clearly to the left of the board
      final x = 10.0;
      final y = r * ch + ch / 2;
      if (r < letters.length) {
        _drawText(canvas, letters[r], Offset(x, y),
            fontSize: textStyle.fontSize!,
            color: textStyle.color!,
            fontWeight: FontWeight.bold);
      }
    }
  }

  void _drawBoardBackground(Canvas canvas, Size size) {
    final paint = Paint()..color = _boardBg;
    // The background should encompass the grid areas only
    final cw = size.width / 9;
    final ch = size.height / 10;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cw / 2 - 4,
          ch / 2 - 4,
          8 * cw + 8,
          9 * ch + 8,
        ),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  void _drawGrid(Canvas canvas, Size size, double cw, double ch) {
    final paint = Paint()
      ..color = _gridColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Vertical lines (columns 0-8)
    for (int c = 0; c <= 8; c++) {
      final x = c * cw + cw / 2;
      // Skip middle verticals across river (rows 4-5)
      if (c > 0 && c < 8) {
        canvas.drawLine(Offset(x, ch / 2), Offset(x, ch * 4 + ch / 2), paint);
        canvas.drawLine(
            Offset(x, ch * 5 + ch / 2), Offset(x, ch * 9 + ch / 2), paint);
      } else {
        canvas.drawLine(Offset(x, ch / 2), Offset(x, ch * 9 + ch / 2), paint);
      }
    }

    // Horizontal lines (rows 0-9)
    for (int r = 0; r <= 9; r++) {
      final y = r * ch + ch / 2;
      canvas.drawLine(Offset(cw / 2, y), Offset(cw * 8 + cw / 2, y), paint);
    }
  }

  void _drawPalace(Canvas canvas, double cw, double ch) {
    final paint = Paint()
      ..color = _gridColor.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Black palace (top): rows 0-2, cols 3-5
    final bx1 = 3 * cw + cw / 2;
    final bx2 = 5 * cw + cw / 2;
    final by1 = ch / 2;
    final by2 = 2 * ch + ch / 2;
    canvas.drawLine(Offset(bx1, by1), Offset(bx2, by2), paint);
    canvas.drawLine(Offset(bx2, by1), Offset(bx1, by2), paint);

    // Red palace (bottom): rows 7-9, cols 3-5
    final rx1 = 3 * cw + cw / 2;
    final rx2 = 5 * cw + cw / 2;
    final ry1 = 7 * ch + ch / 2;
    final ry2 = 9 * ch + ch / 2;
    canvas.drawLine(Offset(rx1, ry1), Offset(rx2, ry2), paint);
    canvas.drawLine(Offset(rx2, ry1), Offset(rx1, ry2), paint);
  }

  void _drawRiverLabel(Canvas canvas, Size size, double cw, double ch) {
    // River zone separator
    final riverPaint = Paint()
      ..color = _riverColor.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(cw / 2, 4 * ch + ch / 2, 8 * cw, ch),
      riverPaint,
    );

    // River text
    _drawText(canvas, '楚 河', Offset(size.width * 0.28, 4.8 * ch + ch / 2),
        fontSize: 14, color: _riverColor.withOpacity(0.2));
    _drawText(canvas, '漢 界', Offset(size.width * 0.62, 4.8 * ch + ch / 2),
        fontSize: 14, color: _riverColor.withOpacity(0.2));
  }

  void _drawHighlights(Canvas canvas, double cw, double ch) {
    // Last move highlight
    if (gameState.lastMove != null && gameState.lastMove!.length >= 4) {
      final from = BoardPos.fromUcci(gameState.lastMove!.substring(0, 2));
      final to = BoardPos.fromUcci(gameState.lastMove!.substring(2, 4));
      final hlPaint = Paint()
        ..color = _gold.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      if (from != null) {
        canvas.drawCircle(
            Offset(from.col * cw + cw / 2, from.row * ch + ch / 2),
            cw * 0.45,
            hlPaint);
      }
      if (to != null) {
        canvas.drawCircle(Offset(to.col * cw + cw / 2, to.row * ch + ch / 2),
            cw * 0.45, hlPaint);
      }
    }

    // Selected piece highlight
    if (gameState.selectedPos != null) {
      final sp = gameState.selectedPos!;
      final selPaint = Paint()
        ..color = _gold.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(sp.col * cw + cw / 2, sp.row * ch + ch / 2),
          cw * 0.45, selPaint);
    }

    // Valid moves highlight
    final dotPaint = Paint()
      ..color = _gold.withOpacity(0.4)
      ..style = PaintingStyle.fill;
    for (final move in gameState.validMoves) {
      canvas.drawCircle(Offset(move.col * cw + cw / 2, move.row * ch + ch / 2),
          cw * 0.1, dotPaint);
    }

    // Preview move highlight
    if (gameState.previewMove != null && gameState.previewMove!.length >= 4) {
      final to = BoardPos.fromUcci(gameState.previewMove!.substring(2, 4));
      if (to != null) {
        // Special highlighting if it's considered an excellent positional sacrifice
        final isSacrifice = gameState.positionAnalysis?.isSacrifice == true;

        final pvPaint = Paint()
          ..color = (isSacrifice ? const Color(0xFFFF4444) : Colors.cyan)
              .withOpacity(0.2)
          ..style = PaintingStyle.fill;
        final cx = to.col * cw + cw / 2;
        final cy = to.row * ch + ch / 2;
        canvas.drawCircle(Offset(cx, cy), cw * 0.45, pvPaint);

        if (isSacrifice) {
          // Draw an imposing red border to denote a critical sacrifice
          final sacBorder = Paint()
            ..color = const Color(0xFFFF4444)
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke;
          canvas.drawCircle(Offset(cx, cy), cw * 0.5, sacBorder);
        }
      }
    }
  }

  void _drawSuggestionArrows(Canvas canvas, double cw, double ch) {
    if (analysisState.multiPvs.isEmpty) return;

    // Sort by multipv index (1 is best)
    final sortedPvs = analysisState.multiPvs.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    for (var entry in sortedPvs.take(4)) {
      final index = entry.key; // 1-indexed
      final output = entry.value;
      if (output.pvMoves == null || output.pvMoves!.isEmpty) continue;

      final move = output.pvMoves![0];
      final from = BoardPos.fromUcci(move.substring(0, 2));
      final to = BoardPos.fromUcci(move.substring(2, 4));

      if (from == null || to == null) continue;

      final color = index == 1 ? Colors.blue : Colors.red;
      final paint = Paint()
        ..color = color.withOpacity(0.7)
        ..strokeWidth = index == 1 ? 4.0 : 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final p1 = Offset(from.col * cw + cw / 2, from.row * ch + ch / 2);
      final p2 = Offset(to.col * cw + cw / 2, to.row * ch + ch / 2);

      _drawArrow(canvas, p1, p2, paint, cw);
    }
  }

  void _drawArrow(Canvas canvas, Offset p1, Offset p2, Paint paint, double cw) {
    final dir = (p2 - p1);
    final len = dir.distance;
    if (len < 5) return;

    final start = p1 + (dir / len) * (cw * 0.3);
    final end = p2 - (dir / len) * (cw * 0.3);

    canvas.drawLine(start, end, paint);

    // Arrow head
    final headLen = cw * 0.2;
    final angle = dir.direction;
    final path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - headLen * math.cos(angle - math.pi / 6),
      end.dy - headLen * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      end.dx - headLen * math.cos(angle + math.pi / 6),
      end.dy - headLen * math.sin(angle + math.pi / 6),
    );
    path.close();

    final headPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, headPaint);
  }

  void _drawPieces(Canvas canvas, double cw, double ch) {
    for (final piece in gameState.board.pieces) {
      final cx = piece.position.col * cw + cw / 2;
      final cy = piece.position.row * ch + ch / 2;
      final radius = cw * 0.42;
      _drawPiece(canvas, piece, Offset(cx, cy), radius);
    }
  }

  void _drawPiece(Canvas canvas, Piece piece, Offset center, double radius) {
    final isRed = piece.color == PieceColor.red;

    // Outer shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center + const Offset(2, 2), radius, shadowPaint);

    // Piece body gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: isRed
            ? [const Color(0xFFFF6B6B), const Color(0xFF8B1A1A)]
            : [const Color(0xFF4A4A5A), const Color(0xFF0D0D1A)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Gold border
    final borderPaint = Paint()
      ..color = _gold
      ..strokeWidth = radius * 0.1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.92, borderPaint);

    // Inner circle
    final innerBorderPaint = Paint()
      ..color = _gold.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius * 0.75, innerBorderPaint);

    // Hanzi character
    _drawText(canvas, piece.hanzi, center,
        fontSize: radius * 1.1,
        color: isRed ? const Color(0xFFFFE4B5) : const Color(0xFFCCCCDD),
        fontWeight: FontWeight.bold);
  }

  void _drawText(Canvas canvas, String text, Offset center,
      {required double fontSize,
      required Color color,
      FontWeight fontWeight = FontWeight.normal}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_BoardPainter old) => old.gameState != gameState;
}
