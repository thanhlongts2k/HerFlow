// lib/features/mood/data/repositories/mood_repository_impl.dart
import '../../domain/entities/mood_entry.dart';
import '../../domain/repositories/mood_repository.dart';
import '../datasources/mood_local_datasource.dart';

/// Triển khai thực tế MoodRepository
class MoodRepositoryImpl implements MoodRepository {
  final MoodLocalDataSource _localDataSource;

  MoodRepositoryImpl(this._localDataSource);

  @override
  Future<MoodEntry?> getMoodEntryForDate(DateTime date) async {
    return _localDataSource.getEntry(date);
  }

  @override
  Future<void> saveMoodEntry(MoodEntry entry) async {
    await _localDataSource.saveEntry(entry);
  }

  @override
  Future<List<MoodEntry>> getRecentMoodEntries({int days = 7}) async {
    return _localDataSource.getRecentEntries(days);
  }
}
