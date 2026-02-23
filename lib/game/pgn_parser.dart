class PgnGame {
  final Map<String, String> tags;
  final String movesString;
  final List<String> moves;

  PgnGame({required this.tags, required this.movesString, required this.moves});

  String get event => tags['Event'] ?? 'Ván Đấu Không Tên';
  String get red => tags['Red'] ?? tags['White'] ?? 'Người chơi 1';
  String get black => tags['Black'] ?? 'Người chơi 2';
  String get result => tags['Result'] ?? '*';
  String get date => tags['Date'] ?? 'Không rõ';
}

class PgnParser {
  static List<PgnGame> parse(String content) {
    final List<PgnGame> games = [];
    final pattern = RegExp(r'(\[.*?\]\s*)+(.*?)(?=\n\[|$)', dotAll: true);
    final tagPattern = RegExp(r'\[(\w+)\s+"(.*?)"\]');

    final matches = pattern.allMatches(content);
    int count = 0;
    for (final match in matches) {
      if (count >= 1000)
        break; // Increased to 1000 to show "hundreds" as requested
      final tagsText = match.group(1) ?? '';
      final movesText = match.group(2) ?? '';

      final Map<String, String> tags = {};
      tagPattern.allMatches(tagsText).forEach((m) {
        tags[m.group(1)!] = m.group(2)!;
      });

      // Simple move extractor (handling both UCI and WXF styles)
      final moveList = movesText
          .replaceAll(RegExp(r'\{.*?\}'), '') // Remove comments
          .replaceAll(RegExp(r'\d+\.'), '') // Remove move numbers
          .split(RegExp(r'\s+'))
          .where((s) =>
              s.isNotEmpty &&
              !s.contains('/') &&
              s != '*' &&
              s != '1-0' &&
              s != '0-1' &&
              s != '1/2-1/2')
          .toList();

      if (moveList.isNotEmpty) {
        games.add(PgnGame(
          tags: tags,
          movesString: movesText.trim(),
          moves: moveList,
        ));
        count++;
      }
    }
    return games;
  }
}
