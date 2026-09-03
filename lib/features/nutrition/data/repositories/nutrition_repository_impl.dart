// lib/features/nutrition/data/repositories/nutrition_repository_impl.dart
import '../../../../core/constants/cycle_phase.dart';
import '../../domain/entities/nutrition_recommendation.dart';
import '../../domain/repositories/nutrition_repository.dart';
import '../datasources/nutrition_local_datasource.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  final NutritionLocalDataSource _dataSource;

  NutritionRepositoryImpl(this._dataSource);

  @override
  NutritionRecommendation getRecommendationForPhase(CyclePhase phase) {
    return _dataSource.getRecommendation(phase);
  }
}
