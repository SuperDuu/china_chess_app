import 'xiangqi_model.dart';

class NotationTranslator {
  /// Converts a UCCI move (e.g., 'h3c3') to standard Vietnamese Notation (e.g., 'Pháo 2 bình 5')
  /// based on the current board state.
  static String toVietnamese(String ucciMove, XiangqiBoard board) {
    if (ucciMove.length < 4) return ucciMove;
    final from = BoardPos.fromUcci(ucciMove.substring(0, 2));
    final to = BoardPos.fromUcci(ucciMove.substring(2, 4));
    if (from == null || to == null) return ucciMove;

    final piece = board.at(from);
    if (piece == null) return ucciMove;

    final isRed = piece.color == PieceColor.red;

    // File conversion (1-9 from right to left for each player)
    int fromFile = isRed ? 9 - from.col : from.col + 1;
    int toFile = isRed ? 9 - to.col : to.col + 1;

    // Determine direction
    bool isAdvance = false;
    bool isRetreat = false;
    bool isTraverse = false;

    if (from.row == to.row) {
      isTraverse = true;
    } else {
      if (isRed) {
        isAdvance = to.row < from.row;
        isRetreat = to.row > from.row;
      } else {
        isAdvance = to.row > from.row;
        isRetreat = to.row < from.row;
      }
    }

    String direction = '';
    if (isTraverse)
      direction = 'bình';
    else if (isAdvance)
      direction = 'tấn';
    else if (isRetreat) direction = 'thoái';

    // Determine the action value
    int actionValue; // Steps or Destination File
    bool isDiagonalMove = piece.type == PieceType.advisor ||
        piece.type == PieceType.elephant ||
        piece.type == PieceType.horse;

    if (isDiagonalMove) {
      // Must be advance or retreat to a destination file
      actionValue = toFile;
    } else {
      // King, Chariot, Cannon, Pawn
      if (isTraverse) {
        actionValue = toFile;
      } else {
        // Vertical step count
        actionValue = (to.row - from.row).abs();
      }
    }

    // Name resolution
    String pieceName = piece.vietnameseName;
    String positionPrefix = '';

    // Disambiguation for pawns, cannons, chariots, horses on the same file
    List<Piece> sameFilePieces = board
        .piecesOf(piece.color)
        .where((p) => p.type == piece.type && p.position.col == from.col)
        .toList();

    if (sameFilePieces.length > 1) {
      // Sort by row
      sameFilePieces.sort((a, b) => a.position.row.compareTo(b.position.row));

      // For Red (row 0 is top, row 9 is bottom). So smallest row is Front.
      // For Black (row 0 is top, row 9 is bottom). So largest row is Front.
      Piece frontPiece = isRed ? sameFilePieces.first : sameFilePieces.last;
      Piece backPiece = isRed ? sameFilePieces.last : sameFilePieces.first;

      if (piece == frontPiece)
        positionPrefix = 'Tiền ';
      else if (piece == backPiece)
        positionPrefix = 'Hậu ';
      else
        positionPrefix = 'Trung '; // Rare, but possible for pawns

      // If disambiguated, we often omit the fromFile number, or keep it: "Tiền Xe tấn 1" or "Tiền Pháo bình 5"
      return '$positionPrefix$pieceName $direction $actionValue';
    }

    return '$pieceName $fromFile $direction $actionValue';
  }
}
