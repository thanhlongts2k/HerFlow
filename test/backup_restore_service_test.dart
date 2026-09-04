// test/backup_restore_service_test.dart

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/security/backup_encryption_config.dart';
import 'package:herflow/core/security/backup_encryption_service.dart';
import 'package:herflow/core/storage/hive_migration_validator.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/backup/domain/models/backup_metadata.dart';
import 'package:herflow/features/backup/domain/services/backup_restore_service.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';

void main() {
  late Directory tempDir;
  late BackupRestoreService service;
  const testUid = 'uid_wife_mai_lan_2026';

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('moona_backup_restore_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    // Mở các Box cần thiết cho bài test
    await Hive.openBox(AppConstants.cycleBoxName);
    await Hive.openBox(AppConstants.settingsBoxName);
    await Hive.openBox(AppConstants.motherhoodBoxName);
    await Hive.openBox(AppConstants.moodBoxName);
    await Hive.openBox(AppConstants.userBoxName);

    service = BackupRestoreService(
      trackedBoxNames: [
        AppConstants.cycleBoxName,
        AppConstants.settingsBoxName,
        AppConstants.motherhoodBoxName,
        AppConstants.moodBoxName,
        AppConstants.userBoxName,
      ],
    );
  });

  tearDown(() async {
    // Dọn dẹp dữ liệu trong các Box sau mỗi bài test
    await Hive.box(AppConstants.cycleBoxName).clear();
    await Hive.box(AppConstants.settingsBoxName).clear();
    await Hive.box(AppConstants.motherhoodBoxName).clear();
    await Hive.box(AppConstants.moodBoxName).clear();
    await Hive.box(AppConstants.userBoxName).clear();
  });

  group('Restore Matrix Tests (Điều 11 & 12 AGENTS.md)', () {
    // ── M1: Roundtrip Chuẩn (Export -> Modify local -> Import -> Verify 100%) ──
    test('M1: Valid .moona container roundtrip restores 100% data across multiple stages', () async {
      final cycleBox = Hive.box(AppConstants.cycleBoxName);
      final settingsBox = Hive.box(AppConstants.settingsBoxName);
      final motherhoodBox = Hive.box(AppConstants.motherhoodBoxName);

      // Ghi dữ liệu mẫu đa giai đoạn
      await cycleBox.put(UserScope.key(AppConstants.keyLastPeriodStart, testUid), '2026-08-15T00:00:00.000');
      await cycleBox.put(UserScope.key(AppConstants.keyCycleLength, testUid), 30);
      await settingsBox.put(UserScope.key(AppConstants.keyLifeStage, testUid), LifeStage.motherhood.name);
      await motherhoodBox.put(UserScope.key(AppConstants.keyActiveChildId, testUid), 'baby-001');

      // 1. Export container
      final container = await service.createBackupContainer(uid: testUid, deviceId: 'Pixel 8');
      expect(container.metadata.boxCount, 5);
      expect(container.ciphertext.isNotEmpty, isTrue);

      // 2. Làm thay đổi dữ liệu cục bộ (giả lập mất dữ liệu hoặc cài lại)
      await cycleBox.put(UserScope.key(AppConstants.keyCycleLength, testUid), 24);
      await motherhoodBox.delete(UserScope.key(AppConstants.keyActiveChildId, testUid));

      // 3. Khôi phục từ container
      final restoredPayload = await service.restoreFromContainer(container, uid: testUid);
      expect(restoredPayload.exportedByUid, testUid);

      // 4. Kiểm chứng phục hồi chính xác 100%
      expect(cycleBox.get(UserScope.key(AppConstants.keyCycleLength, testUid)), 30);
      expect(cycleBox.get(UserScope.key(AppConstants.keyLastPeriodStart, testUid)), '2026-08-15T00:00:00.000');
      expect(settingsBox.get(UserScope.key(AppConstants.keyLifeStage, testUid)), LifeStage.motherhood.name);
      expect(motherhoodBox.get(UserScope.key(AppConstants.keyActiveChildId, testUid)), 'baby-001');
    });

    // ── M2: Tệp bị hỏng / Checksum Mismatch ──
    test('M2: Tampered container or corrupted checksum throws BackupCorruptedException and preserves local data', () async {
      final cycleBox = Hive.box(AppConstants.cycleBoxName);
      await cycleBox.put(UserScope.key(AppConstants.keyCycleLength, testUid), 28);

      final container = await service.createBackupContainer(uid: testUid);

      // Giả lập làm sai lệch checksum trong metadata
      final tamperedMetadata = BackupMetadata(
        formatVersion: container.metadata.formatVersion,
        appVersion: container.metadata.appVersion,
        createdAt: container.metadata.createdAt,
        deviceId: container.metadata.deviceId,
        uidHash: container.metadata.uidHash,
        ivBase64: container.metadata.ivBase64,
        checksum: 'tampered_fake_checksum_hash_1234567890',
        boxCount: container.metadata.boxCount,
      );

      final tamperedContainer = BackupContainer(
        metadata: tamperedMetadata,
        ciphertext: container.ciphertext,
      );

      // Thao tác khôi phục bắt buộc phải ném BackupCorruptedException
      expect(
        () => service.restoreFromContainer(tamperedContainer, uid: testUid),
        throwsA(isA<BackupCorruptedException>()),
      );

      // Dữ liệu cục bộ không bị ảnh hưởng (Zero regression)
      expect(cycleBox.get(UserScope.key(AppConstants.keyCycleLength, testUid)), 28);
    });

    // ── M3: Khôi phục bằng sai UID / Khóa tài khoản khác ──
    test('M3: Attempting restore with different UID throws BackupInvalidKeyException and preserves local data', () async {
      final cycleBox = Hive.box(AppConstants.cycleBoxName);
      await cycleBox.put(UserScope.key(AppConstants.keyCycleLength, testUid), 28);

      final container = await service.createBackupContainer(uid: testUid);

      // Cố gắng khôi phục bằng một tài khoản khác
      const differentUid = 'attacker_or_other_account_uid_999';

      expect(
        () => service.restoreFromContainer(container, uid: differentUid),
        throwsA(isA<BackupInvalidKeyException>()),
      );

      // Dữ liệu ban đầu giữ nguyên an toàn
      expect(cycleBox.get(UserScope.key(AppConstants.keyCycleLength, testUid)), 28);
    });

    // ── M4: Migration tương thích ngược từ phiên bản cũ (v0.6/v0.7) ──
    test('M4: Restoring legacy backup triggers HiveMigrationValidator and auto-migrates missing fields', () async {
      const legacyUid = 'legacy_user_v06';
      final settingsBox = Hive.box(AppConstants.settingsBoxName);

      // Tạo một container thủ công mô phỏng phiên bản cũ (chỉ có partner_couple_id, chưa có life_stage)
      const encService = BackupEncryptionService();
      final key = encService.deriveKey(legacyUid);
      final iv = encService.generateRandomIv();

      final legacyPayload = '{"exportedAt":"2026-08-01T00:00:00.000","exportedByUid":"$legacyUid","schemaVersion":0,"boxes":{"${AppConstants.settingsBoxName}":{"${UserScope.key('partner_couple_id', legacyUid)}":"couple-abc-123"}}}';
      final checksum = encService.calculateChecksum(legacyPayload);
      final ciphertext = encService.encryptPayload(legacyPayload, key, iv);

      final legacyContainer = BackupContainer(
        metadata: BackupMetadata(
          formatVersion: 1,
          appVersion: '0.6.6',
          createdAt: DateTime(2026, 8, 1),
          deviceId: 'Legacy Android',
          uidHash: encService.calculateUidHash(legacyUid),
          ivBase64: iv.base64,
          checksum: checksum,
          boxCount: 1,
        ),
        ciphertext: ciphertext,
      );

      // Khôi phục container cũ
      await service.restoreFromContainer(legacyContainer, uid: legacyUid);

      // Kiểm tra HiveMigrationValidator đã tự động suy luận lifeStage = couple và isPausedMode = false
      final migratedStage = HiveMigrationValidator.readLifeStage(settingsBox, legacyUid);
      final migratedPaused = HiveMigrationValidator.readIsPaused(settingsBox, legacyUid);

      expect(migratedStage, LifeStage.couple);
      expect(migratedPaused, isFalse);
    });

    // ── M5: Serialization Container JSON ──
    test('M5: BackupContainer JSON serialization roundtrip maintains structure', () async {
      final container = await service.createBackupContainer(uid: testUid, deviceId: 'Galaxy S24');
      final jsonStr = container.toJson();

      final parsed = BackupContainer.fromJson(jsonStr);
      expect(parsed.metadata.magic, BackupEncryptionConfig.magicHeader);
      expect(parsed.metadata.formatVersion, BackupEncryptionConfig.currentFormatVersion);
      expect(parsed.metadata.deviceId, 'Galaxy S24');
      expect(parsed.ciphertext, container.ciphertext);
    });

    // ── M6: Từ chối phiên bản cấu trúc không được hỗ trợ ──
    test('M6: Backup with unsupported formatVersion throws BackupVersionMismatchException', () async {
      final container = await service.createBackupContainer(uid: testUid);

      final futureContainer = BackupContainer(
        metadata: BackupMetadata(
          formatVersion: 999, // Phiên bản tương lai chưa hỗ trợ
          appVersion: '9.9.9',
          createdAt: DateTime.now(),
          deviceId: 'Future Device',
          uidHash: container.metadata.uidHash,
          ivBase64: container.metadata.ivBase64,
          checksum: container.metadata.checksum,
          boxCount: container.metadata.boxCount,
        ),
        ciphertext: container.ciphertext,
      );

      expect(
        () => service.restoreFromContainer(futureContainer, uid: testUid),
        throwsA(isA<BackupVersionMismatchException>()),
      );
    });
  });
}
