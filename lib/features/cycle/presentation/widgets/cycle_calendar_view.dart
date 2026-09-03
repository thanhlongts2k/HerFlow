// lib/features/cycle/presentation/widgets/cycle_calendar_view.dart
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/date_utils.dart';
import '../../domain/entities/cycle_info.dart';

/// Widget Lịch Tương Tác TableCalendar hiển thị màu sắc và ký hiệu 4 pha sinh học
class CycleCalendarView extends StatefulWidget {
  final CycleInfo cycleInfo;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const CycleCalendarView({
    super.key,
    required this.cycleInfo,
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<CycleCalendarView> createState() => _CycleCalendarViewState();
}

class _CycleCalendarViewState extends State<CycleCalendarView> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: widget.selectedDate,
          calendarFormat: _calendarFormat,
          startingDayOfWeek: StartingDayOfWeek.monday,
          currentDay: DateTime.now(),
          selectedDayPredicate: (day) => AppDateUtils.isSameDay(day, widget.selectedDate),
          onDaySelected: (newSelectedDate, _) {
            widget.onDateSelected(AppDateUtils.normalize(newSelectedDate));
          },
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: AppColors.primaryContainer,
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
      ),
    );
  }

  Widget _buildDayCell(
    DateTime day, {
    required bool isSelected,
    bool isToday = false,
    required bool isDark,
  }) {
    final phase = widget.cycleInfo.getPhaseForDate(day);
    final isPeriod = widget.cycleInfo.isPeriodDay(day);
    final isOvulation = widget.cycleInfo.isOvulationDay(day);

    Color bgColor;
    if (isSelected) {
      bgColor = phase.color;
    } else if (isPeriod) {
      bgColor = AppColors.phaseMenstrual.withAlpha(isDark ? 80 : 180);
    } else {
      bgColor = phase.backgroundColor.withAlpha(isDark ? 45 : 150);
    }

    return Container(
      margin: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.primary
              : (isSelected ? phase.color : (isOvulation ? AppColors.phaseOvulation : Colors.transparent)),
          width: isToday || isOvulation ? 2 : 1,
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                fontWeight: isSelected || isToday || isOvulation ? FontWeight.w800 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          if (isPeriod && !isSelected)
            const Positioned(
              bottom: 2,
              right: 2,
              child: Icon(
                Icons.water_drop_rounded,
                size: 9,
                color: AppColors.primary,
              ),
            ),
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
