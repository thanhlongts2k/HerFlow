// lib/features/lifecycle/presentation/widgets/pregnancy_setup_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/lifecycle/domain/models/fetal_week_data.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/domain/services/pregnancy_calculator_service.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';

/// Phương thức thiết lập ngày thai kỳ
enum PregnancyCalculationMethod {
  lmp, // Ngày đầu kỳ kinh cuối
  edd, // Ngày dự sinh (siêu âm)
}

/// BottomSheet thiết lập ngày thai kỳ trực quan, ấm áp
class PregnancySetupSheet extends ConsumerStatefulWidget {
  const PregnancySetupSheet({super.key});

  /// Hàm tiện ích tĩnh mở BottomSheet
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PregnancySetupSheet(),
    );
  }

  @override
  ConsumerState<PregnancySetupSheet> createState() => _PregnancySetupSheetState();
}

class _PregnancySetupSheetState extends ConsumerState<PregnancySetupSheet> {
  PregnancyCalculationMethod _method = PregnancyCalculationMethod.lmp;
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Khởi tạo từ config hiện có nếu đã có
    final existingConfig = ref.read(pregnancyConfigProvider);
    if (existingConfig != null) {
      if (existingConfig.lastMenstrualPeriod != null) {
        _method = PregnancyCalculationMethod.lmp;
        _selectedDate = existingConfig.lastMenstrualPeriod;
      } else if (existingConfig.estimatedDueDate != null) {
        _method = PregnancyCalculationMethod.edd;
        _selectedDate = existingConfig.estimatedDueDate;
      }
    } else {
      // Mặc định gợi ý LMP khoảng 6 tuần trước
      _selectedDate = DateTime.now().subtract(const Duration(days: 42));
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    AppHaptics.selection();
    final now = DateTime.now();

    final DateTime initialDate;
    final DateTime firstDate;
    final DateTime lastDate;

    if (_method == PregnancyCalculationMethod.lmp) {
      firstDate = now.subtract(const Duration(days: 300)); // Tối đa ~42 tuần trước
      lastDate = now;
      initialDate = (_selectedDate != null &&
              _selectedDate!.isAfter(firstDate) &&
              _selectedDate!.isBefore(lastDate))
          ? _selectedDate!
          : now.subtract(const Duration(days: 42));
    } else {
      firstDate = now;
      lastDate = now.add(const Duration(days: 290)); // Dự sinh trong vòng ~41 tuần tới
      initialDate = (_selectedDate != null &&
              _selectedDate!.isAfter(firstDate) &&
              _selectedDate!.isBefore(lastDate))
          ? _selectedDate!
          : now.add(const Duration(days: 238));
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: _method == PregnancyCalculationMethod.lmp
          ? 'CHỌN NGÀY ĐẦU KỲ KINH CUỐI'
          : 'CHỌN NGÀY DỰ SINH THEO SIÊU ÂM',
      cancelText: 'HỦY',
      confirmText: 'CHỌN NGÀY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      AppHaptics.light();
      setState(() {
        _selectedDate = PregnancyCalculatorService.normalizeDate(picked);
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedDate == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    AppHaptics.medium();

    try {
      final pregnancyNotifier = ref.read(pregnancyConfigProvider.notifier);
      if (_method == PregnancyCalculationMethod.lmp) {
        await pregnancyNotifier.setPregnancyByLmp(_selectedDate!);
      } else {
        await pregnancyNotifier.setPregnancyByEdd(_selectedDate!);
      }

      // Tự động chuyển LifeStage sang pregnancy nếu chưa ở stage này
      await ref.read(lifeStageControllerProvider.notifier).switchStage(LifeStage.pregnancy);

      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true);
        } else {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    } catch (e) {
      debugPrint('[PregnancySetupSheet] Error saving pregnancy config: $e');
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Tính toán live preview
    GestationalAgeResult? ageResult;
    DateTime? estimatedDueDate;
    FetalWeekData? weekData;

    if (_selectedDate != null) {
      if (_method == PregnancyCalculationMethod.lmp) {
        ageResult = PregnancyCalculatorService.calculateGestationalAge(_selectedDate!);
        estimatedDueDate = PregnancyCalculatorService.calculateDueDateFromLMP(_selectedDate!);
      } else {
        final calculatedLmp = PregnancyCalculatorService.calculateLMPFromDueDate(_selectedDate!);
        ageResult = PregnancyCalculatorService.calculateGestationalAge(calculatedLmp);
        estimatedDueDate = _selectedDate!;
      }
      weekData = FetalWeekData.getWeekData(ageResult.currentWeekOrdinal);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1828) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header tiêu đề
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Text('🌱', style: TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hành Trình Đón Bé Yêu',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thiết lập ngày để đồng hành 40 tuần thai kỳ',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black54,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Segment chọn phương thức tính (LMP vs EDD)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(8),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: _MethodSegmentButton(
                        label: 'Kỳ kinh cuối (LMP)',
                        icon: Icons.calendar_today_rounded,
                        isSelected: _method == PregnancyCalculationMethod.lmp,
                        onTap: () {
                          if (_method != PregnancyCalculationMethod.lmp) {
                            AppHaptics.selection();
                            setState(() {
                              _method = PregnancyCalculationMethod.lmp;
                              // Gợi ý lại ngày LMP hợp lệ
                              _selectedDate = DateTime.now().subtract(const Duration(days: 42));
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _MethodSegmentButton(
                        label: 'Ngày dự sinh (EDD)',
                        icon: Icons.child_care_rounded,
                        isSelected: _method == PregnancyCalculationMethod.edd,
                        onTap: () {
                          if (_method != PregnancyCalculationMethod.edd) {
                            AppHaptics.selection();
                            setState(() {
                              _method = PregnancyCalculationMethod.edd;
                              // Gợi ý ngày EDD hợp lệ (khoảng 34 tuần nữa)
                              _selectedDate = DateTime.now().add(const Duration(days: 238));
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ chọn ngày DatePicker
              InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => _pickDate(context),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF282035) : const Color(0xFFFAF5FF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColors.primary.withAlpha(isDark ? 70 : 45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(isDark ? 35 : 20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.edit_calendar_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _method == PregnancyCalculationMethod.lmp
                                  ? 'Ngày đầu của kỳ kinh cuối:'
                                  : 'Ngày dự sinh (theo bác sĩ/siêu âm):',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedDate != null
                                  ? DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate!)
                                  : 'Chạm để chọn ngày',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isDark ? Colors.white38 : Colors.black26,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Live Preview: Xem trước tuổi thai và dữ liệu tuần thai tức thì
              if (ageResult != null && estimatedDueDate != null && weekData != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFAB47BC).withAlpha(isDark ? 40 : 25),
                        AppColors.primary.withAlpha(isDark ? 35 : 18),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFAB47BC).withAlpha(isDark ? 80 : 50),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            weekData.fruitEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bé hiện tại: ${ageResult.formattedAge}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Tuần thứ ${ageResult.currentWeekOrdinal} • ${ageResult.trimester.shortName}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.purple[200] : const Color(0xFF7B1FA2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dự kiến sinh: ${DateFormat('dd/MM/yyyy').format(estimatedDueDate)} (còn ${ageResult.daysUntilDue} ngày)',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.straighten_rounded, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kích thước tương đương ${weekData.fruitName} (${weekData.formattedLength} • ${weekData.formattedWeight})',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Nút bắt đầu theo dõi thai kỳ
              ElevatedButton(
                onPressed: _isSubmitting || _selectedDate == null ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Bắt Đầu Theo Dõi Thai Kỳ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodSegmentButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodSegmentButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? (isDark ? Colors.white : AppColors.primary)
                  : (isDark ? Colors.white60 : Colors.black54),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
