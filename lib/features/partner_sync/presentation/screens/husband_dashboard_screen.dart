// lib/features/partner_sync/presentation/screens/husband_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/domain/models/partner_status_model.dart';

/// Màn hình Dashboard Realtime dành riêng cho Chồng lắng nghe trực tiếp từ Firestore
class HusbandDashboardScreen extends ConsumerWidget {
  const HusbandDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveStatusAsync = ref.watch(partnerLiveStatusStreamProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Của Anh',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const Text(
              'Đồng bộ trực tiếp từ HerFlow của Vợ',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.link_off_rounded),
            tooltip: 'Ngắt kết nối',
            onPressed: () => _confirmDisconnect(context, ref),
          ),
        ],
      ),
      body: liveStatusAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.secondary),
              SizedBox(height: 12),
              Text('Đang kết nối luồng dữ liệu thời gian thực...', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Lỗi kết nối Firestore: $err', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (status) {
          if (status == null) {
            return _buildWaitingForWifeView(context, isDark);
          }
          return _buildRealtimeDashboard(context, status, isDark);
        },
      ),
    );
  }

  /// Trạng thái chờ vợ cập nhật dữ liệu hôm nay
  Widget _buildWaitingForWifeView(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer.withAlpha(isDark ? 50 : 120),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.hourglass_bottom_rounded, size: 48, color: AppColors.secondary),
            ),
            const SizedBox(height: 18),
            const Text(
              'Đang Chờ Vợ Ghi Nhận Hôm Nay',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Thiết bị đã kết nối thành công! Ngay khi vợ mở HerFlow và cập nhật thể trạng, thông tin sẽ hiển thị tức thì tại đây.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  /// Dashboard trực tiếp khi có dữ liệu realtime
  Widget _buildRealtimeDashboard(
    BuildContext context,
    PartnerStatusModel status,
    bool isDark,
  ) {
    final theme = Theme.of(context);
    final phaseColor = _getPhaseColor(status.currentPhase);
    final formattedTime = DateFormat('HH:mm - dd/MM/yyyy').format(status.updatedAt);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. HERO CARD: PHA CHU KỲ & NĂNG LƯỢNG
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  phaseColor.withAlpha(isDark ? 80 : 35),
                  AppColors.secondary.withAlpha(isDark ? 50 : 15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: phaseColor.withAlpha(isDark ? 100 : 70),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: phaseColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            status.currentPhase,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Cập nhật: $formattedTime',
                      style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Năng lượng của vợ
                Row(
                  children: [
                    Text(
                      _getEnergyEmoji(status.energyLevel),
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Năng lượng: ${status.energyLevel}/5 (${_getEnergyLabel(status.energyLevel)})',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: status.energyLevel / 5.0,
                              backgroundColor: Colors.grey.withAlpha(40),
                              valueColor: AlwaysStoppedAnimation<Color>(phaseColor),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. LỜI KHUYÊN HÀNH ĐỘNG VÀNG CHO CHỒNG
          _buildCard(
            context,
            title: 'Hành động ấm áp dành cho bạn hôm nay',
            icon: Icons.lightbulb_rounded,
            iconColor: AppColors.accentPeach,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentPeach.withAlpha(isDark ? 30 : 20),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentPeach.withAlpha(60)),
              ),
              child: Text(
                status.husbandActionTip.isNotEmpty
                    ? status.husbandActionTip
                    : 'Hãy lắng nghe và chuẩn bị một ly nước ấm sẵn sàng cho nàng nhé!',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 3. THẺ CẢM XÚC & TRIỆU CHỨNG HÔM NAY CỦA VỢ
          _buildCard(
            context,
            title: 'Biểu hiện cơ thể & tâm lý của nàng',
            icon: Icons.favorite_border_rounded,
            iconColor: AppColors.primary,
            child: status.moodTags.isEmpty
                ? const Text('Vợ chưa chọn triệu chứng đặc biệt nào.')
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: status.moodTags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.primaryDark,
                        ),
                        backgroundColor: AppColors.primaryContainer.withAlpha(isDark ? 60 : 150),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: AppColors.primary.withAlpha(60)),
                        ),
                      );
                    }).toList(),
                  ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
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
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Color _getPhaseColor(String phaseName) {
    if (phaseName.contains('Hành kinh')) return AppColors.phaseMenstrual;
    if (phaseName.contains('Nang trứng')) return AppColors.phaseFollicular;
    if (phaseName.contains('Rụng trứng')) return AppColors.phaseOvulation;
    return AppColors.phaseLuteal;
  }

  String _getEnergyEmoji(int level) {
    switch (level) {
      case 1:
        return '😫';
      case 2:
        return '🥱';
      case 3:
        return '😐';
      case 4:
        return '😊';
      case 5:
      default:
        return '⚡';
    }
  }

  String _getEnergyLabel(int level) {
    switch (level) {
      case 1:
        return 'Kiệt sức, cần nghỉ ngơi';
      case 2:
        return 'Mệt mỏi';
      case 3:
        return 'Bình thường';
      case 4:
        return 'Tươi tắn, tích cực';
      case 5:
      default:
        return 'Tràn đầy năng lượng';
    }
  }

  void _confirmDisconnect(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ngắt kết nối với Vợ?'),
        content: const Text(
          'Bạn sẽ không còn nhận được thông tin cập nhật trạng thái của vợ nữa cho đến khi nhập mã mới.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ref.read(partnerSyncControllerProvider.notifier).disconnect();
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            child: const Text('Ngắt kết nối'),
          ),
        ],
      ),
    );
  }
}
