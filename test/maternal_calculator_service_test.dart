// test/maternal_calculator_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:herflow/features/lifecycle/domain/models/maternal_health_profile_model.dart';
import 'package:herflow/features/lifecycle/domain/models/pregnancy_config_model.dart';
import 'package:herflow/features/lifecycle/domain/services/maternal_calculator_service.dart';

void main() {
  group('MaternalCalculatorService - BẢO VỆ PHÉP CHIA CHO 0 & BMI', () {
    test('calculateBmi: Kiểm tra an toàn khi chiều cao hoặc cân nặng <= 0 hoặc null', () {
      expect(MaternalCalculatorService.calculateBmi(heightCm: null, weightKg: 50), isNull);
      expect(MaternalCalculatorService.calculateBmi(heightCm: 160, weightKg: null), isNull);
      expect(MaternalCalculatorService.calculateBmi(heightCm: 0, weightKg: 50), isNull);
      expect(MaternalCalculatorService.calculateBmi(heightCm: -160, weightKg: 50), isNull);
      expect(MaternalCalculatorService.calculateBmi(heightCm: 160, weightKg: 0), isNull);
      expect(MaternalCalculatorService.calculateBmi(heightCm: 160, weightKg: -50), isNull);
    });

    test('calculateBmi: Tính chính xác chỉ số BMI cho người 1m60 nặng 50kg (BMI ~19.5)', () {
      final bmi = MaternalCalculatorService.calculateBmi(heightCm: 160, weightKg: 50);
      expect(bmi, 19.5); // 50 / (1.6 * 1.6) = 19.53125 -> 19.5
    });

    test('calculateBmi: Tính chính xác chỉ số BMI cho người 1m55 nặng 65kg (BMI ~27.1)', () {
      final bmi = MaternalCalculatorService.calculateBmi(heightCm: 155, weightKg: 65);
      expect(bmi, 27.1); // 65 / (1.55 * 1.55) = 27.055 -> 27.1
    });
  });

  group('MaternalCalculatorService - PHÂN LOẠI 4 NHÓM CHUẨN IOM', () {
    test('getBmiCategory: Nhẹ cân (BMI < 18.5) có dải tăng 12.5 - 18.0 kg', () {
      final cat = MaternalCalculatorService.getBmiCategory(17.8);
      expect(cat, IomBmiCategory.underweight);
      expect(cat.minTotalGain, 12.5);
      expect(cat.maxTotalGain, 18.0);
    });

    test('getBmiCategory: Thể trạng bình thường (18.5 <= BMI < 25.0) có dải tăng 11.5 - 16.0 kg', () {
      expect(MaternalCalculatorService.getBmiCategory(18.5), IomBmiCategory.normal);
      expect(MaternalCalculatorService.getBmiCategory(22.0), IomBmiCategory.normal);
      expect(MaternalCalculatorService.getBmiCategory(24.9), IomBmiCategory.normal);
      expect(IomBmiCategory.normal.minTotalGain, 11.5);
      expect(IomBmiCategory.normal.maxTotalGain, 16.0);
    });

    test('getBmiCategory: Thừa cân (25.0 <= BMI < 30.0) có dải tăng 7.0 - 11.5 kg', () {
      expect(MaternalCalculatorService.getBmiCategory(25.0), IomBmiCategory.overweight);
      expect(MaternalCalculatorService.getBmiCategory(28.3), IomBmiCategory.overweight);
      expect(MaternalCalculatorService.getBmiCategory(29.9), IomBmiCategory.overweight);
      expect(IomBmiCategory.overweight.minTotalGain, 7.0);
      expect(IomBmiCategory.overweight.maxTotalGain, 11.5);
    });

    test('getBmiCategory: Béo phì (BMI >= 30.0) có dải tăng 5.0 - 9.0 kg', () {
      expect(MaternalCalculatorService.getBmiCategory(30.0), IomBmiCategory.obese);
      expect(MaternalCalculatorService.getBmiCategory(35.5), IomBmiCategory.obese);
      expect(IomBmiCategory.obese.minTotalGain, 5.0);
      expect(IomBmiCategory.obese.maxTotalGain, 9.0);
    });
  });

  group('MaternalCalculatorService - PHÂN TẦNG TUỔI MẸ (ĐẶC BIỆT TUỔI >= 35)', () {
    test('getAgeTier: Phân tầng chính xác 3 nhóm tuổi sinh học', () {
      expect(MaternalCalculatorService.getAgeTier(16), MaternalAgeTier.adolescent);
      expect(MaternalCalculatorService.getAgeTier(17), MaternalAgeTier.adolescent);

      expect(MaternalCalculatorService.getAgeTier(18), MaternalAgeTier.standard);
      expect(MaternalCalculatorService.getAgeTier(27), MaternalAgeTier.standard);
      expect(MaternalCalculatorService.getAgeTier(34), MaternalAgeTier.standard);

      expect(MaternalCalculatorService.getAgeTier(35), MaternalAgeTier.advanced);
      expect(MaternalCalculatorService.getAgeTier(42), MaternalAgeTier.advanced);

      expect(MaternalCalculatorService.getAgeTier(null), MaternalAgeTier.standard);
    });
  });

  group('MaternalCalculatorService - DẢI TĂNG CÂN THEO TUẦN (GIẢ ĐỊNH THAI ĐƠN)', () {
    test('calculateWeeklyGainRange: Tuần 13 phải đạt chuẩn Tam cá nguyệt 1 (0.5 - 2.0 kg)', () {
      final range = MaternalCalculatorService.calculateWeeklyGainRange(
        category: IomBmiCategory.normal,
        gestationalWeek: 13,
      );
      expect(range.minGainKg, 0.5);
      expect(range.maxGainKg, 2.0);
    });

    test('calculateWeeklyGainRange: Tuần 40 phải chạm đúng đích toàn thai kỳ IOM', () {
      // Nhẹ cân (12.5 - 18.0)
      final under = MaternalCalculatorService.calculateWeeklyGainRange(
        category: IomBmiCategory.underweight,
        gestationalWeek: 40,
      );
      expect(under.minGainKg, 12.5);
      expect(under.maxGainKg, 18.0);

      // Bình thường (11.5 - 16.0)
      final normal = MaternalCalculatorService.calculateWeeklyGainRange(
        category: IomBmiCategory.normal,
        gestationalWeek: 40,
      );
      expect(normal.minGainKg, 11.5);
      expect(normal.maxGainKg, 16.0);

      // Thừa cân (7.0 - 11.5)
      final over = MaternalCalculatorService.calculateWeeklyGainRange(
        category: IomBmiCategory.overweight,
        gestationalWeek: 40,
      );
      expect(over.minGainKg, 7.0);
      expect(over.maxGainKg, 11.5);

      // Béo phì (5.0 - 9.0)
      final obese = MaternalCalculatorService.calculateWeeklyGainRange(
        category: IomBmiCategory.obese,
        gestationalWeek: 40,
      );
      expect(obese.minGainKg, 5.0);
      expect(obese.maxGainKg, 9.0);
    });

    test('evaluateGain: Đánh giá chính xác 3 trạng thái Tăng chậm, Lý tưởng, Tăng nhanh', () {
      const rec = RecommendedWeightGain(minGainKg: 3.0, maxGainKg: 5.0);

      // Quá ít (dưới min - 0.5 = 2.5 kg)
      expect(
        MaternalCalculatorService.evaluateGain(actualGainKg: 2.0, recommended: rec),
        WeightGainStatus.under,
      );

      // Lý tưởng (từ 2.5 đến 5.5 kg)
      expect(
        MaternalCalculatorService.evaluateGain(actualGainKg: 2.8, recommended: rec),
        WeightGainStatus.optimal,
      );
      expect(
        MaternalCalculatorService.evaluateGain(actualGainKg: 4.0, recommended: rec),
        WeightGainStatus.optimal,
      );
      expect(
        MaternalCalculatorService.evaluateGain(actualGainKg: 5.2, recommended: rec),
        WeightGainStatus.optimal,
      );

      // Quá nhiều (vượt max + 0.5 = 5.5 kg)
      expect(
        MaternalCalculatorService.evaluateGain(actualGainKg: 6.0, recommended: rec),
        WeightGainStatus.over,
      );
    });
  });

  group('MaternalHealthProfileModel - PROGRESSIVE PROFILING & TƯƠNG THÍCH NGƯỢC HIVE', () {
    test('completionPercentage: Tính đúng tỷ lệ % hoàn thiện hồ sơ', () {
      // 0 trường
      const empty = MaternalHealthProfileModel();
      expect(empty.completionPercentage, 0);

      // 3 trường: năm sinh, chiều cao, cân nặng -> 50%
      const half = MaternalHealthProfileModel(
        birthYear: 1995,
        heightCm: 160,
        prePregnancyWeightKg: 52,
      );
      expect(half.completionPercentage, 50);
      expect(half.isBiometricsComplete, isTrue);

      // Đủ 6 trường -> 100%
      const full = MaternalHealthProfileModel(
        birthYear: 1995,
        heightCm: 160,
        prePregnancyWeightKg: 52,
        parity: 'Con so (Con đầu)',
        deliveryPlan: 'Sinh thường',
        targetHospital: 'BV Phụ Sản Hà Nội',
      );
      expect(full.completionPercentage, 100);
      expect(full.isBiometricsComplete, isTrue);
    });

    test('Safe Migration: Dữ liệu JSON cũ của PregnancyConfigModel không có maternalProfile vẫn parse an toàn', () {
      final oldJson = {
        'lastMenstrualPeriod': '2026-01-01T00:00:00.000',
        'estimatedDueDate': '2026-10-08T00:00:00.000',
        'isTrackingActive': true,
      };

      final config = PregnancyConfigModel.fromMap(oldJson);
      expect(config.lastMenstrualPeriod, DateTime(2026, 1, 1));
      expect(config.estimatedDueDate, DateTime(2026, 10, 8));
      expect(config.maternalProfile, isNull);
    });

    test('Full Roundtrip: Serialization toMap -> fromMap giữ nguyên 100% thuộc tính', () {
      final original = PregnancyConfigModel(
        lastMenstrualPeriod: DateTime(2026, 2, 1),
        estimatedDueDate: DateTime(2026, 11, 8),
        maternalProfile: const MaternalHealthProfileModel(
          birthYear: 1990,
          heightCm: 162.5,
          prePregnancyWeightKg: 54.0,
          currentWeightKg: 57.5,
          parity: 'Con rạ (Con thứ 2)',
          deliveryPlan: 'Sinh mổ',
          targetHospital: 'BV Từ Dũ',
          isMultiplePregnancy: false,
        ),
      );

      final map = original.toMap();
      final restored = PregnancyConfigModel.fromMap(map);

      expect(restored, equals(original));
      expect(restored.maternalProfile?.prePregnancyBmi, 20.4);
      expect(restored.maternalProfile?.actualGainKg, 3.5);
      expect(restored.maternalProfile?.targetHospital, 'BV Từ Dũ');
    });
  });

  group('MaternalEvaluationResult - LỜI KHUYÊN Y KHOA & THỰC ĐƠN BỐ BẦU', () {
    test('evaluateProfile: Mẹ >= 35 tuổi tự động kích hoạt cảnh báo NIPT', () {
      final profile = MaternalHealthProfileModel(
        birthYear: DateTime.now().year - 36, // 36 tuổi
        heightCm: 160,
        prePregnancyWeightKg: 50,
      );

      final eval = MaternalCalculatorService.evaluateProfile(
        profile: profile,
        gestationalWeek: 16,
      );

      expect(eval.ageTier, MaternalAgeTier.advanced);
      expect(eval.clinicalTip, contains('Mẹ từ 35 tuổi trở lên'));
      expect(eval.clinicalTip, contains('NIPT'));
    });

    test('evaluateProfile: Sinh thực đơn chuẩn cho Bố Bầu khi Vợ tăng cân chậm', () {
      const profile = MaternalHealthProfileModel(
        birthYear: 1996,
        heightCm: 160,
        prePregnancyWeightKg: 50, // BMI = 19.5 (Bình thường)
        currentWeightKg: 50.5,   // Tăng 0.5 kg ở tuần 24 (Chuẩn tuần 24 là ~4.9 ~ 7.7 kg)
      );

      final eval = MaternalCalculatorService.evaluateProfile(
        profile: profile,
        gestationalWeek: 24,
      );

      expect(eval.gainStatus, WeightGainStatus.under);
      expect(eval.husbandNutritionAdvice, contains('Vợ đang tăng cân chậm'));
      expect(eval.husbandNutritionAdvice, contains('sữa chua'));
    });
  });
}
