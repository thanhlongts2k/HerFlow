// lib/features/mood/presentation/screens/mood_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/mood/presentation/controllers/mood_controller.dart';
import 'package:herflow/features/mood/domain/entities/mood_entry.dart';

/// Màn hình Ghi Nhận Cảm Xúc & Triệu Chứng Thể Trạng (Micro-logging)
class MoodScreen extends ConsumerWidget {
  const MoodScreen({super.key});

  static const List<Map<String, dynamic>> _energyOptions = [
    {'level': 1, 'emoji': '😫', 'label': 'Kiệt sức'},
    {'level': 2, 'emoji': '🥱', 'label': 'Mệt mỏi'},
    {'level': 3, 'emoji': '😐', 'label': 'Bình thường'},
    {'level': 4, 'emoji': '😊', 'label': 'Tích cực'},
    {'level': 5, 'emoji': '⚡', 'label': 'Tràn đầy'},
  ];

  static const List<String> _moodOptions = [
    'Thư thái',
    'Vui vẻ',
    'Hạnh phúc',
    'Nhạy cảm',
    'Cáu gắt',
    'Lo âu',
    'Bình yên',
    'Dễ xúc động',
  ];

  static const List<String> _symptomOptions = [
    'Đau bụng kinh',
    'Đau thắt lưng',
    'Căng tức ngực',
    'Thèm đồ ngọt',
    'Đầy hơi',
    'Nổi mụn',
    'Nhức đầu',
    'Khó ngủ',
    'Chóng mặt',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final moodEntry = ref.watch(selectedDateMoodProvider);
    final recentHistory = ref.watch(recentMoodHistoryProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhật Ký Thể Trạng',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              AppDateUtils.formatHeaderDate(selectedDate),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. CHỌN MỨC NĂNG LƯỢNG (1 - 5)
            _buildSectionCard(
              context,
              title: 'Mức năng lượng hôm nay',
              icon: Icons.battery_charging_full_rounded,
              child: _buildEnergySelector(context, ref, moodEntry.energyLevel),
            ),

            const SizedBox(height: 16),

            // 2. CHỌN TÂM TRẠNG
            _buildSectionCard(
              context,
              title: 'Tâm trạng chủ đạo',
              icon: Icons.mood_rounded,
              child: _buildMoodChips(ref, moodEntry.mood),
            ),

            const SizedBox(height: 16),

            // 3. TRIỆU CHỨNG THỂ CHẤT
            _buildSectionCard(
              context,
              title: 'Triệu chứng cơ thể',
              icon: Icons.health_and_safety_rounded,
              child: _buildSymptomChips(ref, moodEntry.symptoms),
            ),

            const SizedBox(height: 16),

            // 4. BIỂU ĐỒ XU HƯỚNG NĂNG LƯỢNG 7 NGÀY GẦN NHẤT (FL_CHART)
            _buildSectionCard(
              context,
              title: 'Xu hướng năng lượng 7 ngày',
              icon: Icons.show_chart_rounded,
              child: recentHistory.when(
                loading: () => const SizedBox(
                  height: 160,
                  child: Center(child: CircularProgressIndicator(color: AppColors.secondary)),
                ),
                error: (e, _) => Text('Lỗi tải biểu đồ: $e'),
                data: (history) => _buildEnergyTrendChart(context, history, isDark),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.secondary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  /// Bảng chọn 1-chạm mức năng lượng
  Widget _buildEnergySelector(BuildContext context, WidgetRef ref, int currentLevel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _energyOptions.map((opt) {
        final level = opt['level'] as int;
        final emoji = opt['emoji'] as String;
        final label = opt['label'] as String;
        final isSelected = currentLevel == level;

        return Expanded(
          child: GestureDetector(
            onTap: () {
              ref.read(selectedDateMoodProvider.notifier).setEnergy(level);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.secondaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.secondary : Colors.grey.withAlpha(50),
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(emoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.secondaryDark : Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Chips chọn tâm trạng
  Widget _buildMoodChips(WidgetRef ref, String currentMood) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _moodOptions.map((m) {
        final isSelected = currentMood == m;
        return FilterChip(
          selected: isSelected,
          label: Text(m),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.secondaryDark : null,
          ),
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.secondaryContainer,
          checkmarkColor: AppColors.secondaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.secondary : Colors.grey.withAlpha(60),
            ),
          ),
          onSelected: (_) {
            ref.read(selectedDateMoodProvider.notifier).setMood(m);
          },
        );
      }).toList(),
    );
  }

  /// Chips chọn triệu chứng cơ thể
  Widget _buildSymptomChips(WidgetRef ref, List<String> activeSymptoms) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _symptomOptions.map((s) {
        final isSelected = activeSymptoms.contains(s);
        return FilterChip(
          selected: isSelected,
          label: Text(s),
          labelStyle: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primaryDark : null,
          ),
          backgroundColor: Colors.transparent,
          selectedColor: AppColors.primaryContainer,
          checkmarkColor: AppColors.primaryDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? AppColors.primary : Colors.grey.withAlpha(60),
            ),
          ),
          onSelected: (_) {
            ref.read(selectedDateMoodProvider.notifier).toggleSymptom(s);
          },
        );
      }).toList(),
    );
  }

  /// Biểu đồ xu hướng năng lượng bằng fl_chart
  Widget _buildEnergyTrendChart(
    BuildContext context,
    List<MoodEntry> entries,
    bool isDark,
  ) {
    if (entries.isEmpty) {
      return const Center(child: Text('Chưa có đủ dữ liệu để vẽ biểu đồ'));
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < entries.length; i++) {
      spots.add(FlSpot(i.toDouble(), entries[i].energyLevel.toDouble()));
    }

    return SizedBox(
      height: 160,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, right: 14, bottom: 6),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (entries.length - 1).toDouble(),
            minY: 1,
            maxY: 5,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 1,
              getDrawingHorizontalLine: (val) => FlLine(
                color: isDark ? Colors.white10 : Colors.black12,
                strokeWidth: 0.8,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 24,
                  getTitlesWidget: (val, meta) {
                    final emojis = {1: '😫', 3: '😐', 5: '⚡'};
                    if (emojis.containsKey(val.toInt())) {
                      return Text(emojis[val.toInt()]!, style: const TextStyle(fontSize: 10));
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 22,
                  getTitlesWidget: (val, meta) {
                    final idx = val.toInt();
                    if (idx >= 0 && idx < entries.length) {
                      final d = entries[idx].date;
                      return Text(
                        DateFormat('dd/MM').format(d),
                        style: const TextStyle(fontSize: 9.5, color: Colors.grey),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.35,
                color: AppColors.secondary,
                barWidth: 3.5,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppColors.secondary.withAlpha(isDark ? 40 : 35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
