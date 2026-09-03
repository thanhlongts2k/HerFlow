// lib/features/mood/presentation/controllers/mood_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/mood/data/datasources/mood_local_datasource.dart';
import 'package:herflow/features/mood/data/repositories/mood_repository_impl.dart';
import 'package:herflow/features/mood/domain/entities/mood_entry.dart';
import 'package:herflow/features/mood/domain/repositories/mood_repository.dart';

/// Provider cung cấp DataSource cục bộ Hive cho Mood
final moodLocalDataSourceProvider = Provider<MoodLocalDataSource>((ref) {
  final box = Hive.box(AppConstants.moodBoxName);
  return MoodLocalDataSource(box);
});

/// Provider cung cấp Repository Mood
final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  final ds = ref.watch(moodLocalDataSourceProvider);
  return MoodRepositoryImpl(ds);
});

/// StateNotifier quản lý nhật ký cho ngày đang chọn
class SelectedDateMoodController extends StateNotifier<MoodEntry> {
  final MoodRepository _repository;
  final DateTime _selectedDate;

  SelectedDateMoodController(this._repository, this._selectedDate)
      : super(MoodEntry(date: _selectedDate)) {
    loadEntry();
  }

  Future<void> loadEntry() async {
    final entry = await _repository.getMoodEntryForDate(_selectedDate);
    if (entry != null) {
      state = entry;
    } else {
      state = MoodEntry(date: _selectedDate);
    }
  }

  Future<void> setEnergy(int level) async {
    state = state.copyWith(energyLevel: level);
    await _repository.saveMoodEntry(state);
  }

  Future<void> setMood(String mood) async {
    state = state.copyWith(mood: mood);
    await _repository.saveMoodEntry(state);
  }

  Future<void> toggleSymptom(String symptom) async {
    final list = List<String>.from(state.symptoms);
    if (list.contains(symptom)) {
      list.remove(symptom);
    } else {
      list.add(symptom);
    }
    state = state.copyWith(symptoms: list);
    await _repository.saveMoodEntry(state);
  }

  Future<void> setNote(String note) async {
    state = state.copyWith(note: note);
    await _repository.saveMoodEntry(state);
  }
}

/// Provider cho nhật ký của ngày đang chọn trên lịch
final selectedDateMoodProvider =
    StateNotifierProvider<SelectedDateMoodController, MoodEntry>((ref) {
  final repo = ref.watch(moodRepositoryProvider);
  final selectedDate = ref.watch(selectedCalendarDateProvider);
  return SelectedDateMoodController(repo, selectedDate);
});

/// Provider cung cấp dữ liệu 7 ngày gần nhất để vẽ biểu đồ fl_chart
final recentMoodHistoryProvider = FutureProvider<List<MoodEntry>>((ref) async {
  // Lắng nghe thay đổi của ngày đang chọn để tự động refresh chart
  ref.watch(selectedDateMoodProvider);
  final repo = ref.watch(moodRepositoryProvider);
  return repo.getRecentMoodEntries(days: 7);
});
