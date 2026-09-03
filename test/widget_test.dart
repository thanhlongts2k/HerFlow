// test/widget_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/features/cycle/domain/entities/cycle_info.dart';
import 'package:herflow/features/cycle/domain/entities/period_record.dart';

void main() {
  group('Cycle Core Engine Unit Tests', () {
    final baseDate = DateTime(2026, 9, 1);
    final cycle = CycleInfo(
      lastPeriodStart: baseDate,
      cycleLength: 28,
      periodDuration: 5,
    );

    test('Menstrual Phase (Day 1 - 5) should be classified correctly', () {
      // Ngày 1
      expect(cycle.getCycleDay(baseDate), 1);
      expect(cycle.getPhaseForDate(baseDate), CyclePhase.menstrual);

      // Ngày 5
      final day5 = baseDate.add(const Duration(days: 4));
      expect(cycle.getCycleDay(day5), 5);
      expect(cycle.getPhaseForDate(day5), CyclePhase.menstrual);
      expect(cycle.isPeriodDay(day5), isTrue);
    });

    test('Follicular Phase (Day 6 - 12) should be classified correctly', () {
      final day7 = baseDate.add(const Duration(days: 6));
      expect(cycle.getCycleDay(day7), 7);
      expect(cycle.getPhaseForDate(day7), CyclePhase.follicular);
      expect(cycle.isPeriodDay(day7), isFalse);
    });

    test('Ovulation Phase (Day 13 - 15) should be classified correctly', () {
      // Ngày rụng trứng lý thuyết = 28 - 14 = ngày 14
      final ovulationDay = baseDate.add(const Duration(days: 13)); // Ngày 14
      expect(cycle.getCycleDay(ovulationDay), 14);
      expect(cycle.getPhaseForDate(ovulationDay), CyclePhase.ovulation);
      expect(cycle.isOvulationDay(ovulationDay), isTrue);
      expect(cycle.isFertileWindow(ovulationDay), isTrue);
      expect(cycle.getConceptionChance(ovulationDay), 'Rất cao (Đỉnh điểm)');
    });

    test('Luteal Phase (Day 16 - 28) should be classified correctly', () {
      final lutealDay = baseDate.add(const Duration(days: 20)); // Ngày 21
      expect(cycle.getCycleDay(lutealDay), 21);
      expect(cycle.getPhaseForDate(lutealDay), CyclePhase.luteal);
      expect(cycle.isFertileWindow(lutealDay), isFalse);
    });

    test('Days until next period calculation', () {
      // Ngày 1: Còn 28 ngày
      expect(cycle.daysUntilNextPeriod(baseDate), 28);

      // Ngày 15: Còn 14 ngày
      final day15 = baseDate.add(const Duration(days: 14));
      expect(cycle.daysUntilNextPeriod(day15), 14);
    });

    test('CycleDayInfo calculation provides workout & hormone insights', () {
      final dayInfo = cycle.getDayInfo(baseDate);
      expect(dayInfo.phase, CyclePhase.menstrual);
      expect(dayInfo.isPeriodDay, isTrue);
      expect(dayInfo.expectedEnergy, 1);
      expect(dayInfo.workoutTip.isNotEmpty, isTrue);
      expect(dayInfo.hormoneStatus.isNotEmpty, isTrue);
    });

    test('PeriodRecord duration and date matching', () {
      final record = PeriodRecord(
        id: 'rec-1',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 5),
        flowIntensity: FlowIntensity.heavy,
      );

      expect(record.durationInDays, 5);
      expect(record.containsDate(DateTime(2026, 8, 3)), isTrue);
      expect(record.containsDate(DateTime(2026, 8, 6)), isFalse);
    });
  });
}
