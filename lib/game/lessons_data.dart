class ChessLesson {
  final String title;
  final String content;
  final String category; // 'opening', 'middle', 'endgame'

  ChessLesson(
      {required this.title, required this.content, required this.category});
}

class LessonsRepository {
  static final List<ChessLesson> all = [
    // Opening (Khai cuộc)
    ChessLesson(
      title: 'Pháo Đầu Mã Đội',
      category: 'opening',
      content:
          'Đây là thế trận tấn công trung lộ mạnh mẽ. Người đi trước dùng Pháo khống chế trung lộ, kết hợp với hai Mã tấn công dồn dập.',
    ),
    ChessLesson(
      title: 'Bình Phong Mã',
      category: 'opening',
      content:
          'Thế trận phòng thủ vững chắc nhất. Hai Mã bảo vệ lẫn nhau, Xe và Pháo linh hoạt tạo thành bức tường thành khó phá vỡ.',
    ),
    ChessLesson(
      title: 'Thuận Pháo',
      category: 'opening',
      content:
          'Hai bên cùng vào Pháo đầu. Đây là cuộc đối công quyết liệt, đòi hỏi kỹ năng tính toán và tấn công từ rất sớm.',
    ),

    // Middle (Trung cuộc)
    ChessLesson(
      title: 'Chiến thuật Phế quân lấy thế',
      category: 'middle',
      content:
          'Chấp nhận bỏ quân nhỏ (hoặc thậm chí quân lớn) để chiếm lấy vị trí chiến lược, tạo đường sát cục hoặc phong tỏa đối phương.',
    ),
    ChessLesson(
      title: 'Pháo Lồng (Thiên địa pháo)',
      category: 'middle',
      content:
          'Sử dụng hai Pháo phối hợp cùng lúc từ hai hướng (thường là trung lộ và sườn) để uy hiếp Tướng đối phương.',
    ),
    ChessLesson(
      title: 'Mã Điền (Mã chân tượng)',
      category: 'middle',
      content:
          'Tận dụng Mã ở vị trí yết hầu để khống chế các lộ quan trọng, tạo tiền đề cho Xe và Pháo tấn công dứt điểm.',
    ),

    // Endgame (Tàn cuộc)
    ChessLesson(
      title: 'Đơn Xe thắng Sĩ Tượng Toàn',
      category: 'endgame',
      content:
          'Xe có thể giành chiến thắng nếu biết cách tận dụng sai lầm trong việc vị trí Tướng và Sĩ Tượng của đối thủ.',
    ),
    ChessLesson(
      title: 'Pháo Chốt thắng Sĩ Tượng',
      category: 'endgame',
      content:
          'Sự kết hợp giữa Pháo làm hòi và Chốt áp sát là khắc tinh của bộ đôi phòng ngự Sĩ Tượng.',
    ),
    ChessLesson(
      title: 'Mã Chốt thắng Sĩ',
      category: 'endgame',
      content:
          'Chiến thuật phối hợp Mã và Chốt để bắt Sĩ, mở đường cho Tướng tham chiến dứt điểm cuộc chơi.',
    ),
  ];
}
