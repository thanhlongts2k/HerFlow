// lib/features/partner_sync/presentation/screens/pairing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/partner_sync/domain/models/pairing_model.dart';
import 'package:herflow/features/partner_sync/presentation/screens/husband_dashboard_screen.dart';

/// Màn hình Kết Nối Ghép Đôi Vợ - Chồng qua mã Pairing Code 6 ký tự
class PairingScreen extends ConsumerStatefulWidget {
  final int? initialIndex;
  const PairingScreen({super.key, this.initialIndex});

  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initialTab = widget.initialIndex ??
        (ref.read(userRoleProvider) == UserRole.husband ? 1 : 0);
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pairingState = ref.watch(partnerSyncControllerProvider);
    final savedCoupleId = ref.watch(savedCoupleIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Đồng Bộ Cặp Đôi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.favorite_rounded), text: 'Dành cho Vợ'),
            Tab(icon: Icon(Icons.shield_rounded), text: 'Dành cho Chồng'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: PHÍA VỢ (HOST / TẠO MÃ)
          _buildWifeTab(context, pairingState, isDark),

          // TAB 2: PHÍA CHỒNG (PARTNER / NHẬP MÃ)
          _buildHusbandTab(context, pairingState, savedCoupleId, isDark),
        ],
      ),
    );
  }

  /// Tab 1: Phía Vợ — Tạo mã và chia sẻ cho chồng
  Widget _buildWifeTab(BuildContext context, PairingState state, bool isDark) {
    final repo = ref.watch(partnerSyncRepositoryProvider);
    final activeCode = state.activePairingCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withAlpha(isDark ? 60 : 150),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tạo mã kết nối 6 ký tự để chồng có thể theo dõi chu kỳ và tâm trạng của bạn theo thời gian thực.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white : AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          if (activeCode == null) ...[
            // Chưa tạo mã
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withAlpha(20),
                ),
                child: const Icon(Icons.key_rounded, size: 48, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: state.isLoading
                  ? null
                  : () {
                      ref.read(partnerSyncControllerProvider.notifier).generatePairingCode();
                    },
              icon: state.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.qr_code_2_rounded),
              label: Text(state.isLoading ? 'Đang tạo mã...' : 'Tạo Mã Kết Nối Mới'),
            ),
          ] else ...[
            // Badge offline nếu mã được tạo cục bộ (không có Firestore)
            if (state.isOfflineCode) ...[  
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withAlpha(120)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Mã kết nối nội bộ (Thử nghiệm) — Không cần mạng để thử flow ghép đôi',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Đã có mã: Lắng nghe trạng thái realtime
            StreamBuilder<PairingModel?>(
              stream: state.isOfflineCode ? Stream.value(null) : repo.watchPairingStatus(activeCode),
              builder: (context, snapshot) {
                final pairing = snapshot.data;
                final isConnected = pairing?.status == PairingStatus.connected;

                return Column(
                  children: [
                    Text(
                      isConnected ? '🎉 ĐÃ KẾT NỐI THÀNH CÔNG' : 'MÃ KẾT NỐI CỦA BẠN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: isConnected ? AppColors.success : AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Hộp hiển thị mã 6 ký tự
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isConnected ? AppColors.success : AppColors.primary,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isConnected ? AppColors.success : AppColors.primary).withAlpha(30),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            activeCode,
                            style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 6,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                            tooltip: 'Sao chép mã',
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: activeCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã sao chép mã kết nối vào bộ nhớ tạm!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isConnected
                          ? 'Chồng đã kết nối. Trạng thái của bạn sẽ được tự động đồng bộ!'
                          : 'Gửi mã này cho chồng. Mã có hiệu lực trong 24 giờ.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isConnected ? AppColors.success : Colors.grey,
                        fontWeight: isConnected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () {
                        ref.read(partnerSyncControllerProvider.notifier).generatePairingCode();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Tạo mã khác'),
                    ),
                  ],
                );
              },
            ),
          ],

          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.error.withAlpha(80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Tab 2: Phía Chồng — Nhập mã và mở Dashboard realtime
  Widget _buildHusbandTab(
    BuildContext context,
    PairingState state,
    String? savedCoupleId,
    bool isDark,
  ) {
    // Nếu chồng đã kết nối trước đó
    if (savedCoupleId != null && savedCoupleId.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.success.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.favorite_rounded, color: AppColors.success, size: 50),
            ),
            const SizedBox(height: 18),
            const Text(
              'Đã Kết Nối Với Vợ!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn đang theo dõi trực tiếp trạng thái chu kỳ của vợ theo thời gian thực.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HusbandDashboardScreen()),
                );
              },
              icon: const Icon(Icons.dashboard_rounded),
              label: const Text('Mở Dashboard Chồng'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                ref.read(partnerSyncControllerProvider.notifier).disconnect();
              },
              child: const Text('Ngắt kết nối', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.secondaryContainer.withAlpha(isDark ? 60 : 150),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.secondary.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_moon_rounded, color: AppColors.secondary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nhập mã 6 ký tự do vợ bạn cung cấp để bắt đầu theo dõi và nhận gợi ý chăm sóc nàng.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? Colors.white : AppColors.secondaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Ô nhập mã 6 ký tự
          TextField(
            controller: _codeInputController,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 8,
              fontFamily: 'monospace',
            ),
            decoration: InputDecoration(
              hintText: 'HF••••',
              counterText: '',
              filled: true,
              fillColor: isDark ? AppColors.cardDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.secondary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: Colors.grey.withAlpha(60)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.secondary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          ElevatedButton.icon(
            onPressed: state.isLoading
                ? null
                : () async {
                    final code = _codeInputController.text.trim();
                    final success = await ref
                        .read(partnerSyncControllerProvider.notifier)
                        .connectWithCode(code);
                    if (success && context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HusbandDashboardScreen()),
                      );
                    }
                  },
            icon: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.link_rounded),
            label: Text(state.isLoading ? 'Đang kết nối...' : 'Kết Nối Ngay'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: Colors.white,
            ),
          ),

          if (state.errorMessage != null) ...[
            const SizedBox(height: 16),
            Text(
              state.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
