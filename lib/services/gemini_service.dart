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
    required List<String> translatedTopMoves,
    required PieceColor playerPerspective,
    bool isCheck = false,
    bool isMate = false,
  }) async* {
    final movesJson = translatedTopMoves.join(', ');
    final sideToMove = fen.contains(' w') ? PieceColor.red : PieceColor.black;
    final sideName = sideToMove == PieceColor.red ? 'Đỏ' : 'Đen';

    final prompt = '''
Bạn là "Vũ Đức Du Mentor" - một chuyên gia Cờ Tướng hàng đầu.
Nhiệm vụ: Cung cấp "Giải thích sâu" cho phe $sideName.

Dữ liệu kĩ thuật:
- Hình cờ (FEN): $fen
- Top 3 nước đi gợi ý (đã dịch sang tiếng Việt): $movesJson

Yêu cầu phân tích (NGHIÊM NGẶT):
1. Ngôn ngữ: Phải dùng khẩu quyết Cờ Tướng Việt Nam (ví dụ: "Pháo 2 bình 5", "Mã 8 tấn 7", "Xe 9 thối 1"). KHÔNG dùng tọa độ như a0h0.
2. Cấu trúc "Giải thích sâu":
   - So sánh nước đi tốt nhất hiện tại với 2 nước đi khả dĩ khác trong danh sách $movesJson.
   - Phân tích sự đánh đổi về:
     + Vật chất vs Vị trí (VD: "Phế Mã để chiếm lộ sườn").
     + Tấn công vs Phòng thủ (VD: "Bỏ Xe chiếu bí hay về Sĩ giữ thành").
3. Độ dài: Khoảng 300-400 ký tự.
4. Kết thúc: Bắt buộc bằng một câu hỏi gợi mở để người chơi tự tư duy nước tiếp theo.

Phong cách: Uyên bác, thực dụng, giống như một người thầy đang dạy học trò.
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
