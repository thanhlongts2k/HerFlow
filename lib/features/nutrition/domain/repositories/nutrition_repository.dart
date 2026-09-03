// lib/features/nutrition/domain/repositories/nutrition_repository.dart
import '../../../../core/constants/cycle_phase.dart';
import '../entities/nutrition_recommendation.dart';

/// Hợp đồng Repository dinh dưỡng chu kỳ
abstract class NutritionRepository {
  NutritionRecommendation getRecommendationForPhase(CyclePhase phase);
}
