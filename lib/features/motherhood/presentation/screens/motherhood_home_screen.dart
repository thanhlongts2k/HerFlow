// lib/features/motherhood/presentation/screens/motherhood_home_screen.dart
//
// Màn hình chính Dashboard Giai Đoạn Nuôi Con (Motherhood Dashboard).
// Tích hợp:
// 1. BabySummaryHeroCard (Tổng quan hôm nay: cữ bú, giấc ngủ, tã bỉm)
// 2. BabyQuickActionBar (Thanh 4 nút 1-chạm: Bú, Ngủ, Tã, Cân nặng)
// 3. LAM Status Card (Đánh giá vô kinh cho con bú WHO & ức chế trễ kinh)
// 4. Wonder Weeks Card (Dự báo tuần khủng hoảng nhận thức & tuần bão tố)
// 5. Daily Activity Timeline (Dòng thời gian sinh hoạt của bé trong ngày kèm phân quyền Cha/Mẹ)
// 6. Safeguards: Empty state khi chưa có bé & Chế độ Chữa Lành khi isPaused == true

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/moona_confirm_dialog.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/motherhood/domain/models/baby_activity_log_model.dart';
import 'package:herflow/features/motherhood/domain/models/child_profile_model.dart';
import 'package:herflow/features/motherhood/domain/models/wonder_weeks_model.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/child_profile_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/lam_status_controller.dart';
import 'package:herflow/features/motherhood/presentation/widgets/baby_quick_action_bar.dart';
import 'package:herflow/features/motherhood/presentation/widgets/baby_summary_hero_card.dart';

class MotherhoodHomeScreen extends ConsumerStatefulWidget {
  const MotherhoodHomeScreen({super.key});

  @override
  ConsumerState<MotherhoodHomeScreen> createState() =>
      _MotherhoodHomeScreenState();
}

class _MotherhoodHomeScreenState extends ConsumerState<MotherhoodHomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activeChild = ref.read(activeChildProvider);
      if (activeChild != null) {
        ref.read(lamStatusControllerProvider.notifier).evaluateWithChild(activeChild);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final childProfileState = ref.watch(childProfileControllerProvider);
    final activeChild = childProfileState.activeChild;
    final isPaused = ref.watch(isPausedModeProvider) || (activeChild?.isPaused ?? false);

    // Lắng nghe thay đổi bé để đánh giá lại LAM
    ref.listen<ChildProfileModel?>(activeChildProvider, (prev, next) {
      if (next != null && next != prev) {
        ref.read(lamStatusControllerProvider.notifier).evaluateWithChild(next);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('🍼', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    activeChild != null ? activeChild.name : 'Nuôi Con',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              activeChild != null
                  ? '${activeChild.getAgeDisplay()} • Tuần ${activeChild.getAgeInWeeks()}'
                  : 'Hồ sơ chăm sóc bé yêu',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Nút đổi hoặc thêm bé
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Danh sách bé',
            onPressed: () => _showChildrenManagerSheet(context),
          ),
          // Nút Chế độ chữa lành
          IconButton(
            icon: Icon(
              isPaused ? Icons.spa_rounded : Icons.spa_outlined,
              color: isPaused ? AppColors.primary : null,
            ),
            tooltip: isPaused ? 'Đang ở chế độ Chữa Lành' : 'Chế độ Chữa Lành',
            onPressed: () => _handleTogglePauseMode(isPaused),
          ),
        ],
      ),
      body: childProfileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : childProfileState.children.isEmpty
              ? _buildEmptyState(context, isDark)
              : isPaused
                  ? _buildHealingModeView(context, isDark, activeChild)
                  : _buildDashboardContent(context, isDark, activeChild!),
    );
  }

  // ── 1. NỘI DUNG CHÍNH CỦA DASHBOARD NUÔI CON ─────────────────────────────

  Widget _buildDashboardContent(
    BuildContext context,
    bool isDark,
    ChildProfileModel child,
  ) {
    final logState = ref.watch(babyLogControllerProvider);
    final lamState = ref.watch(lamStatusControllerProvider);
    final correctedWeeks = child.getCorrectedAgeInWeeks();
    final leap = WonderWeeksData.getLeapForWeek(correctedWeeks);
    final isStorm = WonderWeeksData.isStormPeriod(correctedWeeks);

    return SingleChildScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Thẻ Hero tổng quan
          BabySummaryHeroCard(
            child: child,
            onSwitchChild: () => _showChildrenManagerSheet(context),
          ),
          const SizedBox(height: 14),

          // 2. Thanh 4 nút tác vụ nhanh 1-chạm
          BabyQuickActionBar(child: child),
          const SizedBox(height: 16),

          // 3. Thẻ Đánh giá Vô kinh cho con bú (WHO LAM)
          _buildLamStatusCard(context, isDark, lamState, child),
          const SizedBox(height: 16),

          // 4. Thẻ Wonder Weeks (Tuần khủng hoảng phát triển)
          if (leap != null) ...[
            _buildWonderWeeksCard(context, isDark, leap, isStorm),
            const SizedBox(height: 16),
          ],

          // 5. Dòng thời gian sinh hoạt trong ngày (Daily Timeline)
          _buildDailyTimeline(context, isDark, logState.todayLogs),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── 2. THẺ ĐÁNH GIÁ VÔ KINH CHO CON BÚ (WHO LAM) ──────────────────────────

  Widget _buildLamStatusCard(
    BuildContext context,
    bool isDark,
    LamState lamState,
    ChildProfileModel child,
  ) {
    final theme = Theme.of(context);
    final eligible = lamState.isEligible;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: eligible
              ? AppColors.phaseOvulation.withAlpha(80)
              : Colors.orange.withAlpha(80),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (eligible ? AppColors.phaseOvulation : Colors.orange)
                      .withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  eligible ? Icons.shield_rounded : Icons.info_outline_rounded,
                  size: 18,
                  color: eligible ? AppColors.phaseOvulation : Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ngừa Thai Tự Nhiên LAM (WHO)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (eligible ? AppColors.phaseOvulation : Colors.grey)
                      .withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  eligible ? 'Đang hiệu lực ~98%' : 'Không hiệu lực',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: eligible ? AppColors.phaseOvulation : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lamState.statusMessage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildLamConditionChip(
                label: 'Bé < 6 tháng',
                isMet: lamState.isUnder6Months,
                isDark: isDark,
              ),
              _buildLamConditionChip(
                label: 'Bú mẹ hoàn toàn',
                isMet: lamState.isExclusiveBreastfeeding,
                isDark: isDark,
              ),
              _buildLamConditionChip(
                label: 'Chưa có kinh lại',
                isMet: !lamState.hasMensesReturned,
                isDark: isDark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Nút cập nhật kinh nguyệt
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => _showMensesToggleDialog(context, lamState),
              icon: const Icon(Icons.edit_calendar_outlined, size: 14),
              label: Text(
                lamState.hasMensesReturned
                    ? 'Kinh nguyệt đã trở lại'
                    : 'Đánh dấu khi có kinh lại',
                style: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLamConditionChip({
    required String label,
    required bool isMet,
    required bool isDark,
  }) {
    return Chip(
      avatar: Icon(
        isMet ? Icons.check_circle_rounded : Icons.cancel_rounded,
        size: 14,
        color: isMet ? AppColors.phaseOvulation : Colors.grey,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isMet ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
        ),
      ),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      backgroundColor: isMet
          ? AppColors.phaseOvulation.withAlpha(18)
          : (isDark ? Colors.white10 : Colors.black.withAlpha(8)),
      side: BorderSide.none,
    );
  }

  // ── 3. THẺ WONDER WEEKS LEAP ─────────────────────────────────────────────

  Widget _buildWonderWeeksCard(
    BuildContext context,
    bool isDark,
    WonderWeeksLeap leap,
    bool isStorm,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isStorm
              ? Colors.deepOrange.withAlpha(70)
              : Colors.amber.withAlpha(70),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isStorm ? Colors.deepOrange : Colors.amber).withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(isStorm ? '⚡' : '☀️', style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Leap ${leap.leapIndex}: ${leap.title}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (isStorm ? Colors.deepOrange : Colors.amber).withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isStorm ? 'Bão tố (Tuần ${leap.startWeek}-${leap.endWeek})' : 'Tuần bình yên',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isStorm ? Colors.deepOrange : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            leap.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.white70 : Colors.black87,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(8) : Colors.amber.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('💡', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mẹo cho ba mẹ: ${leap.parentTip}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white60 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. DÒNG THỜI GIAN HOẠT ĐỘNG TRONG NGÀY (DAILY TIMELINE) ───────────────

  Widget _buildDailyTimeline(
    BuildContext context,
    bool isDark,
    List<BabyActivityLogModel> logs,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nhật Ký Hôm Nay (${logs.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              DateFormat('dd/MM/yyyy').format(DateTime.now()),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withAlpha(8),
              ),
            ),
            child: Column(
              children: [
                const Text('🍼', style: TextStyle(fontSize: 32)),
                const SizedBox(height: 8),
                Text(
                  'Hôm nay chưa có ghi chép nào',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Chạm vào thanh tác vụ nhanh bên trên để ghi cữ bú, giấc ngủ hay thay tã cho bé mẹ nhé!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark ? Colors.white38 : Colors.black45,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, index) {
              final log = logs[index];
              return _buildTimelineItem(ctx, isDark, log);
            },
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    bool isDark,
    BabyActivityLogModel log,
  ) {
    final isHusband = log.loggedByRole == 'husband';

    String detailText = '';
    switch (log.type) {
      case ActivityType.feeding:
        if (log.feedingType != null) {
          switch (log.feedingType!) {
            case FeedingType.breastLeft:
              detailText = 'Bú mẹ ngực trái • ${log.calculatedDurationMinutes} phút';
              break;
            case FeedingType.breastRight:
              detailText = 'Bú mẹ ngực phải • ${log.calculatedDurationMinutes} phút';
              break;
            case FeedingType.bottleBreastMilk:
              detailText = 'Bú bình sữa mẹ • ${log.amountMl?.toInt() ?? 0}ml';
              break;
            case FeedingType.bottleFormula:
              detailText = 'Bú sữa công thức • ${log.amountMl?.toInt() ?? 0}ml';
              break;
            case FeedingType.solid:
              detailText = 'Ăn dặm';
              break;
          }
        }
        break;
      case ActivityType.sleep:
        detailText = 'Ngủ ${log.calculatedDurationMinutes} phút';
        break;
      case ActivityType.diaper:
        if (log.diaperType != null) {
          switch (log.diaperType!) {
            case DiaperType.wet:
              detailText = 'Tã ướt 💧';
              break;
            case DiaperType.dirty:
              detailText = 'Tã bẩn 💩';
              break;
            case DiaperType.both:
              detailText = 'Cả ướt & bẩn 🧷';
              break;
            case DiaperType.clean:
              detailText = 'Tã sạch ✨';
              break;
          }
        }
        break;
      default:
        detailText = log.notes ?? '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withAlpha(8),
        ),
      ),
      child: Row(
        children: [
          // Icon hoạt động
          Text(log.type.icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),

          // Nội dung & giờ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.type.label,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      DateFormat('HH:mm').format(log.timestamp),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  detailText,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                if (log.notes != null && log.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    log.notes!,
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white38 : Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Badge Cha / Mẹ ghi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isHusband ? AppColors.secondary : AppColors.primary)
                  .withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              isHusband ? 'Bố 👨' : 'Mẹ 👩',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isHusband ? AppColors.secondary : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. EMPTY STATE (KHI CHƯA CÓ BÉ NÀO) ──────────────────────────────────

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🍼', style: TextStyle(fontSize: 48)),
            ),
            const SizedBox(height: 20),
            Text(
              'Chào Mừng Mẹ Đến Với Nuôi Con 🌸',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Hãy thêm hồ sơ của bé để bắt đầu theo dõi cữ bú, giấc ngủ, tã bỉm và biểu đồ tăng trưởng chuẩn WHO.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddChildDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Thêm Hồ Sơ Bé Yêu', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 6. CHẾ ĐỘ CHỮA LÀNH (HEALING MODE KHI isPaused == true) ───────────────

  Widget _buildHealingModeView(
    BuildContext context,
    bool isDark,
    ChildProfileModel? child,
  ) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.accentMint.withAlpha(40),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text('🌿', style: TextStyle(fontSize: 44)),
            ),
            const SizedBox(height: 20),
            Text(
              'Không Gian Chữa Lành & Phục Hồi 🕊️',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'HerFlow đang tạm ẩn các chỉ số theo dõi. Mẹ hãy dành trọn thời gian để nghỉ ngơi, '
              'nuôi dưỡng cảm xúc và bồi đắp sức khỏe sau sinh.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                height: 1.45,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _handleTogglePauseMode(true),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Khôi Phục Giao Diện Nuôi Con'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 7. BOTTOMSHEET QUẢN LÝ DANH SÁCH BÉ ───────────────────────────────────

  void _showChildrenManagerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final pState = ref.watch(childProfileControllerProvider);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Hồ Sơ Các Bé 👶',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddChildDialog(context);
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Thêm bé'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                ListView.separated(
                  shrinkWrap: true,
                  itemCount: pState.children.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final b = pState.children[index];
                    final isSelected = b.childId == pState.activeChildId;

                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      tileColor: isSelected
                          ? AppColors.primary.withAlpha(20)
                          : (isDark ? Colors.white.withAlpha(8) : Colors.black.withAlpha(6)),
                      leading: Text(
                        b.gender == 'girl' ? '👧' : '👶',
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        b.name,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(b.getAgeDisplay()),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle_rounded,
                              color: AppColors.primary)
                          : null,
                      onTap: () {
                        AppHaptics.selection();
                        ref
                            .read(childProfileControllerProvider.notifier)
                            .setActiveChild(b.childId);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 8. DIALOG THÊM BÉ MỚI ────────────────────────────────────────────────

  void _showAddChildDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    DateTime birthDate = DateTime.now();
    String gender = 'boy';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text('Thêm Hồ Sơ Bé 🍼', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Tên thân mật của bé',
                      hintText: 'Ví dụ: Bé Bơ, Bé Đậu',
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Chọn giới tính
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Text('👶'),
                          label: const Text('Bé Trai'),
                          selected: gender == 'boy',
                          onSelected: (v) => setDialogState(() => gender = 'boy'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          avatar: const Text('👧'),
                          label: const Text('Bé Gái'),
                          selected: gender == 'girl',
                          onSelected: (v) => setDialogState(() => gender = 'girl'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Ngày sinh
                  ListTile(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    tileColor: Theme.of(ctx).brightness == Brightness.dark
                        ? Colors.white10
                        : Colors.black.withAlpha(8),
                    leading: const Icon(Icons.cake_outlined),
                    title: const Text('Ngày sinh của bé', style: TextStyle(fontSize: 13)),
                    subtitle: Text(
                      DateFormat('dd/MM/yyyy').format(birthDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogCtx,
                        initialDate: birthDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 1095)), // 3 năm
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => birthDate = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    AppHaptics.medium();

                    final newChild = ChildProfileModel(
                      childId: 'child_${DateTime.now().millisecondsSinceEpoch}',
                      parentUid: '',
                      name: nameCtrl.text.trim(),
                      birthDate: birthDate,
                      gender: gender,
                      createdAt: DateTime.now(),
                    );

                    await ref
                        .read(childProfileControllerProvider.notifier)
                        .addChild(newChild);

                    if (dialogCtx.mounted) {
                      Navigator.pop(dialogCtx);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Lưu Bé'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── 9. DIALOG ĐÁNH DẤU KINH NGUYỆT TRỞ LẠI (LAM) ──────────────────────────

  void _showMensesToggleDialog(BuildContext context, LamState lamState) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Kinh Nguyệt Sau Sinh', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            lamState.hasMensesReturned
                ? 'Bạn có muốn hủy đánh dấu và xác nhận kinh nguyệt CHƯA trở lại?'
                : 'Đánh dấu kinh nguyệt đã trở lại sẽ kết thúc hiệu lực của Phương pháp vô kinh LAM và bật lại các cảnh báo tránh thai.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                AppHaptics.medium();
                await ref
                    .read(lamStatusControllerProvider.notifier)
                    .setMensesReturned(!lamState.hasMensesReturned);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text(lamState.hasMensesReturned ? 'Chưa có kinh lại' : 'Xác nhận có kinh lại'),
            ),
          ],
        );
      },
    );
  }

  // ── 10. CHUYỂN ĐỔI CHẾ ĐỘ CHỮA LÀNH ──────────────────────────────────────

  Future<void> _handleTogglePauseMode(bool currentIsPaused) async {
    AppHaptics.selection();
    if (!currentIsPaused) {
      final confirmed = await MoonaConfirmDialog.show(
        context,
        title: 'Tạm Dừng Chế Độ Nuôi Con?',
        message:
            'Chế độ này sẽ ẩn toàn bộ thông tin cữ bú, giấc ngủ của bé để mẹ có không gian nghỉ ngơi tĩnh tâm và phục hồi thể chất.',
        icon: Icons.spa_outlined,
        confirmText: 'Bật chế độ Chữa Lành',
        cancelText: 'Hủy',
        isDestructive: false,
      );
      if (confirmed == true && mounted) {
        await ref
            .read(lifeStageControllerProvider.notifier)
            .setPauseMode(isPaused: true, reason: 'medical');
      }
    } else {
      await ref
          .read(lifeStageControllerProvider.notifier)
          .setPauseMode(isPaused: false);
    }
  }
}
