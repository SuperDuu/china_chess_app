import '../game/xiangqi_model.dart';

/// A parsed threat: a friendly piece under attack with no defenders.
class ThreatInfo {
  final Piece threatenedPiece;
  final List<Piece> attackers;
  final bool isUnprotected;

  const ThreatInfo({
    required this.threatenedPiece,
    required this.attackers,
    required this.isUnprotected,
  });

  String get description {
    final name = threatenedPiece.vietnameseName;
    final pos = threatenedPiece.position.toUcci();
    if (isUnprotected) {
      return '$name tại $pos đang bị treo (không có quân bảo vệ)';
    }
    return '$name tại $pos đang bị đe dọa';
  }
}

/// Intent parsed from opponent's best move.
class OpponentIntent {
  final String bestMove;
  final Piece? targetPiece;
  final IntentType type;

  const OpponentIntent({
    required this.bestMove,
    this.targetPiece,
    required this.type,
  });

  String get description {
    final toPos =
        bestMove.length >= 4 ? bestMove.substring(2, 4).toUpperCase() : '?';
    return switch (type) {
      IntentType.capturePiece =>
        'Đối thủ đang nhắm vào ${targetPiece?.vietnameseName ?? "quân"} tại $toPos',
      IntentType.checkKing => 'Đối thủ đang chiếu Tướng! Bảo vệ ngay.',
      IntentType.buildAttack =>
        'Đối thủ đang triển khai lực (Nước $bestMove). Chú ý bố trí.',
      IntentType.threatMate =>
        '⚠️ Đối thủ đang chuẩn bị sát cục! Hành động ngay.',
    };
  }
}

enum IntentType { capturePiece, checkKing, buildAttack, threatMate }

/// Computes analysis from current board state and engine output.
class AnalysisModel {
  /// Detect threats to current player's pieces.
  static List<ThreatInfo> detectThreats(
      XiangqiBoard board, PieceColor currentPlayer) {
    final opponent =
        currentPlayer == PieceColor.red ? PieceColor.black : PieceColor.red;
    final result = <ThreatInfo>[];

    for (final piece in board.piecesOf(currentPlayer)) {
      final attackers = board
          .piecesOf(opponent)
          .where((a) => board.canAttack(a, piece.position))
          .toList();
      if (attackers.isEmpty) continue;

      final defenders = board.getDefenders(piece.position, currentPlayer);
      result.add(ThreatInfo(
        threatenedPiece: piece,
        attackers: attackers,
        isUnprotected: defenders.isEmpty,
      ));
    }

    result.sort((a, b) {
      if (a.isUnprotected != b.isUnprotected) return a.isUnprotected ? -1 : 1;
      return _pieceValue(b.threatenedPiece.type)
          .compareTo(_pieceValue(a.threatenedPiece.type));
    });

    return result;
  }

  /// Parse opponent intent from bestmove and board state.
  static OpponentIntent? parseOpponentIntent(
      String? bestMove, XiangqiBoard board, PieceColor opponent) {
    if (bestMove == null || bestMove.length < 4) return null;
    final toPos = BoardPos.fromUcci(bestMove.substring(2, 4));
    if (toPos == null) return null;

    final targetPiece = board.at(toPos);
    if (targetPiece != null && targetPiece.color != opponent) {
      if (targetPiece.type == PieceType.king) {
        return OpponentIntent(
            bestMove: bestMove,
            targetPiece: targetPiece,
            type: IntentType.checkKing);
      }
      return OpponentIntent(
          bestMove: bestMove,
          targetPiece: targetPiece,
          type: IntentType.capturePiece);
    }

    return OpponentIntent(
        bestMove: bestMove, targetPiece: null, type: IntentType.buildAttack);
  }

  static int _pieceValue(PieceType t) => switch (t) {
        PieceType.chariot => 900,
        PieceType.cannon => 450,
        PieceType.horse => 400,
        PieceType.elephant => 200,
        PieceType.advisor => 200,
        PieceType.soldier => 100,
        PieceType.king => 9999,
      };

  /// Calculates the raw material score from the perspective of Red.
  /// (Red pieces - Black pieces).
  static int calculateMaterialScore(XiangqiBoard board) {
    int score = 0;
    for (final p in board.pieces) {
      final val = _pieceValue(p.type);
      score += p.color == PieceColor.red ? val : -val;
    }
    return score;
  }
}

/// Information about positional advantage vs material advantage.
class PositionalAnalysis {
  final int materialDiff; // Red material - Black material
  final int engineScore; // Engine evaluation (from perspective of side to move)
  final int positionalBonus; // Engine score minus material diff
  final bool isSacrifice; // Is the player sacrificing material for position?
  final String? tempoAnalysis; // Analysis of tempo/lines

  const PositionalAnalysis({
    required this.materialDiff,
    required this.engineScore,
    required this.positionalBonus,
    required this.isSacrifice,
    this.tempoAnalysis,
  });
}
