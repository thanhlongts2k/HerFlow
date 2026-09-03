// lib/features/mood/data/datasources/mood_local_datasource.dart
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/utils/date_utils.dart';
import '../../domain/entities/mood_entry.dart';

/// Nguồn dữ liệu Hive cục bộ cho Nhật ký Tâm trạng & Thể trạng
class MoodLocalDataSource {
  final Box _box;

  MoodLocalDataSource(this._box);

  String _dateKey(DateTime date) {
    final norm = AppDateUtils.normalize(date);
    return '${norm.year}-${norm.month.toString().padLeft(2, '0')}-${norm.day.toString().padLeft(2, '0')}';
  }

  MoodEntry? getEntry(DateTime date) {
    final key = _dateKey(date);
    final raw = _box.get(key);
    if (raw != null && raw is String) {
      try {
        return MoodEntry.fromJson(raw);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveEntry(MoodEntry entry) async {
    final key = _dateKey(entry.date);
    await _box.put(key, entry.toJson());
  }

  List<MoodEntry> getRecentEntries(int days) {
    final list = <MoodEntry>[];
    final today = AppDateUtils.normalize(DateTime.now());

    for (int i = days - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      final entry = getEntry(d) ?? MoodEntry(date: d, energyLevel: 3, mood: 'Bình thường');
      list.add(entry);
    }
    return list;
  }
}
