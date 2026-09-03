// lib/features/nutrition/domain/entities/nutrition_recommendation.dart
import '../../../../core/constants/cycle_phase.dart';

/// Thực thể thông tin dinh dưỡng đồng bộ theo từng pha chu kỳ
class NutritionRecommendation {
  final CyclePhase phase;
  final String title;
  final String description;
  final List<String> superfoods;
  final List<String> foodsToAvoid;
  final List<String> keyNutrients;
  final String teaSuggestion;
  final String sampleMeal;

  const NutritionRecommendation({
    required this.phase,
    required this.title,
    required this.description,
    required this.superfoods,
    required this.foodsToAvoid,
    required this.keyNutrients,
    required this.teaSuggestion,
    required this.sampleMeal,
  });
}
