import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/xiangqi_model.dart';

class GeminiService {
  static const String _defaultApiKey =
      'AIzaSyCgtiAxvzdY2CTtbdAiHzpTNYxM9NpXtV4';

  Future<GenerativeModel> _getModel() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('gemini_api_key') ?? _defaultApiKey;

    return GenerativeModel(
      model:
          'gemini-3-flash-preview', // Updated to gemini-3-flash-preview as per user request
      apiKey: apiKey,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.none),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.none),
      ],
    );
  }

  Stream<String> analyzePositionStream({
    required String fen,
    required int score,
    required String bestMove,
    required List<String> pvMoves,
    required PieceColor playerPerspective,
    bool isCheck = false,
    bool isMate = false,
  }) async* {
    final pvList = pvMoves.join(', ');
    final sideToMove = fen.contains(' w') ? PieceColor.red : PieceColor.black;
    final sideName = sideToMove == PieceColor.red ? 'Đỏ' : 'Đen';
    final isAnalysisForPlayer = sideToMove == playerPerspective;

    final prompt = '''
Bạn là Vũ Đức Du Mentor. Bạn đang phân tích CẬN KỀ và CHI TIẾT cho phe $sideName.
${isAnalysisForPlayer ? "Đối tượng bạn đang khuyên là NGƯỜI CHƠI." : "Đối tượng bạn đang cảnh báo là về THÂM Ý ĐỐI THỦ."}
${isCheck ? "⚠️ LƯU Ý: Phe $sideName đang bị CHIẾU TƯỚNG!" : ""}
${isMate ? "💀 CẢNH BÁO: Hình cờ này sắp SÁT CỤC (MATE)!" : ""}

Dữ liệu:
- Hình cờ (FEN): $fen
- Score: $score
- Bestmove: $bestMove
- Chuỗi PV: $pvList

Yêu cầu (CHUYÊN SÂU):
1. Độ dài: Khoảng 300 ký tự (phân tích kỹ hơn).
2. Logic: ${isAnalysisForPlayer ? "Chỉ rõ tại sao nước này giúp Người chơi ưu thế về mặt chiến thuật (chiếm lộ, bắt quân, hay tạo thế)." : "Vạch trần âm mưu hiểm hóc của đối thủ và cách nó phá vỡ thế trận của bạn."}
3. Triển vọng: Dự đoán 2-3 nhịp tiếp theo dựa trên chuỗi PV.
4. Chốt hạ: Khẳng định lý do đây là nước đi "sát sườn" nhất hiện tại.
''';

    try {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 10));
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          yield 'Cố vấn đang tạm vắng (Mất kết nối Internet).';
          return;
        }
      } catch (_) {
        yield 'Cố vấn đang tạm vắng (Mất kết nối Internet).';
        return;
      }

      final model = await _getModel();
      final content = [Content.text(prompt)];
      final responses = model.generateContentStream(content);

      String accumulatedText = '';
      await for (final response in responses) {
        final chunk = response.text;
        if (chunk != null) {
          accumulatedText += chunk;
          yield accumulatedText;
        }
      }
    } catch (e) {
      if (e.toString().contains('403') ||
          e.toString().contains('PERMISSION_DENIED')) {
        yield 'Lỗi 403: API Key bị rò rỉ hoặc không hợp lệ. Vui lòng cập nhật Key mới.';
      } else {
        yield 'Lỗi kết nối kỳ đài: $e';
      }
    }
  }
}
