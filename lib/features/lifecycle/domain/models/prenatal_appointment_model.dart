// lib/features/lifecycle/domain/models/prenatal_appointment_model.dart
//
// Mô hình mốc khám thai vàng (7 mốc chuẩn y tế Việt Nam)
// Hỗ trợ lưu trạng thái hoàn thành và ngày hẹn thực tế của người dùng.

import 'package:flutter/foundation.dart';

/// Mô hình một mốc khám thai vàng (Prenatal Golden Checkup)
@immutable
class PrenatalAppointmentModel {
  /// ID duy nhất, dùng làm khóa lưu trữ trạng thái người dùng
  final String id;

  /// Tuần thai bắt đầu của khoảng khám (1–40)
  final int weekStart;

  /// Tuần thai kết thúc của khoảng khám
  final int weekEnd;

  /// Tên mốc khám
  final String title;

  /// Mô tả chi tiết nội dung khám
  final String description;

  /// Emoji biểu tượng
  final String emoji;

  /// Người dùng đã tick hoàn thành chưa
  final bool isDone;

  /// Ngày hẹn thực tế do người dùng tự lưu (optional)
  final DateTime? appointmentDate;

  const PrenatalAppointmentModel({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.title,
    required this.description,
    required this.emoji,
    this.isDone = false,
    this.appointmentDate,
  });

  /// Nhãn phạm vi tuần hiển thị: "Tuần 11-13" hoặc "Tuần 32"
  String get weekRangeLabel =>
      weekStart == weekEnd ? 'Tuần $weekStart' : 'Tuần $weekStart–$weekEnd';

  /// Trạng thái hiển thị: mốc đã qua, hiện tại, hay tương lai dựa trên [currentWeek]
  AppointmentStatus statusFor(int currentWeek) {
    if (isDone || currentWeek > weekEnd) return AppointmentStatus.done;
    if (currentWeek >= weekStart && currentWeek <= weekEnd) {
      return AppointmentStatus.current;
    }
    if (currentWeek < weekStart) return AppointmentStatus.upcoming;
    return AppointmentStatus.done;
  }

  PrenatalAppointmentModel copyWith({
    bool? isDone,
    DateTime? appointmentDate,
  }) {
    return PrenatalAppointmentModel(
      id: id,
      weekStart: weekStart,
      weekEnd: weekEnd,
      title: title,
      description: description,
      emoji: emoji,
      isDone: isDone ?? this.isDone,
      appointmentDate: appointmentDate ?? this.appointmentDate,
    );
  }

  /// Chỉ serialize phần do người dùng thay đổi (isDone + appointmentDate)
  Map<String, dynamic> toUserDataMap() {
    return {
      'id': id,
      'isDone': isDone,
      'appointmentDate': appointmentDate?.toIso8601String(),
    };
  }

  /// Merge dữ liệu tĩnh với trạng thái người dùng đã lưu
  static PrenatalAppointmentModel mergeUserData(
    PrenatalAppointmentModel base,
    Map<String, dynamic>? userData,
  ) {
    if (userData == null) return base;
    return base.copyWith(
      isDone: userData['isDone'] as bool? ?? false,
      appointmentDate: userData['appointmentDate'] != null
          ? DateTime.tryParse(userData['appointmentDate'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PrenatalAppointmentModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  // ── 7 Mốc Khám Thai Vàng (Dữ liệu tĩnh chuẩn y tế Việt Nam) ──────────────

  static const List<PrenatalAppointmentModel> goldenCheckups = [
    PrenatalAppointmentModel(
      id: 'checkup_11_13',
      weekStart: 11,
      weekEnd: 13,
      title: 'Đo độ mờ da gáy & Double Test / NIPT',
      description:
          'Siêu âm đo NT (Nuchal Translucency) phát hiện nguy cơ dị tật nhiễm sắc thể. '
          'Xét nghiệm Double Test hoặc NIPT sàng lọc hội chứng Down, Edward, Patau.',
      emoji: '🔬',
    ),
    PrenatalAppointmentModel(
      id: 'checkup_16_18',
      weekStart: 16,
      weekEnd: 18,
      title: 'Triple Test & Kiểm tra dị tật sớm',
      description:
          'Xét nghiệm Triple Test sàng lọc dị tật ống thần kinh và hội chứng Down. '
          'Siêu âm kiểm tra hình thái sơ bộ và xác định giới tính bé (nếu muốn biết).',
      emoji: '🧬',
    ),
    PrenatalAppointmentModel(
      id: 'checkup_20_24',
      weekStart: 20,
      weekEnd: 24,
      title: 'Siêu âm 4D hình thái học mốc vàng',
      description:
          'Siêu âm chi tiết kiểm tra toàn diện: tim thai, não, thận, cột sống, '
          'bàn tay, bàn chân và tất cả cơ quan nội tạng. '
          'Đây là mốc khám quan trọng nhất của thai kỳ.',
      emoji: '🫀',
    ),
    PrenatalAppointmentModel(
      id: 'checkup_24_28',
      weekStart: 24,
      weekEnd: 28,
      title: 'Nghiệm pháp đường huyết OGTT',
      description:
          'Xét nghiệm dung nạp glucose (OGTT) sàng lọc tiểu đường thai kỳ (GDM). '
          'Theo dõi cân nặng và huyết áp để phòng ngừa tiền sản giật.',
      emoji: '🩸',
    ),
    PrenatalAppointmentModel(
      id: 'checkup_32',
      weekStart: 32,
      weekEnd: 32,
      title: 'Đánh giá tăng trưởng thai & vị trí bánh nhau',
      description:
          'Siêu âm đánh giá tốc độ tăng trưởng của bé, vị trí bánh nhau, '
          'lượng nước ối và kiểm tra dây rốn. Bắt đầu theo dõi cử động thai hàng ngày.',
      emoji: '📊',
    ),
    PrenatalAppointmentModel(
      id: 'checkup_36',
      weekStart: 36,
      weekEnd: 36,
      title: 'Tiêm uốn ván & Kiểm tra ngôi thai, NST',
      description:
          'Tiêm nhắc lại uốn ván (nếu chưa đủ mũi). Siêu âm kiểm tra ngôi thai '
          '(đầu xuống hay ngược chiều). Làm Non-stress Test (NST) theo dõi nhịp tim bé khi đạp.',
      emoji: '💉',
    ),
    PrenatalAppointmentModel(
      id: 'checkup_37_40',
      weekStart: 37,
      weekEnd: 40,
      title: 'Khám tuần cuối & Theo dõi chuyển dạ',
      description:
          'Khám định kỳ mỗi tuần. Theo dõi dấu hiệu chuyển dạ sớm: '
          'ra dịch nhầy cổ tử cung, vỡ ối, cơn gò đều đặn. '
          'Chuẩn bị giỏ đồ đi sinh và nắm rõ lộ trình đến bệnh viện.',
      emoji: '🏥',
    ),
  ];
}

/// Trạng thái hiển thị của mốc khám dựa trên tuần thai hiện tại
enum AppointmentStatus {
  /// Mốc sắp tới (tuần hiện tại < weekStart)
  upcoming,

  /// Mốc đang trong khoảng tuần khám (ưu tiên highlight)
  current,

  /// Đã qua hoặc đã tick hoàn thành
  done,
}
