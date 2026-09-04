// lib/features/lifecycle/domain/services/maternal_calculator_service.dart
import 'package:flutter/material.dart';
import 'package:herflow/core/constants/app_colors.dart';
import 'package:herflow/features/lifecycle/domain/models/maternal_health_profile_model.dart';

/// Phân loại chỉ số BMI tiền thai kỳ theo chuẩn Viện Y học Hoa Kỳ (IOM 2009)
enum IomBmiCategory {
  /// Nhẹ cân (BMI < 18.5)
  underweight(
    label: 'Nhẹ cân',
    bmiRangeLabel: 'BMI < 18.5',
    minTotalGain: 12.5,
    maxTotalGain: 18.0,
    color: AppColors.secondary,
  ),

  /// Thể trạng chuẩn (BMI 18.5 - 24.9)
  normal(
    label: 'Bình thường',
    bmiRangeLabel: 'BMI 18.5 - 24.9',
    minTotalGain: 11.5,
    maxTotalGain: 16.0,
    color: AppColors.success,
  ),

  /// Thừa cân (BMI 25.0 - 29.9)
  overweight(
    label: 'Thừa cân',
    bmiRangeLabel: 'BMI 25.0 - 29.9',
    minTotalGain: 7.0,
    maxTotalGain: 11.5,
    color: Color(0xFFF59E0B), // Amber
  ),

  /// Béo phì (BMI >= 30.0)
  obese(
    label: 'Béo phì',
    bmiRangeLabel: 'BMI ≥ 30.0',
    minTotalGain: 5.0,
    maxTotalGain: 9.0,
    color: AppColors.error,
  );

  final String label;
  final String bmiRangeLabel;
  final double minTotalGain;
  final double maxTotalGain;
  final Color color;

  const IomBmiCategory({
    required this.label,
    required this.bmiRangeLabel,
    required this.minTotalGain,
    required this.maxTotalGain,
    required this.color,
  });
}

/// Phân tầng độ tuổi mẹ sinh học
enum MaternalAgeTier {
  /// Mẹ vị thành niên (< 18 tuổi)
  adolescent(
    label: 'Vị thành niên (<18)',
    color: AppColors.secondary,
  ),

  /// Độ tuổi sinh học tiêu chuẩn (18 - 34 tuổi)
  standard(
    label: 'Độ tuổi tiêu chuẩn (18-34)',
    color: AppColors.success,
  ),

  /// Thai kỳ nguy cơ cao / Lớn tuổi (≥ 35 tuổi - Advanced Maternal Age)
  advanced(
    label: 'Mẹ ≥ 35 tuổi (Nguy cơ cao)',
    color: Color(0xFFE11D48), // Rose
  );

  final String label;
  final Color color;

  const MaternalAgeTier({
    required this.label,
    required this.color,
  });
}

/// Đánh giá mức độ tăng cân thực tế so với dải khuyến nghị chuẩn IOM
enum WeightGainStatus {
  under(
    label: 'Tăng cân chậm hơn khuyến nghị',
    color: Color(0xFFF59E0B),
    icon: Icons.trending_down_rounded,
  ),
  optimal(
    label: 'Tăng cân lý tưởng trong chuẩn IOM',
    color: AppColors.success,
    icon: Icons.check_circle_rounded,
  ),
  over(
    label: 'Tăng cân nhanh hơn khuyến nghị',
    color: AppColors.error,
    icon: Icons.trending_up_rounded,
  );

  final String label;
  final Color color;
  final IconData icon;

  const WeightGainStatus({
    required this.label,
    required this.color,
    required this.icon,
  });
}

/// Dải cân nặng khuyến nghị cho tuần thai
class RecommendedWeightGain {
  final double minGainKg;
  final double maxGainKg;

  const RecommendedWeightGain({
    required this.minGainKg,
    required this.maxGainKg,
  });

  String get formattedRange => '+${minGainKg.toStringAsFixed(1)} ~ +${maxGainKg.toStringAsFixed(1)} kg';

  @override
  String toString() => 'RecommendedWeightGain($formattedRange)';
}

/// Kết quả đánh giá thể trạng toàn diện của thai phụ
class MaternalEvaluationResult {
  final double? bmi;
  final IomBmiCategory? bmiCategory;
  final int? age;
  final MaternalAgeTier? ageTier;
  final RecommendedWeightGain? weeklyGainRange;
  final double? actualGainKg;
  final WeightGainStatus? gainStatus;
  final String clinicalTip;
  final String husbandNutritionAdvice;
  final bool isMultiplePregnancy;

  const MaternalEvaluationResult({
    this.bmi,
    this.bmiCategory,
    this.age,
    this.ageTier,
    this.weeklyGainRange,
    this.actualGainKg,
    this.gainStatus,
    required this.clinicalTip,
    required this.husbandNutritionAdvice,
    this.isMultiplePregnancy = false,
  });
}

/// Dịch vụ tính toán y học thể trạng mẹ bầu và chuẩn tăng cân IOM (Institute of Medicine)
class MaternalCalculatorService {
  MaternalCalculatorService._();

  /// Tính chỉ số BMI tiền thai kỳ: BMI = weight (kg) / [height (m)]^2
  /// BẢO VỆ PHÉP CHIA CHO 0: bắt buộc kiểm tra (heightCm != null && heightCm > 0)
  static double? calculateBmi({double? heightCm, double? weightKg}) {
    if (heightCm == null || heightCm <= 0 || weightKg == null || weightKg <= 0) {
      return null;
    }
    final heightM = heightCm / 100.0;
    final rawBmi = weightKg / (heightM * heightM);
    if (rawBmi.isNaN || rawBmi.isInfinite) {
      return null;
    }
    return double.tryParse(rawBmi.toStringAsFixed(1));
  }

  /// Phân loại nhóm BMI theo tiêu chuẩn Viện Y học Hoa Kỳ (IOM 2009)
  static IomBmiCategory getBmiCategory(double bmi) {
    if (bmi < 18.5) {
      return IomBmiCategory.underweight;
    } else if (bmi < 25.0) {
      return IomBmiCategory.normal;
    } else if (bmi < 30.0) {
      return IomBmiCategory.overweight;
    } else {
      return IomBmiCategory.obese;
    }
  }

  /// Phân tầng độ tuổi mẹ sinh học
  static MaternalAgeTier getAgeTier(int? age) {
    if (age == null) return MaternalAgeTier.standard;
    if (age >= 35) return MaternalAgeTier.advanced;
    if (age < 18) return MaternalAgeTier.adolescent;
    return MaternalAgeTier.standard;
  }

  /// Tính toán dải cân nặng khuyến nghị cho tuần thai hiện tại (1..40)
  /// GIẢ ĐỊNH THAI ĐƠN (Singleton pregnancy) mặc định:
  /// - Tam cá nguyệt 1 (Tuần 1 - 13): 0.5 - 2.0 kg cho toàn bộ các nhóm BMI.
  /// - Tam cá nguyệt 2 & 3 (Tuần 14 - 40): Nội suy tuyến tính theo tốc độ tăng hàng tuần.
  static RecommendedWeightGain calculateWeeklyGainRange({
    required IomBmiCategory category,
    required int gestationalWeek,
    bool isMultiplePregnancy = false,
  }) {
    final cleanWeek = gestationalWeek.clamp(1, 40);

    // Xử lý đa thai (nếu có)
    if (isMultiplePregnancy) {
      // Đa thai: IOM khuyến nghị tăng 16.8 - 24.5 kg (với BMI bình thường)
      const t1Min = 1.0;
      const t1Max = 3.0;
      final totalMin = category.minTotalGain + 5.0;
      final totalMax = category.maxTotalGain + 8.0;

      if (cleanWeek <= 13) {
        final minVal = (t1Min / 13.0) * cleanWeek;
        final maxVal = (t1Max / 13.0) * cleanWeek;
        return RecommendedWeightGain(
          minGainKg: double.parse(minVal.toStringAsFixed(1)),
          maxGainKg: double.parse(maxVal.toStringAsFixed(1)),
        );
      } else {
        final t2Weeks = (cleanWeek - 13);
        final minVal = t1Min + ((totalMin - t1Min) / 27.0) * t2Weeks;
        final maxVal = t1Max + ((totalMax - t1Max) / 27.0) * t2Weeks;
        return RecommendedWeightGain(
          minGainKg: double.parse(minVal.toStringAsFixed(1)),
          maxGainKg: double.parse(maxVal.toStringAsFixed(1)),
        );
      }
    }

    // Thai đơn (Singleton Pregnancy):
    const t1Min = 0.5;
    const t1Max = 2.0;

    if (cleanWeek <= 13) {
      final minVal = (t1Min / 13.0) * cleanWeek;
      final maxVal = (t1Max / 13.0) * cleanWeek;
      return RecommendedWeightGain(
        minGainKg: double.parse(minVal.toStringAsFixed(1)),
        maxGainKg: double.parse(maxVal.toStringAsFixed(1)),
      );
    } else {
      final t2Weeks = cleanWeek - 13;
      final minVal = t1Min + ((category.minTotalGain - t1Min) / 27.0) * t2Weeks;
      final maxVal = t1Max + ((category.maxTotalGain - t1Max) / 27.0) * t2Weeks;
      return RecommendedWeightGain(
        minGainKg: double.parse(minVal.toStringAsFixed(1)),
        maxGainKg: double.parse(maxVal.toStringAsFixed(1)),
      );
    }
  }

  /// Đánh giá mức tăng cân thực tế so với dải IOM khuyến nghị
  static WeightGainStatus evaluateGain({
    required double actualGainKg,
    required RecommendedWeightGain recommended,
  }) {
    // Cho phép dung sai sinh học ±0.5 kg
    if (actualGainKg < recommended.minGainKg - 0.5) {
      return WeightGainStatus.under;
    } else if (actualGainKg > recommended.maxGainKg + 0.5) {
      return WeightGainStatus.over;
    } else {
      return WeightGainStatus.optimal;
    }
  }

  /// Đánh giá toàn diện hồ sơ thể trạng mẹ bầu và sinh lời khuyên cá nhân hóa
  static MaternalEvaluationResult evaluateProfile({
    required MaternalHealthProfileModel profile,
    required int gestationalWeek,
  }) {
    final bmi = profile.prePregnancyBmi;
    final bmiCategory = bmi != null ? getBmiCategory(bmi) : null;
    final age = profile.maternalAge;
    final ageTier = age != null ? getAgeTier(age) : null;

    RecommendedWeightGain? weeklyGainRange;
    if (bmiCategory != null) {
      weeklyGainRange = calculateWeeklyGainRange(
        category: bmiCategory,
        gestationalWeek: gestationalWeek,
        isMultiplePregnancy: profile.isMultiplePregnancy,
      );
    }

    final actualGainKg = profile.actualGainKg;
    WeightGainStatus? gainStatus;
    if (actualGainKg != null && weeklyGainRange != null) {
      gainStatus = evaluateGain(
        actualGainKg: actualGainKg,
        recommended: weeklyGainRange,
      );
    }

    // 1. Sinh lời khuyên lâm sàng (Clinical Tip)
    final StringBuffer clinicalBuffer = StringBuffer();
    if (ageTier == MaternalAgeTier.advanced) {
      clinicalBuffer.write(
        'Mẹ từ 35 tuổi trở lên (Thai kỳ cần theo dõi sát): Ưu tiên sàng lọc NIPT sớm từ tuần 10, siêu âm hình thái học chi tiết và kiểm tra huyết áp định kỳ phòng tiền sản giật. ',
      );
    } else if (ageTier == MaternalAgeTier.adolescent) {
      clinicalBuffer.write(
        'Mẹ trẻ tuổi: Cần chú trọng bổ sung đầy đủ canxi, sắt, kẽm và đạm để hỗ trợ sự phát triển song song của cả mẹ và bé. ',
      );
    }

    if (bmiCategory != null) {
      switch (bmiCategory) {
        case IomBmiCategory.underweight:
          clinicalBuffer.write(
            'Thể trạng trước bầu nhẹ cân: Cần nạp năng lượng giàu dưỡng chất (thịt đỏ, cá hồi, bơ, sữa hạt) để đạt mức tăng trưởng an toàn cho thai nhi.',
          );
          break;
        case IomBmiCategory.normal:
          clinicalBuffer.write(
            'Chỉ số BMI ban đầu rất lý tưởng! Hãy tiếp tục duy trì chế độ ăn cân bằng 4 nhóm chất, uống đủ nước và vận động nhẹ nhàng.',
          );
          break;
        case IomBmiCategory.overweight:
          clinicalBuffer.write(
            'Thể trạng trước bầu thừa cân: Ưu tiên tinh bột hấp thu chậm (gạo lứt, yến mạch), hạn chế đồ ngọt và tầm soát tiểu đường thai kỳ ở tuần 24-28.',
          );
          break;
        case IomBmiCategory.obese:
          clinicalBuffer.write(
            'Cần kiểm soát khẩu phần chất béo và đường tinh luyện. Chia nhỏ thành 5-6 bữa ăn trong ngày và theo dõi sát chỉ số đường huyết định kỳ.',
          );
          break;
      }
    } else {
      clinicalBuffer.write(
        'Cập nhật chiều cao và cân nặng để nhận phân tích chi tiết chuẩn IOM và dải tăng cân an toàn cho bạn.',
      );
    }

    // 2. Sinh thực đơn & gợi ý hành động cho Bố Bầu (Husband Actionable Nutrition Tip)
    final StringBuffer husbandBuffer = StringBuffer();
    if (gainStatus == WeightGainStatus.under) {
      husbandBuffer.write(
        'Vợ đang tăng cân chậm hơn chuẩn IOM. Bố hãy chuẩn bị thêm 2 bữa phụ dinh dưỡng mỗi ngày: sữa chua hạt chia, sinh tố bơ chuối, các loại hạt óc chó/hạnh nhân và sữa bầu ấm.',
      );
    } else if (gainStatus == WeightGainStatus.over) {
      husbandBuffer.write(
        'Vợ đang tăng cân nhanh hơn khuyến nghị. Bố giúp nàng chuẩn bị các món hấp/luộc thanh đạm, cắt sẵn đĩa ổi/táo/dưa chuột ăn vặt và rủ nàng đi dạo nhẹ nhàng 20 phút mỗi tối.',
      );
    } else if (gainStatus == WeightGainStatus.optimal) {
      husbandBuffer.write(
        'Mức tăng cân của vợ đang rất chuẩn mực! Bố tiếp tục duy trì thực đơn phong phú đủ rau xanh, cá hồi, thịt bò và động viên nàng uống đủ nước mỗi ngày.',
      );
    } else {
      husbandBuffer.write(
        'Bố hãy nhắc vợ cập nhật cân nặng thai kỳ định kỳ để cùng theo dõi sự phát triển tối ưu của bé yêu.',
      );
    }

    return MaternalEvaluationResult(
      bmi: bmi,
      bmiCategory: bmiCategory,
      age: age,
      ageTier: ageTier,
      weeklyGainRange: weeklyGainRange,
      actualGainKg: actualGainKg,
      gainStatus: gainStatus,
      clinicalTip: clinicalBuffer.toString().trim(),
      husbandNutritionAdvice: husbandBuffer.toString().trim(),
      isMultiplePregnancy: profile.isMultiplePregnancy,
    );
  }
}
