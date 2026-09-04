// lib/core/storage/hive_migration_validator.dart

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';

/// Trình quản lý migration schema Hive cho Moona.
///
/// ## Mục đích (DP-01)
/// Đảm bảo người dùng đang chạy v0.6.6/v0.6.7 KHÔNG bị crash khi
/// nâng cấp lên v0.7.x có thêm các field mới trong Hive settings box.
///
/// ## Cách hoạt động
/// - Mỗi lần thêm field mới vào Hive: tăng [_currentSchemaVersion] lên 1.
/// - Viết thêm một migration method `_migrateVNToVN+1()`.
/// - Hệ thống sẽ tự động chạy migration còn thiếu theo thứ tự.
///
/// ## Nơi gọi
/// `main.dart` — sau khi `await Hive.openBox(...)`, trước `runApp()`.
///
/// ```dart
/// await HiveMigrationValidator.runMigrations(
///   settingsBox: Hive.box(AppConstants.settingsBoxName),
///   uid: currentUid, // có thể rỗng nếu chưa login
/// );
/// ```
class HiveMigrationValidator {
  HiveMigrationValidator._();

  /// Phiên bản schema hiện tại của ứng dụng.
  /// Tăng lên 1 mỗi khi thêm field mới vào Hive trong một bản phát hành mới.
  static const int _currentSchemaVersion = 2;

  /// Key lưu phiên bản schema (user-scoped để mỗi account track riêng).
  static const String _schemaVersionKey = 'hive_schema_version';

  /// Key coupleId trong PartnerSyncRepository (dùng để infer lifeStage).
  static const String _coupleIdKey = 'partner_couple_id';

  /// Key lifeStage mới (Phase 1).
  static const String _lifeStageKey = AppConstants.keyLifeStage;

  /// Key isPaused mới (Phase 1).
  static const String _isPausedKey = AppConstants.keyIsPausedMode;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Chạy toàn bộ migration cần thiết theo thứ tự version tăng dần.
  ///
  /// An toàn khi [uid] rỗng (user chưa đăng nhập) — sẽ dùng non-scoped key
  /// như một fallback. Thực tế migration quan trọng chỉ chạy sau khi login.
  ///
  /// Returns: schema version trước khi migrate (để logging/debugging).
  static Future<int> runMigrations({
    Box? settingsBox,
    String uid = '',
  }) async {
    final effectiveBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName);

    // Xác định scope key
    final versionKey = uid.isNotEmpty
        ? UserScope.key(_schemaVersionKey, uid)
        : _schemaVersionKey;

    // Đọc version hiện tại — null-safe (trả 0 nếu chưa có = user cũ v0.6.x)
    final raw = effectiveBox.get(versionKey);
    final currentVersion = raw is int ? raw : 0;

    if (currentVersion >= _currentSchemaVersion) {
      // Đã up-to-date, không làm gì
      return currentVersion;
    }

    debugPrint(
      '[HiveMigration] uid=${uid.isEmpty ? "anon" : uid}: '
      'schema v$currentVersion → v$_currentSchemaVersion',
    );

    // Chạy các migration còn thiếu theo thứ tự
    if (currentVersion < 1) {
      await _migrateV0ToV1(settingsBox: effectiveBox, uid: uid);
    }
    if (currentVersion < 2) {
      await _migrateV1ToV2(settingsBox: effectiveBox, uid: uid);
    }

    // Ghi lại version mới sau khi migration thành công
    await effectiveBox.put(versionKey, _currentSchemaVersion);
    debugPrint('[HiveMigration] Migration hoàn tất → v$_currentSchemaVersion');

    return currentVersion; // Trả version cũ để caller biết đã migrate hay chưa
  }

  // ── Private migration steps ───────────────────────────────────────────────

  /// Migration v0 → v1: Thêm field `life_stage`.
  ///
  /// Logic infer `lifeStage` từ `coupleId` hiện có:
  ///   - Nếu có coupleId hợp lệ → `LifeStage.couple`
  ///   - Không có → `LifeStage.solo`
  ///
  /// Chỉ ghi nếu chưa tồn tại (idempotent — an toàn khi chạy lại).
  static Future<void> _migrateV0ToV1({
    required Box settingsBox,
    required String uid,
  }) async {
    final lifeStageKey = uid.isNotEmpty
        ? UserScope.key(_lifeStageKey, uid)
        : _lifeStageKey;

    // Idempotent: Chỉ migrate nếu chưa có life_stage
    final existingStage = settingsBox.get(lifeStageKey);
    if (existingStage is String && existingStage.isNotEmpty) {
      debugPrint('[HiveMigration v0→v1] uid=$uid: life_stage đã tồn tại, skip.');
      return;
    }

    // Đọc coupleId để infer stage
    final coupleIdKey = uid.isNotEmpty
        ? UserScope.key(_coupleIdKey, uid)
        : _coupleIdKey;
    final coupleIdRaw = settingsBox.get(coupleIdKey);
    final hasValidCouple =
        coupleIdRaw is String && coupleIdRaw.trim().isNotEmpty;

    final migratedStage = hasValidCouple
        ? LifeStage.couple.toStorageString()
        : LifeStage.solo.toStorageString();

    await settingsBox.put(lifeStageKey, migratedStage);
    debugPrint(
      '[HiveMigration v0→v1] uid=$uid: '
      'coupleId=${hasValidCouple ? "có" : "không"} → lifeStage=$migratedStage',
    );
  }

  /// Migration v1 → v2: Thêm field `is_paused_mode`.
  ///
  /// Đảm bảo mọi user cũ đều có `isPaused = false` trong Hive,
  /// tránh NPE khi đọc field này lần đầu.
  static Future<void> _migrateV1ToV2({
    required Box settingsBox,
    required String uid,
  }) async {
    final pausedKey = uid.isNotEmpty
        ? UserScope.key(_isPausedKey, uid)
        : _isPausedKey;

    // Idempotent: Chỉ ghi nếu chưa có
    final existingPaused = settingsBox.get(pausedKey);
    if (existingPaused is bool) {
      debugPrint('[HiveMigration v1→v2] uid=$uid: is_paused_mode đã tồn tại, skip.');
      return;
    }

    await settingsBox.put(pausedKey, false);
    debugPrint('[HiveMigration v1→v2] uid=$uid: is_paused_mode = false (default)');
  }

  // ── Utility (dùng trong test) ─────────────────────────────────────────────

  /// Đọc schema version hiện tại của một uid cụ thể (dùng để debug/test).
  static int getCurrentSchemaVersion(Box settingsBox, String uid) {
    final key = uid.isNotEmpty
        ? UserScope.key(_schemaVersionKey, uid)
        : _schemaVersionKey;
    final raw = settingsBox.get(key);
    return raw is int ? raw : 0;
  }

  /// Đọc lifeStage đã lưu từ Hive (null-safe, không crash).
  static LifeStage readLifeStage(Box settingsBox, String uid) {
    final key = uid.isNotEmpty
        ? UserScope.key(_lifeStageKey, uid)
        : _lifeStageKey;
    final raw = settingsBox.get(key);
    final value = raw is String ? raw : null;
    return LifeStageExt.fromString(value);
  }

  /// Đọc isPaused đã lưu từ Hive (null-safe, mặc định false).
  static bool readIsPaused(Box settingsBox, String uid) {
    final key = uid.isNotEmpty
        ? UserScope.key(_isPausedKey, uid)
        : _isPausedKey;
    final raw = settingsBox.get(key);
    return raw is bool ? raw : false; // null → false, không crash
  }
}
