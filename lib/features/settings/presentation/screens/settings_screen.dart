// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/app_version_provider.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/routes/app_routes.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/core/widgets/moona_brand_logo.dart';
import 'package:herflow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:herflow/features/cycle/domain/entities/cycle_info.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/husband_view/presentation/screens/husband_view_screen.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';
import 'package:herflow/features/settings/domain/models/nickname_config.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';
import 'package:herflow/core/services/app_update_service.dart';
import 'package:herflow/core/widgets/app_update_dialog.dart';

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

          _SettingsDivider(),

          // ── NHÓM 2: VAI TRÒ ỨNG DỤNG (READ-ONLY BADGE) ───────────
          _SectionHeader(
            icon: Icons.badge_outlined,
            title: 'Vai Trò Ứng Dụng',
            color: currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                                  ? '🌸 Tài khoản: Phụ nữ'
                                  : '🛡️ Tài khoản: Người thương',
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary).withAlpha(isDark ? 35 : 20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (currentRole == UserRole.wife ? AppColors.primary : AppColors.secondary).withAlpha(60),
                          ),
                        ),
                        child: const Text(
                          'Cố định',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Vai trò được gắn cố định với tài khoản Google đang đăng nhập.',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white54 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),

          _SettingsDivider(),

          // ── NHÓM: HỒ SƠ & DANH XƯNG (NICKNAME ENGINE) ──────────
          _buildNicknameSection(context, ref, isDark, nicknameConfig),

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
            trailing: TextButton(
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
              child: Text(
                isConnected ? 'Quản lý' : 'Kết nối ngay',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),

          // Lối tắt xem trước giao diện của Chồng (nếu đang ở vai trò Vợ)
          if (currentRole == UserRole.wife)
            ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.secondary, size: 20),
              ),
              title: const Text('Xem trước Góc nhìn của Chồng', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Xem giao diện người bạn đời sẽ nhìn thấy', style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HusbandViewScreen(isWifePreview: true),
                  ),
                );
              },
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
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Đăng xuất'),
                  content: const Text('Bạn có chắc muốn đăng xuất khỏi tài khoản này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
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

  Widget _buildNicknameSection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    NicknameConfig nicknameConfig,
  ) {
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
          child: Column(
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
          ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Nhập danh xưng yêu thích...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                onSave(text);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Lưu'),
          ),
        ],
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

                      final settingsBox = Hive.box(AppConstants.settingsBoxName);
                      await settingsBox.put(AppConstants.keyLastPeriodStart, selectedDate.toIso8601String());
                      await settingsBox.put(AppConstants.keyCycleLength, cycleLen);
                      await settingsBox.put(AppConstants.keyPeriodDuration, periodDur);

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

