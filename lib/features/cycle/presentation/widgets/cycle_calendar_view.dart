// lib/features/cycle/presentation/widgets/cycle_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/date_utils.dart';
import '../../domain/entities/cycle_info.dart';

/// Widget Lịch Tương Tác TableCalendar hiển thị màu sắc và ký hiệu 4 pha sinh học
/// Phân biệt trực quan rõ rệt giữa:
///   - Kỳ kinh THỰC TẾ (Actual): Nền hồng đậm, icon giọt nước đặc (solid)
///   - Kỳ kinh DỰ KIẾN (Predicted): Nền hồng pastel bán trong suốt, viền hồng, icon giọt nước nét mảnh (outline)
///   - Ngày Rụng Trứng: Icon ngôi sao vàng/mint
class CycleCalendarView extends StatefulWidget {
  final CycleInfo cycleInfo;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final VoidCallback? onEditCycle;

  const CycleCalendarView({
    super.key,
    required this.cycleInfo,
    required this.selectedDate,
    required this.onDateSelected,
    this.onEditCycle,
  });

  @override
  State<CycleCalendarView> createState() => _CycleCalendarViewState();
}

class _CycleCalendarViewState extends State<CycleCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  PageController? _pageController;
  late DateTime _focusedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.selectedDate;
  }

  @override
  void didUpdateWidget(CycleCalendarView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!AppDateUtils.isSameDay(widget.selectedDate, oldWidget.selectedDate)) {
      _focusedDay = widget.selectedDate;
    }
  }

  @override
  void dispose() {
    // KHÔNG gọi _pageController?.dispose() vì TableCalendar tự giải phóng controller này
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header phụ: Tiêu đề & Nút Chỉnh sửa chu kỳ thanh lịch (Tách riêng khỏi header tháng)
            if (widget.onEditCycle != null)
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Lịch Chu Kỳ Sinh Học',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nút chuyển tháng an toàn qua _pageController
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _pageController?.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _pageController?.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: widget.onEditCycle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(isDark ? 80 : 60),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tune_rounded, size: 12, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text(
                                  'Chỉnh sửa chu kỳ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            // Lịch TableCalendar chính
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              startingDayOfWeek: StartingDayOfWeek.monday,
              currentDay: DateTime.now(),
              selectedDayPredicate: (day) => AppDateUtils.isSameDay(day, widget.selectedDate),
              onDaySelected: (newSelectedDate, newFocusedDay) {
                setState(() {
                  _focusedDay = newFocusedDay;
                });
                widget.onDateSelected(AppDateUtils.normalize(newSelectedDate));
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              onCalendarCreated: (pageController) {
                _pageController = pageController;
              },
              onFormatChanged: (format) {
                setState(() => _calendarFormat = format);
              },
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: AppColors.primaryContainer.withAlpha(isDark ? 60 : 255),
                  borderRadius: BorderRadius.circular(12),
                ),
                formatButtonTextStyle: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                titleTextStyle: theme.textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day, isSelected: false, isDark: isDark);
                },
                selectedBuilder: (context, day, focusedDay) {
                  return _buildDayCell(day, isSelected: true, isDark: isDark);
                },
                todayBuilder: (context, day, focusedDay) {
                  final isSel = AppDateUtils.isSameDay(day, widget.selectedDate);
                  return _buildDayCell(day, isSelected: isSel, isToday: true, isDark: isDark);
                },
              ),
            ),

            const SizedBox(height: 10),

            // Legend nhỏ phân biệt Thực tế vs Dự kiến ngay dưới lịch
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildMiniLegend(
                    icon: Icons.water_drop_rounded,
                    color: AppColors.primary,
                    label: 'Thực tế',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  _buildMiniLegend(
                    icon: Icons.water_drop_outlined,
                    color: AppColors.primary,
                    label: 'Dự kiến',
                    isDark: isDark,
                  ),
                  const SizedBox(width: 14),
                  _buildMiniLegend(
                    icon: Icons.star_rounded,
                    color: AppColors.phaseOvulation,
                    label: 'Rụng trứng',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniLegend({
    required IconData icon,
    required Color color,
    required String label,
    required bool isDark,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    required bool isSelected,
    bool isToday = false,
    required bool isDark,
  }) {
    final phase = widget.cycleInfo.getPhaseForDate(day);
    final isActual = widget.cycleInfo.isActualPeriod(day);
    final isPredicted = widget.cycleInfo.isPredictedPeriod(day);
    final isOvulation = widget.cycleInfo.isOvulationDay(day);

    Color bgColor;
    Border? border;

    if (isSelected) {
      bgColor = phase.color;
      border = Border.all(color: phase.color, width: 2);
    } else if (isActual) {
      // Ngày hành kinh THỰC TẾ: Nền hồng đậm đặc trưng
      bgColor = AppColors.primary.withAlpha(isDark ? 160 : 210);
      border = isToday ? Border.all(color: Colors.white, width: 2) : null;
    } else if (isPredicted) {
      // Ngày hành kinh DỰ KIẾN: Nền hồng pastel nhạt bán trong suốt, viền nét rõ
      bgColor = AppColors.phaseMenstrual.withAlpha(isDark ? 45 : 70);
      border = Border.all(
        color: AppColors.primary.withAlpha(isDark ? 140 : 160),
        width: 1.5,
      );
    } else {
      bgColor = phase.backgroundColor.withAlpha(isDark ? 45 : 150);
      if (isToday) {
        border = Border.all(color: AppColors.primary, width: 2);
      } else if (isOvulation) {
        border = Border.all(color: AppColors.phaseOvulation, width: 1.5);
      }
    }

    // Màu chữ ngày
    Color textColor;
    if (isSelected || isActual) {
      textColor = Colors.white;
    } else if (isPredicted) {
      textColor = isDark ? AppColors.primaryLight : AppColors.primary;
    } else {
      textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    return Container(
      margin: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: textColor,
                fontWeight: isSelected || isToday || isActual || isOvulation
                    ? FontWeight.w800
                    : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),

          // Icon giọt nước đặc cho ngày THỰC TẾ
          if (isActual && !isSelected)
            const Positioned(
              bottom: 2,
              right: 2,
              child: Icon(
                Icons.water_drop_rounded,
                size: 9,
                color: Colors.white,
              ),
            ),

          // Icon giọt nước nét mảnh cho ngày DỰ KIẾN
          if (isPredicted && !isSelected)
            Positioned(
              bottom: 2,
              right: 2,
              child: Icon(
                Icons.water_drop_outlined,
                size: 9,
                color: AppColors.primary.withAlpha(200),
              ),
            ),

          // Icon ngôi sao cho ngày RỤNG TRỨNG
          if (isOvulation && !isSelected)
            const Positioned(
              top: 2,
              right: 2,
              child: Icon(
                Icons.star_rounded,
                size: 9,
                color: AppColors.phaseOvulation,
              ),
            ),
        ],
      ),
    );
  }
}
