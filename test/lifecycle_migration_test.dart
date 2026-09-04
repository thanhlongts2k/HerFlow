// test/lifecycle_migration_test.dart
//
// Unit tests cho Step 1.1 — LifeStage model + HiveMigrationValidator (DP-01).
// Không phụ thuộc Firebase, Firestore hay Flutter widgets.
// Chạy: flutter test test/lifecycle_migration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/auth/domain/models/user_model.dart';
import 'package:herflow/core/storage/hive_migration_validator.dart';
import 'package:herflow/core/constants/app_constants.dart';

/// Mock Box Hive đơn giản dùng Map — không cần plugin native.
class _FakeHiveBox extends Fake implements Box {
  final Map<dynamic, dynamic> _data = {};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _data.containsKey(key) ? _data[key] : defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    _data[key] = value;
  }

  @override
  bool containsKey(dynamic key) => _data.containsKey(key);

  /// Helper: Seed dữ liệu ban đầu (giả lập dữ liệu Hive cũ của v0.6.6).
  void seed(Map<dynamic, dynamic> data) => _data.addAll(data);
}

void main() {
  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 1: LifeStage Enum
  // ════════════════════════════════════════════════════════════════════════════
  group('LifeStage enum', () {
    test('Có đủ 5 giá trị', () {
      expect(LifeStage.values.length, equals(5));
    });

    test('displayName trả tiếng Việt đúng cho mỗi stage', () {
      expect(LifeStage.solo.displayName,        equals('Nàng'));
      expect(LifeStage.couple.displayName,      equals('Chung Đôi'));
      expect(LifeStage.conception.displayName,  equals('Chuẩn Bị Bầu'));
      expect(LifeStage.pregnancy.displayName,   equals('Thai Kỳ'));
      expect(LifeStage.motherhood.displayName,  equals('Nuôi Con'));
    });

    test('icon trả emoji đúng', () {
      expect(LifeStage.solo.icon,        equals('🌸'));
      expect(LifeStage.couple.icon,      equals('💑'));
      expect(LifeStage.conception.icon,  equals('🌱'));
      expect(LifeStage.pregnancy.icon,   equals('🤰'));
      expect(LifeStage.motherhood.icon,  equals('🍼'));
    });

    test('description không rỗng cho mỗi stage', () {
      for (final stage in LifeStage.values) {
        expect(stage.description, isNotEmpty,
            reason: '$stage.description không được rỗng');
      }
    });

    group('Feature flags: supportsPartner & requiresCoupleModule', () {
      test('Solo = false (độc thân thuần túy không ghép đôi)', () {
        expect(LifeStage.solo.supportsPartner, isFalse);
        expect(LifeStage.solo.requiresCoupleModule, isFalse);
        expect(LifeStage.solo.isSolo, isTrue);
      });
      test('Couple, conception, pregnancy, motherhood = true (đều hỗ trợ bạn đời / Chồng)', () {
        for (final s in [
          LifeStage.couple,
          LifeStage.conception,
          LifeStage.pregnancy,
          LifeStage.motherhood,
        ]) {
          expect(s.supportsPartner, isTrue, reason: '$s phải hỗ trợ người đồng hành');
          expect(s.requiresCoupleModule, isTrue, reason: '$s cần kích hoạt module đồng hành');
          expect(s.isSolo, isFalse);
        }
      });
    });

    group('Feature flags: tracksMenstrualCycle', () {
      test('Solo, couple, conception = true', () {
        for (final s in [LifeStage.solo, LifeStage.couple, LifeStage.conception]) {
          expect(s.tracksMenstrualCycle, isTrue, reason: '$s phải theo dõi chu kỳ');
        }
      });
      test('Pregnancy, motherhood = false (DP-05)', () {
        expect(LifeStage.pregnancy.tracksMenstrualCycle, isFalse);
        expect(LifeStage.motherhood.tracksMenstrualCycle, isFalse);
      });
    });

    group('Feature flags: cyclePredictionPaused', () {
      test('Pregnancy và motherhood = true (LAM guard)', () {
        expect(LifeStage.pregnancy.cyclePredictionPaused, isTrue);
        expect(LifeStage.motherhood.cyclePredictionPaused, isTrue);
      });
      test('Các mode còn lại = false', () {
        for (final s in [LifeStage.solo, LifeStage.couple, LifeStage.conception]) {
          expect(s.cyclePredictionPaused, isFalse);
        }
      });
    });

    group('Feature flags: isPersonalMode', () {
      test('Chỉ Solo = true (cá nhân thuần túy, không hỗ trợ partner)', () {
        expect(LifeStage.solo.isPersonalMode, isTrue);
      });
      test('Các mode còn lại = false (đều có hỗ trợ partner)', () {
        for (final s in [
          LifeStage.couple,
          LifeStage.conception,
          LifeStage.pregnancy,
          LifeStage.motherhood,
        ]) {
          expect(s.isPersonalMode, isFalse, reason: '$s không phải personal-only mode');
        }
      });
    });

    group('displayOrder', () {
      test('Thứ tự tăng dần đúng', () {
        expect(LifeStage.solo.displayOrder,        equals(0));
        expect(LifeStage.couple.displayOrder,      equals(1));
        expect(LifeStage.conception.displayOrder,  equals(2));
        expect(LifeStage.pregnancy.displayOrder,   equals(3));
        expect(LifeStage.motherhood.displayOrder,  equals(4));
      });
    });

    group('Serialization: fromString', () {
      test('Parse đúng từ string hợp lệ', () {
        expect(LifeStageExt.fromString('solo'),        equals(LifeStage.solo));
        expect(LifeStageExt.fromString('couple'),      equals(LifeStage.couple));
        expect(LifeStageExt.fromString('conception'),  equals(LifeStage.conception));
        expect(LifeStageExt.fromString('pregnancy'),   equals(LifeStage.pregnancy));
        expect(LifeStageExt.fromString('motherhood'),  equals(LifeStage.motherhood));
      });

      test('Fallback về solo khi string không hợp lệ (DP-01)', () {
        expect(LifeStageExt.fromString(null),             equals(LifeStage.solo));
        expect(LifeStageExt.fromString(''),               equals(LifeStage.solo));
        expect(LifeStageExt.fromString('invalid_value'),  equals(LifeStage.solo));
        expect(LifeStageExt.fromString('COUPLE'),         equals(LifeStage.solo)); // case-sensitive
        expect(LifeStageExt.fromString('123'),            equals(LifeStage.solo));
      });

      test('toStorageString() round-trips qua fromString()', () {
        for (final stage in LifeStage.values) {
          final stored = stage.toStorageString();
          final restored = LifeStageExt.fromString(stored);
          expect(restored, equals(stage),
              reason: '$stage không round-trip đúng qua serialization');
        }
      });
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 2: UserModel backward compat & currentLifeStage getter
  // ════════════════════════════════════════════════════════════════════════════
  group('UserModel.currentLifeStage (DP-01 backward compat)', () {
    test('User v0.6.7 không có lifeStage + không có role → solo (default an toàn)', () {
      const user = UserModel(
        uid: 'uid1', displayName: 'Test', email: 'test@test.com',
        // lifeStage: null (mô phỏng user v0.6.6)
        // role: null
      );
      expect(user.currentLifeStage, equals(LifeStage.solo));
      expect(user.isCoupleMode, isFalse);
    });

    test('User v0.6.7 có role=husband + không có lifeStage → couple (backward compat)', () {
      const user = UserModel(
        uid: 'uid2', displayName: 'Chồng', email: 'chong@test.com',
        role: 'husband',
        // lifeStage: null (chưa có field này)
      );
      expect(user.currentLifeStage, equals(LifeStage.couple));
      expect(user.isCoupleMode, isTrue);
    });

    test('User v0.6.7 có role=wife + không có lifeStage → solo', () {
      const user = UserModel(
        uid: 'uid3', displayName: 'Vợ', email: 'vo@test.com',
        role: 'wife',
        // lifeStage: null
      );
      expect(user.currentLifeStage, equals(LifeStage.solo));
    });

    test('User mới v0.7 có lifeStage=couple → couple', () {
      const user = UserModel(
        uid: 'uid4', displayName: 'New', email: 'new@test.com',
        lifeStage: 'couple',
      );
      expect(user.currentLifeStage, equals(LifeStage.couple));
      expect(user.isCoupleMode, isTrue);
    });

    test('User mới v0.7 có lifeStage=pregnancy → pregnancy', () {
      const user = UserModel(
        uid: 'uid5', displayName: 'Pregnant', email: 'p@test.com',
        lifeStage: 'pregnancy',
      );
      expect(user.currentLifeStage, equals(LifeStage.pregnancy));
      expect(user.isBabyPhase, isTrue);
    });

    test('User mới có lifeStage hỏng (corrupt) → fallback solo, không crash', () {
      const user = UserModel(
        uid: 'uid6', displayName: 'Corrupt', email: 'c@test.com',
        lifeStage: 'INVALID_GARBAGE_FROM_DB',
      );
      expect(user.currentLifeStage, equals(LifeStage.solo));
      expect(() => user.currentLifeStage, returnsNormally);
    });

    test('isPaused mặc định false khi không truyền vào (DP-01)', () {
      const user = UserModel(
        uid: 'uid7', displayName: 'Test', email: 't@test.com',
        // isPaused không truyền → default false
      );
      expect(user.isPaused, isFalse);
    });

    test('copyWith giữ nguyên lifeStage và isPaused khi không truyền', () {
      const original = UserModel(
        uid: 'uid8', displayName: 'Orig', email: 'o@test.com',
        lifeStage: 'motherhood',
        isPaused: true,
        pauseReason: 'loss',
      );
      final updated = original.copyWith(displayName: 'Updated');
      expect(updated.lifeStage, equals('motherhood'));
      expect(updated.isPaused, isTrue);
      expect(updated.pauseReason, equals('loss'));
      expect(updated.displayName, equals('Updated'));
    });

    test('copyWith clearPauseReason=true xóa pauseReason về null', () {
      const user = UserModel(
        uid: 'uid9', displayName: 'Test', email: 't@test.com',
        isPaused: false,
        pauseReason: 'loss',
      );
      final cleared = user.copyWith(clearPauseReason: true);
      expect(cleared.pauseReason, isNull);
    });

    group('UserModel.fromMap backward compat (DP-01)', () {
      test('fromMap từ dữ liệu cũ v0.6.6 (không có lifeStage/isPaused) → không crash', () {
        final oldData = {
          'uid': 'uid_old',
          'displayName': 'User Cũ',
          'email': 'old@test.com',
          'role': 'wife',
          // Không có lifeStage, isPaused, pauseReason
        };
        final user = UserModel.fromMap(oldData);
        expect(user.lifeStage, isNull);
        expect(user.isPaused, isFalse);   // Default false, không NPE
        expect(user.pauseReason, isNull);
        expect(user.currentLifeStage, equals(LifeStage.solo));
      });

      test('fromMap với isPaused=null trong DB → false (type-safe)', () {
        final data = {
          'uid': 'uid_null',
          'displayName': 'Test',
          'email': 't@test.com',
          'isPaused': null, // Giá trị null rõ ràng
        };
        final user = UserModel.fromMap(data);
        expect(user.isPaused, isFalse); // Không crash
      });

      test('fromMap toMap round-trip bảo toàn tất cả field Phase 1', () {
        const original = UserModel(
          uid: 'uid_rt',
          displayName: 'Round Trip',
          email: 'rt@test.com',
          role: 'wife',
          lifeStage: 'couple',
          isPaused: false,
          pauseReason: null,
        );
        final map = original.toMap();
        final restored = UserModel.fromMap(map);
        expect(restored.lifeStage, equals(original.lifeStage));
        expect(restored.isPaused, equals(original.isPaused));
        expect(restored.pauseReason, equals(original.pauseReason));
        expect(restored.currentLifeStage, equals(LifeStage.couple));
      });
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 3: HiveMigrationValidator
  // ════════════════════════════════════════════════════════════════════════════
  group('HiveMigrationValidator (DP-01)', () {
    const String testUid = 'test_user_123';

    /// Helper: key scoped theo uid cho test.
    String k(String baseKey) => '${testUid}_$baseKey';

    test('User mới hoàn toàn (box rỗng) → migration chạy thành công', () async {
      final box = _FakeHiveBox();
      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      expect(
        HiveMigrationValidator.getCurrentSchemaVersion(box, testUid),
        equals(2), // currentSchemaVersion
      );
    });

    test('Sau migration: lifeStage = solo khi không có coupleId (v0.6.6 user)', () async {
      final box = _FakeHiveBox();
      // Không seed coupleId → không có couple

      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      expect(
        HiveMigrationValidator.readLifeStage(box, testUid),
        equals(LifeStage.solo),
      );
    });

    test('Sau migration: lifeStage = couple khi có coupleId (v0.6.7 user đã ghép đôi)', () async {
      final box = _FakeHiveBox();
      // Seed coupleId như v0.6.7 đã có
      box.seed({k('partner_couple_id'): 'couple_abc_123'});

      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      expect(
        HiveMigrationValidator.readLifeStage(box, testUid),
        equals(LifeStage.couple),
      );
    });

    test('Sau migration: isPaused = false (default an toàn)', () async {
      final box = _FakeHiveBox();
      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      expect(
        HiveMigrationValidator.readIsPaused(box, testUid),
        isFalse,
      );
    });

    test('Migration idempotent: chạy 2 lần không thay đổi kết quả', () async {
      final box = _FakeHiveBox();
      box.seed({k('partner_couple_id'): 'couple_xyz'});

      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);
      final stageAfterFirst = HiveMigrationValidator.readLifeStage(box, testUid);

      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);
      final stageAfterSecond = HiveMigrationValidator.readLifeStage(box, testUid);

      expect(stageAfterFirst, equals(stageAfterSecond));
      expect(stageAfterFirst, equals(LifeStage.couple));
    });

    test('Migration idempotent: lifeStage đã có sẵn → không bị ghi đè', () async {
      final box = _FakeHiveBox();
      // Seed: user đã có lifeStage=pregnancy và KHÔNG có coupleId
      box.seed({k('life_stage'): 'pregnancy'});

      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      // Phải giữ pregnancy, không bị đổi về solo
      expect(
        HiveMigrationValidator.readLifeStage(box, testUid),
        equals(LifeStage.pregnancy),
      );
    });

    test('readIsPaused: Hive có isPaused=true → trả true', () async {
      final box = _FakeHiveBox();
      box.seed({k(AppConstants.keyIsPausedMode): true});

      // Không chạy migration (isPaused đã có sẵn)
      expect(
        HiveMigrationValidator.readIsPaused(box, testUid),
        isTrue,
      );
    });

    test('readIsPaused: Hive có giá trị null → trả false không crash (DP-01)', () {
      final box = _FakeHiveBox();
      // Không seed gì → get() trả null

      expect(
        HiveMigrationValidator.readIsPaused(box, testUid),
        isFalse, // Null → false, không NPE
      );
    });

    test('readIsPaused: Hive có giá trị corrupt (String) → trả false không crash', () {
      final box = _FakeHiveBox();
      box.seed({k(AppConstants.keyIsPausedMode): 'true_corrupt'}); // String thay vì bool

      expect(
        HiveMigrationValidator.readIsPaused(box, testUid),
        isFalse, // Type check: 'true_corrupt' is! bool → false
      );
    });

    test('readLifeStage: Hive có giá trị corrupt → trả solo không crash', () {
      final box = _FakeHiveBox();
      box.seed({k(AppConstants.keyLifeStage): '!!!corrupt_value!!!'});

      expect(
        HiveMigrationValidator.readLifeStage(box, testUid),
        equals(LifeStage.solo), // Fallback an toàn
      );
    });

    test('Migration với uid rỗng (user chưa login) → không crash', () async {
      final box = _FakeHiveBox();
      await expectLater(
        HiveMigrationValidator.runMigrations(settingsBox: box, uid: ''),
        completes, // Không throw
      );
    });

    test('coupleId rỗng (empty string) → lifeStage = solo, không phải couple', () async {
      final box = _FakeHiveBox();
      // Seed coupleId rỗng (đã logout/unlink)
      box.seed({k('partner_couple_id'): ''});

      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      expect(
        HiveMigrationValidator.readLifeStage(box, testUid),
        equals(LifeStage.solo), // Chuỗi rỗng không tính là có couple
      );
    });

    test('runMigrations trả về version CŨ (trước khi migrate)', () async {
      final box = _FakeHiveBox();
      // box hoàn toàn mới → currentVersion = 0

      final previousVersion =
          await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      expect(previousVersion, equals(0)); // Đã từ v0 lên v2
    });

    test('runMigrations trả về version hiện tại khi đã up-to-date', () async {
      final box = _FakeHiveBox();

      // Lần 1: migrate từ 0 lên 2
      await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      // Lần 2: đã up-to-date → trả 2
      final version =
          await HiveMigrationValidator.runMigrations(settingsBox: box, uid: testUid);

      expect(version, equals(2));
    });
  });
}
