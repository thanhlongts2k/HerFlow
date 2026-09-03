// lib/features/settings/presentation/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/app_version_provider.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/husband_view/presentation/screens/husband_view_screen.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';

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
          // ── NHÓM 1: BẢO MẬT & RIÊNG TƯ ──────────────────────────
          _SectionHeader(
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
            activeThumbColor: AppColors.primary,
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

          // ── NHÓM 2: VAI TRÒ ỨNG DỤNG ─────────────────────────────
          _SectionHeader(
            icon: Icons.badge_outlined,
            title: 'Vai Trò Ứng Dụng',
            color: AppColors.secondary,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: _RoleCard(
                    role: UserRole.wife,
                    isSelected: currentRole == UserRole.wife,
                    title: 'Tôi là Vợ',
                    subtitle: 'Theo dõi chu kỳ',
                    emoji: '🌸',
                    selectedColor: AppColors.primary,
                    onTap: () async {
                      await ref.read(userRoleProvider.notifier).setRole(UserRole.wife);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RoleCard(
                    role: UserRole.husband,
                    isSelected: currentRole == UserRole.husband,
                    title: 'Tôi là Chồng',
                    subtitle: 'Đồng hành cùng nàng',
                    emoji: '🛡️',
                    selectedColor: AppColors.secondary,
                    onTap: () async {
                      await ref.read(userRoleProvider.notifier).setRole(UserRole.husband);
                    },
                  ),
                ),
              ],
            ),
          ),

          _SettingsDivider(),

          // ── NHÓM 3: ĐỒNG BỘ CẶP ĐÔI ─────────────────────────────
          _SectionHeader(
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

          _SettingsDivider(),

          // ── NHÓM 3: GIAO DIỆN ─────────────────────────────────────
          _SectionHeader(
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
            activeThumbColor: Colors.purple,
            onChanged: (val) async {
              final box = Hive.box(AppConstants.settingsBoxName);
              await box.put('haptic_enabled', val);
              ref.read(_hapticEnabledProvider.notifier).state = val;
            },
          ),

          _SettingsDivider(),

          // ── NHÓM 4: DỮ LIỆU & GIỚI THIỆU ───────────────────────
          _SectionHeader(
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

          // Phiên bản động từ package_info_plus
          ref.watch(appVersionProvider).when(
            data: (info) => ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.teal.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.info_rounded, color: Colors.teal, size: 20),
              ),
              title: const Text('Phiên bản', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${info.appName} ${info.shortVersion} (Build ${info.buildNumber})',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  info.shortVersion,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.info_rounded, color: Colors.teal),
              title: Text('Phiên bản', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('Đang tải...', style: TextStyle(fontSize: 12)),
            ),
            error: (_, _) => const ListTile(
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

class _RoleCard extends StatelessWidget {
  final UserRole role;
  final bool isSelected;
  final String title;
  final String subtitle;
  final String emoji;
  final Color selectedColor;
  final VoidCallback onTap;

  const _RoleCard({
    required this.role,
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.selectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withAlpha(isDark ? 45 : 25)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : (isDark ? AppColors.dividerDark : AppColors.dividerLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 20)),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, size: 18, color: selectedColor)
                else
                  Icon(Icons.radio_button_unchecked_rounded, size: 18, color: Colors.grey.withAlpha(120)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: isSelected ? selectedColor : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

