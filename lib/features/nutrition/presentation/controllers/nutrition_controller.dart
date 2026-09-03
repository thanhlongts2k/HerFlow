// lib/features/nutrition/presentation/controllers/nutrition_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:herflow/core/constants/cycle_phase.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/nutrition/data/datasources/nutrition_local_datasource.dart';
import 'package:herflow/features/nutrition/data/repositories/nutrition_repository_impl.dart';
import 'package:herflow/features/nutrition/domain/entities/nutrition_recommendation.dart';
import 'package:herflow/features/nutrition/domain/repositories/nutrition_repository.dart';

final nutritionDataSourceProvider = Provider<NutritionLocalDataSource>((ref) {
  return NutritionLocalDataSource();
});

final nutritionRepositoryProvider = Provider<NutritionRepository>((ref) {
  final ds = ref.watch(nutritionDataSourceProvider);
  return NutritionRepositoryImpl(ds);
});

/// Provider cung cấp đề xuất dinh dưỡng tự động theo pha sinh học của ngày đang chọn
final activeNutritionRecommendationProvider = Provider<NutritionRecommendation>((ref) {
  final cycleAsync = ref.watch(cycleControllerProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  final repo = ref.watch(nutritionRepositoryProvider);

  final phase = cycleAsync.maybeWhen(
    data: (info) => info.getPhaseForDate(selectedDate),
    orElse: () => CyclePhase.follicular,
  );

  return repo.getRecommendationForPhase(phase);
});
