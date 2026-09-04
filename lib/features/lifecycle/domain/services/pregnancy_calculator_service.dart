// lib/features/lifecycle/domain/services/pregnancy_calculator_service.dart
import 'package:flutter/foundation.dart';

/// Ba tam cá nguyệt (3 giai đoạn) của thai kỳ chuẩn y khoa
enum Trimester {
  first,
  second,
  third;

  /// Tên tiếng Việt đầy đủ kèm mô tả
  String get displayName => switch (this) {
        Trimester.first => 'Tam cá nguyệt 1 (3 tháng đầu - Tuần 1-13)',
        Trimester.second => 'Tam cá nguyệt 2 (3 tháng giữa - Tuần 14-27)',
        Trimester.third => 'Tam cá nguyệt 3 (3 tháng cuối - Tuần 28-40+)',
      };

  /// Tên gọi ngắn gọn
  String get shortName => switch (this) {
        Trimester.first => '3 tháng đầu',
        Trimester.second => '3 tháng giữa',
        Trimester.third => '3 tháng cuối',
      };
}

/// Kết quả tính toán tuổi thai chuẩn xác
@immutable
class GestationalAgeResult {
  /// Số tuần thai hoàn thành (1 -> 40+). Nếu < 7 ngày thì là 0 tuần.
  final int currentWeek;

  /// Số ngày lẻ trong tuần hiện tại (0 -> 6)
  final int currentDayOfWeek;

  /// Tổng số ngày mang thai kể từ LMP
  final int totalDaysPregnant;

  /// Số ngày đếm ngược đến ngày dự sinh (EDD - TargetDate)
  final int daysUntilDue;

  /// Tiến độ thai kỳ (0.0 -> 1.0)
  final double progressPercentage;

  /// Tam cá nguyệt hiện tại
  final Trimester trimester;

  const GestationalAgeResult({
    required this.currentWeek,
    required this.currentDayOfWeek,
    required this.totalDaysPregnant,
    required this.daysUntilDue,
    required this.progressPercentage,
    required this.trimester,
  });

  /// Chuỗi hiển thị định dạng: "11 tuần 3 ngày"
  String get formattedAge => '$currentWeek tuần $currentDayOfWeek ngày';

  /// Tuần thai thứ mấy đang diễn ra (1-indexed, ví dụ: 11 tuần 3 ngày là Tuần thứ 12)
  int get currentWeekOrdinal => currentWeek + 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GestationalAgeResult &&
        other.currentWeek == currentWeek &&
        other.currentDayOfWeek == currentDayOfWeek &&
        other.totalDaysPregnant == totalDaysPregnant &&
        other.daysUntilDue == daysUntilDue &&
        other.progressPercentage == progressPercentage &&
        other.trimester == trimester;
  }

  @override
  int get hashCode => Object.hash(
        currentWeek,
        currentDayOfWeek,
        totalDaysPregnant,
        daysUntilDue,
        progressPercentage,
        trimester,
      );

  @override
  String toString() {
    return 'GestationalAgeResult($formattedAge, Tổng: $totalDaysPregnant ngày, Còn: $daysUntilDue ngày, Tiến độ: ${(progressPercentage * 100).toStringAsFixed(1)}%, ${trimester.shortName})';
  }
}

/// Service tính toán tuổi thai chuẩn y khoa (Naegele's Rule)
class PregnancyCalculatorService {
  /// Số ngày thai kỳ chuẩn theo quy tắc Naegele (40 tuần = 280 ngày)
  static const int standardPregnancyDays = 280;

  /// Chuẩn hóa ngày chỉ lấy năm, tháng, ngày (bỏ thành phần giờ, phút, giây)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Tính ngày dự sinh ước tính (EDD) từ ngày đầu kỳ kinh cuối (LMP)
  /// Chuẩn y khoa: LMP + 280 ngày
  static DateTime calculateDueDateFromLMP(DateTime lmp) {
    final cleanLmp = normalizeDate(lmp);
    return cleanLmp.add(const Duration(days: standardPregnancyDays));
  }

  /// Tính ngày đầu kỳ kinh cuối (LMP) từ ngày dự sinh (EDD)
  /// Chuẩn y khoa: EDD - 280 ngày
  static DateTime calculateLMPFromDueDate(DateTime edd) {
    final cleanEdd = normalizeDate(edd);
    return cleanEdd.subtract(const Duration(days: standardPregnancyDays));
  }

  /// Tính toán tuổi thai chuẩn xác tại thời điểm [targetDate] (mặc định là hôm nay)
  static GestationalAgeResult calculateGestationalAge(
    DateTime lmp, [
    DateTime? targetDate,
  ]) {
    final cleanLmp = normalizeDate(lmp);
    final cleanTarget = normalizeDate(targetDate ?? DateTime.now());

    final differenceInDays = cleanTarget.difference(cleanLmp).inDays;
    final totalDays = differenceInDays < 0 ? 0 : differenceInDays;

    final currentWeek = totalDays ~/ 7;
    final currentDayOfWeek = totalDays % 7;
    final daysUntilDue = standardPregnancyDays - totalDays;
    final progress = (totalDays / standardPregnancyDays).clamp(0.0, 1.0);

    // Xác định Tam cá nguyệt chuẩn y tế:
    // Tam cá nguyệt 1: Tuần 1-13 (0w0d đến 13w6d)
    // Tam cá nguyệt 2: Tuần 14-27 (14w0d đến 27w6d)
    // Tam cá nguyệt 3: Tuần 28-40+ (28w0d trở lên)
    final Trimester trimester;
    if (currentWeek <= 13) {
      trimester = Trimester.first;
    } else if (currentWeek <= 27) {
      trimester = Trimester.second;
    } else {
      trimester = Trimester.third;
    }

    return GestationalAgeResult(
      currentWeek: currentWeek,
      currentDayOfWeek: currentDayOfWeek,
      totalDaysPregnant: totalDays,
      daysUntilDue: daysUntilDue,
      progressPercentage: progress,
      trimester: trimester,
    );
  }
}
