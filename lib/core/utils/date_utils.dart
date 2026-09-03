// lib/core/utils/date_utils.dart
import 'package:intl/intl.dart';

/// Các tiện ích xử lý ngày tháng chuyên dùng cho HerFlow
class AppDateUtils {
  AppDateUtils._();

  static final DateFormat dayMonthFormat = DateFormat('dd/MM', 'vi');
  static final DateFormat fullDateFormat = DateFormat('dd/MM/yyyy', 'vi');
  static final DateFormat monthYearFormat = DateFormat('MMMM yyyy', 'vi');
  static final DateFormat dayOfWeekFormat = DateFormat('EEEE', 'vi');

  /// Chuẩn hóa ngày về 00:00:00 để so sánh không bị ảnh hưởng bởi giờ phút giây
  static DateTime normalize(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Tính số ngày chênh lệch giữa hai thời điểm
  static int daysBetween(DateTime from, DateTime to) {
    final f = normalize(from);
    final t = normalize(to);
    return t.difference(f).inDays;
  }

  /// Kiểm tra 2 ngày có cùng ngày/tháng/năm không
  static bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Format dạng "Hôm nay, 03 tháng 09"
  static String formatHeaderDate(DateTime date) {
    final now = DateTime.now();
    if (isSameDay(date, now)) {
      return 'Hôm nay, ${DateFormat('dd MMMM', 'vi').format(date)}';
    } else if (isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'Hôm qua, ${DateFormat('dd MMMM', 'vi').format(date)}';
    } else if (isSameDay(date, now.add(const Duration(days: 1)))) {
      return 'Ngày mai, ${DateFormat('dd MMMM', 'vi').format(date)}';
    }
    return '${DateFormat('EEEE', 'vi').format(date)}, ${DateFormat('dd MMMM', 'vi').format(date)}';
  }
}
