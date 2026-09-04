// lib/features/backup/domain/models/backup_payload.dart

import 'dart:convert';

/// Dữ liệu thô sau khi giải mã chứa snapshot toàn bộ các Hive Boxes của người dùng
class BackupPayload {
  final DateTime exportedAt;
  final String exportedByUid;
  final int schemaVersion;
  final Map<String, Map<String, dynamic>> boxes;

  const BackupPayload({
    required this.exportedAt,
    required this.exportedByUid,
    required this.schemaVersion,
    required this.boxes,
  });

  Map<String, dynamic> toMap() {
    return {
      'exportedAt': exportedAt.toIso8601String(),
      'exportedByUid': exportedByUid,
      'schemaVersion': schemaVersion,
      'boxes': boxes,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory BackupPayload.fromMap(Map<String, dynamic> map) {
    final rawBoxes = map['boxes'] as Map<String, dynamic>? ?? {};
    final parsedBoxes = <String, Map<String, dynamic>>{};

    rawBoxes.forEach((boxName, boxContent) {
      if (boxContent is Map) {
        parsedBoxes[boxName] = Map<String, dynamic>.from(boxContent);
      }
    });

    return BackupPayload(
      exportedAt: DateTime.tryParse(map['exportedAt'] as String? ?? '') ?? DateTime.now(),
      exportedByUid: map['exportedByUid'] as String? ?? '',
      schemaVersion: map['schemaVersion'] as int? ?? 1,
      boxes: parsedBoxes,
    );
  }

  factory BackupPayload.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return BackupPayload.fromMap(map);
  }
}
