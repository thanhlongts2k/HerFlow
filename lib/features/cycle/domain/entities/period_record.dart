// lib/features/cycle/domain/entities/period_record.dart

/// Mức độ lượng kinh nguyệt trong ngày hành kinh
enum FlowIntensity {
  light,
  medium,
  heavy;

  String get vietnameseName {
    switch (this) {
      case FlowIntensity.light:
        return 'Ít';
      case FlowIntensity.medium:
        return 'Vừa';
      case FlowIntensity.heavy:
        return 'Nhiều';
    }
  }
}

/// Bản ghi của một kỳ kinh nguyệt trong lịch sử chu kỳ
class PeriodRecord {
  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final FlowIntensity flowIntensity;
  final bool isOngoing;

  const PeriodRecord({
    required this.id,
    required this.startDate,
    this.endDate,
    this.flowIntensity = FlowIntensity.medium,
    this.isOngoing = false,
  });

  /// Thời lượng hành kinh (ngày). Nếu chưa kết thúc, tạm tính đến ngày hiện tại
  int get durationInDays {
    if (endDate != null) {
      return endDate!.difference(startDate).inDays + 1;
    }
    final now = DateTime.now();
    if (now.isAfter(startDate)) {
      return now.difference(startDate).inDays + 1;
    }
    return 1;
  }

  /// Kiểm tra xem một ngày cụ thể có rơi vào kỳ kinh nguyệt này không
  bool containsDate(DateTime date) {
    final checkDate = DateTime(date.year, date.month, date.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);

    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      return (checkDate.isAtSameMomentAs(start) || checkDate.isAfter(start)) &&
          (checkDate.isAtSameMomentAs(end) || checkDate.isBefore(end));
    } else {
      // Nếu đang diễn ra, tạm tính trong vòng 7 ngày
      final maxEnd = start.add(const Duration(days: 6));
      return (checkDate.isAtSameMomentAs(start) || checkDate.isAfter(start)) &&
          (checkDate.isAtSameMomentAs(maxEnd) || checkDate.isBefore(maxEnd));
    }
  }

  PeriodRecord copyWith({
    String? id,
    DateTime? startDate,
    DateTime? endDate,
    FlowIntensity? flowIntensity,
    bool? isOngoing,
  }) {
    return PeriodRecord(
      id: id ?? this.id,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      flowIntensity: flowIntensity ?? this.flowIntensity,
      isOngoing: isOngoing ?? this.isOngoing,
    );
  }
}
