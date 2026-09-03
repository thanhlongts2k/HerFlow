// lib/core/constants/app_colors.dart
import 'package:flutter/material.dart';

/// Bảng màu phong cách Soft Pastel tinh tế dành riêng cho HerFlow.
/// Kết hợp hài hòa giữa hồng ấm, kem vani, tím lavender và xanh mint thư giãn.
class AppColors {
  AppColors._();

  // === PRIMARY COLORS (HỒNG ẤM PASTEL) ===
  static const Color primary = Color(0xFFE87A90);
  static const Color primaryLight = Color(0xFFF7BAC5);
  static const Color primaryDark = Color(0xFFC75D74);
  static const Color primaryContainer = Color(0xFFFFECEF);

  // === SECONDARY COLORS (TÍM LAVENDER NHẠT) ===
  static const Color secondary = Color(0xFFB388EB);
  static const Color secondaryLight = Color(0xFFD8B9F8);
  static const Color secondaryDark = Color(0xFF8F5FD4);
  static const Color secondaryContainer = Color(0xFFF3E8FF);

  // === ACCENT COLORS (PEACH & MINT) ===
  static const Color accentPeach = Color(0xFFF8B195);
  static const Color accentMint = Color(0xFFA8E6CF);
  static const Color accentButter = Color(0xFFFFF1C5);

  // === 4 PHASIC BIOLOGICAL COLORS (MÀU 4 PHA SINH HỌC) ===
  /// 1. Pha hành kinh (Menstrual): Hồng dâu trầm nhẹ nhàng
  static const Color phaseMenstrual = Color(0xFFE26D80);
  static const Color phaseMenstrualBg = Color(0xFFFDECEF);

  /// 2. Pha nang trứng (Follicular): Cam đào pastel tràn đầy sức sống
  static const Color phaseFollicular = Color(0xFFF5A384);
  static const Color phaseFollicularBg = Color(0xFFFFF3ED);

  /// 3. Pha rụng trứng (Ovulation): Xanh ngọc mint thanh khiết, đỉnh điểm năng lượng
  static const Color phaseOvulation = Color(0xFF67B99A);
  static const Color phaseOvulationBg = Color(0xFFEDF8F4);

  /// 4. Pha hoàng thể (Luteal): Tím thạch anh lavender êm dịu, thư giãn
  static const Color phaseLuteal = Color(0xFFA58BC7);
  static const Color phaseLutealBg = Color(0xFFF5EFFB);

  // === BACKGROUND & SURFACE (LIGHT MODE) ===
  static const Color bgLight = Color(0xFFFDFBF7); // Kem vani dịu mắt
  static const Color backgroundLight = bgLight;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color dividerLight = Color(0xFFF0EBE5);

  // === TEXT COLORS (LIGHT MODE) ===
  static const Color textPrimaryLight = Color(0xFF2E262A);
  static const Color textSecondaryLight = Color(0xFF7A6E75);
  static const Color textMutedLight = Color(0xFFA99DA4);

  // === BACKGROUND & SURFACE (DARK MODE) ===
  static const Color bgDark = Color(0xFF191418); // Nền ấm tối chocolate/espresso
  static const Color backgroundDark = bgDark;
  static const Color surfaceDark = Color(0xFF251F24);
  static const Color cardDark = Color(0xFF2C242A);
  static const Color dividerDark = Color(0xFF382F36);

  // === TEXT COLORS (DARK MODE) ===
  static const Color textPrimaryDark = Color(0xFFF9F5F8);
  static const Color textSecondaryDark = Color(0xFFC7BDC4);
  static const Color textMutedDark = Color(0xFF8D828A);

  // === STATUS & FEEDBACK ===
  static const Color success = Color(0xFF52B788);
  static const Color warning = Color(0xFFF4A261);
  static const Color error = Color(0xFFE76F51);
  static const Color info = Color(0xFF4EA8DE);
}
