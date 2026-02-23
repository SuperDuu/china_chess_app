enum PuzzlePhase { opening, middlegame, endgame }

enum PuzzleType {
  mate, // Chiếu hết
  capture, // Bắt quân
  combination, // Phối hợp
  defense, // Phòng thủ
  development, // Phát triển (khai cuộc)
  technique // Kỹ thuật (tàn cuộc)
}

class Puzzle {
  final String id;
  final String fen;
  final String solution; // Multiple moves separated by comma, e.g. "h2e2,h9g7"
  final PuzzlePhase phase;
  final PuzzleType type;
  final int movesToSolve;
  final String description;
  final String? detailedExplanation;
  final int difficulty; // 1-5
  final String? openingName; // For phase = opening
  final String? endgameType; // For phase = endgame

  Puzzle({
    required this.id,
    required this.fen,
    required this.solution,
    required this.phase,
    required this.type,
    required this.movesToSolve,
    required this.description,
    this.detailedExplanation,
    required this.difficulty,
    this.openingName,
    this.endgameType,
  });

  factory Puzzle.fromJson(Map<String, dynamic> json) {
    return Puzzle(
      id: json['id'],
      fen: json['fen'],
      solution: json['solution'],
      phase: PuzzlePhase.values
          .firstWhere((e) => e.toString() == 'PuzzlePhase.${json['phase']}'),
      type: PuzzleType.values
          .firstWhere((e) => e.toString() == 'PuzzleType.${json['type']}'),
      movesToSolve: json['movesToSolve'] ?? 1,
      description: json['description'] ?? '',
      detailedExplanation: json['detailedExplanation'],
      difficulty: json['difficulty'] ?? 3,
      openingName: json['openingName'],
      endgameType: json['endgameType'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fen': fen,
        'solution': solution,
        'phase': phase.toString().split('.').last,
        'type': type.toString().split('.').last,
        'movesToSolve': movesToSolve,
        'description': description,
        'detailedExplanation': detailedExplanation,
        'difficulty': difficulty,
        'openingName': openingName,
        'endgameType': endgameType,
      };
}
