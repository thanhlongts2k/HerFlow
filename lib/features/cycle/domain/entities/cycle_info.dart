// lib/features/cycle/domain/entities/cycle_info.dart
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'cycle_day_info.dart';
import 'period_record.dart';

/// Thực thể cấu hình chu kỳ sinh học 4 pha
/// Phân biệt rạch ròi giữa kỳ kinh THỰC TẾ (Actual) và DỰ BÁO (Predicted)
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

  /// Mốc chuẩn kỳ kinh thực tế gần nhất (Anchor Period Start)
  DateTime get anchorStart {
    if (records.isNotEmpty) {
      // Sắp xếp giảm dần theo ngày bắt đầu để lấy kỳ mới nhất
      final sorted = List<PeriodRecord>.from(records)
        ..sort((a, b) => b.startDate.compareTo(a.startDate));
      return AppDateUtils.normalize(sorted.first.startDate);
    }
    return AppDateUtils.normalize(lastPeriodStart);
  }

  /// Tính ngày của chu kỳ cho một thời điểm bất kỳ (Bắt đầu từ ngày 1)
  int getCycleDay(DateTime date) {
    final normDate = AppDateUtils.normalize(date);
    final diff = AppDateUtils.daysBetween(anchorStart, normDate);
    if (diff < 0) {
      final mod = (diff % cycleLength) + cycleLength;
      return (mod % cycleLength) + 1;
    }
    return (diff % cycleLength) + 1;
  }

  /// Ngày dự kiến kỳ kinh tiếp theo bắt đầu (sau anchorStart)
  DateTime get nextPeriodDate {
    return anchorStart.add(Duration(days: cycleLength));
  }

  /// Kiểm tra xem hiện tại có đang bị trễ kinh so với dự kiến không (khi chưa có kỳ kinh mới)
  bool isLate(DateTime date) {
    final normDate = AppDateUtils.normalize(date);
    final diff = AppDateUtils.daysBetween(anchorStart, normDate);
    return diff > cycleLength;
  }

  /// Số ngày trễ kinh (>= 1 nếu trễ, = 0 nếu đúng hạn hoặc chưa tới)
  int getDaysLate(DateTime date) {
    final normDate = AppDateUtils.normalize(date);
    final diff = AppDateUtils.daysBetween(anchorStart, normDate);
    if (diff > cycleLength) {
      return diff - cycleLength;
    }
    return 0;
  }

  /// Số ngày còn lại đến kỳ kinh tiếp theo (không trả về số âm)
  int daysUntilNextPeriod(DateTime fromDate) {
    final normFrom = AppDateUtils.normalize(fromDate);
    final diff = AppDateUtils.daysBetween(anchorStart, normFrom);
    if (diff < 0) {
      // Nếu từ ngày trong quá khứ trước anchorStart
      return AppDateUtils.daysBetween(normFrom, anchorStart);
    }
    if (diff > cycleLength) {
      // Đã quá hạn (trễ kinh) -> 0 ngày còn lại
      return 0;
    }
    final currentCycleDay = diff % cycleLength;
    if (currentCycleDay == 0 && diff > 0) {
      return 0;
    }
    return cycleLength - currentCycleDay;
  }

  /// Ngày rụng trứng lý thuyết trong chu kỳ: Ngày thứ (cycleLength - 14)
  int get ovulationDayNumber => cycleLength - 14;

  /// Ngày rụng trứng lý thuyết
  DateTime get ovulationDate => anchorStart.add(Duration(days: ovulationDayNumber - 1));

  /// Cửa sổ rụng trứng bắt đầu (5 ngày trước ngày rụng trứng)
  DateTime get fertileWindowStart => anchorStart.add(Duration(days: (ovulationDayNumber - 5).clamp(1, cycleLength) - 1));

  /// Cửa sổ rụng trứng kết thúc (1 ngày sau ngày rụng trứng)
  DateTime get fertileWindowEnd => anchorStart.add(Duration(days: (ovulationDayNumber + 1).clamp(1, cycleLength) - 1));

  /// Kiểm tra xem một ngày có phải là kỳ kinh THỰC TẾ (Đã ghi nhận nhật ký hoặc nằm trong anchor period)
  bool isActualPeriod(DateTime date) {
    final normDate = AppDateUtils.normalize(date);

    // 1. Kiểm tra trong danh sách nhật ký thực tế đã lưu
    for (final r in records) {
      if (r.containsDate(normDate)) return true;
    }

    // 2. Nếu ngày nằm trong chu kỳ mốc anchorStart (anchorStart -> anchorStart + periodDuration - 1)
    final anchorEnd = anchorStart.add(Duration(days: periodDuration - 1));
    if ((normDate.isAtSameMomentAs(anchorStart) || normDate.isAfter(anchorStart)) &&
        (normDate.isAtSameMomentAs(anchorEnd) || normDate.isBefore(anchorEnd))) {
      return true;
    }

    return false;
  }

  /// Kiểm tra xem một ngày có phải là kỳ kinh DỰ BÁO TƯƠNG LAI (Không áp dụng cho quá khứ)
  bool isPredictedPeriod(DateTime date) {
    final normDate = AppDateUtils.normalize(date);

    // Tuyệt đối không dự báo cho ngày trước hoặc trong chu kỳ mốc hiện tại
    final currentCycleEnd = anchorStart.add(Duration(days: cycleLength - 1));
    if (normDate.isBefore(currentCycleEnd) || normDate.isAtSameMomentAs(currentCycleEnd)) {
      return false;
    }

    // Nếu ngày này đã được người dùng ghi nhận thực tế thì không phải là dự báo
    for (final r in records) {
      if (r.containsDate(normDate)) return false;
    }

    // Tính toán dự phóng cho các chu kỳ tương lai (3 - 12 tháng)
    final diff = AppDateUtils.daysBetween(anchorStart, normDate);
    final dayInCycle = (diff % cycleLength) + 1;

    return dayInCycle <= periodDuration;
  }

  /// Kiểm tra xem một ngày có phải ngày hành kinh (Thực tế HOẶC Dự kiến)
  bool isPeriodDay(DateTime date) {
    return isActualPeriod(date) || isPredictedPeriod(date);
  }

  /// Kiểm tra xem ngày này có thuộc về các chu kỳ dự báo tương lai hay không
  bool isPredicted(DateTime date) {
    final normDate = AppDateUtils.normalize(date);
    final currentCycleEnd = anchorStart.add(Duration(days: cycleLength - 1));
    return normDate.isAfter(currentCycleEnd);
  }

  /// Kiểm tra xem một ngày có phải là ngày rụng trứng đỉnh điểm
  bool isOvulationDay(DateTime date) {
    final normDate = AppDateUtils.normalize(date);

    // Không dự báo ngày rụng trứng ảo trong quá khứ trước anchorStart nếu không có log
    if (normDate.isBefore(anchorStart)) {
      return false;
    }

    final day = getCycleDay(normDate);
    return day == ovulationDayNumber;
  }

  /// Kiểm tra xem một ngày có nằm trong Cửa sổ thụ thai (Fertile Window: 5 ngày trước đến ngày rụng trứng)
  bool isFertileWindow(DateTime date) {
    final normDate = AppDateUtils.normalize(date);

    if (normDate.isBefore(anchorStart)) {
      return false;
    }

    final day = getCycleDay(normDate);
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
    final normDate = AppDateUtils.normalize(date);

    // Nếu là ngày có kinh thực tế
    if (isActualPeriod(normDate)) {
      return CyclePhase.menstrual;
    }

    // Nếu là ngày kinh dự báo
    if (isPredictedPeriod(normDate)) {
      return CyclePhase.menstrual;
    }

    // Đối với ngày trong quá khứ trước anchorStart mà không có kỳ kinh
    if (normDate.isBefore(anchorStart)) {
      return CyclePhase.follicular;
    }

    final day = getCycleDay(normDate);

    // 1. Pha hành kinh
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
    final normDate = AppDateUtils.normalize(date);
    final actual = isActualPeriod(normDate);
    final predicted = isPredictedPeriod(normDate);

    return CycleDayInfo.calculate(
      date: normDate,
      cycleDay: getCycleDay(normDate),
      phase: getPhaseForDate(normDate),
      isPeriodDay: actual || predicted,
      isActualPeriod: actual,
      isPredictedPeriod: predicted,
      isPredicted: isPredicted(normDate),
      isFertileWindow: isFertileWindow(normDate),
      isOvulationDay: isOvulationDay(normDate),
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
