// lib/features/partner_sync/domain/models/partner_status_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Mô hình dữ liệu trạng thái thể trạng & cảm xúc tóm tắt của Vợ đồng bộ lên Cloud cho Chồng xem
class PartnerStatusModel {
  final String coupleId;
  final String currentPhase;
  final int cycleDay;
  final int energyLevel;
  final String mood;
  final List<String> symptoms;
  final List<String> moodTags;
  final String moodSummary;
  final String husbandActionTip;
  final DateTime updatedAt;

  const PartnerStatusModel({
    required this.coupleId,
    required this.currentPhase,
    this.cycleDay = 1,
    required this.energyLevel,
    this.mood = '',
    this.symptoms = const [],
    required this.moodTags,
    this.moodSummary = '',
    required this.husbandActionTip,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'coupleId': coupleId,
      'currentPhase': currentPhase,
      'cycleDay': cycleDay,
      'energyLevel': energyLevel,
      'mood': mood,
      'symptoms': symptoms,
      'moodTags': moodTags,
      'moodSummary': moodSummary,
      'husbandActionTip': husbandActionTip,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory PartnerStatusModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final tags = List<String>.from(map['moodTags'] ?? []);
    final rawMood = map['mood'] as String? ?? '';
    final parsedMood = rawMood.isNotEmpty
        ? rawMood
        : (tags.isNotEmpty ? tags.first : 'Thư thái');

    final rawSymptoms = map['symptoms'] != null
        ? List<String>.from(map['symptoms'])
        : (tags.length > 1 ? tags.sublist(1) : <String>[]);

    return PartnerStatusModel(
      coupleId: map['coupleId'] as String? ?? '',
      currentPhase: map['currentPhase'] as String? ?? 'Nang trứng',
      cycleDay: (map['cycleDay'] as num?)?.toInt() ?? 1,
      energyLevel: (map['energyLevel'] as num?)?.toInt() ?? 3,
      mood: parsedMood,
      symptoms: rawSymptoms,
      moodTags: tags,
      moodSummary: map['moodSummary'] as String? ?? '',
      husbandActionTip: map['husbandActionTip'] as String? ?? '',
      updatedAt: parseDate(map['updatedAt']),
    );
  }

  factory PartnerStatusModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return PartnerStatusModel.fromMap(data);
  }

  PartnerStatusModel copyWith({
    String? coupleId,
    String? currentPhase,
    int? cycleDay,
    int? energyLevel,
    String? mood,
    List<String>? symptoms,
    List<String>? moodTags,
    String? moodSummary,
    String? husbandActionTip,
    DateTime? updatedAt,
  }) {
    return PartnerStatusModel(
      coupleId: coupleId ?? this.coupleId,
      currentPhase: currentPhase ?? this.currentPhase,
      cycleDay: cycleDay ?? this.cycleDay,
      energyLevel: energyLevel ?? this.energyLevel,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      moodTags: moodTags ?? this.moodTags,
      moodSummary: moodSummary ?? this.moodSummary,
      husbandActionTip: husbandActionTip ?? this.husbandActionTip,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
