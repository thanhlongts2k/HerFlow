// lib/features/mood/domain/repositories/mood_repository.dart
import '../entities/mood_entry.dart';

/// Hợp đồng Repository quản lý nhật ký tâm trạng & triệu chứng thể chất
abstract class MoodRepository {
  /// Lấy nhật ký của một ngày cụ thể
  Future<MoodEntry?> getMoodEntryForDate(DateTime date);

  /// Lưu hoặc cập nhật nhật ký cho một ngày
  Future<void> saveMoodEntry(MoodEntry entry);

  /// Lấy danh sách các nhật ký trong N ngày gần nhất (để vẽ biểu đồ fl_chart)
  Future<List<MoodEntry>> getRecentMoodEntries({int days = 7});
}
