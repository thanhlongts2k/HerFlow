// lib/features/cycle/presentation/screens/cycle_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/care_signals/presentation/controllers/care_signal_controller.dart';
import 'package:herflow/features/care_signals/presentation/widgets/care_signal_sheet.dart';
import 'package:herflow/features/husband_view/presentation/screens/husband_view_screen.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';
import 'package:herflow/features/settings/presentation/screens/settings_screen.dart';
import '../controllers/cycle_controller.dart';
import '../widgets/cycle_calendar_view.dart';
import '../widgets/cycle_day_detail_card.dart';
import '../widgets/cycle_hero_indicator.dart';
import '../widgets/cycle_phase_legend.dart';
import '../widgets/cycle_settings_sheet.dart';
import '../widgets/log_period_modal.dart';

/// Provider lưu ID tín hiệu phản hồi đã được người dùng đóng (để không hiện lại)
final dismissedHusbandResponseIdProvider = StateProvider<String?>((ref) => null);

/// Màn hình chính Theo Dõi Chu Kỳ Sinh Học 4 Pha (Cycle Screen)
class CycleScreen extends ConsumerStatefulWidget {
  const CycleScreen({super.key});

  @override
  ConsumerState<CycleScreen> createState() => _CycleScreenState();
}

class _CycleScreenState extends ConsumerState<CycleScreen> {
  @override
  void initState() {
    super.initState();
    // Tự động đẩy trạng thái hôm nay của Vợ lên Cloud khi mở màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(partnerSyncControllerProvider.notifier).syncCurrentWifeStatusToCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cycleAsync = ref.watch(cycleControllerProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final dayInfo = ref.watch(selectedCycleDayInfoProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Lắng nghe tín hiệu yêu thương mới nhất để phát hiện phản hồi từ Chồng
    final latestSignal = ref.watch(latestCareSignalStreamProvider).valueOrNull;
    final dismissedId = ref.watch(dismissedHusbandResponseIdProvider);
    final nicknameConfig = ref.watch(nicknameConfigProvider);
    final savedCoupleId = ref.watch(savedCoupleIdProvider);

    // Kích hoạt rung haptic nhẹ khi Chồng vừa gửi tin nhắn HOẶC vừa bấm phản hồi
    ref.listen(latestCareSignalStreamProvider, (prev, next) {
      final prevSignal = prev?.valueOrNull;
      final nextSignal = next.valueOrNull;
      if (nextSignal != null) {
        if (nextSignal.isFromHusband && (prevSignal == null || prevSignal.id != nextSignal.id)) {
          AppHaptics.medium();
        } else if (nextSignal.isResponded &&
            (prevSignal == null || !prevSignal.isResponded || prevSignal.id != nextSignal.id)) {
          AppHaptics.light();
        }
      }
    });

    final bool showHusbandBanner = latestSignal != null &&
        dismissedId != latestSignal.id &&
        (latestSignal.isFromHusband ||
            (latestSignal.isResponded &&
                latestSignal.responseMessage != null &&
                latestSignal.responseMessage!.isNotEmpty));

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Moona',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              AppDateUtils.formatHeaderDate(DateTime.now()),
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          // Nút Care Signal (tín hiệu yêu thương)
          IconButton(
            icon: const Icon(Icons.favorite_rounded, color: AppColors.primary),
            tooltip: 'Gửi tín hiệu yêu thương đến chồng',
            onPressed: () => CareSignalSheet.show(context),
          ),
          // Badge Người thương kết nối
          if (savedCoupleId != null && savedCoupleId.isNotEmpty)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(isDark ? 45 : 25),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.secondary.withAlpha(90)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 9,
                      backgroundColor: AppColors.secondary,
                      child: Text('🛡️', style: TextStyle(fontSize: 8)),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      nicknameConfig.callPartnerAs,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Nút xem trước Góc nhìn của Chồng
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppColors.secondary),
            tooltip: 'Xem trước Góc nhìn của Chồng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HusbandViewScreen(isWifePreview: true),
                ),
              );
            },
          ),
          // Nút Settings — điều hướng sang SettingsScreen riêng
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt ứng dụng',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: cycleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (err, _) => Center(
          child: Text('Lỗi tải dữ liệu: $err'),
        ),
        data: (cycleInfo) {
          final daysLeft = cycleInfo.daysUntilNextPeriod(selectedDate);
          final currentDayInfo = dayInfo ?? cycleInfo.getDayInfo(selectedDate);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0. IN-APP BANNER PHẢN HỒI NGỌT NGÀO TỪ CHỒNG (TỰ ẨN SAU 10S)
                if (showHusbandBanner)
                  _HusbandResponseBanner(
                    signal: latestSignal,
                    partnerNickname: nicknameConfig.callPartnerAs,
                    onDismiss: () {
                      ref.read(dismissedHusbandResponseIdProvider.notifier).state =
                          latestSignal.id;
                    },
                  ),

                // 1. HERO INDICATOR: VÒNG TRÒN TIẾN TRÌNH SINH HỌC
                CycleHeroIndicator(
                  dayInfo: currentDayInfo,
                  daysLeft: daysLeft,
                ),

                const SizedBox(height: 20),

                // 2. LỊCH TƯƠNG TÁC TABLE_CALENDAR 4 PHA (Kèm nút chỉnh sửa chu kỳ tích hợp)
                CycleCalendarView(
                  cycleInfo: cycleInfo,
                  selectedDate: selectedDate,
                  onDateSelected: (newDate) {
                    ref.read(selectedCalendarDateProvider.notifier).state = newDate;
                  },
                  onEditCycle: () {
                    CycleSettingsSheet.show(
                      context,
                      cycleInfo.cycleLength,
                      cycleInfo.periodDuration,
                    );
                  },
                ),

                const SizedBox(height: 8),

                // 3. CHÚ THÍCH MÀU SẮC 4 PHA SINH HỌC
                const CyclePhaseLegend(),

                const SizedBox(height: 20),

                // 4. THẺ CHI TIẾT NGÀY ĐƯỢC CHỌN (GỢI Ý DINH DƯỠNG, TẬP LUYỆN & NỘI TIẾT TỐ)
                CycleDayDetailCard(
                  dayInfo: currentDayInfo,
                  onTogglePeriod: () {
                    ref.read(cycleControllerProvider.notifier).togglePeriodDay(selectedDate);
                  },
                ),

                const SizedBox(height: 24),

                // 5. NÚT GHI NHẬN KỲ KINH MỚI CHI TIẾT
                OutlinedButton.icon(
                  onPressed: () => LogPeriodModal.show(context, selectedDate),
                  icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                  label: const Text('Ghi nhận kỳ kinh chi tiết cho ngày này'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Banner thông báo phản hồi / hỏi thăm từ Chồng kèm 4 nút phản hồi nhanh 1 chạm
class _HusbandResponseBanner extends ConsumerStatefulWidget {
  final CareSignalModel signal;
  final VoidCallback onDismiss;
  final String partnerNickname;

  const _HusbandResponseBanner({
    required this.signal,
    required this.onDismiss,
    this.partnerNickname = 'Người thương',
  });

  @override
  ConsumerState<_HusbandResponseBanner> createState() => _HusbandResponseBannerState();
}

class _HusbandResponseBannerState extends ConsumerState<_HusbandResponseBanner> {
  Timer? _dismissTimer;
  bool _isResponding = false;

  static const List<String> _quickWifeReplies = [
    '🥺 Hơi mệt và mỏi lưng anh ơi',
    '🧋 Em thèm trà sữa / đồ ngọt',
    '🥰 Em khỏe re, nhớ anh nè',
    '🛌 Em đang nằm nghỉ chút',
  ];

  @override
  void initState() {
    super.initState();
    _checkTimer();
  }

  void _checkTimer() {
    // Chỉ tự ẩn sau 10s nếu đã được phản hồi.
    // Nếu là câu hỏi thăm chưa phản hồi, giữ lại để vợ bấm trả lời.
    if (widget.signal.isResponded) {
      _startDismissTimer();
    } else {
      _dismissTimer?.cancel();
    }
  }

  void _startDismissTimer() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _HusbandResponseBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signal.id != widget.signal.id ||
        oldWidget.signal.respondedAt != widget.signal.respondedAt ||
        oldWidget.signal.responseMessage != widget.signal.responseMessage) {
      _checkTimer();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _respond(String replyText) async {
    if (_isResponding) return;
    setState(() => _isResponding = true);
    AppHaptics.medium();

    try {
      await ref.read(partnerSyncRepositoryProvider).respondCareSignal(
        signalId: widget.signal.id,
        responseMessage: replyText,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi phản hồi đến ${widget.partnerNickname} 💕'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResponding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isQuestion = widget.signal.isFromHusband && !widget.signal.isResponded;
    final senderName = widget.signal.senderNickname ?? widget.partnerNickname;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF381A2A), const Color(0xFF241420)]
              : [const Color(0xFFFFF0F5), const Color(0xFFFFE8EF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withAlpha(isDark ? 110 : 160),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(isDark ? 50 : 35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(isQuestion ? '💬' : '💖', style: const TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isQuestion
                                ? '$senderName vừa nhắn hỏi thăm 💕'
                                : 'Lời nhắn từ $senderName 💕',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.5,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            widget.signal.respondedAt != null
                                ? 'Đã phản hồi'
                                : (isQuestion ? 'Vừa xong • 1 chạm trả lời ngay' : 'Vừa xong'),
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                  ],
                ),
                const SizedBox(height: 10),

                // Bong bóng tin nhắn
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withAlpha(80)
                        : Colors.white.withAlpha(200),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(isDark ? 60 : 80),
                    ),
                  ),
                  child: Text(
                    isQuestion
                        ? (widget.signal.customNote ?? 'Đang nghĩ đến em...')
                        : (widget.signal.isFromHusband
                            ? 'Bạn: "${widget.signal.responseMessage}"'
                            : (widget.signal.responseMessage ?? '')),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.3,
                    ),
                  ),
                ),

                // NẾU LÀ CÂU HỎI TỪ CHỒNG & CHƯA PHẢN HỒI: HIỂN THỊ 4 NÚT PHẢN HỒI NHANH 1 CHẠM
                if (isQuestion) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Phản hồi nhanh 1 chạm cho anh:',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(200),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _quickWifeReplies.map((reply) {
                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isResponding ? null : () => _respond(reply),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: AppColors.primary.withAlpha(isDark ? 80 : 50),
                              ),
                            ),
                            child: Text(
                              reply,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.signal.isFromHusband
                        ? 'Lời hỏi thăm: "${widget.signal.customNote}"'
                        : 'Phản hồi cho: "${widget.signal.customNote ?? widget.signal.type.label}"',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              color: theme.textTheme.bodySmall?.color,
              tooltip: 'Đóng thông báo',
              onPressed: () {
                AppHaptics.selection();
                widget.onDismiss();
              },
            ),
          ),
        ],
      ),
    );
  }
}
