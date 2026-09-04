import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/core/providers/app_version_provider.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/routes/app_routes.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/moona_brand_logo.dart';
import 'package:herflow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:herflow/features/cycle/domain/entities/cycle_info.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';
import 'package:herflow/features/settings/domain/models/nickname_config.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/pregnancy_setup_sheet.dart';
import 'package:herflow/core/services/app_update_service.dart';
import 'package:herflow/core/widgets/app_update_dialog.dart';
import 'package:herflow/core/widgets/moona_confirm_dialog.dart';

import 'package:herflow/core/theme/theme_controller.dart';

// ────────────────────────────────────────────────────────────
// LOCAL PROVIDERS — quản lý state các switch trong màn hình này
// ────────────────────────────────────────────────────────────

/// Provider đọc/ghi trạng thái khóa sinh trắc học từ Hive settingsBox
final _biometricEnabledProvider = StateProvider<bool>((ref) {
  final box = Hive.box(AppConstants.settingsBoxName);
  return box.get(AppConstants.keyIsBiometricEnabled, defaultValue: false) as bool;
});

/// Provider bật/tắt Haptic Feedback toàn app

final _hapticEnabledProvider = StateProvider<bool>((ref) {
  final box = Hive.box(AppConstants.settingsBoxName);
  return box.get('haptic_enabled', defaultValue: true) as bool;
});

/// Provider thời gian tự động khóa
final _autoLockTimeProvider = StateProvider<int>((ref) {
  final box = Hive.box(AppConstants.settingsBoxName);
  return box.get('auto_lock_minutes', defaultValue: 0) as int; // 0 = ngay lập tức
});

// ────────────────────────────────────────────────────────────
// SETTINGS SCREEN
// ────────────────────────────────────────────────────────────

/// Màn hình cài đặt tổng hợp — thay thế cho các switch bị đặt sai vị trí
/// trong CycleSettingsSheet. Chia thành 4 nhóm rõ ràng:
/// 1. Bảo mật & Riêng tư  2. Đồng bộ Cặp đôi
/// 3. Giao diện           4. Dữ liệu & Giới thiệu
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isBiometricEnabled = ref.watch(_biometricEnabledProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isHapticEnabled = ref.watch(_hapticEnabledProvider);
    final autoLockMinutes = ref.watch(_autoLockTimeProvider);
    final coupleId = ref.watch(savedCoupleIdProvider);
    final isConnected = coupleId != null && coupleId.isNotEmpty;
    final currentRole = ref.watch(userRoleProvider);
    final currentUser = ref.watch(currentUserProvider);
    final nicknameConfig = ref.watch(nicknameConfigProvider);
    final cycleInfo = ref.watch(cycleControllerProvider).valueOrNull;
    final isDark = theme.brightness == Brightness.dark;

    final currentStage = ref.watch(currentLifeStageProvider);
    final lifeStageState = ref.watch(lifeStageControllerProvider);
    final supportsPartner = ref.watch(supportsCompanionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài Đặt',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── HỒ SƠ TÀI KHOẢN GOOGLE ─────────────────────────────
          _buildUserProfileCard(context, ref, isDark, currentUser),

          const SizedBox(height: 6),

          // ── GIAI ĐOẠN CUỘC SỐNG (LIFE STAGE & PAUSE MODE) ────────
          _buildLifeStageCard(
            context,
            ref,
            isDark,
            currentStage,
            lifeStageState,
            currentRole,
            isConnected: isConnected,
          ),

          const SizedBox(height: 6),

          // ── NHÓM 1: BẢO MẬT & RIÊNG TƯ ──────────────────────────
          const _SectionHeader(
            icon: Icons.security_rounded,
            title: 'Bảo Mật & Riêng Tư',
            color: AppColors.primary,
          ),

          // Switch khóa sinh trắc học
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 20),
            ),
            title: const Text('Khóa bằng sinh trắc học', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Yêu cầu vân tay / FaceID khi mở Moona', style: TextStyle(fontSize: 12)),
            value: isBiometricEnabled,
            activeColor: AppColors.primary,
            onChanged: (val) async {
              final box = Hive.box(AppConstants.settingsBoxName);
              await box.put(AppConstants.keyIsBiometricEnabled, val);
              ref.read(_biometricEnabledProvider.notifier).state = val;
            },
          ),

          // Dropdown thời gian tự động khóa
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            child: isBiometricEnabled
                ? ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                    ),
                    title: const Text('Tự động khóa', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Sau bao lâu không dùng thì khóa', style: TextStyle(fontSize: 12)),
                    trailing: DropdownButton<int>(
                      value: autoLockMinutes,
                      underline: const SizedBox.shrink(),
                      borderRadius: BorderRadius.circular(12),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('Ngay lập tức')),
                        DropdownMenuItem(value: 1, child: Text('Sau 1 phút')),
                        DropdownMenuItem(value: 5, child: Text('Sau 5 phút')),
                        DropdownMenuItem(value: 15, child: Text('Sau 15 phút')),
                      ],
                      onChanged: (val) async {
                        if (val == null) return;
                        final box = Hive.box(AppConstants.settingsBoxName);
                        await box.put('auto_lock_minutes', val);
                        ref.read(_autoLockTimeProvider.notifier).state = val;
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // ── CÁC CẤU HÌNH CẶP ĐÔI (CHỈ HIỆN KHI Ở CHẾ ĐỘ HỖ TRỢ ĐỒNG HÀNH - KHÔNG PHẢI SOLO) ──
          if (supportsPartner) ...[
            _SettingsDivider(),

            // ── NHÓM 2: VAI TRÒ ỨNG DỤNG (READ-ONLY BADGE) ───────────
            _SectionHeader(
              icon: Icons.badge_outlined,
              title: 'Vai Trò Ứng Dụng',
              color: currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  AppHaptics.light();
                  _showRoleSelectionBottomSheet(context, ref, currentRole, isConnected);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : AppColors.cardLight,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: (currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary).withAlpha(isDark ? 80 : 50),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: (currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary).withAlpha(isDark ? 40 : 25),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              currentRole == UserRole.wife ? '🌸' : '🛡️',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentRole == UserRole.wife
                                      ? '🌸 Vai trò: Phụ nữ (Vợ)'
                                      : '🛡️ Vai trò: Người thương (Chồng)',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentRole == UserRole.wife
                                      ? 'Theo dõi chu kỳ sinh học'
                                      : 'Đồng hành & Chăm sóc nàng',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: (currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary).withAlpha(isDark ? 45 : 30),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: (currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary).withAlpha(80),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  isConnected ? 'Hoán đổi' : 'Đổi vai trò',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            isConnected ? Icons.swap_horiz_rounded : Icons.touch_app_rounded,
                            size: 14,
                            color: isDark ? Colors.white54 : Colors.grey[700],
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isConnected
                                  ? 'Đang kết nối cặp đôi. Chạm để hoán đổi góc nhìn giữa Vợ và Chồng.'
                                  : 'Chạm để chuyển đổi linh hoạt giữa giao diện Vợ và Chồng.',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white54 : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            _SettingsDivider(),

            // ── NHÓM: HỒ SƠ & DANH XƯNG (NICKNAME ENGINE) ──────────
            _buildNicknameSection(
              context,
              ref,
              isDark,
              nicknameConfig,
              isConnected: isConnected,
              currentRole: currentRole,
            ),

            _SettingsDivider(),

            // ── NHÓM 3: ĐỒNG BỘ CẶP ĐÔI ─────────────────────────────
            const _SectionHeader(
              icon: Icons.favorite_rounded,
              title: 'Đồng Bộ Cặp Đôi',
              color: AppColors.secondary,
            ),

            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (isConnected ? AppColors.success : Colors.grey).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isConnected ? Icons.link_rounded : Icons.link_off_rounded,
                  color: isConnected ? AppColors.success : Colors.grey,
                  size: 20,
                ),
              ),
              title: const Text('Trạng thái kết nối', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                isConnected ? 'Đã kết nối với đối phương 💑' : 'Chưa ghép đôi',
                style: TextStyle(
                  fontSize: 12,
                  color: isConnected ? AppColors.success : Colors.grey,
                  fontWeight: isConnected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
              onTap: isConnected
                  ? () => _showConnectionManagementSheet(context, ref)
                  : null,
              trailing: isConnected
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () => _showConnectionManagementSheet(context, ref),
                          child: const Text(
                            'Quản lý',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.link_off_rounded, color: AppColors.error, size: 20),
                          tooltip: 'Hủy kết nối',
                          onPressed: () async {
                            final confirmed = await MoonaConfirmDialog.show(
                              context,
                              title: 'Hủy Kết Nối Cặp Đôi?',
                              message:
                                  'Bạn và Người thương sẽ ngắt kết nối đồng bộ dữ liệu thời gian thực. Cả hai sẽ cần nhập mã ghép đôi mới nếu muốn kết nối lại.',
                              icon: Icons.link_off_rounded,
                              confirmText: 'Hủy kết nối',
                              cancelText: 'Giữ kết nối',
                              isDestructive: true,
                              cooldownSeconds: 10,
                              cooldownConfirmText: 'Tôi chắc chắn muốn hủy kết nối',
                            );
                            if (confirmed == true) {
                              await ref.read(partnerSyncControllerProvider.notifier).disconnect();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Đã hủy kết nối cặp đôi thành công.'),
                                    backgroundColor: AppColors.primary,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    )
                  : TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PairingScreen(
                              initialIndex: currentRole == UserRole.husband ? 1 : 0,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Kết nối ngay',
                        style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                      ),
                    ),
            ),

            // ── NHÓM: CHU KỲ CỦA NÀNG (DÀNH CHO NGƯỜI THƯƠNG) ───────
            if (currentRole == UserRole.husband) ...[
              _SettingsDivider(),
              _buildPartnerCycleSection(
                context,
                ref,
                isDark,
                cycleInfo,
                nicknameConfig.callPartnerAs,
              ),
            ],
          ],

          _SettingsDivider(),

          // ── NHÓM 3: GIAO DIỆN ─────────────────────────────────────
          const _SectionHeader(
            icon: Icons.palette_outlined,
            title: 'Giao Diện',
            color: Colors.purple,
          ),

          // Chọn Theme
          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.brightness_6_rounded, color: Colors.purple, size: 20),
            ),
            title: const Text('Chủ đề giao diện', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              _themeModeLabel(themeMode),
              style: const TextStyle(fontSize: 12),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_rounded, size: 16),
                  label: Text('Sáng'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_rounded, size: 16),
                  label: Text('Hệ thống'),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_rounded, size: 16),
                  label: Text('Tối'),
                ),
              ],
              selected: {themeMode},
              style: ButtonStyle(
                side: WidgetStateProperty.all(BorderSide(color: AppColors.primary.withAlpha(80))),
              ),
              onSelectionChanged: (Set<ThemeMode> selected) {
                final mode = selected.first;
                ref.read(themeModeProvider.notifier).setThemeMode(mode);
              },
            ),
          ),

          const SizedBox(height: 8),

          // Switch Haptic Feedback
          SwitchListTile(
            secondary: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.purple.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.vibration_rounded, color: Colors.purple, size: 20),
            ),
            title: const Text('Phản hồi xúc giác (Haptic)', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Rung nhẹ khi tương tác với ứng dụng', style: TextStyle(fontSize: 12)),
            value: isHapticEnabled,
            activeColor: Colors.purple,
            onChanged: (val) async {
              final box = Hive.box(AppConstants.settingsBoxName);
              await box.put('haptic_enabled', val);
              ref.read(_hapticEnabledProvider.notifier).state = val;
            },
          ),

          _SettingsDivider(),

          // ── NHÓM 4: DỮ LIỆU & GIỚI THIỆU ───────────────────────
          const _SectionHeader(
            icon: Icons.info_outline_rounded,
            title: 'Dữ Liệu & Giới Thiệu',
            color: Colors.teal,
          ),

          ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.teal.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.teal, size: 20),
            ),
            title: const Text('Sao lưu & Khôi phục', style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text('Xuất / nhập file .moona mã hóa AES-256', style: TextStyle(fontSize: 12)),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng Backup sẽ khả dụng trong v0.4.0')),
              );
            },
          ),

          // Phiên bản động từ package_info_plus & Kiểm tra cập nhật OTA
          ref.watch(appVersionProvider).when(
            data: (info) => ListTile(
              leading: const MoonaBrandLogo(size: 34, hasShadow: false),
              title: const Text('Phiên bản', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${info.appName} ${info.shortVersion} (Build ${info.buildNumber}) • Nhấn để kiểm tra',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withAlpha(60)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'v${info.shortVersion}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.sync_rounded, size: 12, color: AppColors.primary),
                  ],
                ),
              ),
              onTap: () async {
                AppHaptics.light();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Text('Đang kiểm tra bản cập nhật từ GitHub...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                try {
                  final update = await AppUpdateService.checkForUpdate(forceCheck: true);
                  if (!context.mounted) return;

                  if (update != null) {
                    AppUpdateDialog.show(context, update);
                  } else {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Bạn đang sử dụng phiên bản Moona mới nhất (${info.shortVersion})! ✨'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    );
                  }
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Không thể kiểm tra cập nhật. Vui lòng kiểm tra kết nối mạng Internet! ⚠️'),
                      backgroundColor: Colors.orange.shade800,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  );
                }
              },
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.info_rounded, color: Colors.teal),
              title: Text('Phiên bản', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Đang tải...', style: TextStyle(fontSize: 12)),
            ),
            error: (_, __) => const ListTile(
              leading: Icon(Icons.info_rounded, color: Colors.teal),
              title: Text('Moona'),
              subtitle: Text('v0.3.0', style: TextStyle(fontSize: 12)),
            ),
          ),

          const SizedBox(height: 24),

          // Footer tagline
          Center(
            child: Text(
              AppConstants.appTagline,
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey.withAlpha(180)),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showRoleSelectionBottomSheet(
    BuildContext context,
    WidgetRef ref,
    UserRole currentRole,
    bool isConnected,
  ) {
    AppHaptics.medium();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1B2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Chọn Vai Trò Của Bạn',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Moona sẽ cá nhân hóa giao diện và trải nghiệm tương thích theo vai trò.',
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(height: 20),

            // Lựa chọn: Vợ / Phụ nữ
            _buildRoleOptionItem(
              context: ctx,
              title: '🌸 Phụ Nữ (Vợ)',
              subtitle: 'Theo dõi chu kỳ kinh nguyệt, rụng trứng, thể trạng và năng lượng sinh học.',
              isSelected: currentRole == UserRole.wife,
              color: AppColors.primary,
              onTap: () => _handleRoleChange(context, ref, UserRole.wife, currentRole, isConnected),
            ),
            const SizedBox(height: 12),

            // Lựa chọn: Chồng / Người thương
            _buildRoleOptionItem(
              context: ctx,
              title: '🛡️ Người Thương (Chồng)',
              subtitle: 'Trợ lý thấu hiểu, đồng hành, nhận tín hiệu yêu thương và chăm sóc nàng.',
              isSelected: currentRole == UserRole.husband,
              color: AppColors.secondary,
              onTap: () => _handleRoleChange(context, ref, UserRole.husband, currentRole, isConnected),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRoleChange(
    BuildContext context,
    WidgetRef ref,
    UserRole newRole,
    UserRole currentRole,
    bool isConnected,
  ) async {
    Navigator.pop(context); // Đóng BottomSheet
    if (newRole == currentRole) return;

    if (isConnected) {
      // KỊCH BẢN 2: ĐÃ GHÉP ĐÔI -> CẢNH BÁO HOÁN ĐỔI VỊ TRÍ
      final confirm = await MoonaConfirmDialog.show(
        context,
        title: 'Hoán Đổi Vai Trò?',
        message:
            'Bạn đang kết nối với Người thương với tư cách "${currentRole.label}". Đổi sang "${newRole.label}" sẽ hoán đổi vị trí và giao diện đồng hành của cả hai.\n\nBạn có chắc chắn muốn hoán đổi không?',
        icon: Icons.swap_horiz_rounded,
        confirmText: 'Xác nhận hoán đổi',
        cancelText: 'Hủy',
        isDestructive: false,
        customColor: AppColors.secondary,
      );

      if (confirm != true || !context.mounted) return;
    }

    // 1. Cập nhật State trong RAM & Hive cục bộ
    await ref.read(userRoleProvider.notifier).setRole(newRole);
    await ref.read(nicknameConfigProvider.notifier).loadForUser();

    // 2. Đồng bộ vai trò lên Firestore users/{uid}
    final uid = UserScope.currentUid();
    if (uid.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'role': newRole.name,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));

        // Nếu đã ghép đôi, ghi nhận hoán đổi vai trò lên couples/{coupleId}
        final coupleId = ref.read(savedCoupleIdProvider);
        if (coupleId != null && coupleId.isNotEmpty) {
          await FirebaseFirestore.instance.collection('couples').doc(coupleId).set({
            'lastRoleSwapAt': FieldValue.serverTimestamp(),
            'swappedBy': uid,
          }, SetOptions(merge: true)).timeout(const Duration(seconds: 8));
        }
      } catch (e) {
        debugPrint('Sync new role to Firestore error: $e');
      }
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🎉 Đã chuyển sang vai trò ${newRole.label} thành công!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );

      // Nếu đang mở từ push screen, pop về MainNavScreen để refresh giao diện
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  Widget _buildRoleOptionItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withAlpha(isDark ? 45 : 25) : (isDark ? Colors.white10 : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? color : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? color : Colors.grey,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Sáng';
      case ThemeMode.dark:
        return 'Tối';
      default:
        return 'Theo hệ thống';
    }
  }

  Widget _buildUserProfileCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    dynamic currentUser,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withAlpha(40),
            backgroundImage: currentUser?.photoUrl != null && currentUser!.photoUrl!.isNotEmpty
                ? NetworkImage(currentUser.photoUrl!)
                : null,
            child: currentUser?.photoUrl == null
                ? const Icon(Icons.person, color: AppColors.primary, size: 28)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentUser?.displayName ?? 'Người dùng Moona',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  currentUser?.email ?? 'Chưa đăng nhập',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              final confirmed = await MoonaConfirmDialog.show(
                context,
                title: 'Đăng Xuất Tài Khoản?',
                message: 'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Moona trên thiết bị này?',
                icon: Icons.logout_rounded,
                confirmText: 'Đăng xuất',
                cancelText: 'Ở lại',
                isDestructive: true,
              );
              if (confirmed == true) {
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (r) => false);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLifeStageCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    LifeStage currentStage,
    LifeStageState lifeStageState,
    UserRole currentRole, {
    bool isConnected = false,
  }) {
    final isHusband = currentRole == UserRole.husband;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phần Header / Thông tin Giai đoạn
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () {
              AppHaptics.light();
              if (isHusband) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text('Giai đoạn do Vợ làm chủ tiến trình. Tài khoản Chồng chỉ xem.'),
                        ),
                      ],
                    ),
                    backgroundColor: isDark ? const Color(0xFF2C243B) : const Color(0xFF3B334C),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
              _showLifeStageBottomSheet(
                context,
                ref,
                currentStage,
                lifeStageState.isPaused,
                isPaired: isConnected,
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withAlpha(isDark ? 50 : 30),
                          AppColors.secondary.withAlpha(isDark ? 50 : 30),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.primary.withAlpha(isDark ? 60 : 40),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      currentStage.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              currentStage.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isHusband
                                    ? (isDark ? Colors.white12 : Colors.black12)
                                    : AppColors.primary.withAlpha(isDark ? 40 : 25),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                isHusband ? 'Chỉ xem' : 'Đang hoạt động',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isHusband
                                      ? (isDark ? Colors.white60 : Colors.black54)
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentStage.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isHusband ? Icons.lock_outline_rounded : Icons.arrow_forward_ios_rounded,
                    size: isHusband ? 18 : 14,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ],
              ),
            ),
          ),

          // Khi đang ở chế độ Thai kỳ: Hiển thị tóm tắt tuần thai & nút chỉnh sửa ngày dự sinh
          if (currentStage == LifeStage.pregnancy) ...[
            Builder(
              builder: (context) {
                final pregnancyConfig = ref.watch(pregnancyConfigProvider);
                final gestationalAge = ref.watch(currentGestationalAgeProvider);
                final fetalWeek = ref.watch(currentFetalWeekDataProvider);

                if (pregnancyConfig == null || !pregnancyConfig.isTrackingActive || gestationalAge == null) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Text(
                            fetalWeek?.fruitEmoji ?? '👶',
                            style: const TextStyle(fontSize: 22),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bé: ${gestationalAge.formattedAge} • Dự sinh: ${pregnancyConfig.estimatedDueDate != null ? DateFormat('dd/MM/yyyy').format(pregnancyConfig.estimatedDueDate!) : ''}',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (fetalWeek != null)
                                  Text(
                                    'Cỡ ${fetalWeek.fruitName} (${fetalWeek.formattedLength} • ${fetalWeek.formattedWeight})',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (!isHusband)
                            TextButton(
                              onPressed: () => PregnancySetupSheet.show(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Sửa ngày',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],

          Divider(
            height: 1,
            thickness: 1,
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),

          // Công tắc Pause / Loss Mode một chạm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: lifeStageState.isPaused
                        ? const Color(0xFF10B981).withAlpha(25)
                        : (isDark ? Colors.white10 : Colors.black.withAlpha(10)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    lifeStageState.isPaused ? '🌿' : '🕊️',
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Chế độ Tạm dừng / Chữa lành',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (lifeStageState.isPaused) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Bật',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ẩn dự báo & thông báo nhạy cảm khi cần thời gian chữa lành.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: lifeStageState.isPaused,
                  activeColor: const Color(0xFF10B981),
                  onChanged: isHusband
                      ? null
                      : (val) async {
                          AppHaptics.selection();
                          await ref
                              .read(lifeStageControllerProvider.notifier)
                              .setPauseMode(isPaused: val);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  val
                                      ? 'Đã kích hoạt Chế độ Tạm dừng / Chữa lành.'
                                      : 'Đã tắt Chế độ Tạm dừng / Chữa lành.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLifeStageBottomSheet(
    BuildContext context,
    WidgetRef ref,
    LifeStage currentStage,
    bool isPaused, {
    bool isPaired = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1F1B2C) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Text(
                      'Giai Đoạn Cuộc Sống',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(bottomSheetContext),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Chọn giai đoạn phù hợp để Moona tùy biến giao diện và tính năng tương ứng.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                // 5 giai đoạn: Solo, Couple, Conception, Pregnancy, Motherhood
                ...LifeStage.values.map((stage) {
                  final isSelected = stage == currentStage;
                  return _buildLifeStageOptionItem(
                    context: bottomSheetContext,
                    rootContext: context,
                    ref: ref,
                    isDark: isDark,
                    stage: stage,
                    isSelected: isSelected,
                    isPaired: isPaired,
                  );
                }),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLifeStageOptionItem({
    required BuildContext context,
    required BuildContext rootContext,
    required WidgetRef ref,
    required bool isDark,
    required LifeStage stage,
    required bool isSelected,
    required bool isPaired,
  }) {
    final isSoloLocked = stage == LifeStage.solo && isPaired;

    final itemWidget = Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withAlpha(isDark ? 30 : 15)
            : (isDark ? Colors.white.withAlpha(6) : Colors.black.withAlpha(6)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : (isDark ? Colors.white12 : Colors.black12),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          if (isSoloLocked) {
            AppHaptics.light();
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Bạn đang trong chế độ Cặp Đôi. Vui lòng hủy kết nối trước khi chuyển về chế độ Nàng.'),
                    ),
                  ],
                ),
                backgroundColor: isDark ? const Color(0xFF2C243B) : const Color(0xFF3B334C),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }

          AppHaptics.selection();
          Navigator.pop(context);
          if (!isSelected) {
            // Khi chọn chuyển sang Thai Kỳ mà chưa có cấu hình thai kỳ -> mở PregnancySetupSheet
            if (stage == LifeStage.pregnancy) {
              final pregnancyConfig = ref.read(pregnancyConfigProvider);
              if (pregnancyConfig == null || !pregnancyConfig.isTrackingActive) {
                final configured = await PregnancySetupSheet.show(rootContext);
                if (configured == true && rootContext.mounted) {
                  ScaffoldMessenger.of(rootContext).showSnackBar(
                    SnackBar(
                      content: const Text('Đã thiết lập thai kỳ & chuyển sang giai đoạn "Thai Kỳ" 🤰'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
                return;
              }
            }

            await ref.read(lifeStageControllerProvider.notifier).switchStage(stage);
            if (rootContext.mounted) {
              ScaffoldMessenger.of(rootContext).showSnackBar(
                SnackBar(
                  content: Text('Đã chuyển sang giai đoạn "${stage.displayName}".'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Text(
                stage.icon,
                style: const TextStyle(fontSize: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          stage.displayName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppColors.primary : null,
                          ),
                        ),
                        if (isSoloLocked) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.black12,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  size: 11,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cần hủy ghép đôi',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stage.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSoloLocked)
                Icon(
                  Icons.lock_rounded,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 20,
                )
              else if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );

    if (isSoloLocked) {
      return Opacity(
        opacity: 0.5,
        child: itemWidget,
      );
    }
    return itemWidget;
  }

  Widget _buildNicknameSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    NicknameConfig nicknameConfig, {
    required bool isConnected,
    required UserRole currentRole,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          icon: Icons.favorite_outline_rounded,
          title: 'Hồ Sơ & Danh Xưng',
          color: AppColors.primary,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: (isConnected && currentRole == UserRole.husband)
              ? _buildWifeLedNicknameCard(context, isDark, nicknameConfig)
              : _buildEditableNicknameForm(context, ref, isDark, nicknameConfig),
        ),
      ],
    );
  }

  /// Thẻ hiển thị tĩnh (Read-Only) phong cách mềm mại dành riêng cho Chồng khi đã ghép đôi
  /// Thể hiện nguyên tắc: "Phân quyền danh xưng theo ý Vợ" (Wife-Led Nicknames)
  Widget _buildWifeLedNicknameCard(
    BuildContext context,
    bool isDark,
    NicknameConfig nicknameConfig,
  ) {
    final sheCallsYou = nicknameConfig.partnerCallsMeAs.isNotEmpty
        ? nicknameConfig.partnerCallsMeAs
        : 'Anh';
    final sheWantsYouToCallHer = nicknameConfig.callPartnerAs.isNotEmpty
        ? nicknameConfig.callPartnerAs
        : 'Em bé';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.secondary.withAlpha(25)
            : const Color(0xFFFFF0F5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withAlpha(isDark ? 70 : 90),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(isDark ? 20 : 15),
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
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Danh Xưng Do Cô Ấy Quyết Định 💕',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Khi đã ghép đôi, danh xưng được đồng bộ trực tiếp theo ý nàng.',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mục 1: Cô ấy gọi bạn là
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withAlpha(isDark ? 20 : 10)),
            ),
            child: Row(
              children: [
                const Text('🌸', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cô ấy gọi bạn là:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sheCallsYou,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Mục 2: Cô ấy muốn bạn gọi cô ấy là
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withAlpha(isDark ? 20 : 10)),
            ),
            child: Row(
              children: [
                const Text('💖', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cô ấy muốn bạn gọi cô ấy là:',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sheWantsYouToCallHer,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Live Preview
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(isDark ? 25 : 15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('💬', style: TextStyle(fontSize: 15)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Xem trước: "$sheCallsYou vừa gửi tín hiệu yêu thương cho $sheWantsYouToCallHer 💕"',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : AppColors.primary,
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

  Widget _buildEditableNicknameForm(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    NicknameConfig nicknameConfig,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Bạn gọi người ấy là
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bạn gọi người ấy là:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            TextButton.icon(
              onPressed: () => _showCustomNicknameDialog(
                context,
                title: 'Cách bạn gọi người ấy',
                currentValue: nicknameConfig.callPartnerAs,
                onSave: (val) => ref.read(nicknameConfigProvider.notifier).setCallPartnerAs(val),
              ),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('Tự gõ', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: NicknameConfig.presets.map((name) {
              final isSel = nicknameConfig.callPartnerAs == name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(name),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      ref.read(nicknameConfigProvider.notifier).setCallPartnerAs(name);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Bạn tự xưng với người ấy là
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Bạn tự xưng là:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            TextButton.icon(
              onPressed: () => _showCustomNicknameDialog(
                context,
                title: 'Cách bạn tự xưng',
                currentValue: nicknameConfig.selfCallAs,
                onSave: (val) => ref.read(nicknameConfigProvider.notifier).setSelfCallAs(val),
              ),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('Tự gõ', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: NicknameConfig.presets.map((name) {
              final isSel = nicknameConfig.selfCallAs == name;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(name),
                  selected: isSel,
                  selectedColor: AppColors.secondary,
                  labelStyle: TextStyle(
                    color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) {
                      ref.read(nicknameConfigProvider.notifier).setSelfCallAs(name);
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Live Preview Card
        Builder(
          builder: (context) {
            final isSame = nicknameConfig.selfCallAs.trim().toLowerCase() ==
                nicknameConfig.callPartnerAs.trim().toLowerCase();
            final selfDisplay = isSame ? '${nicknameConfig.selfCallAs} (Bạn)' : nicknameConfig.selfCallAs;
            final partnerDisplay = isSame ? '${nicknameConfig.callPartnerAs} (Người ấy)' : nicknameConfig.callPartnerAs;
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(isDark ? 25 : 15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withAlpha(isDark ? 60 : 40)),
              ),
              child: Row(
                children: [
                  const Text('💬', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Xem trước: "$selfDisplay vừa gửi tín hiệu yêu thương cho $partnerDisplay 💕"',
                      style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPartnerCycleSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    CycleInfo? cycleInfo,
    String partnerName,
  ) {
    final lastStart = cycleInfo?.lastPeriodStart ?? DateTime.now().subtract(const Duration(days: 14));
    final lastStartStr = DateFormat('dd/MM/yyyy').format(lastStart);
    final cycleLen = cycleInfo?.cycleLength ?? 28;
    final periodDur = cycleInfo?.periodDuration ?? 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          icon: Icons.calendar_today_rounded,
          title: 'Chu Kỳ Của $partnerName',
          color: AppColors.primary,
        ),
        ListTile(
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.edit_calendar_rounded, color: AppColors.primary, size: 20),
          ),
          title: Text('Thông số chu kỳ của $partnerName', style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            'Kỳ gần nhất: $lastStartStr • Chu kỳ: $cycleLen ngày • Hành kinh: $periodDur ngày',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: ElevatedButton(
            onPressed: () => _showEditPartnerCycleModal(context, ref, lastStart, cycleLen, periodDur, partnerName),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Hiệu chỉnh', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  void _showCustomNicknameDialog(
    BuildContext context, {
    required String title,
    required String currentValue,
    required ValueChanged<String> onSave,
  }) {
    final controller = TextEditingController(text: currentValue);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(25) : Colors.black.withAlpha(15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 140 : 35),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withAlpha(isDark ? 80 : 60),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Nhập danh xưng yêu thích...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          AppHaptics.light();
                          Navigator.pop(ctx);
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Hủy', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final text = controller.text.trim();
                          if (text.isNotEmpty) {
                            AppHaptics.medium();
                            onSave(text);
                          }
                          Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditPartnerCycleModal(
    BuildContext context,
    WidgetRef ref,
    DateTime initialDate,
    int initialCycleLen,
    int initialPeriodDur,
    String partnerName,
  ) {
    DateTime selectedDate = initialDate;
    int cycleLen = initialCycleLen;
    int periodDur = initialPeriodDur;

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
                      Text(
                        'Hiệu Chỉnh Chu Kỳ $partnerName',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
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
                          const Text(
                            'Kỳ kinh gần nhất bắt đầu vào ngày nào?',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          CalendarDatePicker(
                            initialDate: selectedDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 90)),
                            lastDate: DateTime.now().add(const Duration(days: 1)),
                            onDateChanged: (date) => setModalState(() => selectedDate = date),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Độ dài chu kỳ trung bình:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.secondary),
                                    onPressed: cycleLen > 21
                                        ? () => setModalState(() => cycleLen--)
                                        : null,
                                  ),
                                  Text(
                                    '$cycleLen ngày',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                                    onPressed: cycleLen < 45
                                        ? () => setModalState(() => cycleLen++)
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
                                    onPressed: periodDur > 2
                                        ? () => setModalState(() => periodDur--)
                                        : null,
                                  ),
                                  Text(
                                    '$periodDur ngày',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppColors.secondary),
                                    onPressed: periodDur < 10
                                        ? () => setModalState(() => periodDur++)
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
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      AppHaptics.success();

                      await ref.read(cycleControllerProvider.notifier).setLastPeriodStart(selectedDate);
                      await ref.read(cycleControllerProvider.notifier).setCycleLength(cycleLen);
                      await ref.read(cycleControllerProvider.notifier).setPeriodDuration(periodDur);

                      // Đồng bộ nếu đã ghép đôi
                      ref.read(partnerSyncControllerProvider.notifier).syncTodayStatus();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã cập nhật chu kỳ của $partnerName thành công! 💕'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text(
                      'Lưu Cập Nhật',
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

  /// Modal BottomSheet Quản Lý Trạng Thái Kết Nối Đôi Lứa
  void _showConnectionManagementSheet(BuildContext context, WidgetRef ref) {
    try {
      AppHaptics.selection();
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final savedCoupleId = ref.read(savedCoupleIdProvider);
      final pairingState = ref.read(partnerSyncControllerProvider);
      final nicknameConfig = ref.read(nicknameConfigProvider);
      final currentRole = ref.read(userRoleProvider);

      final partnerName = nicknameConfig.callPartnerAs.isNotEmpty
          ? nicknameConfig.callPartnerAs
          : (currentRole == UserRole.husband ? 'Em bé' : 'Anh');

      final pairingCode = pairingState.activePairingCode;
      final coupleId = savedCoupleId;
      final rawCoupleId = coupleId ?? '';

      // Fallback an toàn tuyệt đối theo đúng đặc tả:
      // final codeToCopy = pairingCode ?? coupleId ?? 'MOONA-CONNECTED';
      final String codeToCopy = (pairingCode != null && pairingCode.trim().isNotEmpty)
          ? pairingCode.trim()
          : ((coupleId != null && coupleId.trim().isNotEmpty)
              ? coupleId.trim()
              : 'MOONA-CONNECTED');

      // Ưu tiên hiển thị mã 6 ký tự nếu còn lưu, nếu không thì hiển thị 8 ký tự của coupleId
      final String displayCode = (pairingCode != null && pairingCode.trim().isNotEmpty)
          ? pairingCode.trim()
          : (rawCoupleId.trim().isNotEmpty
              ? (rawCoupleId.trim().length >= 8
                  ? rawCoupleId.trim().substring(0, 8).toUpperCase()
                  : rawCoupleId.trim().toUpperCase())
              : 'MOONA-CONNECTED');

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (modalContext) {
          return Container(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 80 : 30),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thanh Handle Bar
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(80),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Icon & Tiêu đề
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success.withAlpha(isDark ? 40 : 25),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.success,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Quản Lý Kết Nối Đôi Lứa 💕',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Đang kết nối cùng $partnerName',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Hộp hiển thị Mã Ghép Đôi / Mã Cặp Đôi
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark
                        : AppColors.primaryContainer.withAlpha(45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(isDark ? 80 : 100),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'MÃ KẾT NỐI LIÊN KẾT',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: AppColors.primary.withAlpha(200),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        displayCode,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          fontFamily: 'monospace',
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          try {
                            AppHaptics.light();
                            final textToCopy = codeToCopy.isNotEmpty ? codeToCopy : 'MOONA-CONNECTED';
                            await Clipboard.setData(ClipboardData(text: textToCopy));
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                      SizedBox(width: 8),
                                      Text('Đã sao chép mã liên kết vào khay nhớ tạm! 📋'),
                                    ],
                                  ),
                                  backgroundColor: AppColors.secondary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e, stack) {
                            debugPrint('Error copying code to clipboard: $e\n$stack');
                          }
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text(
                          'Sao chép mã',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Thông tin trạng thái kỹ thuật
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withAlpha(10) : Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Vai trò của bạn:',
                            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                          ),
                          Text(
                            currentRole == UserRole.husband ? 'Chồng 🛡️' : 'Vợ 🌸',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kênh đồng bộ:',
                            style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                          ),
                          const Text(
                            'Firestore Realtime Sync ⚡',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Nút Hủy Kết Nối (Unpair) với xác nhận cảnh báo đỏ
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      AppHaptics.heavy();
                      final confirmed = await MoonaConfirmDialog.show(
                        context,
                        title: 'Hủy Kết Nối Cặp Đôi?',
                        message:
                            'Bạn và $partnerName sẽ ngắt kết nối đồng bộ dữ liệu thời gian thực. Sau khi hủy, cả hai sẽ cần nhập lại mã ghép đôi mới nếu muốn kết nối lại.',
                        icon: Icons.link_off_rounded,
                        confirmText: 'Hủy kết nối',
                        cancelText: 'Giữ kết nối',
                        isDestructive: true,
                        cooldownSeconds: 10,
                        cooldownConfirmText: 'Tôi chắc chắn muốn hủy kết nối',
                      );
                      if (confirmed == true) {
                        if (modalContext.mounted) {
                          Navigator.pop(modalContext);
                        }
                        await ref.read(partnerSyncControllerProvider.notifier).disconnect();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Đã hủy kết nối cặp đôi thành công.'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.link_off_rounded, color: AppColors.error, size: 20),
                    label: const Text(
                      'Hủy kết nối cặp đôi',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.error.withAlpha(120)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Nút Đóng
                TextButton(
                  onPressed: () => Navigator.pop(modalContext),
                  child: Text(
                    'Đóng',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } catch (e, stack) {
      debugPrint('Error showing connection management sheet: $e\n$stack');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không thể mở quản lý kết nối. Vui lòng thử lại.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        );
      }
    }
  }
}

// ────────────────────────────────────────────────────────────
// SHARED WIDGETS
// ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 8, indent: 16, endIndent: 16);
  }
}

