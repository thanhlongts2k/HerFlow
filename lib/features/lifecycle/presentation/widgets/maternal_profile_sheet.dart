// lib/features/lifecycle/presentation/widgets/maternal_profile_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/core/utils/haptic_feedback_utils.dart';
import 'package:herflow/features/lifecycle/domain/models/maternal_health_profile_model.dart';
import 'package:herflow/features/lifecycle/domain/services/maternal_calculator_service.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';

/// Modal Bottom Sheet chỉnh sửa và hoàn thiện Hồ Sơ Thể Trạng Mẹ Bầu
class MaternalProfileSheet extends ConsumerStatefulWidget {
  const MaternalProfileSheet({super.key});

  /// Hiển thị sheet dạng modal
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MaternalProfileSheet(),
    );
  }

  @override
  ConsumerState<MaternalProfileSheet> createState() => _MaternalProfileSheetState();
}

class _MaternalProfileSheetState extends ConsumerState<MaternalProfileSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _birthYearController;
  late TextEditingController _heightController;
  late TextEditingController _preWeightController;
  late TextEditingController _currentWeightController;
  late TextEditingController _hospitalController;

  String? _selectedParity;
  String? _selectedDeliveryPlan;
  bool _isMultiplePregnancy = false;

  final List<String> _parityOptions = const [
    'Con so (Con đầu)',
    'Con rạ (Con thứ 2)',
    'Con thứ 3+',
  ];

  final List<String> _deliveryPlanOptions = const [
    'Sinh thường',
    'Sinh mổ',
    'Đang cân nhắc',
  ];

  final List<String> _hospitalSuggestions = const [
    'BV Phụ Sản TW',
    'BV Phụ Sản Hà Nội',
    'BV Từ Dũ',
    'BV Hùng Vương',
    'Vinmec',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(pregnancyConfigProvider)?.maternalProfile;

    _birthYearController = TextEditingController(
      text: profile?.birthYear != null ? profile!.birthYear.toString() : '',
    );
    _heightController = TextEditingController(
      text: profile?.heightCm != null ? profile!.heightCm.toString() : '',
    );
    _preWeightController = TextEditingController(
      text: profile?.prePregnancyWeightKg != null
          ? profile!.prePregnancyWeightKg.toString()
          : '',
    );
    _currentWeightController = TextEditingController(
      text: profile?.currentWeightKg != null
          ? profile!.currentWeightKg.toString()
          : '',
    );
    _hospitalController = TextEditingController(
      text: profile?.targetHospital ?? '',
    );

    _selectedParity = profile?.parity;
    _selectedDeliveryPlan = profile?.deliveryPlan;
    _isMultiplePregnancy = profile?.isMultiplePregnancy ?? false;
  }

  @override
  void dispose() {
    _birthYearController.dispose();
    _heightController.dispose();
    _preWeightController.dispose();
    _currentWeightController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  /// Tính toán live BMI từ text fields
  double? get _liveBmi {
    final h = double.tryParse(_heightController.text.trim());
    final w = double.tryParse(_preWeightController.text.trim());
    return MaternalCalculatorService.calculateBmi(heightCm: h, weightKg: w);
  }

  /// Tính toán tuổi mẹ từ năm sinh
  int? get _liveAge {
    final year = int.tryParse(_birthYearController.text.trim());
    if (year != null && year > 1900 && year <= DateTime.now().year) {
      return DateTime.now().year - year;
    }
    return null;
  }

  Future<void> _handleSave() async {
    AppHaptics.medium();
    if (!_formKey.currentState!.validate()) return;

    final birthYear = int.tryParse(_birthYearController.text.trim());
    final heightCm = double.tryParse(_heightController.text.trim());
    final preWeight = double.tryParse(_preWeightController.text.trim());
    final curWeight = double.tryParse(_currentWeightController.text.trim());
    final hospital = _hospitalController.text.trim();

    final updatedProfile = MaternalHealthProfileModel(
      birthYear: birthYear,
      heightCm: heightCm,
      prePregnancyWeightKg: preWeight,
      currentWeightKg: curWeight,
      parity: _selectedParity,
      deliveryPlan: _selectedDeliveryPlan,
      targetHospital: hospital.isNotEmpty ? hospital : null,
      isMultiplePregnancy: _isMultiplePregnancy,
      updatedAt: DateTime.now(),
    );

    await ref
        .read(pregnancyControllerProvider.notifier)
        .updateMaternalProfile(updatedProfile);

    AppHaptics.success();
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật hồ sơ thể trạng mẹ bầu thành công! ✨'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final liveBmiVal = _liveBmi;
    final liveBmiCat = liveBmiVal != null ? MaternalCalculatorService.getBmiCategory(liveBmiVal) : null;
    final liveAgeVal = _liveAge;
    final liveAgeTier = liveAgeVal != null ? MaternalCalculatorService.getAgeTier(liveAgeVal) : null;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1B2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 80 : 30),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.monitor_weight_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hồ Sơ Thể Trạng Mẹ Bầu',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Chuẩn hóa y khoa IOM & cá nhân hóa tăng cân',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Đóng',
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── 1. Năm sinh & Phân tầng tuổi mẹ ──────────────────────────
              _buildSectionTitle('1. Năm sinh của Mẹ', Icons.cake_outlined, isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _birthYearController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hintText: 'Ví dụ: 1996',
                  suffixText: 'năm',
                  isDark: isDark,
                ),
                onChanged: (_) => setState(() {}),
                validator: (val) {
                  if (val != null && val.trim().isNotEmpty) {
                    final y = int.tryParse(val.trim());
                    if (y == null || y < 1950 || y > DateTime.now().year) {
                      return 'Năm sinh không hợp lệ';
                    }
                  }
                  return null;
                },
              ),
              if (liveAgeVal != null && liveAgeTier != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: liveAgeTier.color.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: liveAgeTier.color.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        liveAgeTier == MaternalAgeTier.advanced
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline_rounded,
                        color: liveAgeTier.color,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$liveAgeVal tuổi • ${liveAgeTier.label}',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: liveAgeTier.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // ── 2. Chiều cao & Cân nặng trước thai kỳ ─────────────────────
              _buildSectionTitle('2. Chiều cao & Cân nặng trước bầu', Icons.straighten_rounded, isDark),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        labelText: 'Chiều cao',
                        hintText: '160',
                        suffixText: 'cm',
                        isDark: isDark,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final h = double.tryParse(val.trim());
                          if (h == null || h <= 100 || h >= 220) {
                            return '100-220 cm';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _preWeightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(
                        labelText: 'Cân nặng trước',
                        hintText: '50.0',
                        suffixText: 'kg',
                        isDark: isDark,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          final w = double.tryParse(val.trim());
                          if (w == null || w <= 30 || w >= 200) {
                            return '30-200 kg';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              // LIVE BMI BADGE
              if (liveBmiVal != null && liveBmiCat != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: liveBmiCat.color.withAlpha(isDark ? 35 : 20),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: liveBmiCat.color.withAlpha(80)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: liveBmiCat.color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'BMI: $liveBmiVal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${liveBmiCat.label} • Khuyến nghị tăng ${liveBmiCat.minTotalGain} - ${liveBmiCat.maxTotalGain} kg cả thai kỳ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: liveBmiCat.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),

              // ── 3. Cân nặng hiện tại (Ghi nhận tiến trình) ────────────────
              _buildSectionTitle('3. Cân nặng hiện tại trong thai kỳ', Icons.scale_rounded, isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  hintText: 'Nhập cân nặng gần nhất để theo dõi mức tăng',
                  suffixText: 'kg',
                  isDark: isDark,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),

              // ── 4. Tiền sử mang thai (Parity) ────────────────────────────
              _buildSectionTitle('4. Mẹ mang thai lần thứ mấy?', Icons.family_restroom_rounded, isDark),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _parityOptions.map((opt) {
                  final isSelected = _selectedParity == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (val) {
                      AppHaptics.selection();
                      setState(() => _selectedParity = val ? opt : null);
                    },
                    selectedColor: AppColors.primary.withAlpha(isDark ? 80 : 50),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── 5. Kế hoạch sinh nở ──────────────────────────────────────
              _buildSectionTitle('5. Dự định phương pháp sinh', Icons.medical_services_outlined, isDark),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _deliveryPlanOptions.map((opt) {
                  final isSelected = _selectedDeliveryPlan == opt;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSelected,
                    onSelected: (val) {
                      AppHaptics.selection();
                      setState(() => _selectedDeliveryPlan = val ? opt : null);
                    },
                    selectedColor: AppColors.primary.withAlpha(isDark ? 80 : 50),
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // ── 6. Nơi dự kiến sinh ──────────────────────────────────────
              _buildSectionTitle('6. Bệnh viện dự định sinh', Icons.local_hospital_outlined, isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hospitalController,
                decoration: _inputDecoration(
                  hintText: 'Nhập hoặc chọn bệnh viện phụ sản',
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _hospitalSuggestions.map((hosp) {
                  return ActionChip(
                    label: Text(hosp, style: const TextStyle(fontSize: 11)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      AppHaptics.selection();
                      setState(() => _hospitalController.text = hosp);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // ── 7. Giả định thai đơn / đa thai ───────────────────────────
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Mang đa thai (Sinh đôi, sinh ba)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                subtitle: const Text('Mặc định thuật toán áp dụng cho thai đơn (Singleton)', style: TextStyle(fontSize: 11.5)),
                value: _isMultiplePregnancy,
                activeColor: AppColors.primary,
                onChanged: (val) {
                  AppHaptics.selection();
                  setState(() => _isMultiplePregnancy = val);
                },
              ),
              const SizedBox(height: 24),

              // ── Nút Lưu Hồ Sơ ───────────────────────────────────────────
              ElevatedButton(
                onPressed: _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: const Text(
                  'Lưu Hồ Sơ Thể Trạng',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    String? labelText,
    String? hintText,
    String? suffixText,
    required bool isDark,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      suffixText: suffixText,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(7),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? Colors.white12 : Colors.black.withAlpha(15),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}
