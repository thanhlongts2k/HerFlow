// lib/features/cycle/domain/entities/cycle_info.dart
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'cycle_day_info.dart';
import 'period_record.dart';

/// Thực thể lưu trữ cấu hình chu kỳ và tính toán pha sinh học chuyên sâu
class CycleInfo {
  final DateTime lastPeriodStart;
  final int cycleLength;
  final int periodDuration;
  final List<PeriodRecord> records;

  const CycleInfo({
    required this.lastPeriodStart,
    this.cycleLength = AppConstants.defaultCycleLength,
    this.periodDuration = AppConstants.defaultPeriodDuration,
    this.records = const [],
  });

  /// Tính ngày của chu kỳ cho một thời điểm bất kỳ (Bắt đầu từ ngày 1)
  int getCycleDay(DateTime date) {
    final diff = AppDateUtils.daysBetween(lastPeriodStart, date);
    if (diff < 0) {
      final mod = (diff % cycleLength) + cycleLength;
      return (mod % cycleLength) + 1;
    }
    return (diff % cycleLength) + 1;
  }

  /// Ngày dự kiến kỳ kinh tiếp theo bắt đầu
  DateTime get nextPeriodDate {
    return lastPeriodStart.add(Duration(days: cycleLength));
  }

  /// Số ngày còn lại đến kỳ kinh tiếp theo
  int daysUntilNextPeriod(DateTime fromDate) {
    final diff = AppDateUtils.daysBetween(lastPeriodStart, fromDate);
    final currentCycleDay = diff >= 0 ? (diff % cycleLength) : ((diff % cycleLength) + cycleLength);
    return cycleLength - currentCycleDay;
  }

  /// Ngày rụng trứng lý thuyết trong chu kỳ: Ngày thứ (cycleLength - 14)
  int get ovulationDayNumber => cycleLength - 14;

  /// Kiểm tra xem một ngày có phải là ngày hành kinh (Thực tế từ bản ghi hoặc Dự kiến)
  bool isPeriodDay(DateTime date) {
    // 1. Kiểm tra bản ghi thực tế
    for (final r in records) {
      if (r.containsDate(date)) return true;
    }
    // 2. Kiểm tra theo thuật toán chu kỳ (nếu không có bản ghi phủ)
    final day = getCycleDay(date);
    return day <= periodDuration;
  }

  /// Kiểm tra xem một ngày có phải là ngày rụng trứng đỉnh điểm không
  bool isOvulationDay(DateTime date) {
    final day = getCycleDay(date);
    return day == ovulationDayNumber;
  }

  /// Kiểm tra xem một ngày có nằm trong Cửa sổ thụ thai (Fertile Window: 5 ngày trước đến ngày rụng trứng)
  bool isFertileWindow(DateTime date) {
    final day = getCycleDay(date);
    return day >= (ovulationDayNumber - 5) && day <= (ovulationDayNumber + 1);
  }

  /// Ngày bắt đầu dự kiến của giai đoạn Tiền kinh nguyệt (PMS - 7 ngày trước kỳ kinh mới)
  DateTime get nextPmsStartDate => nextPeriodDate.subtract(const Duration(days: 7));

  /// Kiểm tra xem một ngày có nằm trong Cửa sổ Tiền kinh nguyệt (PMS Window - 1 đến 7 ngày trước kỳ kinh tiếp theo)
  bool isPmsWindow(DateTime date) {
    final daysLeft = daysUntilNextPeriod(date);
    return daysLeft >= 1 && daysLeft <= 7;
  }

  /// Thuật toán phân loại 4 pha sinh học chính xác theo từng ngày trong chu kỳ
  CyclePhase getPhaseForDate(DateTime date) {
    final day = getCycleDay(date);

    // 1. Pha hành kinh: Ngày 1 -> periodDuration
    if (day <= periodDuration) {
      return CyclePhase.menstrual;
    }

    // 2. Pha nang trứng: Sau hành kinh đến trước cửa sổ rụng trứng (ovulationDay - 2)
    if (day < (ovulationDayNumber - 1)) {
      return CyclePhase.follicular;
    }

    // 3. Pha rụng trứng: Cửa sổ rụng trứng (ovulationDay - 1 đến ovulationDay + 1)
    if (day <= (ovulationDayNumber + 1)) {
      return CyclePhase.ovulation;
    }

    // 4. Pha hoàng thể: Sau rụng trứng đến hết chu kỳ
    return CyclePhase.luteal;
  }

  /// Đánh giá khả năng thụ thai cho một ngày cụ thể
  String getConceptionChance(DateTime date) {
    if (isOvulationDay(date)) return 'Rất cao (Đỉnh điểm)';
    if (isFertileWindow(date)) return 'Cao (Cửa sổ thụ thai)';
    final phase = getPhaseForDate(date);
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Rất thấp';
      case CyclePhase.follicular:
        return 'Trung bình';
      case CyclePhase.ovulation:
        return 'Rất cao';
      case CyclePhase.luteal:
        return 'Thấp';
    }
  }

  /// Lấy toàn bộ thông tin sinh học chi tiết đóng gói trong CycleDayInfo
  CycleDayInfo getDayInfo(DateTime date) {
    return CycleDayInfo.calculate(
      date: date,
      cycleDay: getCycleDay(date),
      phase: getPhaseForDate(date),
      isPeriodDay: isPeriodDay(date),
      isFertileWindow: isFertileWindow(date),
      isOvulationDay: isOvulationDay(date),
    );
  }

  CycleInfo copyWith({
    DateTime? lastPeriodStart,
    int? cycleLength,
    int? periodDuration,
    List<PeriodRecord>? records,
  }) {
    return CycleInfo(
      lastPeriodStart: lastPeriodStart ?? this.lastPeriodStart,
      cycleLength: cycleLength ?? this.cycleLength,
      periodDuration: periodDuration ?? this.periodDuration,
      records: records ?? this.records,
    );
  }
}
