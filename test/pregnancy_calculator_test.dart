// test/pregnancy_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:herflow/features/lifecycle/domain/models/fetal_week_data.dart';
import 'package:herflow/features/lifecycle/domain/models/pregnancy_config_model.dart';
import 'package:herflow/features/lifecycle/domain/services/pregnancy_calculator_service.dart';

void main() {
  group('PregnancyCalculatorService Unit Tests', () {
    test('calculateDueDateFromLMP: Tính đúng ngày dự sinh (LMP + 280 ngày)', () {
      final lmp = DateTime(2026, 1, 1);
      final edd = PregnancyCalculatorService.calculateDueDateFromLMP(lmp);

      // Năm 2026 không nhuận:
      // Tháng 1: 30 ngày còn lại (2-31)
      // Tháng 2: 28 ngày (58)
      // Tháng 3: 31 ngày (89)
      // Tháng 4: 30 ngày (119)
      // Tháng 5: 31 ngày (150)
      // Tháng 6: 30 ngày (180)
      // Tháng 7: 31 ngày (211)
      // Tháng 8: 31 ngày (242)
      // Tháng 9: 30 ngày (272)
      // Tháng 10: 8 ngày -> 280 ngày = 08/10/2026
      expect(edd, DateTime(2026, 10, 8));
      expect(edd.difference(lmp).inDays, 280);
    });

    test('calculateLMPFromDueDate: Tính đúng LMP từ ngày dự sinh (EDD - 280 ngày)', () {
      final edd = DateTime(2026, 10, 8);
      final lmp = PregnancyCalculatorService.calculateLMPFromDueDate(edd);

      expect(lmp, DateTime(2026, 1, 1));
      expect(edd.difference(lmp).inDays, 280);
    });

    test('calculateGestationalAge: Ngày thứ 80 thai kỳ phải ra Tuần 11 + 3 ngày', () {
      final lmp = DateTime(2026, 1, 1);
      // 80 ngày sau LMP:
      final targetDate = lmp.add(const Duration(days: 80)); // 2026-03-22

      final result = PregnancyCalculatorService.calculateGestationalAge(lmp, targetDate);

      expect(result.totalDaysPregnant, 80);
      expect(result.currentWeek, 11);
      expect(result.currentDayOfWeek, 3);
      expect(result.daysUntilDue, 200);
      expect(result.progressPercentage, closeTo(80 / 280, 0.001));
      expect(result.trimester, Trimester.first);
      expect(result.formattedAge, '11 tuần 3 ngày');
      expect(result.currentWeekOrdinal, 12); // Đang ở tuần thứ 12
    });

    test('Xác định chính xác 3 Tam cá nguyệt (Trimester)', () {
      final lmp = DateTime(2026, 1, 1);

      // Tuần 5 (ngày 35): Tam cá nguyệt 1
      final t1 = PregnancyCalculatorService.calculateGestationalAge(
        lmp,
        lmp.add(const Duration(days: 35)),
      );
      expect(t1.currentWeek, 5);
      expect(t1.trimester, Trimester.first);
      expect(t1.trimester.shortName, '3 tháng đầu');

      // Tuần 13 ngày 6 (ngày 97): Vẫn thuộc Tam cá nguyệt 1
      final t1End = PregnancyCalculatorService.calculateGestationalAge(
        lmp,
        lmp.add(const Duration(days: 97)),
      );
      expect(t1End.currentWeek, 13);
      expect(t1End.currentDayOfWeek, 6);
      expect(t1End.trimester, Trimester.first);

      // Tuần 14 ngày 0 (ngày 98): Bắt đầu Tam cá nguyệt 2
      final t2Start = PregnancyCalculatorService.calculateGestationalAge(
        lmp,
        lmp.add(const Duration(days: 98)),
      );
      expect(t2Start.currentWeek, 14);
      expect(t2Start.currentDayOfWeek, 0);
      expect(t2Start.trimester, Trimester.second);
      expect(t2Start.trimester.shortName, '3 tháng giữa');

      // Tuần 27 ngày 6 (ngày 195): Vẫn thuộc Tam cá nguyệt 2
      final t2End = PregnancyCalculatorService.calculateGestationalAge(
        lmp,
        lmp.add(const Duration(days: 195)),
      );
      expect(t2End.currentWeek, 27);
      expect(t2End.currentDayOfWeek, 6);
      expect(t2End.trimester, Trimester.second);

      // Tuần 28 ngày 0 (ngày 196): Bắt đầu Tam cá nguyệt 3
      final t3Start = PregnancyCalculatorService.calculateGestationalAge(
        lmp,
        lmp.add(const Duration(days: 196)),
      );
      expect(t3Start.currentWeek, 28);
      expect(t3Start.currentDayOfWeek, 0);
      expect(t3Start.trimester, Trimester.third);
      expect(t3Start.trimester.shortName, '3 tháng cuối');

      // Tuần 40 ngày 0 (ngày 280): Ngày dự sinh
      final t3Due = PregnancyCalculatorService.calculateGestationalAge(
        lmp,
        lmp.add(const Duration(days: 280)),
      );
      expect(t3Due.currentWeek, 40);
      expect(t3Due.daysUntilDue, 0);
      expect(t3Due.progressPercentage, 1.0);
      expect(t3Due.trimester, Trimester.third);
    });

    test('Edge Cases: Target date trước LMP và vượt quá ngày dự sinh', () {
      final lmp = DateTime(2026, 1, 1);

      // Target trước LMP
      final before = PregnancyCalculatorService.calculateGestationalAge(
        lmp,
        DateTime(2025, 12, 25),
      );
      expect(before.totalDaysPregnant, 0);
      expect(before.currentWeek, 0);
      expect(before.currentDayOfWeek, 0);
      expect(before.daysUntilDue, 280);
      expect(before.progressPercentage, 0.0);
      expect(before.trimester, Trimester.first);

      // Target vượt quá 280 ngày (thai quá ngày dự sinh, ngày 287 = 41 tuần 0 ngày)
      final overdue = PregnancyCalculatorService.calculateGestationalAge(
        lmp,
        lmp.add(const Duration(days: 287)),
      );
      expect(overdue.totalDaysPregnant, 287);
      expect(overdue.currentWeek, 41);
      expect(overdue.currentDayOfWeek, 0);
      expect(overdue.daysUntilDue, -7);
      expect(overdue.progressPercentage, 1.0); // clamped 1.0
      expect(overdue.trimester, Trimester.third);
    });
  });

  group('FetalWeeklyData Unit Tests', () {
    test('Bộ dữ liệu 40 tuần có đủ 40 tuần, không tuần nào bị thiếu hoặc rỗng', () {
      const list = FetalWeekData.fetalWeeklyDataList;
      expect(list.length, 40);

      for (int i = 0; i < 40; i++) {
        final item = list[i];
        final expectedWeek = i + 1;

        expect(item.week, expectedWeek, reason: 'Tuần thứ $expectedWeek phải đúng index');
        expect(item.fruitName.isNotEmpty, isTrue, reason: 'Tuần $expectedWeek thiếu fruitName');
        expect(item.fruitEmoji.isNotEmpty, isTrue, reason: 'Tuần $expectedWeek thiếu fruitEmoji');
        expect(item.babyHighlights.isNotEmpty, isTrue,
            reason: 'Tuần $expectedWeek thiếu babyHighlights');
        expect(item.momTip.isNotEmpty, isTrue, reason: 'Tuần $expectedWeek thiếu momTip');
        expect(item.approxLengthCm, greaterThanOrEqualTo(0.0));
        expect(item.approxWeightG, greaterThanOrEqualTo(0.0));
      }
    });

    test('Chiều dài và cân nặng thai nhi tăng dần từ tuần 4 đến 40', () {
      const list = FetalWeekData.fetalWeeklyDataList;
      for (int i = 4; i < 39; i++) {
        final current = list[i];
        final next = list[i + 1];

        expect(next.approxLengthCm, greaterThanOrEqualTo(current.approxLengthCm),
            reason: 'Chiều dài tuần ${next.week} phải >= tuần ${current.week}');
        expect(next.approxWeightG, greaterThanOrEqualTo(current.approxWeightG),
            reason: 'Cân nặng tuần ${next.week} phải >= tuần ${current.week}');
      }
    });

    test('getWeekData helper hỗ trợ clamp chính xác', () {
      // Tuần âm hoặc 0 clamp về tuần 1
      final w0 = FetalWeekData.getWeekData(0);
      expect(w0.week, 1);
      expect(w0.fruitName, 'Hạt mầm yêu thương');

      // Tuần vượt quá 40 clamp về tuần 40
      final w50 = FetalWeekData.getWeekData(50);
      expect(w50.week, 40);
      expect(w50.fruitName, 'Quả dưa hấu tròn lớn');

      // Tuần 20
      final w20 = FetalWeekData.getWeekData(20);
      expect(w20.week, 20);
      expect(w20.fruitName, 'Quả chuối tiêu');
      expect(w20.fruitEmoji, '🍌');
      expect(w20.formattedLength, '~25.6 cm');
      expect(w20.formattedWeight, '~300.0 g');

      // Tuần 40: hiển thị kg
      final w40 = FetalWeekData.getWeekData(40);
      expect(w40.formattedWeight, '~3.50 kg');
    });
  });

  group('PregnancyConfigModel Unit Tests', () {
    test('toMap và fromMap hoạt động toàn vẹn', () {
      final lmp = DateTime(2026, 1, 15);
      final edd = DateTime(2026, 10, 22);
      final conception = DateTime(2026, 1, 29);

      final model = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: edd,
        conceptionDate: conception,
        isTrackingActive: true,
      );

      final map = model.toMap();
      final restored = PregnancyConfigModel.fromMap(map);

      expect(restored.lastMenstrualPeriod, lmp);
      expect(restored.estimatedDueDate, edd);
      expect(restored.conceptionDate, conception);
      expect(restored.isTrackingActive, isTrue);
      expect(restored, model);
      expect(restored.hashCode, model.hashCode);
    });

    test('copyWith cho phép cập nhật từng trường độc lập', () {
      const initial = PregnancyConfigModel();
      expect(initial.isTrackingActive, isTrue);
      expect(initial.lastMenstrualPeriod, isNull);

      final lmp = DateTime(2026, 2, 1);
      final updated = initial.copyWith(
        lastMenstrualPeriod: lmp,
        isTrackingActive: false,
      );

      expect(updated.lastMenstrualPeriod, lmp);
      expect(updated.isTrackingActive, isFalse);
      expect(updated.estimatedDueDate, isNull);
    });

    test('fromMap với map null trả về model mặc định an toàn', () {
      final defaultModel = PregnancyConfigModel.fromMap(null);
      expect(defaultModel.isTrackingActive, isTrue);
      expect(defaultModel.lastMenstrualPeriod, isNull);
      expect(defaultModel.estimatedDueDate, isNull);
    });
  });
}
