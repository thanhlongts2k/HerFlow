// lib/features/backup/domain/services/backup_restore_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/security/backup_encryption_config.dart';
import 'package:herflow/core/security/backup_encryption_service.dart';
import 'package:herflow/core/storage/hive_migration_validator.dart';
import 'package:herflow/core/utils/user_scope.dart';
import '../models/backup_metadata.dart';
import '../models/backup_payload.dart';

/// Dịch vụ cốt lõi quản trị quy trình Sao lưu & Khôi phục dữ liệu toàn diện của Moona
class BackupRestoreService {
  final BackupEncryptionService _encryptionService;
  final FirebaseFirestore? _firestore;
  final List<String> _trackedBoxNames;

  BackupRestoreService({
    BackupEncryptionService? encryptionService,
    FirebaseFirestore? firestore,
    List<String>? trackedBoxNames,
  })  : _encryptionService = encryptionService ?? const BackupEncryptionService(),
        _firestore = firestore,
        _trackedBoxNames = trackedBoxNames ??
            const [
              AppConstants.cycleBoxName,
              AppConstants.moodBoxName,
              AppConstants.settingsBoxName,
              AppConstants.userBoxName,
              AppConstants.motherhoodBoxName,
              AppConstants.conceptionBoxName,
              AppConstants.pregnancyBoxName,
              AppConstants.nutritionBoxName,
            ];

  FirebaseFirestore get _effectiveFirestore => _firestore ?? FirebaseFirestore.instance;

  // ── 1. EXPORT / BACKUP ENGINE ─────────────────────────────────────────────

  /// Thu thập dữ liệu toàn bộ các Hive Box và đóng gói thành BackupContainer đã mã hóa
  Future<BackupContainer> createBackupContainer({
    required String uid,
    String? deviceId,
  }) async {
    final allBoxesData = <String, Map<String, dynamic>>{};

    // Quét qua tất cả các Box của 5 giai đoạn
    for (final boxName in _trackedBoxNames) {
      Box box;
      if (Hive.isBoxOpen(boxName)) {
        box = Hive.box(boxName);
      } else {
        try {
          box = await Hive.openBox(boxName);
        } catch (e) {
          debugPrint('[BackupRestoreService] Không thể mở box $boxName: $e');
          continue;
        }
      }

      final boxData = <String, dynamic>{};
      for (final key in box.keys) {
        final val = box.get(key);
        if (val != null) {
          boxData[key.toString()] = val;
        }
      }
      allBoxesData[boxName] = boxData;
    }

    // Đọc phiên bản schema hiện tại từ settingsBox
    int schemaVersion = 1;
    if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
      schemaVersion = HiveMigrationValidator.getCurrentSchemaVersion(
        Hive.box(AppConstants.settingsBoxName),
        uid,
      );
    }

    // Lấy thông tin phiên bản app từ package_info_plus (an toàn khi chạy test)
    String appVersion = '0.8.2';
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      // Fallback khi chạy headless test
    }

    // 1. Tạo raw payload
    final payload = BackupPayload(
      exportedAt: DateTime.now(),
      exportedByUid: uid,
      schemaVersion: schemaVersion,
      boxes: allBoxesData,
    );

    final plainJson = payload.toJson();

    // 2. Tính toán mã băm toàn vẹn Checksum SHA-256
    final checksum = _encryptionService.calculateChecksum(plainJson);

    // 3. Sinh IV ngẫu nhiên và dẫn xuất khóa từ UID
    final iv = _encryptionService.generateRandomIv();
    final keyBytes = _encryptionService.deriveKey(uid);

    // 4. Nén GZIP và Mã hóa AES-256-CBC
    final ciphertext = _encryptionService.encryptPayload(plainJson, keyBytes, iv);

    // 5. Tính mã băm danh tính UID để kiểm tra chéo
    final uidHash = _encryptionService.calculateUidHash(uid);

    final metadata = BackupMetadata(
      formatVersion: BackupEncryptionConfig.currentFormatVersion,
      appVersion: appVersion,
      createdAt: payload.exportedAt,
      deviceId: deviceId ?? (kIsWeb ? 'Web' : Platform.operatingSystem),
      uidHash: uidHash,
      ivBase64: iv.base64,
      checksum: checksum,
      boxCount: allBoxesData.length,
      sizeBytes: utf8.encode(ciphertext).length,
    );

    return BackupContainer(
      metadata: metadata,
      ciphertext: ciphertext,
    );
  }

  /// Xuất tệp sao lưu cục bộ dạng `.moona` vào thư mục tạm và trả về tệp
  Future<File> exportToLocalFile({
    required String uid,
    String? deviceId,
  }) async {
    final container = await createBackupContainer(uid: uid, deviceId: deviceId);
    final jsonStr = container.toJson();

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/moona_backup_$timestamp.${BackupEncryptionConfig.backupFileExtension}');
    await file.writeAsString(jsonStr, flush: true);

    // Lưu metadata lần sao lưu cục bộ gần nhất vào settingsBox
    await _cacheLastLocalBackup(container.metadata, uid);

    return file;
  }

  /// Kích hoạt hộp thoại chia sẻ hệ thống qua SharePlus để gửi file qua Zalo, Email, Drive
  Future<void> shareLocalBackupFile(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Bản sao lưu Moona (.moona)',
      text: 'Bản sao lưu dữ liệu Moona mã hóa AES-256 ngày ${DateTime.now().toLocal()}',
    );
  }

  /// Đồng bộ snapshot Hive đã mã hóa lên Firestore Private Vault (users/{uid}/backups/latest)
  Future<BackupMetadata> exportToCloudFirestore({
    required String uid,
    String? deviceId,
  }) async {
    if (uid.trim().isEmpty) {
      throw const BackupInvalidKeyException('Bạn cần đăng nhập để sao lưu lên Đám mây.');
    }

    final container = await createBackupContainer(uid: uid, deviceId: deviceId);
    final payloadMap = container.toMap();

    await _effectiveFirestore
        .collection('users')
        .doc(uid)
        .collection('backups')
        .doc('latest')
        .set(payloadMap);

    // Lưu cache metadata đám mây cục bộ để hiển thị offline
    await _cacheLastCloudBackup(container.metadata, uid);

    return container.metadata;
  }

  // ── 2. IMPORT / RESTORE ENGINE ─────────────────────────────────────────────

  /// Khôi phục dữ liệu từ BackupContainer: Giải mã -> Kiểm tra Checksum -> Ghi đè Hive -> Migration
  Future<BackupPayload> restoreFromContainer(
    BackupContainer container, {
    required String uid,
  }) async {
    // 1. Kiểm tra format version
    if (container.metadata.formatVersion > BackupEncryptionConfig.currentFormatVersion) {
      throw const BackupVersionMismatchException();
    }

    // 2. Kiểm tra UID chéo (Chống khôi phục nhầm dữ liệu của tài khoản khác)
    final expectedUidHash = _encryptionService.calculateUidHash(uid);
    if (container.metadata.uidHash.isNotEmpty && container.metadata.uidHash != expectedUidHash) {
      throw const BackupInvalidKeyException(
        'Tệp sao lưu này được tạo bởi một tài khoản Moona khác. '
        'Vui lòng đăng nhập đúng tài khoản gốc để mở khóa và khôi phục dữ liệu.',
      );
    }

    // 3. Dẫn xuất khóa và giải mã AES-256 + Decompress GZIP
    final keyBytes = _encryptionService.deriveKey(uid);
    final plainJson = _encryptionService.decryptPayload(
      container.ciphertext,
      keyBytes,
      container.metadata.ivBase64,
    );

    // 4. Xác minh tính toàn vẹn Checksum SHA-256
    final isChecksumValid = _encryptionService.verifyChecksum(
      plainJson,
      container.metadata.checksum,
    );
    if (!isChecksumValid) {
      throw const BackupCorruptedException(
        'Mã kiểm tra toàn vẹn Checksum không khớp. '
        'Tệp sao lưu có thể đã bị sửa đổi hoặc hư hại trong quá trình truyền tải.',
      );
    }

    // 5. Parse JSON payload
    final payload = BackupPayload.fromJson(plainJson);

    // 6. Ghi đè thông minh vào các Hive Box
    for (final entry in payload.boxes.entries) {
      final boxName = entry.key;
      final boxContent = entry.value;

      Box box;
      if (Hive.isBoxOpen(boxName)) {
        box = Hive.box(boxName);
      } else {
        box = await Hive.openBox(boxName);
      }

      // Ghi đè các key-value được phục hồi
      for (final kv in boxContent.entries) {
        await box.put(kv.key, kv.value);
      }
    }

    // 7. Chạy migration schema tự động nếu bản sao lưu thuộc schema cũ
    if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
      await HiveMigrationValidator.runMigrations(
        settingsBox: Hive.box(AppConstants.settingsBoxName),
        uid: uid,
      );
    }

    return payload;
  }

  /// Khôi phục từ đường dẫn tệp cục bộ (được chọn từ FilePicker)
  Future<BackupPayload> importFromLocalFile(
    String filePath, {
    required String uid,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw const BackupCorruptedException('Tệp sao lưu không tồn tại hoặc đã bị xóa.');
    }

    final jsonStr = await file.readAsString();
    final container = BackupContainer.fromJson(jsonStr);

    return restoreFromContainer(container, uid: uid);
  }

  /// Khôi phục từ snapshot đám mây mới nhất trên Firestore
  Future<BackupPayload> importFromCloudFirestore({
    required String uid,
  }) async {
    if (uid.trim().isEmpty) {
      throw const BackupInvalidKeyException('Bạn cần đăng nhập để khôi phục từ Đám mây.');
    }

    final doc = await _effectiveFirestore
        .collection('users')
        .doc(uid)
        .collection('backups')
        .doc('latest')
        .get();

    if (!doc.exists || doc.data() == null) {
      throw const BackupCorruptedException('Chưa có bản sao lưu đám mây nào cho tài khoản này.');
    }

    final container = BackupContainer.fromJson(jsonEncode(doc.data()));
    return restoreFromContainer(container, uid: uid);
  }

  /// Đọc thông tin tóm tắt của bản sao lưu đám mây gần nhất (nếu có)
  Future<BackupMetadata?> getLatestCloudBackupMetadata({
    required String uid,
  }) async {
    if (uid.trim().isEmpty) return null;

    try {
      final doc = await _effectiveFirestore
          .collection('users')
          .doc(uid)
          .collection('backups')
          .doc('latest')
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return BackupMetadata.fromMap(doc.data()!);
    } catch (e) {
      debugPrint('[BackupRestoreService] Lỗi đọc metadata cloud backup: $e');
      return null;
    }
  }

  // ── 3. PRIVATE CACHE HELPERS ──────────────────────────────────────────────

  Future<void> _cacheLastCloudBackup(BackupMetadata metadata, String uid) async {
    try {
      if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
        final box = Hive.box(AppConstants.settingsBoxName);
        final key = UserScope.key('last_cloud_backup_meta', uid);
        await box.put(key, jsonEncode(metadata.toMap()));
      }
    } catch (_) {}
  }

  Future<void> _cacheLastLocalBackup(BackupMetadata metadata, String uid) async {
    try {
      if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
        final box = Hive.box(AppConstants.settingsBoxName);
        final key = UserScope.key('last_local_backup_meta', uid);
        await box.put(key, jsonEncode(metadata.toMap()));
      }
    } catch (_) {}
  }
}
