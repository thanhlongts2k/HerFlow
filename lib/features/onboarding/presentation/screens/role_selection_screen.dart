import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/routes/app_routes.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';

/// Màn hình Phân định Vai Trò (Role Selection) sau khi đăng nhập
class RoleSelectionScreen extends ConsumerStatefulWidget {
  const RoleSelectionScreen({super.key});

  static const String routeName = '/role_selection';

  @override
  ConsumerState<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends ConsumerState<RoleSelectionScreen> {
  Future<void> _selectWifeRole() async {
    AppHaptics.selection();
    final settingsBox = Hive.box(AppConstants.settingsBoxName);
    await settingsBox.put(AppConstants.keyHasSelectedRole, true);
    final uid = ref.read(currentUserProvider)?.uid;
    await ref.read(userRoleProvider.notifier).setRole(UserRole.wife, uid: uid);

    if (mounted) {
      // Chuyển sang 3 bước thiết lập chu kỳ cá nhân
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    }
  }

  void _showHusbandOptions() {
    AppHaptics.selection();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(100),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shield_rounded, color: AppColors.secondary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Lựa Chọn Dành Cho Người Thương',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Chọn phương thức để bắt đầu đồng hành cùng người phụ nữ của bạn:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),

            // Lựa chọn 1: Nhập mã kết nối từ nàng
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () async {
                Navigator.pop(ctx);
                final settingsBox = Hive.box(AppConstants.settingsBoxName);
                await settingsBox.put(AppConstants.keyHasSelectedRole, true);
                await settingsBox.put(AppConstants.keyIsOnboardingCompleted, true);
                final uid = ref.read(currentUserProvider)?.uid;
                await ref.read(userRoleProvider.notifier).setRole(UserRole.husband, uid: uid);

                if (mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const PairingScreen(initialIndex: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.secondary.withAlpha(70)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppColors.secondary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Đã có mã ghép đôi từ nàng',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Nhập mã 6 ký tự để kết nối trực tiếp và nhận dữ liệu thời gian thực từ máy nàng.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.secondary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Lựa chọn 2: Tự thiết lập chu kỳ của nàng
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                Navigator.pop(ctx);
                _showPartnerCycleSetupDialog();
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.primary.withAlpha(70)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tự thiết lập chu kỳ của nàng',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Chủ động ghi nhận ngày kinh và chu kỳ của nàng để tự theo dõi khi nàng chưa cài app.',
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// Dialog nhập chu kỳ của nàng dành cho Người thương theo dõi độc lập
  void _showPartnerCycleSetupDialog() {
    DateTime selectedDate = DateTime.now().subtract(const Duration(days: 14));
    int cycleLength = 28;
    int periodDuration = 5;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(100),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Thiết Lập Chu Kỳ Của Nàng',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text(
                            'Kỳ kinh gần nhất của nàng bắt đầu khi nào?',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          CalendarDatePicker(
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 60)),
                            lastDate: DateTime.now(),
                            onDateChanged: (date) => setModalState(() => selectedDate = date),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Độ dài chu kỳ nàng:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.secondary),
                                    onPressed: cycleLength > 21
                                        ? () => setModalState(() => cycleLength--)
                                        : null,
                                  ),
                                  Text(
                                    '$cycleLength ngày',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                                    onPressed: cycleLength < 45
                                        ? () => setModalState(() => cycleLength++)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Số ngày hành kinh:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.secondary),
                                    onPressed: periodDuration > 2
                                        ? () => setModalState(() => periodDuration--)
                                        : null,
                                  ),
                                  Text(
                                    '$periodDuration ngày',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                                    onPressed: periodDuration < 10
                                        ? () => setModalState(() => periodDuration++)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  // Nút Hoàn tất
                  ElevatedButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      Navigator.pop(ctx);
                      AppHaptics.success();

                      final settingsBox = Hive.box(AppConstants.settingsBoxName);
                      await settingsBox.put(AppConstants.keyLastPeriodStart, selectedDate.toIso8601String());
                      await settingsBox.put(AppConstants.keyCycleLength, cycleLength);
                      await settingsBox.put(AppConstants.keyPeriodDuration, periodDuration);
                      await settingsBox.put(AppConstants.keyHasSelectedRole, true);
                      await settingsBox.put(AppConstants.keyIsOnboardingCompleted, true);

                      // Cập nhật CycleController
                      await ref.read(cycleControllerProvider.notifier).setLastPeriodStart(selectedDate);
                      await ref.read(cycleControllerProvider.notifier).setCycleLength(cycleLength);
                      await ref.read(cycleControllerProvider.notifier).setPeriodDuration(periodDuration);

                      // Gán vai trò Chồng
                      final uid = ref.read(currentUserProvider)?.uid;
                      await ref.read(userRoleProvider.notifier).setRole(UserRole.husband, uid: uid);

                      if (!mounted) return;
                      navigator.pushReplacementNamed(AppRoutes.home);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Hoàn tất & Mở Góc Nhìn Của Anh 🛡️',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Người dùng đã đăng nhập
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary.withAlpha(40),
                    backgroundImage: currentUser?.photoUrl != null && currentUser!.photoUrl!.isNotEmpty
                        ? NetworkImage(currentUser.photoUrl!)
                        : null,
                    child: currentUser?.photoUrl == null
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Xin chào, ${currentUser?.displayName ?? 'bạn'} ✨',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser?.email ?? '',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              Text(
                'Bạn sử dụng Moona với vai trò nào?',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Moona sẽ thiết kế không gian và giao diện dành riêng cho bạn:',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),

              const SizedBox(height: 24),

              // Thẻ 1: Tôi là Phụ nữ
              _buildRoleCard(
                context,
                title: 'Tôi là Phụ nữ',
                subtitle: 'Theo dõi chu kỳ sinh học của bản thân, ghi nhật ký cảm xúc & sức khỏe',
                emoji: '🌸',
                gradientColors: [
                  AppColors.primary.withAlpha(isDark ? 50 : 25),
                  AppColors.primary.withAlpha(isDark ? 15 : 8),
                ],
                borderColor: AppColors.primary,
                onTap: _selectWifeRole,
              ),

              const SizedBox(height: 14),

              // Thẻ 2: Tôi là Người thương
              _buildRoleCard(
                context,
                title: 'Tôi là Người thương',
                subtitle: 'Đồng hành, thấu hiểu thể trạng và chủ động chăm sóc người phụ nữ của bạn',
                emoji: '🛡️',
                gradientColors: [
                  AppColors.secondary.withAlpha(isDark ? 50 : 25),
                  AppColors.secondary.withAlpha(isDark ? 15 : 8),
                ],
                borderColor: AppColors.secondary,
                onTap: _showHusbandOptions,
              ),

              const Spacer(),

              // Ghi chú bảo mật nhẹ nhàng ở chân trang
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock_outline_rounded,
                      size: 13,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Vai trò được lưu bảo mật và gắn chặt với tài khoản của bạn',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required String emoji,
    required List<Color> gradientColors,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 100),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor.withAlpha(isDark ? 90 : 70), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: borderColor.withAlpha(isDark ? 30 : 15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon vai trò trong vòng tròn nền mờ nhẹ
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: borderColor.withAlpha(isDark ? 35 : 25),
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor.withAlpha(50)),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 16),

              // Cột Tiêu đề & Dòng mô tả ngắn gọn
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: borderColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Mũi tên điều hướng
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: borderColor.withAlpha(isDark ? 30 : 15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: borderColor,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
