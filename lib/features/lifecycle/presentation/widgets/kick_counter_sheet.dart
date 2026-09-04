// lib/features/lifecycle/presentation/widgets/kick_counter_sheet.dart
//
// Giao diện Bộ Đếm Cử Động Thai (Fetal Kick Counter)
// Chuẩn Cardiff "Count to 10" — nút tap lớn, timer thời gian thực, thanh tiến trình 10 nấc.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/lifecycle/domain/models/kick_counter_model.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/kick_counter_controller.dart';

/// Bottom sheet bộ đếm cử động thai Cardiff "Count to 10"
class KickCounterSheet extends ConsumerStatefulWidget {
  const KickCounterSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const KickCounterSheet(),
    );
  }

  @override
  ConsumerState<KickCounterSheet> createState() => _KickCounterSheetState();
}

class _KickCounterSheetState extends ConsumerState<KickCounterSheet>
    with TickerProviderStateMixin {
  // Trạng thái phiên đang chạy (null nếu chưa bắt đầu)
  KickSessionModel? _activeSession;
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  // Animation cho nút tap
  late AnimationController _rippleController;
  late Animation<double> _rippleAnimation;
  bool _isTapping = false;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rippleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _rippleController.dispose();
    super.dispose();
  }

  // ── Timer logic ────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _elapsed = DateTime.now().difference(_activeSession!.startTime);
      });

      // Auto-timeout sau 2 giờ
      if (_elapsed >= KickSessionModel.cardiffTimeLimit) {
        _handleTimeout();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _handleStartSession() async {
    AppHaptics.medium();
    final session =
        await ref.read(kickCounterProvider.notifier).startSession();
    setState(() {
      _activeSession = session;
      _elapsed = Duration.zero;
    });
    _startTimer();
  }

  Future<void> _handleTap() async {
    if (_activeSession == null || !_activeSession!.isInProgress) return;

    AppHaptics.heavy();

    // Scale animation
    setState(() => _isTapping = true);
    _rippleController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 150));
    if (mounted) setState(() => _isTapping = false);

    final updated =
        await ref.read(kickCounterProvider.notifier).addKick(_activeSession!.id);
    if (updated == null || !mounted) return;

    setState(() => _activeSession = updated);

    if (updated.isCompleted) {
      _stopTimer();
      _showCompletionDialog();
    }
  }

  Future<void> _handleTimeout() async {
    _stopTimer();
    final updated =
        await ref.read(kickCounterProvider.notifier).timeoutSession(_activeSession!.id);
    if (!mounted) return;
    if (updated != null) setState(() => _activeSession = updated);
    _showTimeoutDialog();
  }

  void _handleReset() {
    _stopTimer();
    setState(() {
      _activeSession = null;
      _elapsed = Duration.zero;
    });
  }

  void _showCompletionDialog() {
    if (!mounted) return;
    final mins = _activeSession?.completionMinutes ?? 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 28)),
            SizedBox(width: 10),
            Text('Tuyệt vời!',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
          ],
        ),
        content: Text(
          'Bé đã đạp đủ 10 lần trong $mins phút.\n'
          'Con đang khỏe mạnh và tích cực! ❤️',
          style: const TextStyle(fontSize: 14.5, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleReset();
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Hoàn thành 🌸'),
          ),
        ],
      ),
    );
  }

  void _showTimeoutDialog() {
    if (!mounted) return;
    final kicks = _activeSession?.kickCount ?? 0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 26)),
            SizedBox(width: 10),
            Expanded(
              child: Text('Chưa đủ 10 cử động',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ),
          ],
        ),
        content: Text(
          'Bé chỉ đạp $kicks lần trong 2 giờ.\n\n'
          '• Nằm nghiêng bên trái để tăng lưu thông máu.\n'
          '• Uống nước mát hoặc ăn nhẹ để kích thích bé.\n'
          '• Nếu lo lắng, hãy liên hệ bác sĩ ngay.',
          style: const TextStyle(fontSize: 13.5, height: 1.55),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleReset();
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // ── UI ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final kickState = ref.watch(kickCounterProvider);

    final isSessionActive = _activeSession?.isInProgress == true;
    final isSessionDone = _activeSession?.isCompleted == true ||
        _activeSession?.isTimedOut == true;
    final kicks = _activeSession?.kickCount ?? 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      snap: true,
      builder: (_, controller) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 80 : 40),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header
                    _buildHeader(isDark),
                    const SizedBox(height: 20),

                    // Timer + Status
                    if (isSessionActive || isSessionDone)
                      _buildTimerDisplay(isDark, isSessionDone),

                    // Progress bar (10 nấc cử động)
                    if (isSessionActive || isSessionDone) ...[
                      const SizedBox(height: 18),
                      _buildKickProgressBar(kicks, isDark),
                      const SizedBox(height: 24),
                    ],

                    // Nút Tap chính (LARGE ROUND BUTTON)
                    _buildKickButton(isSessionActive, isSessionDone, kicks, isDark),
                    const SizedBox(height: 16),

                    // Các nút điều hành phiên
                    if (_activeSession == null)
                      _buildStartButton(isDark)
                    else if (isSessionActive)
                      _buildResetButton(isDark)
                    else
                      _buildNewSessionButton(isDark),

                    const SizedBox(height: 28),

                    // Phân cách
                    Divider(color: isDark ? Colors.white12 : Colors.black12),
                    const SizedBox(height: 8),

                    // Lịch sử phiên đếm
                    _buildSessionHistory(kickState.recentSessions, isDark),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        Text(
          '👶 Đếm Cử Động Thai',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Chuẩn Cardiff "Count to 10" — Mục tiêu: 10 cử động trong 2 giờ',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerDisplay(bool isDark, bool isSessionDone) {
    final hh = _elapsed.inHours.toString().padLeft(2, '0');
    final mm = (_elapsed.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (_elapsed.inSeconds % 60).toString().padLeft(2, '0');

    Color timerColor;
    if (isSessionDone) {
      timerColor = _activeSession?.isCompleted == true
          ? AppColors.primary
          : Colors.orange;
    } else if (_elapsed.inMinutes >= 90) {
      timerColor = Colors.red;
    } else if (_elapsed.inMinutes >= 60) {
      timerColor = Colors.orange;
    } else {
      timerColor = isDark ? Colors.white70 : Colors.black54;
    }

    return Column(
      children: [
        Text(
          '$hh:$mm:$ss',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: timerColor,
            letterSpacing: 2,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (_elapsed.inMinutes >= 90 && !isSessionDone)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red.withAlpha(isDark ? 60 : 30),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '⚠️ Còn ${(120 - _elapsed.inMinutes)} phút — Cố lên mẹ!',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKickProgressBar(int kicks, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(KickSessionModel.targetKickCount, (i) {
            final filled = i < kicks;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? AppColors.primary
                    : (isDark ? Colors.white.withAlpha(30) : Colors.black.withAlpha(20)),
                border: Border.all(
                  color: filled
                      ? AppColors.primary
                      : (isDark ? Colors.white24 : Colors.black12),
                  width: 1.5,
                ),
                boxShadow: filled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(80),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: filled
                  ? const Icon(Icons.favorite, size: 13, color: Colors.white)
                  : null,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          '$kicks / ${KickSessionModel.targetKickCount} cử động',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildKickButton(
      bool isActive, bool isDone, int kicks, bool isDark) {
    final isDisabled = isDone || _activeSession == null;

    return ScaleTransition(
      scale: _rippleAnimation,
      child: GestureDetector(
        onTap: isActive ? _handleTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isDisabled
                ? LinearGradient(
                    colors: isDark
                      ? [Colors.white.withAlpha(25), Colors.white.withAlpha(12)]
                      : [Colors.grey.shade200, Colors.grey.shade100],
                  )
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withAlpha(200),
                    ],
                  ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(_isTapping ? 120 : 80),
                      blurRadius: _isTapping ? 30 : 20,
                      spreadRadius: _isTapping ? 4 : 0,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDone
                    ? (kicks >= KickSessionModel.targetKickCount
                        ? Icons.celebration_rounded
                        : Icons.access_time_rounded)
                    : (isActive
                        ? Icons.touch_app_rounded
                        : Icons.baby_changing_station_rounded),
                color: isDisabled ? (isDark ? Colors.white30 : Colors.grey) : Colors.white,
                size: 52,
              ),
              const SizedBox(height: 8),
              Text(
                isDisabled
                    ? (isDone ? (kicks >= 10 ? 'Hoàn thành!' : 'Hết giờ') : 'Bắt đầu trước')
                    : 'Bé đạp!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDisabled ? (isDark ? Colors.white30 : Colors.grey) : Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(bool isDark) {
    return FilledButton.icon(
      onPressed: _handleStartSession,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.play_circle_rounded, size: 20),
      label: const Text(
        'Bắt đầu phiên đếm mới',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildResetButton(bool isDark) {
    return OutlinedButton.icon(
      onPressed: _handleReset,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white70 : Colors.black54,
        side: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.refresh_rounded, size: 18),
      label: const Text('Hủy phiên này'),
    );
  }

  Widget _buildNewSessionButton(bool isDark) {
    return FilledButton.icon(
      onPressed: _handleReset,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary.withAlpha(220),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: const Icon(Icons.add_circle_rounded, size: 20),
      label: const Text('Bắt đầu phiên mới', style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildSessionHistory(List<KickSessionModel> sessions, bool isDark) {
    // Chỉ hiển thị 7 phiên gần nhất
    final recent = sessions.take(7).toList();
    if (recent.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'Chưa có phiên đếm nào.\nHãy bắt đầu để theo dõi cử động của bé! 💕',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Colors.black38,
            height: 1.5,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch sử gần nhất',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 10),
        ...recent.map((s) => _buildSessionTile(s, isDark)),
      ],
    );
  }

  Widget _buildSessionTile(KickSessionModel session, bool isDark) {
    final dateLabel = DateFormat('dd/MM HH:mm').format(session.startTime);
    final statusIcon = session.isCompleted
        ? '✅'
        : (session.isTimedOut ? '⚠️' : '⏳');
    final statusLabel = session.isCompleted
        ? '${session.kickCount} cử động • ${session.completionMinutes} phút'
        : (session.isTimedOut
            ? '${session.kickCount} cử động • Hết 2 giờ'
            : '${session.kickCount} cử động • Đang đếm...');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: session.isCompleted
              ? AppColors.primary.withAlpha(60)
              : (session.isTimedOut
                  ? Colors.orange.withAlpha(60)
                  : Colors.blue.withAlpha(40)),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(statusIcon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white.withAlpha(222) : Colors.black87,
                  ),
                ),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
