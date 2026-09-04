// lib/features/motherhood/presentation/widgets/feeding_timer_sheet.dart
//
// Modal bấm giờ cữ bú sơ sinh (Feeding Timer Sheet)
// Hỗ trợ bấm giờ ngực Trái và ngực Phải độc lập hoặc ghi cữ bú bình.
//
// LƯU Ý KỸ THUẬT:
// Mốc startTime được lưu bằng DateTime thực tế để tính toán chính xác
// thời lượng ngay cả khi ứng dụng chạy nền (background) hoặc màn hình bị khóa.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/motherhood/domain/models/baby_activity_log_model.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';

enum BreastSide { left, right, none }

class FeedingTimerSheet extends ConsumerStatefulWidget {
  final String childId;
  final String childName;

  const FeedingTimerSheet({
    super.key,
    required this.childId,
    required this.childName,
  });

  static Future<void> show(
    BuildContext context, {
    required String childId,
    required String childName,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedingTimerSheet(
        childId: childId,
        childName: childName,
      ),
    );
  }

  @override
  ConsumerState<FeedingTimerSheet> createState() => _FeedingTimerSheetState();
}

class _FeedingTimerSheetState extends ConsumerState<FeedingTimerSheet> {
  // Trạng thái bú mẹ trực tiếp
  BreastSide _activeSide = BreastSide.none;
  DateTime? _leftStartTime;
  DateTime? _rightStartTime;
  int _accumulatedLeftSeconds = 0;
  int _accumulatedRightSeconds = 0;
  Timer? _ticker;

  // Trạng thái bú bình
  bool _isBottleMode = false;
  FeedingType _bottleType = FeedingType.bottleBreastMilk;
  final TextEditingController _amountController = TextEditingController(text: '90');
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _ticker?.cancel();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  int get _currentLeftSeconds {
    var secs = _accumulatedLeftSeconds;
    if (_activeSide == BreastSide.left && _leftStartTime != null) {
      secs += DateTime.now().difference(_leftStartTime!).inSeconds;
    }
    return secs;
  }

  int get _currentRightSeconds {
    var secs = _accumulatedRightSeconds;
    if (_activeSide == BreastSide.right && _rightStartTime != null) {
      secs += DateTime.now().difference(_rightStartTime!).inSeconds;
    }
    return secs;
  }

  int get _totalSeconds => _currentLeftSeconds + _currentRightSeconds;

  String _formatDuration(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _toggleSide(BreastSide side) {
    AppHaptics.selection();
    final now = DateTime.now();

    if (_activeSide == side) {
      // Tạm dừng bên đang bấm
      if (side == BreastSide.left && _leftStartTime != null) {
        _accumulatedLeftSeconds += now.difference(_leftStartTime!).inSeconds;
        _leftStartTime = null;
      } else if (side == BreastSide.right && _rightStartTime != null) {
        _accumulatedRightSeconds += now.difference(_rightStartTime!).inSeconds;
        _rightStartTime = null;
      }
      _activeSide = BreastSide.none;
    } else {
      // Đổi bên hoặc bắt đầu bên mới
      if (_activeSide == BreastSide.left && _leftStartTime != null) {
        _accumulatedLeftSeconds += now.difference(_leftStartTime!).inSeconds;
        _leftStartTime = null;
      } else if (_activeSide == BreastSide.right && _rightStartTime != null) {
        _accumulatedRightSeconds += now.difference(_rightStartTime!).inSeconds;
        _rightStartTime = null;
      }

      _activeSide = side;
      if (side == BreastSide.left) {
        _leftStartTime = now;
      } else if (side == BreastSide.right) {
        _rightStartTime = now;
      }
      _startTicker();
    }
    setState(() {});
  }

  Future<void> _handleSaveBreastFeeding() async {
    AppHaptics.medium();
    _ticker?.cancel();

    // Chốt thời gian nếu còn đang chạy
    final now = DateTime.now();
    if (_activeSide == BreastSide.left && _leftStartTime != null) {
      _accumulatedLeftSeconds += now.difference(_leftStartTime!).inSeconds;
    } else if (_activeSide == BreastSide.right && _rightStartTime != null) {
      _accumulatedRightSeconds += now.difference(_rightStartTime!).inSeconds;
    }

    final totalSecs = _accumulatedLeftSeconds + _accumulatedRightSeconds;
    final durationMins = (totalSecs / 60).ceil().clamp(1, 120);

    FeedingType chosenType = FeedingType.breastLeft;
    if (_accumulatedRightSeconds > _accumulatedLeftSeconds) {
      chosenType = FeedingType.breastRight;
    }

    final noteParts = <String>[];
    if (_accumulatedLeftSeconds > 0) {
      noteParts.add('Trái: ${(_accumulatedLeftSeconds ~/ 60)}p');
    }
    if (_accumulatedRightSeconds > 0) {
      noteParts.add('Phải: ${(_accumulatedRightSeconds ~/ 60)}p');
    }
    if (_notesController.text.trim().isNotEmpty) {
      noteParts.add(_notesController.text.trim());
    }

    await ref.read(babyLogControllerProvider.notifier).quickLogFeeding(
      childId: widget.childId,
      type: chosenType,
      durationMinutes: durationMins,
      notes: noteParts.join(' • '),
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🍼 Đã ghi cữ bú cho bé ($durationMins phút)'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSaveBottleFeeding() async {
    AppHaptics.medium();
    final amount = double.tryParse(_amountController.text.trim()) ?? 90.0;

    await ref.read(babyLogControllerProvider.notifier).quickLogFeeding(
      childId: widget.childId,
      type: _bottleType,
      amountMl: amount,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🍼 Đã ghi cữ bú bình: ${amount.toInt()}ml'),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle kéo modal
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
            const SizedBox(height: 16),

            // Header & Switch Mode (Bú Mẹ / Bú Bình)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ghi Cữ Bú 🍼',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Bé: ${widget.childName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black.withAlpha(12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      _buildModeChip('Bú Mẹ', !_isBottleMode, () {
                        setState(() => _isBottleMode = false);
                      }),
                      _buildModeChip('Bú Bình', _isBottleMode, () {
                        setState(() => _isBottleMode = true);
                      }),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (!_isBottleMode) ...[
              // ── CHẾ ĐỘ BÚ MẸ (TIMER NGỰC TRÁI / PHẢI) ──
              Center(
                child: Column(
                  children: [
                    Text(
                      _formatDuration(_totalSeconds),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: _activeSide != BreastSide.none
                            ? AppColors.primary
                            : (isDark ? Colors.white70 : Colors.black87),
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _activeSide == BreastSide.left
                          ? 'Đang bú Ngực Trái...'
                          : _activeSide == BreastSide.right
                              ? 'Đang bú Ngực Phải...'
                              : 'Nhấn vào bên dưới để bắt đầu',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _activeSide != BreastSide.none
                            ? AppColors.primary
                            : (isDark ? Colors.white38 : Colors.black45),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2 Nút Trái & Phải
              Row(
                children: [
                  Expanded(
                    child: _buildBreastButton(
                      side: BreastSide.left,
                      label: 'Ngực Trái 🌸',
                      seconds: _currentLeftSeconds,
                      isActive: _activeSide == BreastSide.left,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBreastButton(
                      side: BreastSide.right,
                      label: 'Ngực Phải 🌸',
                      seconds: _currentRightSeconds,
                      isActive: _activeSide == BreastSide.right,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Ghi chú thêm
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Ghi chú cữ bú (bé hợp tác, trớ sữa, v.v.)...',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nút Hoàn tất
              ElevatedButton.icon(
                onPressed: _totalSeconds > 0 ? _handleSaveBreastFeeding : null,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('Hoàn Tất Cữ Bú Mẹ', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
              ),
            ] else ...[
              // ── CHẾ ĐỘ BÚ BÌNH (SỮA MẸ / SỮA CÔNG THỨC) ──
              Row(
                children: [
                  Expanded(
                    child: _buildBottleTypeChip(
                      'Sữa mẹ vắt 🍼',
                      FeedingType.bottleBreastMilk,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildBottleTypeChip(
                      'Sữa công thức 🥛',
                      FeedingType.bottleFormula,
                      isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Lượng sữa (ml)
              Text(
                'Lượng sữa bé bú (ml):',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: false),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        suffixText: 'ml',
                        filled: true,
                        fillColor: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildQuickMlChip('60ml', 60),
                  const SizedBox(width: 6),
                  _buildQuickMlChip('90ml', 90),
                  const SizedBox(width: 6),
                  _buildQuickMlChip('120ml', 120),
                ],
              ),
              const SizedBox(height: 16),

              // Ghi chú bú bình
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Ghi chú (bình avent, bé bú hết, v.v.)...',
                  hintStyle: TextStyle(fontSize: 13, color: isDark ? Colors.white38 : Colors.black38),
                  filled: true,
                  fillColor: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Nút Lưu Cữ Bú Bình
              ElevatedButton.icon(
                onPressed: _handleSaveBottleFeeding,
                icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                label: const Text('Lưu Cữ Bú Bình', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModeChip(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildBreastButton({
    required BreastSide side,
    required String label,
    required int seconds,
    required bool isActive,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => _toggleSide(side),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withAlpha(35)
              : (isDark ? Colors.white.withAlpha(12) : Colors.black.withAlpha(8)),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isActive ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              isActive ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
              size: 42,
              color: isActive ? AppColors.primary : (isDark ? Colors.white60 : Colors.black45),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isActive ? AppColors.primary : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDuration(seconds),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isActive ? AppColors.primary : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottleTypeChip(String title, FeedingType type, bool isDark) {
    final isSelected = _bottleType == type;
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        setState(() => _bottleType = type);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(35)
              : (isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(6)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: isSelected ? AppColors.primary : null,
          ),
        ),
      ),
    );
  }

  Widget _buildQuickMlChip(String label, int ml) {
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        setState(() {
          _amountController.text = ml.toString();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
