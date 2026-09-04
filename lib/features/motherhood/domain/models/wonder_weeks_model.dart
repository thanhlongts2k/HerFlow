// lib/features/motherhood/domain/models/wonder_weeks_model.dart
//
// Mô hình các tuần khủng hoảng phát triển tri giác (Wonder Weeks Leaps 1-10).
// Dự báo các giai đoạn bé quấy khóc (Storm period) và bước nhảy vọt nhận thức (Sunny week).

class WonderWeeksLeap {
  final int leapIndex;      // 1 đến 10
  final int peakWeek;       // Tuần cao điểm (tính theo ngày dự sinh)
  final int startWeek;      // Tuần bắt đầu bão tố
  final int endWeek;        // Tuần kết thúc bão tố
  final String title;       // Tên bước nhảy tri giác
  final String description; // Mô tả kỹ năng mới của bé
  final String parentTip;   // Lời khuyên cho ba mẹ
  final String calmingTip;  // Bí kíp dỗ bé quấy khóc

  const WonderWeeksLeap({
    required this.leapIndex,
    required this.peakWeek,
    required this.startWeek,
    required this.endWeek,
    required this.title,
    required this.description,
    required this.parentTip,
    required this.calmingTip,
  });
}

class WonderWeeksData {
  static const List<WonderWeeksLeap> leaps = [
    WonderWeeksLeap(
      leapIndex: 1,
      peakWeek: 5,
      startWeek: 4,
      endWeek: 6,
      title: 'Thế Giới Của Các Biến Đổi Giác Quan',
      description: 'Bé bắt đầu quan sát xung quanh lâu hơn, phản ứng với âm thanh và ánh sáng rõ ràng.',
      parentTip: 'Bé bú vặt nhiều hơn và thèm hơi mẹ. Hãy ôm ấp da kề da nhiều hơn.',
      calmingTip: 'Ôm bé nhẹ nhàng, hát ru hoặc mở tiếng ồn trắng (white noise).',
    ),
    WonderWeeksLeap(
      leapIndex: 2,
      peakWeek: 8,
      startWeek: 7,
      endWeek: 9,
      title: 'Thế Giới Của Các Hoa Văn & Họa Tiết',
      description: 'Bé phát hiện ra bàn tay của mình, lắng nghe giọng nói quen thuộc và hóng chuyện.',
      parentTip: 'Bé có thể giật mình hoặc khó ngủ sâu. Bố hãy phụ bế vỗ để mẹ chợp mắt.',
      calmingTip: 'Quấn nhộng chũn và đung đưa nhẹ theo nhịp tim.',
    ),
    WonderWeeksLeap(
      leapIndex: 3,
      peakWeek: 12,
      startWeek: 11,
      endWeek: 13,
      title: 'Thế Giới Của Sự Chuyển Động Êm Dịu',
      description: 'Bé biết với đồ chơi, lật nghiêng và phát ra âm thanh ê a linh hoạt.',
      parentTip: 'Cữ bú ban ngày có thể bị phân tâm vì bé mải nhìn xung quanh.',
      calmingTip: 'Cho bé bú trong phòng yên tĩnh, ánh sáng dịu.',
    ),
    WonderWeeksLeap(
      leapIndex: 4,
      peakWeek: 19,
      startWeek: 14,
      endWeek: 20,
      title: 'Thế Giới Của Các Chuỗi Sự Kiện (Khủng hoảng ngủ tháng thứ 4)',
      description: 'Bước nhảy vọt lớn về giấc ngủ: bé chuyển sang chu kỳ ngủ người lớn và dễ tỉnh giấc.',
      parentTip: 'Kiên nhẫn hỗ trợ bé tự chuyển giấc. Ba mẹ thay phiên nhau canh đêm.',
      calmingTip: 'Thiết lập trình tự đi ngủ nhất quán (tắm, massage, đọc sách, ngủ).',
    ),
    WonderWeeksLeap(
      leapIndex: 5,
      peakWeek: 26,
      startWeek: 22,
      endWeek: 27,
      title: 'Thế Giới Của Mối Quan Hệ (Sợ xa cách)',
      description: 'Bé nhận biết khoảng cách và nhận ra mẹ có thể rời đi, bắt đầu bám mẹ chặt chẽ.',
      parentTip: 'Chơi trò ú òa (peek-a-boo) để dạy bé rằng mẹ đi rồi mẹ sẽ về.',
      calmingTip: 'Luôn chào tạm biệt và nói câu trấn an khi bước ra khỏi tầm nhìn của bé.',
    ),
  ];

  /// Lấy Leap hiện tại hoặc gần nhất dựa trên số tuần tuổi của bé
  static WonderWeeksLeap? getLeapForWeek(int ageInWeeks) {
    for (final leap in leaps) {
      if (ageInWeeks >= leap.startWeek && ageInWeeks <= leap.endWeek) {
        return leap;
      }
    }
    return null;
  }

  /// Kiểm tra xem tuần hiện tại có phải là tuần bão tố (quấy khóc cao điểm) không
  static bool isStormPeriod(int ageInWeeks) {
    final leap = getLeapForWeek(ageInWeeks);
    return leap != null;
  }
}
