// lib/features/mood/presentation/screens/mood_screen.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/husband_view/presentation/widgets/husband_quick_chat_sheet.dart';
import 'package:herflow/features/mood/presentation/controllers/mood_controller.dart';
import 'package:herflow/features/mood/domain/entities/mood_entry.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

/// Màn hình Ghi Nhận Cảm Xúc (Vợ: RW) & Theo Dõi Thể Trạng Nàng (Chồng: RO + Care Action)
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
    final userRole = ref.watch(userRoleProvider);
    final isHusband = userRole == UserRole.husband;
    final nicknameConfig = ref.watch(nicknameConfigProvider);
    final partnerName = nicknameConfig.callPartnerAs.isNotEmpty
        ? nicknameConfig.callPartnerAs
        : (isHusband ? 'Bé iu' : 'Anh');

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isHusband ? 'Thể Trạng Của $partnerName' : 'Nhật Ký Thể Trạng',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              isHusband
                  ? 'Theo dõi thể trạng & tín hiệu của $partnerName (${AppDateUtils.formatHeaderDate(selectedDate)})'
                  : AppDateUtils.formatHeaderDate(selectedDate),
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
            // DÀNH CHO CHỒNG: BẢNG HÀNH ĐỘNG CHĂM SÓC & TÍN HIỆU YÊU THƯƠNG
            if (isHusband) ...[
              _buildHusbandCareActionCard(context, ref, partnerName),
              const SizedBox(height: 16),
            ],

            // 1. MỨC NĂNG LƯỢNG (1 - 5)
            _buildSectionCard(
              context,
              title: isHusband ? 'Mức năng lượng của $partnerName' : 'Mức năng lượng hôm nay',
              icon: Icons.battery_charging_full_rounded,
              isReadOnly: isHusband,
              child: _buildEnergySelector(context, ref, moodEntry.energyLevel, isReadOnly: isHusband),
            ),

            const SizedBox(height: 16),

            // 2. TÂM TRẠNG
            _buildSectionCard(
              context,
              title: isHusband ? 'Tâm trạng của $partnerName' : 'Tâm trạng chủ đạo',
              icon: Icons.mood_rounded,
              isReadOnly: isHusband,
              child: _buildMoodChips(ref, moodEntry.mood, isReadOnly: isHusband),
            ),

            const SizedBox(height: 16),

            // 3. TRIỆU CHỨNG THỂ CHẤT
            _buildSectionCard(
              context,
              title: isHusband ? 'Triệu chứng cơ thể nàng đang có' : 'Triệu chứng cơ thể',
              icon: Icons.health_and_safety_rounded,
              isReadOnly: isHusband,
              child: _buildSymptomChips(ref, moodEntry.symptoms, isReadOnly: isHusband),
            ),

            const SizedBox(height: 16),

            // 4. BIỂU ĐỒ XU HƯỚNG NĂNG LƯỢNG 7 NGÀY GẦN NHẤT
            _buildSectionCard(
              context,
              title: isHusband ? 'Xu hướng năng lượng 7 ngày của nàng' : 'Xu hướng năng lượng 7 ngày',
              icon: Icons.show_chart_rounded,
              isReadOnly: false,
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

  /// Card Hành động Chăm sóc 1-chạm dành riêng cho Chồng
  Widget _buildHusbandCareActionCard(BuildContext context, WidgetRef ref, String partnerName) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C1E3A), const Color(0xFF1E2038)]
              : [const Color(0xFFF3E8FF), const Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.secondary.withAlpha(80)),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondary.withAlpha(25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.secondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tín Hiệu Yêu Thương Cho $partnerName',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.secondaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Chạm để gửi tín hiệu chăm sóc tức thì đến điện thoại của nàng:',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCareActionButton(
                context: context,
                ref: ref,
                emoji: '🤗',
                label: 'Gửi cái ôm',
                message: 'Anh gửi một cái ôm thật ấm áp cho $partnerName nè 🤗',
                partnerName: partnerName,
              ),
              _buildCareActionButton(
                context: context,
                ref: ref,
                emoji: '🍵',
                label: 'Mang nước ấm',
                message: 'Anh mang nước ấm qua cho $partnerName nhé 🍵',
                partnerName: partnerName,
              ),
              _buildCareActionButton(
                context: context,
                ref: ref,
                emoji: '🛋️',
                label: 'Nghỉ ngơi nhé',
                message: '$partnerName ơi, làm mệt rồi thì nghỉ ngơi một chút nhé 🛋️',
                partnerName: partnerName,
              ),
              ElevatedButton.icon(
                onPressed: () {
                  AppHaptics.light();
                  final currentPhase = ref.read(selectedCycleDayInfoProvider)?.phase ?? CyclePhase.follicular;
                  HusbandQuickChatSheet.show(context, phase: currentPhase);
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Nhắn nhủ riêng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCareActionButton({
    required BuildContext context,
    required WidgetRef ref,
    required String emoji,
    required String label,
    required String message,
    required String partnerName,
  }) {
    return OutlinedButton.icon(
      onPressed: () async {
        AppHaptics.selection();
        final coupleId = ref.read(savedCoupleIdProvider) ?? '';
        final nicknameConfig = ref.read(nicknameConfigProvider);

        final signal = CareSignalModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          coupleId: coupleId,
          type: CareSignalType.husbandMessage,
          customNote: message,
          sentAt: DateTime.now(),
          senderRole: 'husband',
          senderNickname: nicknameConfig.selfCallAs,
          targetNickname: partnerName,
        );

        try {
          await ref.read(partnerSyncRepositoryProvider).sendCareSignal(signal);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã gửi "$label" đến $partnerName 💕'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.secondary,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            );
          }
        } catch (_) {}
      },
      icon: Text(emoji, style: const TextStyle(fontSize: 16)),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.secondaryDark,
        backgroundColor: Colors.white.withAlpha(200),
        side: BorderSide(color: AppColors.secondary.withAlpha(100)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    bool isReadOnly = false,
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
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isReadOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer.withAlpha(isDark ? 80 : 180),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded, size: 12, color: AppColors.secondaryDark),
                        SizedBox(width: 4),
                        Text(
                          'Chỉ xem',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.secondaryDark),
                        ),
                      ],
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

  /// Bảng chọn 1-chạm mức năng lượng (Vợ: RW, Chồng: RO)
  Widget _buildEnergySelector(BuildContext context, WidgetRef ref, int currentLevel, {bool isReadOnly = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _energyOptions.map((opt) {
        final level = opt['level'] as int;
        final emoji = opt['emoji'] as String;
        final label = opt['label'] as String;
        final isSelected = currentLevel == level;

        return Expanded(
          child: GestureDetector(
            onTap: isReadOnly
                ? null
                : () {
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

  /// Chips chọn tâm trạng (Vợ: RW, Chồng: RO)
  Widget _buildMoodChips(WidgetRef ref, String currentMood, {bool isReadOnly = false}) {
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
          onSelected: isReadOnly
              ? null
              : (_) {
                  ref.read(selectedDateMoodProvider.notifier).setMood(m);
                },
        );
      }).toList(),
    );
  }

  /// Chips chọn triệu chứng cơ thể (Vợ: RW, Chồng: RO)
  Widget _buildSymptomChips(WidgetRef ref, List<String> activeSymptoms, {bool isReadOnly = false}) {
    if (isReadOnly && activeSymptoms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 16, color: Colors.grey),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Hôm nay nàng chưa ghi nhận triệu chứng mệt mỏi hay đau nhức nào.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _symptomOptions.map((s) {
        final isSelected = activeSymptoms.contains(s);
        // Nếu Chồng xem mà nàng không chọn triệu chứng này, làm mờ đi
        if (isReadOnly && !isSelected) {
          return const SizedBox.shrink();
        }

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
          onSelected: isReadOnly
              ? null
              : (_) {
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
