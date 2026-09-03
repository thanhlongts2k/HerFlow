// lib/features/mood/domain/entities/mood_entry.dart
import 'dart:convert';

/// Thực thể lưu trữ cảm xúc, mức năng lượng và triệu chứng thể trạng hàng ngày
class MoodEntry {
  final DateTime date;
  final int energyLevel; // 1 (Kiệt sức) -> 5 (Tràn đầy năng lượng)
  final String mood; // Vui vẻ, Nhạy cảm, Cáu gắt, Lo âu, Thư thái, Bình yên
  final List<String> symptoms; // Đau bụng, Đau lưng, Căng ngực, Thèm ngọt, Đầy hơi...
  final String note;

  const MoodEntry({
    required this.date,
    this.energyLevel = 3,
    this.mood = 'Thư thái',
    this.symptoms = const [],
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'energyLevel': energyLevel,
      'mood': mood,
      'symptoms': symptoms,
      'note': note,
    };
  }

  factory MoodEntry.fromMap(Map<String, dynamic> map) {
    return MoodEntry(
      date: DateTime.parse(map['date'] as String),
      energyLevel: map['energyLevel'] as int? ?? 3,
      mood: map['mood'] as String? ?? 'Thư thái',
      symptoms: List<String>.from(map['symptoms'] ?? []),
      note: map['note'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory MoodEntry.fromJson(String source) =>
      MoodEntry.fromMap(json.decode(source) as Map<String, dynamic>);

  MoodEntry copyWith({
    DateTime? date,
    int? energyLevel,
    String? mood,
    List<String>? symptoms,
    String? note,
  }) {
    return MoodEntry(
      date: date ?? this.date,
      energyLevel: energyLevel ?? this.energyLevel,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      note: note ?? this.note,
    );
  }
}
