/// Represents all piece types in Chinese Chess (Xiangqi).
enum PieceType { king, advisor, elephant, horse, chariot, cannon, soldier }

/// Represents piece color / side.
enum PieceColor { red, black }

/// Represents a board coordinate (col 0-8, row 0-9).
class BoardPos {
  final int col; // 0-8
  final int row; // 0-9

  const BoardPos(this.col, this.row);

  bool get isValid => col >= 0 && col <= 8 && row >= 0 && row <= 9;

  @override
  bool operator ==(Object other) =>
      other is BoardPos && col == other.col && row == other.row;

  @override
  int get hashCode => col * 10 + row;

  @override
  String toString() => '($col,$row)';

  /// Convert from UCCI coordinate (e.g. "b0" → col=1, row=0).
  /// UCCI columns: a-i (0-8), UCCI rows: 0-9
  static BoardPos? fromUcci(String s) {
    if (s.length < 2) return null;
    final col = s.codeUnitAt(0) - 'a'.codeUnitAt(0);
    final ucciRow = int.tryParse(s[1]);
    if (ucciRow == null) return null;
    // UCCI: 0 is bottom, 9 is top. Internal: 0 is top, 9 is bottom.
    final row = 9 - ucciRow;
    return BoardPos(col, row);
  }

  /// Convert to UCCI string: col→a-i, row→0-9
  String toUcci() {
    final ucciRow = 9 - row;
    return '${'abcdefghi'[col]}$ucciRow';
  }
}

/// A single chess piece.
class Piece {
  final PieceType type;
  final PieceColor color;
  BoardPos position;

  Piece({required this.type, required this.color, required this.position});

  Piece copyWith({BoardPos? position}) =>
      Piece(type: type, color: color, position: position ?? this.position);

  /// Hanzi character for the piece face.
  String get hanzi {
    if (color == PieceColor.red) {
      return switch (type) {
        PieceType.king => '帅',
        PieceType.advisor => '仕',
        PieceType.elephant => '相',
        PieceType.horse => '馬',
        PieceType.chariot => '車',
        PieceType.cannon => '炮',
        PieceType.soldier => '兵',
      };
    } else {
      return switch (type) {
        PieceType.king => '将',
        PieceType.advisor => '士',
        PieceType.elephant => '象',
        PieceType.horse => '馬',
        PieceType.chariot => '車',
        PieceType.cannon => '砲',
        PieceType.soldier => '卒',
      };
    }
  }

  /// Full piece name in Vietnamese.
  String get vietnameseName {
    return switch (type) {
      PieceType.king => color == PieceColor.red ? 'Tướng đỏ' : 'Tướng đen',
      PieceType.advisor => 'Sĩ',
      PieceType.elephant => 'Tượng',
      PieceType.horse => 'Mã',
      PieceType.chariot => 'Xe',
      PieceType.cannon => 'Pháo',
      PieceType.soldier => 'Tốt',
    };
  }

  @override
  String toString() => '${color.name} ${type.name} @ $position';
}

/// The full Xiangqi board state, stored as a 10x9 grid.
class XiangqiBoard {
  // board[row][col], null = empty
  final List<List<Piece?>> squares;
  final PieceColor sideToMove;
  final List<Piece> pieces;

  XiangqiBoard._({
    required this.squares,
    required this.sideToMove,
    required this.pieces,
  });

  /// Create the standard starting position.
  factory XiangqiBoard.startingPosition(
      {PieceColor sideToMove = PieceColor.red}) {
    final board = XiangqiBoard.fromFen(
      'rnbakabnr/9/1c5c1/p1p1p1p1p/9/9/P1P1P1P1P/1C5C1/9/RNBAKABNR',
    );
    return XiangqiBoard._(
      squares: board.squares,
      sideToMove: sideToMove,
      pieces: board.pieces,
    );
  }

  /// Parse a UCCI/Pikafish FEN string.
  factory XiangqiBoard.fromFen(String fen) {
    final parts = fen.split(' ');
    final boardFen = parts[0];
    final sideChar = parts.length > 1 ? parts[1] : 'w';
    final sideToMove = sideChar == 'w' ? PieceColor.red : PieceColor.black;

    final squares =
        List.generate(10, (_) => List<Piece?>.filled(9, null, growable: false));
    final allPieces = <Piece>[];

    final rows = boardFen.split('/');
    for (int r = 0; r < rows.length && r < 10; r++) {
      int col = 0;
      for (final ch in rows[r].runes) {
        final c = String.fromCharCode(ch);
        final digit = int.tryParse(c);
        if (digit != null) {
          col += digit;
        } else {
          final piece = _pieceFromFenChar(c, BoardPos(col, r));
          if (piece != null) {
            squares[r][col] = piece;
            allPieces.add(piece);
          }
          col++;
        }
      }
    }

    return XiangqiBoard._(
      squares: squares,
      sideToMove: sideToMove,
      pieces: allPieces,
    );
  }

  /// Convert board to UCCI/UCI FEN.
  String toFen() {
    final rows = <String>[];
    for (int r = 0; r < 10; r++) {
      final sb = StringBuffer();
      int empty = 0;
      for (int c = 0; c < 9; c++) {
        final p = squares[r][c];
        if (p == null) {
          empty++;
        } else {
          if (empty > 0) {
            sb.write(empty);
            empty = 0;
          }
          sb.write(_pieceToFenChar(p));
        }
      }
      if (empty > 0) sb.write(empty);
      rows.add(sb.toString());
    }
    final side = sideToMove == PieceColor.red ? 'w' : 'b';
    // standard UCI/UCCI FEN expects 6 fields: board side castling ep halfmove fullmove
    return '${rows.join('/')} $side - - 0 1';
  }

  static String _pieceToFenChar(Piece p) {
    final ch = switch (p.type) {
      PieceType.king => 'k',
      PieceType.advisor => 'a',
      PieceType.elephant => 'b',
      PieceType.horse => 'n',
      PieceType.chariot => 'r',
      PieceType.cannon => 'c',
      PieceType.soldier => 'p',
    };
    return p.color == PieceColor.red ? ch.toUpperCase() : ch;
  }

  static Piece? _pieceFromFenChar(String c, BoardPos pos) {
    final upper = c.toUpperCase();
    final isRed = c == upper;
    final color = isRed ? PieceColor.red : PieceColor.black;

    final type = switch (upper) {
      'K' => PieceType.king,
      'A' => PieceType.advisor,
      'B' || 'E' => PieceType.elephant,
      'H' || 'N' => PieceType.horse,
      'R' => PieceType.chariot,
      'C' => PieceType.cannon,
      'P' => PieceType.soldier,
      _ => null,
    };
    if (type == null) return null;
    return Piece(type: type, color: color, position: pos);
  }

  Piece? at(BoardPos pos) => squares[pos.row][pos.col];
  Piece? atRC(int row, int col) => squares[row][col];

  /// Get all pieces for a given color.
  List<Piece> piecesOf(PieceColor color) =>
      pieces.where((p) => p.color == color).toList();

  /// Check if a position is attacked by any piece of [byColor].
  bool isAttacked(BoardPos pos, PieceColor byColor) {
    return piecesOf(byColor).any((p) => _canAttack(p, pos));
  }

  bool _canAttack(Piece attacker, BoardPos target) {
    final dr = (target.row - attacker.position.row).abs();
    final dc = (target.col - attacker.position.col).abs();
    switch (attacker.type) {
      case PieceType.chariot:
        return _chariotAttacks(attacker.position, target);
      case PieceType.cannon:
        return _cannonAttacks(attacker.position, target);
      case PieceType.horse:
        if (!((dr == 2 && dc == 1) || (dr == 1 && dc == 2))) return false;
        // Block point check
        final bx = dr == 2 ? 0 : (target.col > attacker.position.col ? 1 : -1);
        final by = dc == 2 ? 0 : (target.row > attacker.position.row ? 1 : -1);
        return atRC(attacker.position.row + by, attacker.position.col + bx) ==
            null;
      case PieceType.soldier:
        return _soldierAttacks(attacker, target);
      case PieceType.king:
        return dr + dc == 1 && _inPalace(target, attacker.color);
      case PieceType.advisor:
        return dr == 1 && dc == 1 && _inPalace(target, attacker.color);
      case PieceType.elephant:
        if (!(dr == 2 && dc == 2 && !_isCrossRiver(target, attacker.color))) {
          return false;
        }
        return atRC((attacker.position.row + target.row) ~/ 2,
                (attacker.position.col + target.col) ~/ 2) ==
            null;
    }
  }

  bool _chariotAttacks(BoardPos from, BoardPos to) {
    if (from.row != to.row && from.col != to.col) return false;
    return _countPiecesBetween(from, to) == 0;
  }

  bool _cannonAttacks(BoardPos from, BoardPos to) {
    if (from.row != to.row && from.col != to.col) return false;
    return _countPiecesBetween(from, to) == 1; // exactly one screen
  }

  bool _soldierAttacks(Piece s, BoardPos to) {
    final dr = to.row - s.position.row;
    final dc = (to.col - s.position.col).abs();
    if (s.color == PieceColor.red) {
      // Red advances up (decreasing row in 0-9 system)
      return (dr == -1 && dc == 0) ||
          (s.position.row <= 4 && dr == 0 && dc == 1);
    } else {
      return (dr == 1 && dc == 0) ||
          (s.position.row >= 5 && dr == 0 && dc == 1);
    }
  }

  int _countPiecesBetween(BoardPos a, BoardPos b) {
    int count = 0;
    if (a.row == b.row) {
      final minC = a.col < b.col ? a.col + 1 : b.col + 1;
      final maxC = a.col < b.col ? b.col : a.col;
      for (int c = minC; c < maxC; c++) {
        if (squares[a.row][c] != null) count++;
      }
    } else if (a.col == b.col) {
      final minR = a.row < b.row ? a.row + 1 : b.row + 1;
      final maxR = a.row < b.row ? b.row : a.row;
      for (int r = minR; r < maxR; r++) {
        if (squares[r][a.col] != null) count++;
      }
    }
    return count;
  }

  /// Get the list of pieces that defend [pos].
  List<Piece> getDefenders(BoardPos pos, PieceColor ownColor) {
    return piecesOf(ownColor)
        .where((p) => p.position != pos && _canAttack(p, pos))
        .toList();
  }

  /// Get all legal moves for the piece at [pos].
  List<BoardPos> getValidMoves(BoardPos pos) {
    final piece = at(pos);
    if (piece == null || piece.color != sideToMove) return [];

    final candidates = <BoardPos>[];
    final r = pos.row;
    final c = pos.col;

    switch (piece.type) {
      case PieceType.king:
        for (final d in [
          [0, 1],
          [0, -1],
          [1, 0],
          [-1, 0]
        ]) {
          final target = BoardPos(c + d[0], r + d[1]);
          if (target.isValid && _inPalace(target, piece.color)) {
            candidates.add(target);
          }
        }
        break;
      case PieceType.advisor:
        for (final d in [
          [1, 1],
          [1, -1],
          [-1, 1],
          [-1, -1]
        ]) {
          final target = BoardPos(c + d[0], r + d[1]);
          if (target.isValid && _inPalace(target, piece.color)) {
            candidates.add(target);
          }
        }
        break;
      case PieceType.elephant:
        for (final d in [
          [2, 2],
          [2, -2],
          [-2, 2],
          [-2, -2]
        ]) {
          final target = BoardPos(c + d[0], r + d[1]);
          final eye = BoardPos(c + d[0] ~/ 2, r + d[1] ~/ 2);
          if (target.isValid &&
              !_isCrossRiver(target, piece.color) &&
              at(eye) == null) {
            candidates.add(target);
          }
        }
        break;
      case PieceType.horse:
        final horseMoves = [
          [1, 2],
          [1, -2],
          [-1, 2],
          [-1, -2],
          [2, 1],
          [2, -1],
          [-2, 1],
          [-2, -1],
        ];
        for (final d in horseMoves) {
          final target = BoardPos(c + d[0], r + d[1]);
          // Block point (ma chân)
          final bx = d[0].abs() == 2 ? (d[0] > 0 ? 1 : -1) : 0;
          final by = d[1].abs() == 2 ? (d[1] > 0 ? 1 : -1) : 0;
          final block = BoardPos(c + bx, r + by);
          if (target.isValid && at(block) == null) {
            candidates.add(target);
          }
        }
        break;
      case PieceType.chariot:
        _addOrthogonalMoves(pos, candidates, captureMode: false);
        _addOrthogonalMoves(pos, candidates, captureMode: true);
        break;
      case PieceType.cannon:
        _addCannonMoves(pos, candidates);
        break;
      case PieceType.soldier:
        final forward = piece.color == PieceColor.red ? -1 : 1;
        final target = BoardPos(c, r + forward);
        if (target.isValid) candidates.add(target);
        if (_hasCrossRiver(pos, piece.color)) {
          final left = BoardPos(c - 1, r);
          final right = BoardPos(c + 1, r);
          if (left.isValid) candidates.add(left);
          if (right.isValid) candidates.add(right);
        }
        break;
    }

    // Filter by:
    // 1. Cannot capture own pieces
    // 2. Cannot face King directly (Flying General)
    // 3. Move must not leave King in check
    return candidates.where((target) {
      final targetPiece = at(target);
      if (targetPiece?.color == piece.color) return false;

      // Simulate move
      final nextBoard = _simulateMove(pos, target);

      // Flying General check
      if (nextBoard._isFlyingGeneral()) return false;

      // Check check
      return !nextBoard.isCheck(piece.color);
    }).toList();
  }

  void _addOrthogonalMoves(BoardPos from, List<BoardPos> list,
      {required bool captureMode}) {
    final directions = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0]
    ];
    for (final d in directions) {
      for (int i = 1; i < 10; i++) {
        final target = BoardPos(from.col + d[0] * i, from.row + d[1] * i);
        if (!target.isValid) break;
        final p = at(target);
        if (p == null) {
          if (!captureMode) list.add(target);
        } else {
          if (captureMode) list.add(target);
          break;
        }
      }
    }
  }

  void _addCannonMoves(BoardPos from, List<BoardPos> list) {
    final directions = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0]
    ];
    for (final d in directions) {
      bool jumped = false;
      for (int i = 1; i < 10; i++) {
        final target = BoardPos(from.col + d[0] * i, from.row + d[1] * i);
        if (!target.isValid) break;
        final p = at(target);
        if (!jumped) {
          if (p == null) {
            list.add(target);
          } else {
            jumped = true;
          }
        } else {
          if (p != null) {
            list.add(target); // Capture
            break;
          }
        }
      }
    }
  }

  bool _inPalace(BoardPos pos, PieceColor color) {
    if (pos.col < 3 || pos.col > 5) return false;
    if (color == PieceColor.red) return pos.row >= 7 && pos.row <= 9;
    return pos.row >= 0 && pos.row <= 2;
  }

  bool _isCrossRiver(BoardPos pos, PieceColor color) {
    if (color == PieceColor.red) return pos.row <= 4;
    return pos.row >= 5;
  }

  bool _hasCrossRiver(BoardPos pos, PieceColor color) {
    if (color == PieceColor.red) return pos.row <= 4;
    return pos.row >= 5;
  }

  bool isCheck(PieceColor color) {
    final kingPos = pieces
        .firstWhere((p) => p.type == PieceType.king && p.color == color)
        .position;
    final opponent =
        color == PieceColor.red ? PieceColor.black : PieceColor.red;
    return isAttacked(kingPos, opponent);
  }

  bool _isFlyingGeneral() {
    final redKing = pieces
        .firstWhere(
            (p) => p.type == PieceType.king && p.color == PieceColor.red)
        .position;
    final blackKing = pieces
        .firstWhere(
            (p) => p.type == PieceType.king && p.color == PieceColor.black)
        .position;
    if (redKing.col != blackKing.col) return false;
    return _countPiecesBetween(redKing, blackKing) == 0;
  }

  XiangqiBoard _simulateMove(BoardPos from, BoardPos to) {
    final newSquares = List.generate(10, (r) => List<Piece?>.from(squares[r]));
    final piece = newSquares[from.row][from.col]!;
    newSquares[from.row][from.col] = null;
    newSquares[to.row][to.col] = piece.copyWith(position: to);
    final newPieces = newSquares.expand((r) => r).whereType<Piece>().toList();
    return XiangqiBoard._(
      squares: newSquares,
      sideToMove: sideToMove, // Simulation doesn't switch side
      pieces: newPieces,
    );
  }

  /// Apply a UCCI move string (e.g. "b0c2") and return new board.
  XiangqiBoard applyMove(String ucciMove) {
    if (ucciMove.length < 4) return this;
    final fromPos = BoardPos.fromUcci(ucciMove.substring(0, 2));
    final toPos = BoardPos.fromUcci(ucciMove.substring(2, 4));
    if (fromPos == null || toPos == null) return this;

    final validMoves = getValidMoves(fromPos);
    if (!validMoves.contains(toPos)) return this;

    // Deep copy squares
    final newSquares = List.generate(
      10,
      (r) => List<Piece?>.from(squares[r]),
    );
    final piece = newSquares[fromPos.row][fromPos.col];
    if (piece == null) return this;

    final movedPiece = piece.copyWith(position: toPos);
    newSquares[fromPos.row][fromPos.col] = null;
    newSquares[toPos.row][toPos.col] = movedPiece;

    final newPieces =
        newSquares.expand((row) => row).whereType<Piece>().toList();

    return XiangqiBoard._(
      squares: newSquares,
      sideToMove:
          sideToMove == PieceColor.red ? PieceColor.black : PieceColor.red,
      pieces: newPieces,
    );
  }

  /// Public wrapper for attack detection used by analysis layer.
  bool canAttack(Piece attacker, BoardPos target) =>
      _canAttack(attacker, target);
}
