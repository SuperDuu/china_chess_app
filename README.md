# CỜ TƯỚNG AI (Vũ Đức Du Edition)

Ứng dụng Cờ Tướng hiện đại tích hợp AI Pikafish (Stockfish variant) qua FFI và Siêu cố vấn Gemini XAI, mang lại trải nghiệm phân tích kỹ thuật đỉnh cao.

## Tính năng đột phá
- **Siêu cố vấn Gemini (Critic)**: Phân tích phản biện nước đi, chỉ rõ cả ưu điểm và rủi ro (hở sườn, yếu cánh) bằng ngôn ngữ tự nhiên.
- **Luyện tập Max Power**: Engine tự động chạy ở mức **Skill 20, Depth 22** với 4 luồng xử lý trong chế độ Phân tích.
- **Combat Mode**: 3 cấp độ khó (Dễ/Trung bình/Khó) cùng tính năng chọn quân Đỏ/Đen và Bot tự động đi bài.
- **Neon Glow Pieces**: Hiệu ứng phát sáng Neon vàng kim cực đẹp cho quân cờ được gợi ý.
- **Settings tùy biến**: Cho phép người dùng tự nhập Gemini API Key cá nhân.
- **Tọa độ chính xác**: Hệ thống tọa độ 1-9 và a-i được căn chỉnh tỉ lệ chuẩn xác với lưới bàn cờ.

## Công nghệ & Phát triển
- **Framework**: Flutter (Dart)
- **Engine**: Pikafish (C++ FFI Bridge) - Tối ưu cho `arm64-v8a`.
- **XAI**: Google Gemini 1.5 Flash API.
- **Tác giả**: Vũ Đức Du
- **Application ID**: `com.vuducdu.chessmaster`

## Cài đặt
1. Clone repository.
2. Đảm bảo đã cài Flutter SDK.
3. Chạy `flutter pub get`.
4. Cấu hình Gemini API Key trong menu **Cài đặt** để kích hoạt tính năng Cố vấn.
