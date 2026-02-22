import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GeminiService {
  static const String _defaultApiKey =
      'AIzaSyCgtiAxvzdY2CTtbdAiHzpTNYxM9NpXtV4';

  Future<GenerativeModel> _getModel() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? _defaultApiKey;

    return GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  Future<String> analyzePosition({
    required String fen,
    required int score,
    required String bestMove,
    required List<String> pvMoves,
  }) async {
    final pvList = pvMoves.join(', ');
    final side = fen.contains(' w') ? 'Đỏ' : 'Đen';

    final prompt = '''
Bạn là Vũ Đức Du Mentor. Dựa trên chuỗi PV 4 nước tiếp theo từ Engine, hãy giải thích nước đi:

Dữ liệu:
- Hình cờ (FEN): $fen
- Side: $side
- Score: $score
- Bestmove: $bestMove
- Chuỗi PV: $pvList

Yêu cầu (NGHIÊM NGẶT):
1. Độ dài: Đúng 100 chữ, không rườm rà.
2. Ưu điểm: Giải thích logic chiếm lộ, tạo thế công hoặc thủ trong 4 nhịp tới.
3. Nhược điểm: PHẢI CHỈ RÕ rủi ro tiềm ẩn (ví dụ: hở sườn, mất ưu thế cánh, hoặc tạo cơ hội phản công cho địch).
4. Vì sao đáng đi: Chốt hạ lý do nước này vẫn tối ưu nhất bất chấp nhược điểm.
5. Tính trung thực: Không bịa đặt, nói thật lòng dựa trên số liệu Engine.
''';

    try {
      final model = await _getModel();
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      return response.text ?? 'Kỳ hữu thông cảm, tôi đang suy ngẫm chưa ra...';
    } catch (e) {
      return 'Lỗi kết nối kỳ đài (Hãy kiểm tra API Key): $e';
    }
  }
}
