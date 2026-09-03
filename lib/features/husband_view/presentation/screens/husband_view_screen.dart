// lib/features/husband_view/presentation/screens/husband_view_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/date_utils.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/mood/presentation/controllers/mood_controller.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/presentation/screens/husband_dashboard_screen.dart';
import 'package:herflow/features/partner_sync/presentation/screens/pairing_screen.dart';

/// Màn hình Góc Nhìn Yêu Thương Cho Chồng / Người Yêu (Husband View)
class HusbandViewScreen extends ConsumerWidget {
  const HusbandViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(cycleControllerProvider);
    final selectedDate = ref.watch(selectedCalendarDateProvider);
    final moodEntry = ref.watch(selectedDateMoodProvider);
    final savedCoupleId = ref.watch(savedCoupleIdProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Góc Nhìn Của Anh',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Bí quyết thấu hiểu & chăm sóc nàng (${AppDateUtils.formatHeaderDate(selectedDate)})',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Ghép đôi Realtime',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairingScreen()),
              );
            },
          ),
        ],
      ),
      body: cycleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (cycleInfo) {
          final phase = cycleInfo.getPhaseForDate(selectedDate);
          final cycleDay = cycleInfo.getCycleDay(selectedDate);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 0. BANNER GHÉP ĐÔI REALTIME QUA PAIRING CODE
                GestureDetector(
                  onTap: () {
                    if (savedCoupleId != null && savedCoupleId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HusbandDashboardScreen()),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PairingScreen()),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: savedCoupleId != null
                          ? AppColors.success.withAlpha(isDark ? 50 : 25)
                          : AppColors.secondaryContainer.withAlpha(isDark ? 50 : 120),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: savedCoupleId != null
                            ? AppColors.success.withAlpha(80)
                            : AppColors.secondary.withAlpha(60),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          savedCoupleId != null ? Icons.cloud_done_rounded : Icons.sync_lock_rounded,
                          color: savedCoupleId != null ? AppColors.success : AppColors.secondary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            savedCoupleId != null
                                ? 'Đã kết nối Firestore • Chạm để xem Live Dashboard'
                                : 'Kết nối với Chồng qua mã Pairing Code 6 ký tự',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: savedCoupleId != null ? AppColors.success : AppColors.secondaryDark,
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                      ],
                    ),
                  ),
                ),

                // 1. TÓM TẮT TRẠNG THÁI CỦA NÀNG HÔM NAY
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        phase.color.withAlpha(isDark ? 80 : 40),
                        AppColors.secondary.withAlpha(isDark ? 50 : 20),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: phase.color.withAlpha(isDark ? 100 : 70),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: phase.color.withAlpha(40),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.favorite_rounded, color: phase.color, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hôm nay: ${phase.vietnameseName} (Ngày $cycleDay)',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: phase.color,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tâm trạng: ${moodEntry.mood} • Năng lượng: ${moodEntry.energyLevel}/5',
                                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        phase.husbandAdvice,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. NHỮNG VIỆC NÊN CHỦ ĐỘNG LÀM HÔM NAY (DO'S)
                _buildActionCard(
                  context,
                  title: 'Hành động ấm áp nên làm ngay',
                  icon: Icons.thumb_up_alt_rounded,
                  color: AppColors.success,
                  items: [
                    'Chủ động rửa chén, dọn nhà hoặc chăm con giúp nàng.',
                    'Chuẩn bị một ly nước ấm / trà gừng mật ong để sẵn bàn làm việc.',
                    'Ôm nàng thật chặt và nói: "Hôm nay em vất vả rồi, để anh lo nhé!".',
                  ],
                ),

                const SizedBox(height: 16),

                // 3. NHỮNG ĐIỀU NÊN TRÁNH (DON'TS)
                _buildActionCard(
                  context,
                  title: 'Những điều tuyệt đối tránh',
                  icon: Icons.block_rounded,
                  color: AppColors.error,
                  items: [
                    'Tránh tranh luận gay gắt hoặc nói câu "Em lại khó tính rồi đấy".',
                    'Đừng để nàng phải suy nghĩ tối nay ăn gì — hãy chủ động gọi món nàng thích.',
                    'Không phàn nàn nếu nàng mệt và muốn đi ngủ sớm.',
                  ],
                ),

                const SizedBox(height: 20),

                // 4. NÚT SAO CHÉP TÓM TẮT ĐỂ GỬI QUA TIN NHẮN (SMS/ZALO)
                ElevatedButton.icon(
                  onPressed: () {
                    final text = '''
🌸 Tóm tắt thể trạng HerFlow hôm nay:
- Giai đoạn: ${phase.vietnameseName} (Ngày $cycleDay)
- Tâm trạng: ${moodEntry.mood} (Năng lượng: ${moodEntry.energyLevel}/5)
- Lời nhắc yêu thương: ${phase.husbandAdvice}
''';
                    Clipboard.setData(ClipboardData(text: text));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã sao chép tóm tắt trạng thái vào bộ nhớ tạm!'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  icon: const Icon(Icons.copy_all_rounded, size: 20),
                  label: const Text('Sao chép tóm tắt để gửi tin nhắn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<String> items,
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
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map(
              (it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        it,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
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
}
