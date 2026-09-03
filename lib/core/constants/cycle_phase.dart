// lib/core/constants/cycle_phase.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 4 Pha sinh học của chu kỳ kinh nguyệt
enum CyclePhase {
  /// 1. Pha hành kinh: Ngày 1 -> Ngày 5 (Hormone thấp, cơ thể giải phóng niêm mạc)
  menstrual,

  /// 2. Pha nang trứng: Ngày 6 -> Ngày 13 (Estrogen tăng dần, năng lượng dồi dào)
  follicular,

  /// 3. Pha rụng trứng: Ngày 14 -> Ngày 16 (Đỉnh Estrogen & LH, khả năng thụ thai cao nhất)
  ovulation,

  /// 4. Pha hoàng thể: Ngày 17 -> Ngày 28 (Progesterone tăng, tiền kinh nguyệt PMS)
  luteal;

  /// Tên tiếng Việt của pha sinh học
  String get vietnameseName {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Pha Hành Kinh';
      case CyclePhase.follicular:
        return 'Pha Nang Trứng';
      case CyclePhase.ovulation:
        return 'Pha Rụng Trứng';
      case CyclePhase.luteal:
        return 'Pha Hoàng Thể';
    }
  }

  /// Tiêu đề ngắn gọn
  String get shortTitle {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Hành kinh';
      case CyclePhase.follicular:
        return 'Nang trứng';
      case CyclePhase.ovulation:
        return 'Rụng trứng';
      case CyclePhase.luteal:
        return 'Hoàng thể';
    }
  }

  /// Khẩu hiệu trạng thái thể chất
  String get tagline {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Thời gian nghỉ ngơi & hồi phục năng lượng';
      case CyclePhase.follicular:
        return 'Tái sinh, bừng sáng & sẵn sàng sáng tạo';
      case CyclePhase.ovulation:
        return 'Quyến rũ, tự tin & đỉnh cao phong độ';
      case CyclePhase.luteal:
        return 'Lắng nghe cơ thể, chăm sóc & vỗ về nội tâm';
    }
  }

  /// Màu sắc đại diện cho pha
  Color get color {
    switch (this) {
      case CyclePhase.menstrual:
        return AppColors.phaseMenstrual;
      case CyclePhase.follicular:
        return AppColors.phaseFollicular;
      case CyclePhase.ovulation:
        return AppColors.phaseOvulation;
      case CyclePhase.luteal:
        return AppColors.phaseLuteal;
    }
  }

  /// Màu nền nhẹ pastel
  Color get backgroundColor {
    switch (this) {
      case CyclePhase.menstrual:
        return AppColors.phaseMenstrualBg;
      case CyclePhase.follicular:
        return AppColors.phaseFollicularBg;
      case CyclePhase.ovulation:
        return AppColors.phaseOvulationBg;
      case CyclePhase.luteal:
        return AppColors.phaseLutealBg;
    }
  }

  /// Icon đại diện
  IconData get icon {
    switch (this) {
      case CyclePhase.menstrual:
        return Icons.water_drop_rounded;
      case CyclePhase.follicular:
        return Icons.eco_rounded;
      case CyclePhase.ovulation:
        return Icons.wb_sunny_rounded;
      case CyclePhase.luteal:
        return Icons.nightlight_round;
    }
  }

  /// Lời khuyên nhanh cho chồng / bạn trai (Husband View)
  String get husbandAdvice {
    switch (this) {
      case CyclePhase.menstrual:
        return 'Hôm nay nàng dễ mệt mỏi và đau lưng/bụng. Hãy pha nước ấm, chuẩn bị túi chườm hoặc massage lưng nhẹ nhàng cho vợ.';
      case CyclePhase.follicular:
        return 'Tâm trạng nàng đang rất vui vẻ, cởi mở và giàu năng lượng. Rất thích hợp để cùng nhau đi chơi, ăn tối lãng mạn hoặc thử điều mới!';
      case CyclePhase.ovulation:
        return 'Nàng đang ở đỉnh cao hấp dẫn và cảm xúc thăng hoa. Hãy dành cho nàng những lời khen chân thành và cử chỉ âu yếm.';
      case CyclePhase.luteal:
        return 'Giai đoạn nhạy cảm (PMS): Nàng có thể dễ cáu gắt hoặc mau nước mắt. Hãy chủ động làm việc nhà, kiên nhẫn lắng nghe và chuẩn bị món ngọt nàng thích.';
    }
  }
}
