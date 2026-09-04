// lib/features/backup/domain/models/backup_metadata.dart

import 'dart:convert';
import 'package:herflow/core/security/backup_encryption_config.dart';

/// Đại diện cho toàn bộ tệp container sao lưu `.moona` gồm phần Header (Metadata) và phần Thân (Ciphertext)
class BackupContainer {
  final BackupMetadata metadata;
  final String ciphertext;

  const BackupContainer({
    required this.metadata,
    required this.ciphertext,
  });

  Map<String, dynamic> toMap() {
    return {
      'magic': metadata.magic,
      'formatVersion': metadata.formatVersion,
      'appVersion': metadata.appVersion,
      'createdAt': metadata.createdAt.toIso8601String(),
      'deviceId': metadata.deviceId,
      'uidHash': metadata.uidHash,
      'iv': metadata.ivBase64,
      'checksum': metadata.checksum,
      'boxCount': metadata.boxCount,
      'sizeBytes': metadata.sizeBytes,
      'ciphertext': ciphertext,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory BackupContainer.fromJson(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final magic = map['magic'] as String? ?? '';
    if (magic != BackupEncryptionConfig.magicHeader) {
      throw const FormatException('Định dạng tệp không phải bản sao lưu hợp lệ của Moona.');
    }

    final metadata = BackupMetadata.fromMap(map);
    final ciphertext = map['ciphertext'] as String? ?? '';
    if (ciphertext.trim().isEmpty) {
      throw const FormatException('Tệp sao lưu không chứa dữ liệu mã hóa.');
    }

    return BackupContainer(
      metadata: metadata,
      ciphertext: ciphertext,
    );
  }
}

/// Metadata đại diện cho thông tin định danh và bối cảnh của bản sao lưu
class BackupMetadata {
  final String magic;
  final int formatVersion;
  final String appVersion;
  final DateTime createdAt;
  final String deviceId;
  final String uidHash;
  final String ivBase64;
  final String checksum;
  final int boxCount;
  final int sizeBytes;

  const BackupMetadata({
    this.magic = BackupEncryptionConfig.magicHeader,
    required this.formatVersion,
    required this.appVersion,
    required this.createdAt,
    required this.deviceId,
    required this.uidHash,
    required this.ivBase64,
    required this.checksum,
    required this.boxCount,
    this.sizeBytes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'magic': magic,
      'formatVersion': formatVersion,
      'appVersion': appVersion,
      'createdAt': createdAt.toIso8601String(),
      'deviceId': deviceId,
      'uidHash': uidHash,
      'iv': ivBase64,
      'checksum': checksum,
      'boxCount': boxCount,
      'sizeBytes': sizeBytes,
    };
  }

  factory BackupMetadata.fromMap(Map<String, dynamic> map) {
    return BackupMetadata(
      magic: map['magic'] as String? ?? BackupEncryptionConfig.magicHeader,
      formatVersion: map['formatVersion'] as int? ?? 1,
      appVersion: map['appVersion'] as String? ?? '0.8.2',
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      deviceId: map['deviceId'] as String? ?? 'Thiết bị không xác định',
      uidHash: map['uidHash'] as String? ?? '',
      ivBase64: map['iv'] as String? ?? '',
      checksum: map['checksum'] as String? ?? '',
      boxCount: map['boxCount'] as int? ?? 0,
      sizeBytes: map['sizeBytes'] as int? ?? 0,
    );
  }

  BackupMetadata copyWith({int? sizeBytes}) {
    return BackupMetadata(
      magic: magic,
      formatVersion: formatVersion,
      appVersion: appVersion,
      createdAt: createdAt,
      deviceId: deviceId,
      uidHash: uidHash,
      ivBase64: ivBase64,
      checksum: checksum,
      boxCount: boxCount,
      sizeBytes: sizeBytes ?? this.sizeBytes,
    );
  }
}
