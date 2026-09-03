// lib/features/cycle/domain/entities/cycle_day_info.dart
import 'package:herflow/core/constants/cycle_phase.dart';

/// Thông tin sinh học & thể chất chi tiết cho một ngày trong chu kỳ
class CycleDayInfo {
  final DateTime date;
  final int cycleDay;
  final CyclePhase phase;
  final bool isPeriodDay;
  final bool isFertileWindow;
  final bool isOvulationDay;
  final String conceptionProbability;
  final String hormoneStatus;
  final String workoutTip;
  final int expectedEnergy;

  const CycleDayInfo({
    required this.date,
    required this.cycleDay,
    required this.phase,
    required this.isPeriodDay,
    required this.isFertileWindow,
    required this.isOvulationDay,
    required this.conceptionProbability,
    required this.hormoneStatus,
    required this.workoutTip,
    required this.expectedEnergy,
  });

  factory CycleDayInfo.calculate({
    required DateTime date,
    required int cycleDay,
    required CyclePhase phase,
    required bool isPeriodDay,
    required bool isFertileWindow,
    required bool isOvulationDay,
  }) {
    String prob;
    String hormone;
    String workout;
    int energy;

    if (isOvulationDay) {
      prob = 'Đỉnh điểm (Khả năng cao nhất)';
      hormone = 'Estrogen & Hormone tạo hoàng thể (LH) đạt đỉnh';
      workout = 'Thể lực dồi dào, thích hợp tập gym, bơi lội hoặc chạy bền';
      energy = 5;
    } else if (isFertileWindow) {
      prob = 'Cao (Cửa sổ thụ thai)';
      hormone = 'Estrogen tăng nhanh, niêm mạc tử cung dày lên';
      workout = 'Cardio vừa phải, zumba, pilates hoặc đạp xe';
      energy = 4;
    } else if (phase == CyclePhase.menstrual) {
      prob = 'Rất thấp';
      hormone = 'Estrogen & Progesterone ở mức thấp nhất';
      workout = 'Nghỉ ngơi tĩnh dưỡng, đi dạo nhẹ nhàng hoặc yoga phục hồi';
      energy = 1;
    } else if (phase == CyclePhase.follicular) {
      prob = 'Trung bình';
      hormone = 'Estrogen bắt đầu tăng dần, cơ thể tái sinh năng lượng';
      workout = 'Tập tạ nhẹ, yoga vinyasa hoặc chạy bộ nhịp nhàng';
      energy = 3;
    } else {
      // Luteal
      prob = 'Thấp';
      hormone = 'Progesterone chiếm ưu thế, tiền kinh nguyệt (PMS)';
      workout = 'Đi bộ thư giãn, giãn cơ chuyên sâu (Stretching), bơi nhẹ';
      energy = 2;
    }

    return CycleDayInfo(
      date: date,
      cycleDay: cycleDay,
      phase: phase,
      isPeriodDay: isPeriodDay,
      isFertileWindow: isFertileWindow,
      isOvulationDay: isOvulationDay,
      conceptionProbability: prob,
      hormoneStatus: hormone,
      workoutTip: workout,
      expectedEnergy: energy,
    );
  }
}
