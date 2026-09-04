// lib/features/backup/presentation/screens/backup_restore_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/widgets/moona_confirm_dialog.dart';
import '../controllers/backup_restore_controller.dart';

/// Màn hình quản lý Sao lưu & Khôi phục dữ liệu toàn diện (Soft Glassmorphic)
class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = ref.watch(backupRestoreControllerProvider);

    // Lắng nghe sự kiện thông báo SnackBar
    ref.listen<BackupRestoreState>(backupRestoreControllerProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(backupRestoreControllerProvider.notifier).clearMessages();
      } else if (next.successMessage != null && next.successMessage != prev?.successMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(next.successMessage!)),
              ],
            ),
            backgroundColor: Colors.teal.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(backupRestoreControllerProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sao Lưu & Khôi Phục', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              // 1. Thẻ Giới Thiệu Bảo Mật AES-256
              _buildSecurityHeaderCard(theme, isDark),
              const SizedBox(height: 24),

              // 2. Nhóm Sao Lưu Đám Mây (Firestore Private Vault)
              _buildCloudBackupSection(context, theme, isDark, state),
              const SizedBox(height: 24),

              // 3. Nhóm Tệp Sao Lưu Cục Bộ (.moona)
              _buildLocalFileSection(context, theme, isDark, state),
              const SizedBox(height: 32),

              // 4. Lưu ý an toàn cho người dùng
              _buildPrivacyNotice(theme),
              const SizedBox(height: 40),
            ],
          ),

          // Loading Overlay
          if (state.isLoading)
            Container(
              color: Colors.black.withAlpha(120),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 18),
                      Text(
                        state.operationStatus ?? 'Đang xử lý...',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── HEADER CARD ───────────────────────────────────────────────────────────

  Widget _buildSecurityHeaderCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.teal.shade900.withAlpha(120), Colors.teal.shade800.withAlpha(60)]
              : [Colors.teal.shade50, Colors.teal.shade100.withAlpha(100)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.teal.withAlpha(isDark ? 60 : 80),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_rounded, color: Colors.teal, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bảo Mật Cấp Quân Sự AES-256',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dữ liệu 5 giai đoạn của bạn được nén GZIP và mã hóa đầu-cuối. '
                  'Khóa giải mã được dẫn xuất riêng biệt từ tài khoản cá nhân, đảm bảo không ai có thể xem trộm.',
                  style: TextStyle(fontSize: 13, height: 1.4, color: theme.textTheme.bodyMedium?.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── CLOUD BACKUP SECTION ──────────────────────────────────────────────────

  Widget _buildCloudBackupSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    BackupRestoreState state,
  ) {
    final meta = state.lastCloudBackup;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 15,
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
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_sync_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sao Lưu Đám Mây (Private Vault)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  meta != null ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: meta != null ? Colors.teal : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meta != null
                        ? 'Bản gần nhất: ${_dateFormat.format(meta.createdAt)} (${_formatBytes(meta.sizeBytes)})'
                        : 'Chưa có bản sao lưu trên đám mây',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          ref.read(backupRestoreControllerProvider.notifier).syncToCloud();
                        },
                  icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                  label: const Text('Sao Lưu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final confirmed = await MoonaConfirmDialog.show(
                            context,
                            title: 'Khôi Phục Từ Đám Mây?',
                            message: 'Toàn bộ dữ liệu hiện tại trên thiết bị sẽ được thay thế '
                                'bằng bản sao lưu đám mây. Hành động này không thể hoàn tác.',
                            icon: Icons.cloud_download_rounded,
                            confirmText: 'Khôi phục ngay',
                            isDestructive: true,
                          );

                          if (confirmed == true && context.mounted) {
                            ref.read(backupRestoreControllerProvider.notifier).restoreFromCloud(ref);
                          }
                        },
                  icon: const Icon(Icons.cloud_download_rounded, size: 18),
                  label: const Text('Khôi Phục'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyLarge?.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── LOCAL FILE SECTION ────────────────────────────────────────────────────

  Widget _buildLocalFileSection(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    BackupRestoreState state,
  ) {
    final meta = state.lastLocalBackup;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 10),
            blurRadius: 15,
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
                  color: Colors.indigo.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.file_present_rounded, color: Colors.indigo, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tệp Sao Lưu Cục Bộ (.moona)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withAlpha(10) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  meta != null ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                  size: 16,
                  color: meta != null ? Colors.indigo : Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    meta != null
                        ? 'Lần xuất gần nhất: ${_dateFormat.format(meta.createdAt)} (${_formatBytes(meta.sizeBytes)})'
                        : 'Chưa xuất tệp sao lưu nào',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () {
                          ref.read(backupRestoreControllerProvider.notifier).exportLocal();
                        },
                  icon: const Icon(Icons.share_rounded, size: 18),
                  label: const Text('Xuất Tệp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final confirmed = await MoonaConfirmDialog.show(
                            context,
                            title: 'Khôi Phục Từ Tệp .moona?',
                            message: 'Toàn bộ dữ liệu hiện tại trên thiết bị sẽ được thay thế '
                                'bằng dữ liệu từ tệp sao lưu. Hành động này không thể hoàn tác.',
                            icon: Icons.file_open_rounded,
                            confirmText: 'Chọn tệp & Khôi phục',
                            isDestructive: true,
                          );

                          if (confirmed == true && context.mounted) {
                            ref.read(backupRestoreControllerProvider.notifier).pickAndRestoreLocal(ref);
                          }
                        },
                  icon: const Icon(Icons.file_open_rounded, size: 18),
                  label: const Text('Nhập Tệp'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.textTheme.bodyLarge?.color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── PRIVACY NOTICE ────────────────────────────────────────────────────────

  Widget _buildPrivacyNotice(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock_rounded, size: 14, color: theme.textTheme.bodySmall?.color),
              const SizedBox(width: 6),
              Text(
                'Quyền Riêng Tư Là Ưu Tiên Hàng Đầu',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Moona không bao giờ lưu trữ mật mã hoặc khóa giải mã trên máy chủ. '
            'Chỉ bạn mới có quyền mở khóa dữ liệu sức khỏe của chính mình.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              height: 1.4,
              color: theme.textTheme.bodySmall?.color?.withAlpha(180),
            ),
          ),
        ],
      ),
    );
  }
}
