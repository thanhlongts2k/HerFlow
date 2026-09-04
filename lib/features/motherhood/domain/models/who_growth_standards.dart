// lib/features/motherhood/domain/models/who_growth_standards.dart
//
// Bảng đối chiếu chuẩn tăng trưởng trẻ em của Tổ chức Y Tế Thế Giới (WHO Child Growth Standards).
// Tích hợp dữ liệu Z-Score (Median, -2SD, +2SD) cho Bé Trai & Bé Gái từ 0 đến 24 tháng tuổi.
// Thuần Dart, không phụ thuộc API, hoạt động 100% offline-first.

class WhoGrowthDataPoint {
  final int month;
  final double sd2Neg;  // -2 SD (Nguy cơ nhẹ cân / thấp còi)
  final double sd1Neg;  // -1 SD
  final double median;  // Median (Chuẩn trung bình P50)
  final double sd1Pos;  // +1 SD
  final double sd2Pos;  // +2 SD (Nguy cơ thừa cân / cao vượt trội)

  const WhoGrowthDataPoint({
    required this.month,
    required this.sd2Neg,
    required this.sd1Neg,
    required this.median,
    required this.sd1Pos,
    required this.sd2Pos,
  });
}

class WhoGrowthStandards {
  // ── 1. CÂN NẶNG THEO TUỔI (WEIGHT-FOR-AGE, KG) ──────────────────────────────
  // Nguồn: WHO Child Growth Standards (0 - 24 tháng)
  static const List<WhoGrowthDataPoint> weightBoys = [
    WhoGrowthDataPoint(month: 0,  sd2Neg: 2.5, sd1Neg: 2.9, median: 3.3, sd1Pos: 3.9, sd2Pos: 4.4),
    WhoGrowthDataPoint(month: 1,  sd2Neg: 3.4, sd1Neg: 3.9, median: 4.5, sd1Pos: 5.1, sd2Pos: 5.8),
    WhoGrowthDataPoint(month: 2,  sd2Neg: 4.3, sd1Neg: 4.9, median: 5.6, sd1Pos: 6.3, sd2Pos: 7.1),
    WhoGrowthDataPoint(month: 3,  sd2Neg: 5.0, sd1Neg: 5.7, median: 6.4, sd1Pos: 7.2, sd2Pos: 8.0),
    WhoGrowthDataPoint(month: 4,  sd2Neg: 5.6, sd1Neg: 6.2, median: 7.0, sd1Pos: 7.8, sd2Pos: 8.7),
    WhoGrowthDataPoint(month: 5,  sd2Neg: 6.0, sd1Neg: 6.7, median: 7.5, sd1Pos: 8.4, sd2Pos: 9.3),
    WhoGrowthDataPoint(month: 6,  sd2Neg: 6.4, sd1Neg: 7.1, median: 7.9, sd1Pos: 8.8, sd2Pos: 9.8),
    WhoGrowthDataPoint(month: 7,  sd2Neg: 6.7, sd1Neg: 7.4, median: 8.3, sd1Pos: 9.2, sd2Pos: 10.3),
    WhoGrowthDataPoint(month: 8,  sd2Neg: 6.9, sd1Neg: 7.7, median: 8.6, sd1Pos: 9.6, sd2Pos: 10.7),
    WhoGrowthDataPoint(month: 9,  sd2Neg: 7.1, sd1Neg: 8.0, median: 8.9, sd1Pos: 9.9, sd2Pos: 11.0),
    WhoGrowthDataPoint(month: 10, sd2Neg: 7.4, sd1Neg: 8.2, median: 9.2, sd1Pos: 10.2, sd2Pos: 11.4),
    WhoGrowthDataPoint(month: 11, sd2Neg: 7.6, sd1Neg: 8.4, median: 9.4, sd1Pos: 10.5, sd2Pos: 11.7),
    WhoGrowthDataPoint(month: 12, sd2Neg: 7.7, sd1Neg: 8.6, median: 9.6, sd1Pos: 10.8, sd2Pos: 12.0),
    WhoGrowthDataPoint(month: 15, sd2Neg: 8.3, sd1Neg: 9.2, median: 10.3, sd1Pos: 11.5, sd2Pos: 12.8),
    WhoGrowthDataPoint(month: 18, sd2Neg: 8.8, sd1Neg: 9.8, median: 10.9, sd1Pos: 12.2, sd2Pos: 13.7),
    WhoGrowthDataPoint(month: 21, sd2Neg: 9.2, sd1Neg: 10.3, median: 11.5, sd1Pos: 12.9, sd2Pos: 14.5),
    WhoGrowthDataPoint(month: 24, sd2Neg: 9.7, sd1Neg: 10.8, median: 12.2, sd1Pos: 13.6, sd2Pos: 15.3),
  ];

  static const List<WhoGrowthDataPoint> weightGirls = [
    WhoGrowthDataPoint(month: 0,  sd2Neg: 2.4, sd1Neg: 2.8, median: 3.2, sd1Pos: 3.7, sd2Pos: 4.2),
    WhoGrowthDataPoint(month: 1,  sd2Neg: 3.2, sd1Neg: 3.6, median: 4.2, sd1Pos: 4.8, sd2Pos: 5.5),
    WhoGrowthDataPoint(month: 2,  sd2Neg: 3.9, sd1Neg: 4.5, median: 5.1, sd1Pos: 5.8, sd2Pos: 6.6),
    WhoGrowthDataPoint(month: 3,  sd2Neg: 4.5, sd1Neg: 5.2, median: 5.8, sd1Pos: 6.6, sd2Pos: 7.5),
    WhoGrowthDataPoint(month: 4,  sd2Neg: 5.0, sd1Neg: 5.7, median: 6.4, sd1Pos: 7.3, sd2Pos: 8.2),
    WhoGrowthDataPoint(month: 5,  sd2Neg: 5.4, sd1Neg: 6.1, median: 6.9, sd1Pos: 7.8, sd2Pos: 8.8),
    WhoGrowthDataPoint(month: 6,  sd2Neg: 5.7, sd1Neg: 6.5, median: 7.3, sd1Pos: 8.2, sd2Pos: 9.3),
    WhoGrowthDataPoint(month: 7,  sd2Neg: 6.0, sd1Neg: 6.8, median: 7.6, sd1Pos: 8.6, sd2Pos: 9.8),
    WhoGrowthDataPoint(month: 8,  sd2Neg: 6.3, sd1Neg: 7.0, median: 7.9, sd1Pos: 9.0, sd2Pos: 10.2),
    WhoGrowthDataPoint(month: 9,  sd2Neg: 6.5, sd1Neg: 7.3, median: 8.2, sd1Pos: 9.3, sd2Pos: 10.5),
    WhoGrowthDataPoint(month: 10, sd2Neg: 6.7, sd1Neg: 7.5, median: 8.5, sd1Pos: 9.6, sd2Pos: 10.9),
    WhoGrowthDataPoint(month: 11, sd2Neg: 6.9, sd1Neg: 7.7, median: 8.7, sd1Pos: 9.9, sd2Pos: 11.2),
    WhoGrowthDataPoint(month: 12, sd2Neg: 7.0, sd1Neg: 7.9, median: 8.9, sd1Pos: 10.1, sd2Pos: 11.5),
    WhoGrowthDataPoint(month: 15, sd2Neg: 7.6, sd1Neg: 8.5, median: 9.6, sd1Pos: 10.9, sd2Pos: 12.4),
    WhoGrowthDataPoint(month: 18, sd2Neg: 8.1, sd1Neg: 9.1, median: 10.2, sd1Pos: 11.6, sd2Pos: 13.2),
    WhoGrowthDataPoint(month: 21, sd2Neg: 8.6, sd1Neg: 9.6, median: 10.9, sd1Pos: 12.3, sd2Pos: 14.0),
    WhoGrowthDataPoint(month: 24, sd2Neg: 9.0, sd1Neg: 10.2, median: 11.5, sd1Pos: 13.0, sd2Pos: 14.8),
  ];

  // ── 2. CHIỀU DÀI / CHIỀU CAO THEO TUỔI (LENGTH-FOR-AGE, CM) ─────────────────
  static const List<WhoGrowthDataPoint> lengthBoys = [
    WhoGrowthDataPoint(month: 0,  sd2Neg: 46.1, sd1Neg: 48.0, median: 49.9, sd1Pos: 51.8, sd2Pos: 53.7),
    WhoGrowthDataPoint(month: 1,  sd2Neg: 50.8, sd1Neg: 52.8, median: 54.7, sd1Pos: 56.7, sd2Pos: 58.6),
    WhoGrowthDataPoint(month: 2,  sd2Neg: 54.4, sd1Neg: 56.4, median: 58.4, sd1Pos: 60.4, sd2Pos: 62.4),
    WhoGrowthDataPoint(month: 3,  sd2Neg: 57.3, sd1Neg: 59.4, median: 61.4, sd1Pos: 63.5, sd2Pos: 65.5),
    WhoGrowthDataPoint(month: 6,  sd2Neg: 63.6, sd1Neg: 65.5, median: 67.6, sd1Pos: 69.6, sd2Pos: 71.6),
    WhoGrowthDataPoint(month: 9,  sd2Neg: 67.5, sd1Neg: 69.7, median: 72.0, sd1Pos: 74.2, sd2Pos: 76.5),
    WhoGrowthDataPoint(month: 12, sd2Neg: 71.0, sd1Neg: 73.4, median: 75.7, sd1Pos: 78.1, sd2Pos: 80.5),
    WhoGrowthDataPoint(month: 18, sd2Neg: 76.9, sd1Neg: 79.6, median: 82.3, sd1Pos: 85.0, sd2Pos: 87.7),
    WhoGrowthDataPoint(month: 24, sd2Neg: 81.7, sd1Neg: 84.8, median: 87.8, sd1Pos: 90.9, sd2Pos: 93.9),
  ];

  static const List<WhoGrowthDataPoint> lengthGirls = [
    WhoGrowthDataPoint(month: 0,  sd2Neg: 45.4, sd1Neg: 47.3, median: 49.1, sd1Pos: 51.0, sd2Pos: 52.9),
    WhoGrowthDataPoint(month: 1,  sd2Neg: 49.8, sd1Neg: 51.7, median: 53.7, sd1Pos: 55.6, sd2Pos: 57.6),
    WhoGrowthDataPoint(month: 2,  sd2Neg: 53.0, sd1Neg: 55.0, median: 57.1, sd1Pos: 59.1, sd2Pos: 61.1),
    WhoGrowthDataPoint(month: 3,  sd2Neg: 55.6, sd1Neg: 57.7, median: 59.8, sd1Pos: 61.9, sd2Pos: 64.0),
    WhoGrowthDataPoint(month: 6,  sd2Neg: 61.2, sd1Neg: 63.5, median: 65.7, sd1Pos: 68.0, sd2Pos: 70.3),
    WhoGrowthDataPoint(month: 9,  sd2Neg: 65.3, sd1Neg: 67.7, median: 70.1, sd1Pos: 72.6, sd2Pos: 75.0),
    WhoGrowthDataPoint(month: 12, sd2Neg: 68.9, sd1Neg: 71.4, median: 74.0, sd1Pos: 76.6, sd2Pos: 79.2),
    WhoGrowthDataPoint(month: 18, sd2Neg: 74.9, sd1Neg: 77.8, median: 80.7, sd1Pos: 83.6, sd2Pos: 86.5),
    WhoGrowthDataPoint(month: 24, sd2Neg: 80.0, sd1Neg: 83.2, median: 86.4, sd1Pos: 89.6, sd2Pos: 92.9),
  ];

  /// Đánh giá Z-Score cân nặng cho bé
  static double evaluateWeightZScore({
    required double weightKg,
    required int ageMonths,
    required String gender,
  }) {
    final list = gender.toLowerCase() == 'girl' ? weightGirls : weightBoys;
    final point = _findClosestPoint(list, ageMonths);
    if (weightKg >= point.median) {
      final sd = point.sd1Pos - point.median;
      return sd > 0 ? (weightKg - point.median) / sd : 0.0;
    } else {
      final sd = point.median - point.sd1Neg;
      return sd > 0 ? (weightKg - point.median) / sd : 0.0;
    }
  }

  /// Trả về nhãn đánh giá tăng trưởng theo chuẩn Z-Score WHO
  static String getGrowthStatusLabel(double zScore) {
    if (zScore < -2.0) {
      return 'Dưới chuẩn WHO (< -2SD)';
    } else if (zScore < -1.0) {
      return 'Nguy cơ nhẹ cân (-1SD)';
    } else if (zScore <= 1.0) {
      return 'Chuẩn tăng trưởng WHO (P50)';
    } else if (zScore <= 2.0) {
      return 'Phát triển vượt chuẩn (+1SD)';
    } else {
      return 'Trên chuẩn WHO (> +2SD)';
    }
  }

  static WhoGrowthDataPoint _findClosestPoint(List<WhoGrowthDataPoint> list, int month) {
    if (month <= list.first.month) return list.first;
    if (month >= list.last.month) return list.last;
    WhoGrowthDataPoint closest = list.first;
    int minDiff = 999;
    for (final p in list) {
      final diff = (p.month - month).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = p;
      }
    }
    return closest;
  }
}
