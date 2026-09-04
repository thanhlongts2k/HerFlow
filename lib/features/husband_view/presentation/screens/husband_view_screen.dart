// lib/features/husband_view/presentation/screens/husband_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/mood/presentation/controllers/mood_controller.dart';
import 'package:herflow/features/partner_sync/domain/models/partner_status_model.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/care_signals/presentation/controllers/care_signal_controller.dart';
import 'package:herflow/features/cycle/domain/entities/cycle_info.dart';
import 'package:herflow/features/cycle/presentation/widgets/cycle_calendar_view.dart';
import 'package:herflow/features/cycle/presentation/widgets/cycle_phase_legend.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';
import 'package:herflow/features/settings/presentation/screens/settings_screen.dart';
import 'package:herflow/features/care_signals/presentation/widgets/love_notes_thread_modal.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/lifecycle/domain/models/fetal_week_data.dart';
import 'package:herflow/features/lifecycle/domain/services/pregnancy_calculator_service.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';
import '../widgets/husband_quick_chat_sheet.dart';
import '../widgets/contextual_behavior_banner.dart';
import '../widgets/energy_battery_indicator.dart';
import '../widgets/quick_care_signals_row.dart';
import '../widgets/survival_cheat_sheet_card.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/kick_counter_controller.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/kick_counter_sheet.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/child_profile_controller.dart';
import 'package:herflow/features/motherhood/presentation/widgets/husband_motherhood_companion_card.dart';
import 'package:herflow/features/motherhood/presentation/widgets/husband_baby_quick_care_row.dart';

/// Màn hình Góc Nhìn Của Anh — Trợ lý thấu hiểu của quý ông (Gentleman's Companion)
class HusbandViewScreen extends ConsumerWidget {
  final bool isWifePreview;
  const HusbandViewScreen({super.key, this.isWifePreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(cycleControllerProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final moodEntry = ref.watch(selectedDateMoodProvider);
    final savedCoupleId = ref.watch(savedCoupleIdProvider);
    final liveStatusAsync = ref.watch(partnerLiveStatusStreamProvider);
    final careSignalAsync = ref.watch(latestCareSignalStreamProvider);
    final careSignal = careSignalAsync.valueOrNull;
    final nicknameConfig = ref.watch(nicknameConfigProvider);
    final partnerName = nicknameConfig.callPartnerAs;
    final currentStage = ref.watch(currentLifeStageProvider);
    final isPaused = ref.watch(isPausedModeProvider);
    final gestationalAge = ref.watch(currentGestationalAgeProvider);
    final fetalWeekData = ref.watch(currentFetalWeekDataProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String husbandTitle;
    final String husbandSubtitle;
    final IconData husbandIcon;

    switch (currentStage) {
      case LifeStage.pregnancy:
        husbandTitle = 'Góc Nhìn Bố Bầu';
        husbandSubtitle = 'Trợ lý chăm sóc thai kỳ & đồng hành cùng $partnerName (${AppDateUtils.formatHeaderDate(selectedDate)})';
        husbandIcon = Icons.child_care_rounded;
        break;
      case LifeStage.motherhood:
        husbandTitle = 'Góc Nhìn Bố Bỉm';
        husbandSubtitle = 'Trợ lý chăm con & đồng hành cùng $partnerName (${AppDateUtils.formatHeaderDate(selectedDate)})';
        husbandIcon = Icons.family_restroom_rounded;
        break;
      case LifeStage.conception:
        husbandTitle = 'Góc Nhìn Bạn Đời';
        husbandSubtitle = 'Đồng hành chuẩn bị đón bé cùng $partnerName (${AppDateUtils.formatHeaderDate(selectedDate)})';
        husbandIcon = Icons.spa_rounded;
        break;
      case LifeStage.couple:
      case LifeStage.solo:
        husbandTitle = 'Góc Nhìn Của Anh';
        husbandSubtitle = 'Trợ lý thấu hiểu & đồng hành cùng $partnerName (${AppDateUtils.formatHeaderDate(selectedDate)})';
        husbandIcon = Icons.shield_rounded;
        break;
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: isWifePreview,
        leading: isWifePreview
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                tooltip: 'Quay lại',
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(husbandIcon, size: 18, color: AppColors.secondary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    husbandTitle,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            // BUG-03 FIX: Cho phép maxLines: 2 và dùng ellipsis tránh bị cắt cụt 1 dòng
            Text(
              husbandSubtitle,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Nút kết nối / trạng thái ghép đôi
          IconButton(
            icon: Icon(
              savedCoupleId != null ? Icons.cloud_done_rounded : Icons.sync_rounded,
              color: savedCoupleId != null ? AppColors.success : AppColors.secondary,
            ),
            tooltip: savedCoupleId != null ? 'Đã kết nối Live' : 'Ghép đôi với Vợ',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PairingScreen(initialIndex: 1),
                ),
              );
            },
          ),
          // Nút Settings chỉ hiển thị khi đang ở chế độ xem trước (isWifePreview)
          // Khi ở role Chồng bình thường: dùng tab Cài đặt trong BottomNav
          if (isWifePreview)
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
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (cycleInfo) {
          final liveStatus = liveStatusAsync.valueOrNull;
          final currentPhase = liveStatus != null
              ? _parsePhase(liveStatus.currentPhase)
              : cycleInfo.getPhaseForDate(selectedDate);
          final cycleDay = (liveStatus != null && liveStatus.cycleDay > 0)
              ? liveStatus.cycleDay
              : cycleInfo.getCycleDay(selectedDate);
          final energyLevel = liveStatus != null
              ? liveStatus.energyLevel
              : moodEntry.energyLevel;

          final isPregnancy = currentStage == LifeStage.pregnancy;
          final isMotherhood = currentStage == LifeStage.motherhood;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0. BANNER XEM TRƯỚC (DÀNH CHO VỢ)
                if (isWifePreview) ...[
                  _buildPreviewBanner(context, isDark),
                  const SizedBox(height: 10),
                ],

                // ── GIAI ĐOẠN NUÔI CON (MOTHERHOOD MODE DAD DASHBOARD) ──
                if (isMotherhood) ...[
                  // 1.1. BANNER TRẠNG THÁI KẾT NỐI
                  _buildConnectionHeader(context, savedCoupleId, isDark),
                  const SizedBox(height: 12),

                  // 1.2. HỘP TÍN HIỆU YÊU THƯƠNG TỪ NÀNG
                  if (savedCoupleId != null && savedCoupleId.isNotEmpty && careSignal != null) ...[
                    _buildCareSignalBox(context, ref, careSignal, isDark, partnerName),
                    const SizedBox(height: 14),
                  ],

                  if (isPaused) ...[
                    // SAFEGUARD KHI Ở CHẾ ĐỘ TẠM DỪNG & CHỮA LÀNH
                    _buildHealingModeCardForDad(context, isDark, partnerName),
                    const SizedBox(height: 14),
                    QuickCareSignalsRow(
                      partnerName: partnerName,
                      isDark: isDark,
                      isHealing: true,
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    // a. Thẻ "Tình Hình Bé Yêu Hôm Nay" (HusbandMotherhoodCompanionCard)
                    HusbandMotherhoodCompanionCard(
                      status: ref.watch(motherhoodStatusStreamProvider).value,
                      localChild: ref.watch(activeChildProvider),
                      isDark: isDark,
                      partnerName: partnerName,
                    ),
                    const SizedBox(height: 14),

                    // b. Thanh tác vụ nhanh của Bố Bỉm (HusbandBabyQuickCareRow)
                    HusbandBabyQuickCareRow(
                      isDark: isDark,
                      partnerName: partnerName,
                    ),
                    const SizedBox(height: 14),

                    // c. Phím tắt gửi yêu thương cho Mẹ
                    QuickCareSignalsRow(
                      partnerName: partnerName,
                      isDark: isDark,
                      isPregnancy: false,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Thẻ Hỏi Thăm & Nhắn Nhủ Nàng (Quick Chat)
                  if (savedCoupleId != null && savedCoupleId.isNotEmpty)
                    _buildQuickChatCard(context, currentPhase, partnerName, isDark)
                  else
                    _buildUnpairedQuickChatCard(context, isDark, partnerName),
                  const SizedBox(height: 32),
                ] else if (isPregnancy) ...[
                  // 1.1. BANNER TRẠNG THÁI KẾT NỐI
                  _buildConnectionHeader(context, savedCoupleId, isDark),
                  const SizedBox(height: 12),

                  // 1.2. HỘP TÍN HIỆU YÊU THƯƠNG TỪ NÀNG
                  if (savedCoupleId != null && savedCoupleId.isNotEmpty && careSignal != null) ...[
                    _buildCareSignalBox(context, ref, careSignal, isDark, partnerName),
                    const SizedBox(height: 14),
                  ],

                  if (isPaused) ...[
                    // SAFEGUARD KHI Ở CHẾ ĐỘ TẠM DỪNG & CHỮA LÀNH
                    _buildHealingModeCardForDad(context, isDark, partnerName),
                    const SizedBox(height: 14),
                    QuickCareSignalsRow(
                      partnerName: partnerName,
                      isDark: isDark,
                      isHealing: true,
                    ),
                    const SizedBox(height: 14),
                  ] else ...[
                    // a. Thẻ "Bé Yêu Của Bố Tuần Này" (Fetal Pregnancy Card for Dad)
                    _buildFetalPregnancyCardForDad(
                      context,
                      gestationalAge,
                      fetalWeekData,
                      isDark,
                      partnerName,
                    ),
                    const SizedBox(height: 14),

                    // a2. Tóm tắt cử động thai hôm nay (từ tuần 28+ hoặc khi đã có dữ liệu đếm hôm nay)
                    if ((gestationalAge?.currentWeekOrdinal ?? 0) >= 28 ||
                        ref.watch(todayKickSummaryProvider).totalKicks > 0) ...[
                      _buildKickSummaryCard(context, ref, isDark),
                      const SizedBox(height: 14),
                    ],

                    // c. Tùy biến phím tắt Care Signals cho Bố Bầu
                    QuickCareSignalsRow(
                      partnerName: partnerName,
                      isDark: isDark,
                      isPregnancy: true,
                    ),
                    const SizedBox(height: 14),

                    // b. Thẻ "Bí Kíp Chăm Vợ Bầu" (Contextual Husband Pregnancy Insights)
                    _buildPregnancyCheatSheetCard(
                      context,
                      gestationalAge?.trimester,
                      isDark,
                      partnerName,
                    ),
                    const SizedBox(height: 14),

                    // Thể Trạng & Cảm Xúc Mẹ Bầu
                    _buildPregnancyMomStatusCard(
                      context,
                      energyLevel: energyLevel,
                      isDark: isDark,
                      partnerName: partnerName,
                      liveStatus: liveStatus,
                      moodText: liveStatus?.moodSummary.isNotEmpty == true
                          ? liveStatus!.moodSummary
                          : (liveStatus?.moodTags.isNotEmpty == true
                              ? liveStatus!.moodTags.join(', ')
                              : moodEntry.mood),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Thẻ Hỏi Thăm & Nhắn Nhủ Nàng (Quick Chat)
                  if (savedCoupleId != null && savedCoupleId.isNotEmpty)
                    _buildQuickChatCard(context, currentPhase, partnerName, isDark)
                  else
                    _buildUnpairedQuickChatCard(context, isDark, partnerName),
                  const SizedBox(height: 14),

                  // Nút Sao chép tóm tắt gửi nhanh (Zalo/SMS)
                  _buildPregnancyQuickCopyButton(
                    context,
                    gestationalAge: gestationalAge,
                    fetalWeekData: fetalWeekData,
                    energyLevel: energyLevel,
                    moodText: moodEntry.mood,
                    isDark: isDark,
                    isPaused: isPaused,
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  // 1. THẺ "CHẾ ĐỘ ỨNG XỬ" THEO CHU KỲ (CONTEXTUAL MODE BANNER)
                  ContextualBehaviorBanner(
                    phase: currentPhase,
                    partnerName: partnerName,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 12),

                  // 1.2. BANNER TRẠNG THÁI KẾT NỐI
                  _buildConnectionHeader(context, savedCoupleId, isDark),

                  const SizedBox(height: 12),

                  // 2. HỘP TÍN HIỆU YÊU THƯƠNG TỪ NÀNG (CARE SIGNAL) — Chỉ hiển thị khi đã kết nối
                  if (savedCoupleId != null && savedCoupleId.isNotEmpty && careSignal != null) ...[
                    _buildCareSignalBox(context, ref, careSignal, isDark, partnerName),
                    const SizedBox(height: 14),
                  ],

                  // 3. HERO CARD: NHIỆT KẾ CẢM XÚC & NĂNG LƯỢNG NÀNG
                  _buildHeroCard(
                    context,
                    phase: currentPhase,
                    cycleDay: cycleDay,
                    energyLevel: energyLevel,
                    isDark: isDark,
                    partnerName: partnerName,
                    liveStatus: liveStatus,
                    moodText: liveStatus?.moodSummary.isNotEmpty == true
                        ? liveStatus!.moodSummary
                        : (liveStatus?.moodTags.isNotEmpty == true
                            ? liveStatus!.moodTags.join(', ')
                            : moodEntry.mood),
                  ),

                  const SizedBox(height: 14),

                  // 3.1. HÀNG PHÍM TẮT "CỨU NGUY 1 CHẠM" (QUICK CARE SIGNALS)
                  QuickCareSignalsRow(
                    partnerName: partnerName,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 14),

                  // 3.2. THẺ HỎI THĂM & NHẮN NHỦ NÀNG (HUSBAND QUICK CHAT)
                  if (savedCoupleId != null && savedCoupleId.isNotEmpty)
                    _buildQuickChatCard(context, currentPhase, partnerName, isDark)
                  else
                    _buildUnpairedQuickChatCard(context, isDark, partnerName),

                  const SizedBox(height: 14),

                  // 3.5. TÓM TẮT CHU KỲ CỦA NÀNG (CYCLE SUMMARY CARD)
                  _buildCycleSummaryCard(context, ref, cycleInfo, isDark, partnerName),

                  const SizedBox(height: 16),

                  // 4. BẢNG "BÍ KÍP SINH TỒN" 1 CHẠM (DO'S & DON'TS CHEAT-SHEET)
                  SurvivalCheatSheetCard(
                    phase: currentPhase,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 16),

                  // 4.2. GENTLEMAN'S PLAYBOOK: GỢI Ý MÓN ĂN / THỨC UỐNG
                  _buildPlaybookSection(context, currentPhase, isDark),

                  const SizedBox(height: 20),

                  // 5. NÚT SAO CHÉP TÓM TẮT GỬI NHANH (ZALO/SMS)
                  _buildQuickCopyButton(
                    context,
                    phase: currentPhase,
                    cycleDay: cycleDay,
                    energyLevel: energyLevel,
                    moodText: moodEntry.mood,
                    isDark: isDark,
                  ),

                  const SizedBox(height: 32),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Banner thông báo khi Vợ đang xem trước giao diện Chồng
  Widget _buildPreviewBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(isDark ? 40 : 20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withAlpha(isDark ? 80 : 50),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Chế độ xem trước: Đây là giao diện Chồng bạn sẽ thấy khi mở app 💕',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Đóng',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// BUG-04 FIX: Header kết nối — phân biệt rõ 2 trạng thái:
  /// - Đã kết nối: Hiển thị card trạng thái xanh tĩnh (không phải nút bấm ghép đôi)
  /// - Chưa kết nối: Hiển thị banner CTA kêu gọi ghép đôi (bấm được)
  Widget _buildConnectionHeader(
    BuildContext context,
    String? savedCoupleId,
    bool isDark,
  ) {
    final isConnected = savedCoupleId != null && savedCoupleId.isNotEmpty;

    if (isConnected) {
      // ── TRẠNG THÁI ĐÃ KẾT NỐI: Card thông tin xanh lá, không phải nút bấm ──
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.success.withAlpha(isDark ? 35 : 18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.success.withAlpha(isDark ? 80 : 55),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(isDark ? 50 : 30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.success,
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đang đồng hành cùng nhau 💕',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? const Color(0xFF81C784) : AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    'Live sync Firestore đang hoạt động',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            // Nút nhỏ để vào trang quản lý ghép đôi
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairingScreen(initialIndex: 1)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(isDark ? 45 : 25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.success.withAlpha(70)),
                ),
                child: Text(
                  'Chi tiết',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFF81C784) : AppColors.success,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // ── CHƯA KẾT NỐI: Banner CTA kêu gọi ghép đôi (bấm được) ──
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PairingScreen(initialIndex: 1)),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(isDark ? 30 : 15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.secondary.withAlpha(isDark ? 60 : 40),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.link_rounded,
              color: AppColors.secondary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ghép đôi với nàng qua mã 6 ký tự để nhận Live Status',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white70 : AppColors.secondaryDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  /// Hộp nhận tín hiệu yêu thương từ Vợ & Bộ phản hồi 1 chạm
  Widget _buildCareSignalBox(
    BuildContext context,
    WidgetRef ref,
    CareSignalModel signal,
    bool isDark,
    String partnerName,
  ) {
    final timeStr = _formatRelativeTime(signal.sentAt);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2638) : const Color(0xFFF2F5FD),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.secondary.withAlpha(isDark ? 110 : 80),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (signal.isFromHusband ? AppColors.primary : AppColors.secondary)
                      .withAlpha(isDark ? 50 : 30),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  signal.isFromHusband ? '💬' : signal.type.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          signal.isFromHusband
                              ? 'Lời Nhắn Bạn Đã Gửi Tới $partnerName 💬'
                              : 'Tín Hiệu Yêu Thương Từ $partnerName 💕',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: signal.isFromHusband ? AppColors.primary : AppColors.secondary,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      signal.isFromHusband
                          ? (signal.customNote ?? 'Hỏi thăm & nhắn nhủ nàng')
                          : signal.type.label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // BONG BÓNG TIN NHẮN TÌNH CẢM NỔI BẬT NÀNG TỰ GÕ (LOVE NOTE BUBBLE)
          if (!signal.isFromHusband && signal.customNote != null && signal.customNote!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2B1C2E) : const Color(0xFFFFF0F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primary.withAlpha(isDark ? 90 : 80),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(isDark ? 30 : 20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💌', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 6),
                      Text(
                        'Lời nhắn từ $partnerName:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? const Color(0xFFFFB4C8) : AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"${signal.customNote}"',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 20),

          // Trạng thái phản hồi
          if (signal.isResponded) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withAlpha(60)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.favorite_rounded, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      signal.isFromHusband
                          ? '$partnerName đã phản hồi: "${signal.responseMessage}" 💕'
                          : 'Bạn đã phản hồi: "${signal.responseMessage}"',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (signal.isFromHusband) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withAlpha(50)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã gửi tới $partnerName • Đang chờ nàng đọc & phản hồi... ⏳',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              'Phản hồi nhanh 1 chạm cho $partnerName:',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickReplyChip(context, ref, signal.id, '❤️ Anh biết rồi nhé'),
                _buildQuickReplyChip(context, ref, signal.id, '🚗 Anh qua với em ngay'),
                _buildQuickReplyChip(context, ref, signal.id, '🛵 Anh đang mua đồ ăn về nè'),
                _buildQuickReplyChip(context, ref, signal.id, '🫂 Gửi nàng cái ôm thật chặt'),
                _buildQuickReplyChip(context, ref, signal.id, '☕ Anh pha nước ấm cho em liền'),
              ],
            ),
          ],
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              AppHaptics.selection();
              LoveNotesThreadModal.show(context);
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: (signal.isFromHusband ? AppColors.primary : AppColors.secondary)
                    .withAlpha(isDark ? 30 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: (signal.isFromHusband ? AppColors.primary : AppColors.secondary)
                      .withAlpha(50),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.forum_outlined,
                    size: 15,
                    color: signal.isFromHusband ? AppColors.primary : AppColors.secondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Mở Hộp Thư Trò Chuyện với $partnerName 💬',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: signal.isFromHusband ? AppColors.primary : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Thẻ / Nút kích hoạt Modal Chat Nhanh hỏi thăm nàng đặt ngay dưới Hero Card
  Widget _buildQuickChatCard(
    BuildContext context,
    CyclePhase phase,
    String partnerName,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          AppHaptics.selection();
          HusbandQuickChatSheet.show(context, phase: phase);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [
                      AppColors.secondary.withAlpha(45),
                      AppColors.primary.withAlpha(25),
                    ]
                  : [
                      const Color(0xFFF2F4FD),
                      const Color(0xFFFFF0F5),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.secondary.withAlpha(isDark ? 90 : 60),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.secondary.withAlpha(isDark ? 30 : 15),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('💬', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💬 Hỏi thăm & Nhắn nhủ $partnerName',
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Gợi ý thông minh theo pha ${phase.vietnameseName} • 1 chạm gửi nhanh',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Nhắn',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.send_rounded, size: 12, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnpairedQuickChatCard(
    BuildContext context,
    bool isDark,
    String partnerName,
  ) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PairingScreen(initialIndex: 1),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark.withAlpha(160) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : Colors.black12,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.black.withAlpha(10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.favorite_border_rounded, size: 20, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ghép đôi để gửi tin nhắn quan tâm',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Kết nối để mở khóa gửi lời hỏi thăm thích ứng chu kỳ',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.secondary.withAlpha(80)),
              ),
              child: const Text(
                'Ghép đôi',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickReplyChip(
    BuildContext context,
    WidgetRef ref,
    String signalId,
    String text,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () async {
        await ref.read(careSignalControllerProvider).respondSignal(
          signalId: signalId,
          responseMessage: text,
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã gửi phản hồi tới nàng: "$text" 💖'),
              backgroundColor: AppColors.secondary,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.secondary.withAlpha(25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.secondary.withAlpha(55)),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColors.secondary,
          ),
        ),
      ),
    );
  }

  /// Hero Card: Thể trạng nàng & Đo lường năng lượng
  Widget _buildHeroCard(
    BuildContext context, {
    required CyclePhase phase,
    required int cycleDay,
    required int energyLevel,
    required bool isDark,
    required String moodText,
    required String partnerName,
    String? partnerAvatarUrl,
    PartnerStatusModel? liveStatus,
  }) {
    final theme = Theme.of(context);
    final batteryInfo = _getBatteryStatus(energyLevel);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            phase.color.withAlpha(isDark ? 65 : 35),
            const Color(0xFF1E293B).withAlpha(isDark ? 90 : 15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: phase.color.withAlpha(isDark ? 90 : 60),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: phase.color.withAlpha(50),
                    backgroundImage: partnerAvatarUrl != null && partnerAvatarUrl.isNotEmpty
                        ? NetworkImage(partnerAvatarUrl)
                        : null,
                    child: partnerAvatarUrl == null
                        ? const Text('🌸', style: TextStyle(fontSize: 13))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: phase.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${phase.vietnameseName} • Ngày $cycleDay',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: batteryInfo.color.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: batteryInfo.color.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(batteryInfo.icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      batteryInfo.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: batteryInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Lời giải thích tinh tế theo từng pha dành riêng cho nam giới
          Text(
            _getGentlemanInsight(phase, cycleDay),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          // CHỈ SỐ "PIN NĂNG LƯỢNG" (ENERGY BATTERY INDICATOR)
          EnergyBatteryIndicator(
            energyLevel: energyLevel,
            partnerName: partnerName,
            isDark: isDark,
          ),

          if (moodText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tâm trạng $partnerName: $moodText',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ],

          // HIỂN THỊ TAG CẢM XÚC & TRIỆU CHỨNG CƠ THỂ VỢ VỪA TICK THỜI GIAN THỰC
          if (liveStatus != null && liveStatus.moodTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: liveStatus.moodTags.map((tag) {
                final isSymptom = liveStatus.symptoms.contains(tag) ||
                    const [
                      'Đau bụng kinh',
                      'Đau thắt lưng',
                      'Căng tức ngực',
                      'Thèm đồ ngọt',
                      'Đầy hơi',
                      'Nổi mụn',
                      'Nhức đầu',
                      'Khó ngủ',
                      'Chóng mặt',
                    ].contains(tag);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isSymptom ? AppColors.error : AppColors.secondary)
                        .withAlpha(isDark ? 45 : 25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isSymptom ? AppColors.error : AppColors.secondary)
                          .withAlpha(isDark ? 90 : 60),
                    ),
                  ),
                  child: Text(
                    isSymptom ? '🩹 $tag' : '✨ $tag',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSymptom
                          ? (isDark ? const Color(0xFFFF8B8B) : AppColors.error)
                          : (isDark ? const Color(0xFFC0A9FF) : AppColors.secondary),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Widget thẻ tóm tắt chu kỳ sinh học của nàng & nút mở lịch chi tiết
  Widget _buildCycleSummaryCard(
    BuildContext context,
    WidgetRef ref,
    CycleInfo cycleInfo,
    bool isDark,
    String partnerName,
  ) {
    final daysLeft = cycleInfo.daysUntilNextPeriod(DateTime.now());
    final daysLate = cycleInfo.getDaysLate(DateTime.now());
    final isLate = daysLate > 0;
    final nextPeriodStr = DateFormat('dd/MM').format(cycleInfo.nextPeriodDate);
    final fertileStartStr = DateFormat('dd/MM').format(cycleInfo.fertileWindowStart);
    final fertileEndStr = DateFormat('dd/MM').format(cycleInfo.fertileWindowEnd);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withAlpha(120)
            : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLate ? Colors.orange.withAlpha(isDark ? 90 : 60) : (isDark ? Colors.white12 : Colors.black.withAlpha(20)),
          width: isLate ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: (isLate ? Colors.orange : Colors.black).withAlpha(isDark ? 30 : 10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isLate ? Colors.orange : AppColors.primary).withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLate ? Icons.warning_amber_rounded : Icons.calendar_month_rounded,
                  size: 18,
                  color: isLate ? Colors.orange : AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chu Kỳ Sinh Học Của ${partnerName.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2 cột thông tin quan trọng
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isLate ? Colors.orange : AppColors.phaseMenstrual).withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: (isLate ? Colors.orange : AppColors.phaseMenstrual).withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLate ? 'Trạng thái kỳ kinh' : 'Kỳ kinh tới',
                        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLate ? 'Trễ $daysLate ngày' : nextPeriodStr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isLate ? Colors.orange : AppColors.phaseMenstrual,
                        ),
                      ),
                      Text(
                        isLate
                            ? 'Dự kiến: $nextPeriodStr'
                            : (daysLeft > 0 ? 'Còn $daysLeft ngày nữa' : 'Đang trong kỳ'),
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.phaseOvulation.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.phaseOvulation.withAlpha(60)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cửa sổ rụng trứng',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$fertileStartStr - $fertileEndStr',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.phaseOvulation,
                        ),
                      ),
                      Text(
                        'Chu kỳ: ${cycleInfo.cycleLength} ngày',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Thẻ tâm lý tinh tế khi nàng bị trễ kinh
          if (isLate) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(isDark ? 30 : 18),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.orange.withAlpha(70)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.favorite_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gợi ý yêu thương khi $partnerName trễ kinh:',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Chu kỳ có thể xê dịch do stress, thức khuya hoặc công việc. Chàng hãy ở bên vỗ về, chuẩn bị nước ấm và tránh hỏi dồn dập khiến nàng lo lắng nhé! 💕',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Nút xem lịch chu kỳ của nàng
          OutlinedButton.icon(
            onPressed: () => _showPartnerCalendarModal(context, cycleInfo),
            icon: const Icon(Icons.date_range_rounded, size: 16),
            label: Text('Xem lịch chu kỳ của $partnerName'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.secondary,
              side: BorderSide(color: AppColors.secondary.withAlpha(120)),
              minimumSize: const Size.fromHeight(42),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPartnerCalendarModal(BuildContext context, CycleInfo cycleInfo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return Consumer(
          builder: (context, ref, _) {
            final selectedDate = ref.watch(selectedCalendarDateProvider);

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(100),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Lịch Chu Kỳ Sinh Học',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          CycleCalendarView(
                            cycleInfo: cycleInfo,
                            selectedDate: selectedDate,
                            onDateSelected: (newDate) {
                              ref.read(selectedCalendarDateProvider.notifier).state = newDate;
                            },
                          ),
                          const SizedBox(height: 16),
                          const CyclePhaseLegend(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Hộp Gợi ý thực đơn & món nàng thích theo pha chu kỳ
  Widget _buildPlaybookSection(
    BuildContext context,
    CyclePhase phase,
    bool isDark,
  ) {
    final playbook = _getPlaybook(phase);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.restaurant_rounded, size: 16, color: AppColors.accentPeach),
              SizedBox(width: 6),
              Text(
                'Thực Đơn Chiều Nàng Thích Hợp Nhất',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),

        // Gợi ý món nàng thích
        _buildPlaybookCard(
          context,
          title: 'Món ăn & thức uống bồi bổ theo pha',
          badgeText: 'MENU',
          badgeColor: AppColors.accentPeach,
          items: playbook.treats,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildPlaybookCard(
    BuildContext context, {
    required String title,
    required String badgeText,
    required Color badgeColor,
    required List<String> items,
    required bool isDark,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: isDark ? AppColors.cardDark : AppColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isDark ? AppColors.dividerDark : AppColors.dividerLight),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 12.5, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nút sao chép tin nhắn nhanh
  Widget _buildQuickCopyButton(
    BuildContext context, {
    required CyclePhase phase,
    required int cycleDay,
    required int energyLevel,
    required String moodText,
    required bool isDark,
  }) {
    return ElevatedButton.icon(
      onPressed: () {
        final text = '''
🌸 Tóm tắt thể trạng Moona hôm nay:
- Giai đoạn: ${phase.vietnameseName} (Ngày $cycleDay)
- Năng lượng: $energyLevel/5 • Tâm trạng: $moodText
- Lời nhắc ấm áp: ${_getGentlemanInsight(phase, cycleDay)}
''';
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã sao chép tóm tắt trạng thái vào bộ nhớ tạm!'),
            backgroundColor: AppColors.secondary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      },
      icon: const Icon(Icons.copy_all_rounded, size: 18),
      label: const Text('Sao chép tin nhắn quan tâm nhanh'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? const Color(0xFF243048) : AppColors.secondary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }

  // === HELPER FUNCTIONS ===

  CyclePhase _parsePhase(String phaseStr) {
    for (final p in CyclePhase.values) {
      if (p.vietnameseName == phaseStr || p.name == phaseStr) return p;
    }
    return CyclePhase.menstrual;
  }

  _BatteryStatus _getBatteryStatus(int energy) {
    if (energy <= 1) {
      return const _BatteryStatus('🪫', 'Cạn kiệt', AppColors.error);
    } else if (energy == 2) {
      return const _BatteryStatus('🪫', 'Yếu ớt', AppColors.accentPeach);
    } else if (energy == 3) {
      return const _BatteryStatus('🔋', 'Đang hồi phục', AppColors.secondary);
    } else if (energy == 4) {
      return const _BatteryStatus('🔋', 'Tốt', AppColors.success);
    } else {
      return const _BatteryStatus('⚡', 'Tràn đầy năng lượng', AppColors.primary);
    }
  }

  String _getGentlemanInsight(CyclePhase phase, int cycleDay) {
    switch (phase) {
      case CyclePhase.menstrual:
        return 'Hôm nay là Ngày $cycleDay — Nàng đang trải qua cơn đau co thắt và mệt mỏi thể chất. Hãy là điểm tựa ấm áp, chăm sóc và chuẩn bị nước ấm cho nàng.';
      case CyclePhase.follicular:
        return 'Hormone estrogen đang tăng trở lại. Tâm trạng nàng phấn chấn và năng động hơn. Thích hợp cho những buổi hẹn hò ăn uống bất ngờ!';
      case CyclePhase.ovulation:
        return 'Giai đoạn rụng trứng — Nàng rạng rỡ, tự tin và quyến rũ nhất chu kỳ. Tinh thần cởi mở và khả năng thụ thai đạt đỉnh.';
      case CyclePhase.luteal:
        return 'Giai đoạn hoàng thể (tiền kinh nguyệt). Nàng có thể nhạy cảm, dễ cáu hoặc mệt mỏi. Hãy kiên nhẫn, bao dung và đừng phân bua đúng sai.';
    }
  }

  _PlaybookData _getPlaybook(CyclePhase phase) {
    switch (phase) {
      case CyclePhase.menstrual:
        return const _PlaybookData(
          dos: [
            'Chủ động chuẩn bị túi chườm ấm hoặc một ly trà gừng mật ong.',
            'Làm giúp nàng việc nhà, rửa chén hoặc chăm con.',
            'Nói câu: "Hôm nay em mệt rồi, việc này để anh lo".',
          ],
          donts: [
            'Không hỏi dồn dập "Sao em cứ cau có thế?".',
            'Đừng để nàng phải đau đầu nghĩ "Tối nay ăn gì".',
            'Tránh phân bua lý lẽ hoặc so đo việc nhà hôm nay.',
          ],
          treats: [
            'Trà gừng mật ong ấm, canh gà hầm nóng.',
            'Súp bí đỏ, cháo sen sườn non nóng hổi.',
            'Một thanh socola đen ngọt thanh xoa dịu cơn đau.',
          ],
        );
      case CyclePhase.follicular:
        return const _PlaybookData(
          dos: [
            'Lên lịch một buổi hẹn hò bất ngờ ngoài trời.',
            'Cùng nàng tập luyện thể thao nhẹ nhàng hoặc đi dạo.',
            'Khen ngợi trang phục hoặc kiểu tóc mới của nàng.',
          ],
          donts: [
            'Đừng để những ngày cuối tuần trôi qua tẻ nhạt trong nhà.',
            'Không ngắt lời khi nàng hào hứng chia sẻ kế hoạch mới.',
          ],
          treats: [
            'Smoothie bơ chuối tươi mát, sữa chua hạt granola.',
            'Salad cá hồi quả bơ giàu dinh dưỡng.',
            'Bữa tối món Âu hoặc đồ nướng nàng thích.',
          ],
        );
      case CyclePhase.ovulation:
        return const _PlaybookData(
          dos: [
            'Dành cho nàng sự chú ý và những cử chỉ âu yếm lãng mạn.',
            'Lên kế hoạch hẹn hò riêng tư chỉ có hai người.',
            'Tạo không gian ấm cúng, thư thái sau giờ làm việc.',
          ],
          donts: [
            'Không lơ là hoặc thiếu tập trung khi trò chuyện cùng nàng.',
            'Đừng quên những cái ôm siết chặt trước khi đi ngủ.',
          ],
          treats: [
            'Một ly rượu vang đỏ nhẹ cùng bữa tối lãng mạn.',
            'Hải sản tươi ngon, dâu tây hoặc socola ngọt ngào.',
          ],
        );
      case CyclePhase.luteal:
        return const _PlaybookData(
          dos: [
            'Lắng nghe nàng tâm sự mà không phán xét hay cố đưa ra giải pháp ngay.',
            'Massage nhẹ vùng vai gáy và lưng cho nàng trước khi ngủ.',
            'Ôm nàng thật chặt và vỗ về khi nàng cảm thấy buồn vô cớ.',
          ],
          donts: [
            'TUYỆT ĐỐI KHÔNG nói câu: "Em lại tới tháng rồi à?".',
            'Tránh tranh luận chuyện lớn hoặc đưa ra quyết định căng thẳng.',
            'Không phàn nàn nếu nàng đổi ý đột ngột.',
          ],
          treats: [
            'Trà hoa cúc ấm giúp ngủ ngon và xoa dịu thần kinh.',
            'Chè dưỡng nhan, hạt sen long nhãn thanh nhiệt.',
            'Trái cây tươi mát: chuối, cam, việt quất.',
          ],
        );
    }
  }

  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return DateFormat('HH:mm dd/MM').format(dateTime);
  }

  /// Thẻ "Bé Yêu Của Bố Tuần Này" (Fetal Pregnancy Card for Dad)
  Widget _buildFetalPregnancyCardForDad(
    BuildContext context,
    GestationalAgeResult? gestationalAge,
    FetalWeekData? fetalWeekData,
    bool isDark,
    String partnerName,
  ) {
    if (gestationalAge == null || fetalWeekData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF282035) : const Color(0xFFFAF5FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.secondary.withAlpha(isDark ? 80 : 50),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            const Text('🌱', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 10),
            Text(
              'Hành Trình Thai Kỳ Cùng $partnerName',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              '$partnerName chưa thiết lập ngày dự sinh trên máy. Khi nàng thiết lập, thông tin tuổi thai và kích thước bé yêu sẽ tự động xuất hiện tại đây nhé bố!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : Colors.black54,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    final trimester = gestationalAge.trimester;
    final List<Color> gradientColors = switch (trimester) {
      Trimester.first => [
          const Color(0xFFFF8DA1),
          const Color(0xFFFFB4A2),
        ],
      Trimester.second => [
          const Color(0xFF7C4DFF),
          const Color(0xFF448AFF),
        ],
      Trimester.third => [
          const Color(0xFFFF9800),
          const Color(0xFFFFC107),
        ],
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            gradientColors.first.withAlpha(isDark ? 55 : 30),
            gradientColors.last.withAlpha(isDark ? 30 : 12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gradientColors.first.withAlpha(isDark ? 100 : 70),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withAlpha(isDark ? 30 : 15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Tam cá nguyệt + D-Day countdown (Wrap an toàn chống overflow)
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: gradientColors.first.withAlpha(isDark ? 50 : 35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gradientColors.first.withAlpha(isDark ? 120 : 80),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👶', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 5),
                    Text(
                      trimester.displayName,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : gradientColors.first,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.secondary.withAlpha(isDark ? 90 : 60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.event_rounded, size: 13, color: AppColors.secondary),
                    const SizedBox(width: 5),
                    Text(
                      'Còn ${gestationalAge.daysUntilDue} ngày nữa gặp con 🍼',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tuổi thai & Quả so sánh
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black26 : Colors.white).withAlpha(160),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 40 : 15),
                      blurRadius: 10,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  fetalWeekData.fruitEmoji,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bé Yêu Của Bố Tuần Này',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${gestationalAge.formattedAge} • Tuần thứ ${gestationalAge.currentWeekOrdinal}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bé to bằng ${fetalWeekData.fruitName}',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: gradientColors.first,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2 Chip thông số Chiều dài + Cân nặng
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white10 : Colors.white).withAlpha(isDark ? 20 : 180),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.straighten_rounded, size: 15, color: Colors.blueAccent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Dài ${fetalWeekData.formattedLength}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white10 : Colors.white).withAlpha(isDark ? 20 : 180),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.scale_rounded, size: 15, color: Colors.orangeAccent),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Nặng ${fetalWeekData.formattedWeight}',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Thanh tiến trình thai kỳ
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến trình thai kỳ: ${gestationalAge.progressPercentage.toStringAsFixed(1)}%',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'Tuần ${gestationalAge.currentWeekOrdinal}/40',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (gestationalAge.progressPercentage / 100.0).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: isDark ? Colors.white12 : Colors.black12,
                  valueColor: AlwaysStoppedAnimation<Color>(gradientColors.first),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Cột mốc phát triển kỳ diệu của con
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('✨', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cột mốc diệu kỳ tuần này:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      fetalWeekData.babyHighlights,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Thẻ "Bí Kíp Chăm Vợ Bầu" (Contextual Husband Pregnancy Insights)
  Widget _buildPregnancyCheatSheetCard(
    BuildContext context,
    Trimester? trimester,
    bool isDark,
    String partnerName,
  ) {
    final activeTrimester = trimester ?? Trimester.first;

    final List<String> dos;
    final List<String> donts;
    final String trimesterNote;

    switch (activeTrimester) {
      case Trimester.first:
        trimesterNote = 'Tam cá nguyệt 1: Giai đoạn nhạy cảm & ốm nghén';
        dos = [
          'Chủ động nấu ăn hoặc dọn dẹp nhà nếu $partnerName sợ mùi thức ăn.',
          'Chuẩn bị sẵn đồ ăn vặt thanh đạm (bánh quy gừng, nước ấm, hoa quả dịu nhẹ).',
          'Bao dung và nhường nhịn tối đa khi nàng thay đổi cảm xúc do hormone thai kỳ.',
        ];
        donts = [
          'Xịt nước hoa nồng hoặc để mùi dầu mỡ ám trong phòng ngủ.',
          'Ép $partnerName ăn món ngấy hoặc món cô ấy đang sợ mùi.',
          'Tranh luận to tiếng hay để $partnerName cảm thấy cô đơn một mình.',
        ];
        break;
      case Trimester.second:
        trimesterNote = 'Tam cá nguyệt 2: Giai đoạn phục hồi & tăng tốc phát triển';
        dos = [
          'Cùng $partnerName đi siêu âm mốc 20-22 tuần (khảo sát hình thái học toàn diện).',
          'Massage lưng, bắp chân nhẹ nhàng giúp vợ giảm nhức mỏi và chuột rút ban đêm.',
          'Chuẩn bị các bữa ăn giàu canxi, sắt và đồ tẩm bổ lành mạnh cho hai mẹ con.',
        ];
        donts = [
          'Quên nhắc $partnerName lịch xét nghiệm đường huyết thai kỳ (OGTT tuần 24-28).',
          'Để $partnerName khiêng vác đồ nặng hoặc với tay lên cao quá tầm.',
          'Chủ quan khi vợ có dấu hiệu đau bụng dưới hoặc gò cứng bụng bất thường.',
        ];
        break;
      case Trimester.third:
        trimesterNote = 'Tam cá nguyệt 3: Giai đoạn về đích & chuẩn bị đón con';
        dos = [
          'Chuẩn bị sẵn xe cộ, viện phí dự phòng và kiểm tra kỹ giỏ đồ đi sinh.',
          'Hỗ trợ $partnerName khi đứng lên ngồi xuống, đỡ nàng đi lại an toàn.',
          'Cùng vợ học cách thở khi sinh, học cách bế và dỗ trẻ sơ sinh.',
        ];
        donts = [
          'Để $partnerName đi xa hoặc tự lái xe một mình trong những tuần cuối.',
          'Để $partnerName đi lại ở khu vực ẩm ướt, trơn trượt thiếu ánh sáng.',
          'Đi công tác xa mà không có phương án người nhà hỗ trợ vợ khẩn cấp.',
        ];
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F1A2C) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.secondary.withAlpha(isDark ? 80 : 50),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 15),
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
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology_rounded, size: 18, color: AppColors.secondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bí Kíp Chăm Vợ Bầu Cho Bố',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      trimesterNote,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // KHỐI DO
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(isDark ? 25 : 15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.success.withAlpha(isDark ? 70 : 40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success),
                    const SizedBox(width: 6),
                    Text(
                      'NÊN CHỦ ĐỘNG LÀM CHO ${partnerName.toUpperCase()}:',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...dos.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                          Expanded(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // KHỐI DON'T
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withAlpha(isDark ? 25 : 15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.error.withAlpha(isDark ? 70 : 40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.cancel_rounded, size: 15, color: AppColors.error),
                    SizedBox(width: 6),
                    Text(
                      'TUYỆT ĐỐI NÊN TRÁNH:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...donts.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                          Expanded(
                            child: Text(
                              d,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Safeguard khi ở chế độ Tạm Dừng & Chữa Lành (isPaused == true)
  Widget _buildHealingModeCardForDad(
    BuildContext context,
    bool isDark,
    String partnerName,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF90A4AE).withAlpha(isDark ? 50 : 25),
            const Color(0xFFB0BEC5).withAlpha(isDark ? 25 : 15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF90A4AE).withAlpha(isDark ? 90 : 60),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isDark ? Colors.white12 : Colors.white).withAlpha(isDark ? 30 : 200),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('🕊️', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Đồng Hành & Vỗ Về Bạn Đời',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Chế độ Chữa Lành đang được bật',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            'Giai đoạn này, sự dịu dàng, lắng nghe và cái ôm ấm áp của bạn là điểm tựa lớn nhất cho $partnerName. Hãy ở bên cạnh, lắng nghe và chia sẻ mọi gánh nặng tinh thần cùng nàng.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isDark ? Colors.black26 : Colors.white).withAlpha(140),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '💡 Lời khuyên cho bạn:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '• Ôm nàng thật chặt, lắng nghe mà không phán xét.\n'
                  '• Chủ động làm việc nhà, nấu các món bổ dưỡng dễ tiêu.\n'
                  '• Kiên nhẫn ở bên, cho nàng không gian yên tĩnh nghỉ ngơi.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.4,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Thể Trạng & Cảm Xúc Mẹ Bầu
  Widget _buildPregnancyMomStatusCard(
    BuildContext context, {
    required int energyLevel,
    required bool isDark,
    required String moodText,
    required String partnerName,
    PartnerStatusModel? liveStatus,
  }) {
    final theme = Theme.of(context);
    final batteryInfo = _getBatteryStatus(energyLevel);

    final String momTip;
    if (energyLevel <= 2) {
      momTip = '$partnerName đang cảm thấy khá mệt mỏi hoặc ốm nghén. Bố hãy chủ động làm việc nhà, chuẩn bị nước ấm và xoa bóp cho nàng nhé.';
    } else if (energyLevel <= 4) {
      momTip = '$partnerName đang có thể trạng ổn định. Nhắc nàng uống đủ nước, đi dạo nhẹ nhàng và ăn các bữa nhỏ trong ngày.';
    } else {
      momTip = 'Năng lượng của $partnerName hôm nay rất tốt! Thời điểm tuyệt vời để hai vợ chồng trò chuyện cùng con yêu hoặc chuẩn bị kế hoạch sinh.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withAlpha(isDark ? 55 : 25),
            const Color(0xFF1E293B).withAlpha(isDark ? 90 : 15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withAlpha(isDark ? 90 : 50),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withAlpha(50),
                    child: const Text('🤰', style: TextStyle(fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Thể Trạng Của Mẹ Bầu $partnerName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: batteryInfo.color.withAlpha(isDark ? 40 : 25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: batteryInfo.color.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(batteryInfo.icon, style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      batteryInfo.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: batteryInfo.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            momTip,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              height: 1.45,
            ),
          ),

          const SizedBox(height: 14),

          // CHỈ SỐ PIN NĂNG LƯỢNG
          EnergyBatteryIndicator(
            energyLevel: energyLevel,
            partnerName: partnerName,
            isDark: isDark,
          ),

          if (moodText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tâm trạng $partnerName: $moodText',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
            ),
          ],

          // HIỂN THỊ TRIỆU CHỨNG THỰC TẾ CỦA VỢ BẦU
          if (liveStatus != null && liveStatus.moodTags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: liveStatus.moodTags.map((tag) {
                final isSymptom = liveStatus.symptoms.contains(tag) ||
                    const [
                      'Ốm nghén',
                      'Buồn nôn',
                      'Mệt mỏi',
                      'Đau thắt lưng',
                      'Căng tức ngực',
                      'Khó ngủ',
                      'Chóng mặt',
                      'Ợ chua',
                      'Chuột rút',
                    ].contains(tag);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isSymptom ? AppColors.error : AppColors.secondary)
                        .withAlpha(isDark ? 45 : 25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isSymptom ? AppColors.error : AppColors.secondary)
                          .withAlpha(isDark ? 90 : 60),
                    ),
                  ),
                  child: Text(
                    isSymptom ? '🩹 $tag' : '✨ $tag',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSymptom
                          ? (isDark ? Colors.red[200] : AppColors.error)
                          : (isDark ? Colors.tealAccent : AppColors.secondary),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  /// Nút Sao chép tóm tắt gửi nhanh (Zalo/SMS) dành riêng cho Thai Kỳ
  Widget _buildPregnancyQuickCopyButton(
    BuildContext context, {
    required GestationalAgeResult? gestationalAge,
    required FetalWeekData? fetalWeekData,
    required int energyLevel,
    required String moodText,
    required bool isDark,
    required bool isPaused,
  }) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.copy_rounded, size: 16),
      label: const Text('Sao Chép Tóm Tắt Gửi Nhanh (Zalo/SMS)'),
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white70 : AppColors.secondary,
        side: BorderSide(
          color: (isDark ? Colors.white24 : AppColors.secondary.withAlpha(80)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: () {
        AppHaptics.light();
        final text = isPaused
            ? '🌿 Hôm nay anh luôn ở bên cạnh em, yêu thương và chăm sóc em nhé!'
            : (gestationalAge != null && fetalWeekData != null)
                ? '🍼 Hành trình thai kỳ: ${gestationalAge.formattedAge} (Tuần ${gestationalAge.currentWeekOrdinal}/40) • Bé to bằng ${fetalWeekData.fruitName} ${fetalWeekData.fruitEmoji} • Còn ${gestationalAge.daysUntilDue} ngày nữa đón con. Hôm nay bố luôn bên mẹ và bé yêu nhé!'
                : '🍼 Đồng hành cùng mẹ bầu mỗi ngày!';
        Clipboard.setData(ClipboardData(text: text));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Đã sao chép tóm tắt vào bộ nhớ tạm!'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.secondary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
    );
  }

  // ── Kick Summary Card (Bố Bầu / Pregnancy Dad) ─────────────────────────────
  /// Thẻ tóm tắt cử động thai hôm nay — chỉ hiển thị từ tuần 28 trở đi.
  /// Khi tap → mở KickCounterSheet toàn bộ.
  Widget _buildKickSummaryCard(
      BuildContext context, WidgetRef ref, bool isDark) {
    final summary = ref.watch(todayKickSummaryProvider);
    final hasKicks = summary.totalKicks > 0;
    final isGood = summary.totalKicks >= 10;

    return GestureDetector(
      onTap: () {
        AppHaptics.medium();
        KickCounterSheet.show(context);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isGood
              ? LinearGradient(
                  colors: [
                    AppColors.success.withAlpha(isDark ? 40 : 25),
                    AppColors.accentMint.withAlpha(isDark ? 30 : 18),
                  ],
                )
              : null,
          color: isGood
              ? null
              : (isDark
                  ? AppColors.cardDark.withAlpha(220)
                  : AppColors.cardLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGood
                ? AppColors.success.withAlpha(isDark ? 80 : 55)
                : AppColors.primary.withAlpha(isDark ? 55 : 35),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 25 : 10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Text(
              isGood ? '✅' : (hasKicks ? '👶' : '🩷'),
              style: const TextStyle(fontSize: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cử Động Thai Hôm Nay',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white.withAlpha(222) : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasKicks
                        ? '${summary.totalKicks} cử động • ${summary.sessions} phiên hoàn thành'
                        : 'Chưa ghi nhận hôm nay — Nhắc nàng đếm nhé! 💕',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  if (summary.lastSessionTime.isNotEmpty) ...[  
                    const SizedBox(height: 2),
                    Text(
                      summary.lastSessionTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.success.withAlpha(isDark ? 200 : 170),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.touch_app_rounded,
              color: isDark ? Colors.white30 : Colors.black26,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _BatteryStatus {
  final String icon;
  final String label;
  final Color color;
  const _BatteryStatus(this.icon, this.label, this.color);
}

class _PlaybookData {
  final List<String> dos;
  final List<String> donts;
  final List<String> treats;
  const _PlaybookData({required this.dos, required this.donts, required this.treats});
}
