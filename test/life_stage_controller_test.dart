// test/life_stage_controller_test.dart
//
// Unit tests cho Step 1.2 — LifeStageController & State Management (Riverpod).
// Chạy: flutter test test/life_stage_controller_test.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';

/// Fake Box Hive mô phỏng in-memory storage cho unit tests.
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
  Future<void> delete(dynamic key) async {
    _data.remove(key);
  }

  @override
  bool containsKey(dynamic key) => _data.containsKey(key);

  void seed(Map<dynamic, dynamic> data) => _data.addAll(data);
}

void main() {
  setUp(() {
    UserScope.clear();
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 1: LifeStageState Data Class
  // ════════════════════════════════════════════════════════════════════════════
  group('LifeStageState data class', () {
    test('Khởi tạo mặc định: currentStage = solo, isPaused = false, isLoading = false', () {
      const state = LifeStageState();
      expect(state.currentStage, equals(LifeStage.solo));
      expect(state.isPaused, isFalse);
      expect(state.pauseReason, isNull);
      expect(state.isLoading, isFalse);
    });

    test('LifeStageState.normal constructor', () {
      const normal = LifeStageState.normal(stage: LifeStage.conception);
      expect(normal.currentStage, equals(LifeStage.conception));
      expect(normal.isPaused, isFalse);
      expect(normal.pauseReason, isNull);
      expect(normal.isLoading, isFalse);
    });

    test('copyWith cập nhật chính xác các field', () {
      const initial = LifeStageState(
        currentStage: LifeStage.solo,
        isPaused: false,
        pauseReason: null,
        isLoading: false,
      );

      final updated = initial.copyWith(
        currentStage: LifeStage.pregnancy,
        isPaused: true,
        pauseReason: 'medical',
        isLoading: true,
      );

      expect(updated.currentStage, equals(LifeStage.pregnancy));
      expect(updated.isPaused, isTrue);
      expect(updated.pauseReason, equals('medical'));
      expect(updated.isLoading, isTrue);
    });

    test('copyWith clearPauseReason = true xóa pauseReason về null', () {
      const state = LifeStageState(
        currentStage: LifeStage.pregnancy,
        isPaused: true,
        pauseReason: 'loss',
      );

      final cleared = state.copyWith(clearPauseReason: true);
      expect(cleared.pauseReason, isNull);
      expect(cleared.isPaused, isTrue);
    });

    test('Equality và hashCode hoạt động nhất quán', () {
      const state1 = LifeStageState(
        currentStage: LifeStage.motherhood,
        isPaused: true,
        pauseReason: 'personal',
        isLoading: false,
      );
      const state2 = LifeStageState(
        currentStage: LifeStage.motherhood,
        isPaused: true,
        pauseReason: 'personal',
        isLoading: false,
      );
      const state3 = LifeStageState(
        currentStage: LifeStage.couple,
        isPaused: false,
      );

      expect(state1, equals(state2));
      expect(state1.hashCode, equals(state2.hashCode));
      expect(state1, isNot(equals(state3)));
    });

    test('toString chứa đầy đủ thông tin state', () {
      const state = LifeStageState(
        currentStage: LifeStage.couple,
        isPaused: false,
        isLoading: true,
      );
      expect(state.toString(), contains('stage=LifeStage.couple'));
      expect(state.toString(), contains('isLoading=true'));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 2: LifeStageController Logic & Local Storage
  // ════════════════════════════════════════════════════════════════════════════
  group('LifeStageController', () {
    late _FakeHiveBox fakeBox;

    setUp(() {
      fakeBox = _FakeHiveBox();
    });

    test('Khởi tạo ban đầu khi Box rỗng -> default solo', () {
      final controller = LifeStageController(settingsBox: fakeBox);
      expect(controller.state.currentStage, equals(LifeStage.solo));
      expect(controller.state.isPaused, isFalse);
      expect(controller.state.pauseReason, isNull);
    });

    test('Khởi tạo đọc đúng dữ liệu sẵn có trong Box', () {
      fakeBox.seed({
        AppConstants.keyLifeStage: 'pregnancy',
        AppConstants.keyIsPausedMode: true,
        AppConstants.keyPauseReason: 'loss',
      });

      final controller = LifeStageController(settingsBox: fakeBox);
      expect(controller.state.currentStage, equals(LifeStage.pregnancy));
      expect(controller.state.isPaused, isTrue);
      expect(controller.state.pauseReason, equals('loss'));
    });

    test('switchStage cập nhật state và lưu Hive local', () async {
      final controller = LifeStageController(settingsBox: fakeBox);
      const uid = 'test_user_456';

      await controller.switchStage(LifeStage.conception, uid: uid);

      expect(controller.state.currentStage, equals(LifeStage.conception));
      expect(
        fakeBox.get(UserScope.key(AppConstants.keyLifeStage, uid)),
        equals('conception'),
      );
    });

    test('switchStage sang cùng stage là no-op (không ghi đè lại)', () async {
      final controller = LifeStageController(settingsBox: fakeBox);
      const uid = 'test_user_456';

      await controller.switchStage(LifeStage.solo, uid: uid);
      // State ban đầu đã là solo
      expect(controller.state.currentStage, equals(LifeStage.solo));
    });

    test('setPauseMode(isPaused: true) cập nhật state và lưu Hive', () async {
      final controller = LifeStageController(settingsBox: fakeBox);
      const uid = 'test_user_456';

      await controller.setPauseMode(
        isPaused: true,
        reason: 'medical',
        uid: uid,
      );

      expect(controller.state.isPaused, isTrue);
      expect(controller.state.pauseReason, equals('medical'));
      expect(
        fakeBox.get(UserScope.key(AppConstants.keyIsPausedMode, uid)),
        isTrue,
      );
      expect(
        fakeBox.get(UserScope.key(AppConstants.keyPauseReason, uid)),
        equals('medical'),
      );
    });

    test('setPauseMode(isPaused: false) xóa reason và tắt paused mode trong Hive', () async {
      final controller = LifeStageController(settingsBox: fakeBox);
      const uid = 'test_user_456';

      // Bật trước
      await controller.setPauseMode(isPaused: true, reason: 'loss', uid: uid);
      expect(controller.state.isPaused, isTrue);

      // Tắt lại
      await controller.setPauseMode(isPaused: false, uid: uid);
      expect(controller.state.isPaused, isFalse);
      expect(controller.state.pauseReason, isNull);
      expect(
        fakeBox.get(UserScope.key(AppConstants.keyIsPausedMode, uid)),
        isFalse,
      );
      expect(
        fakeBox.containsKey(UserScope.key(AppConstants.keyPauseReason, uid)),
        isFalse,
      );
    });

    test('reset() khôi phục trạng thái mặc định trong RAM', () async {
      final controller = LifeStageController(settingsBox: fakeBox);
      await controller.switchStage(LifeStage.motherhood);
      await controller.setPauseMode(isPaused: true, reason: 'personal');

      controller.reset();

      expect(controller.state.currentStage, equals(LifeStage.solo));
      expect(controller.state.isPaused, isFalse);
      expect(controller.state.pauseReason, isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 3: loadForUser & Backward Compatibility (DP-01)
  // ════════════════════════════════════════════════════════════════════════════
  group('loadForUser & Backward Compatibility', () {
    late _FakeHiveBox fakeBox;

    setUp(() {
      fakeBox = _FakeHiveBox();
    });

    test('Cloud có sẵn lifeStage hợp lệ -> load chính xác', () async {
      final controller = LifeStageController(settingsBox: fakeBox);
      const uid = 'user_cloud_stage';

      await controller.loadForUser(
        uid: uid,
        cloudLifeStage: 'motherhood',
      );

      expect(controller.state.currentStage, equals(LifeStage.motherhood));
      expect(
        fakeBox.get(UserScope.key(AppConstants.keyLifeStage, uid)),
        equals('motherhood'),
      );
    });

    test('Backward compat: Cloud không có lifeStage + hasCoupleId = true -> couple mode', () async {
      final controller = LifeStageController(settingsBox: fakeBox);
      const uid = 'user_legacy_coupled';

      await controller.loadForUser(
        uid: uid,
        cloudLifeStage: null,
        hasCoupleId: true,
      );

      expect(controller.state.currentStage, equals(LifeStage.couple));
      expect(
        fakeBox.get(UserScope.key(AppConstants.keyLifeStage, uid)),
        equals('couple'),
      );
    });

    test('Backward compat: Cloud không có lifeStage nhưng Hive có partner_couple_id -> couple mode', () async {
      const uid = 'user_local_coupled';
      fakeBox.seed({
        UserScope.key('partner_couple_id', uid): 'couple_xyz_123',
      });

      final controller = LifeStageController(settingsBox: fakeBox);
      await controller.loadForUser(
        uid: uid,
        cloudLifeStage: null,
        hasCoupleId: false, // caller không biết, nhưng Hive có
      );

      expect(controller.state.currentStage, equals(LifeStage.couple));
    });

    test('Backward compat: User hoàn toàn mới không có coupleId và không có cloud stage -> solo', () async {
      final controller = LifeStageController(settingsBox: fakeBox);
      const uid = 'user_new_solo';

      await controller.loadForUser(
        uid: uid,
        cloudLifeStage: null,
        hasCoupleId: false,
      );

      expect(controller.state.currentStage, equals(LifeStage.solo));
      expect(
        fakeBox.get(UserScope.key(AppConstants.keyLifeStage, uid)),
        equals('solo'),
      );
    });

    test('Hive đã có localStage khác solo (đã migration) -> ưu tiên localStage', () async {
      const uid = 'user_already_migrated';
      fakeBox.seed({
        UserScope.key(AppConstants.keyLifeStage, uid): 'pregnancy',
      });

      final controller = LifeStageController(settingsBox: fakeBox);
      await controller.loadForUser(
        uid: uid,
        cloudLifeStage: null,
        hasCoupleId: false,
      );

      expect(controller.state.currentStage, equals(LifeStage.pregnancy));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 4: Riverpod Selectors & Providers
  // ════════════════════════════════════════════════════════════════════════════
  group('Riverpod Selectors & Providers', () {
    late _FakeHiveBox fakeBox;
    late ProviderContainer container;

    setUp(() {
      fakeBox = _FakeHiveBox();
      container = ProviderContainer(
        overrides: [
          lifeStageControllerProvider.overrideWith(
            (ref) => LifeStageController(settingsBox: fakeBox, ref: ref),
          ),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('lifeStageProvider trỏ tới lifeStageControllerProvider', () {
      expect(
        container.read(lifeStageProvider).currentStage,
        equals(LifeStage.solo),
      );
    });

    test('isCoupleModeProvider: true khi couple, false khi khác', () async {
      expect(container.read(isCoupleModeProvider), isFalse);

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.couple);

      expect(container.read(isCoupleModeProvider), isTrue);
      expect(container.read(isSoloModeProvider), isFalse);
    });

    test('isSoloModeProvider: true khi solo, false khi khác', () async {
      expect(container.read(isSoloModeProvider), isTrue);

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.pregnancy);

      expect(container.read(isSoloModeProvider), isFalse);
    });

    test('isConceptionModeProvider: true khi conception', () async {
      expect(container.read(isConceptionModeProvider), isFalse);

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.conception);

      expect(container.read(isConceptionModeProvider), isTrue);
    });

    test('isPregnancyModeProvider: true khi pregnancy', () async {
      expect(container.read(isPregnancyModeProvider), isFalse);

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.pregnancy);

      expect(container.read(isPregnancyModeProvider), isTrue);
    });

    test('isMotherhoodModeProvider: true khi motherhood', () async {
      expect(container.read(isMotherhoodModeProvider), isFalse);

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.motherhood);

      expect(container.read(isMotherhoodModeProvider), isTrue);
    });

    test('isPausedModeProvider: phản ánh chính xác state.isPaused', () async {
      expect(container.read(isPausedModeProvider), isFalse);

      await container
          .read(lifeStageControllerProvider.notifier)
          .setPauseMode(isPaused: true, reason: 'loss');

      expect(container.read(isPausedModeProvider), isTrue);

      await container
          .read(lifeStageControllerProvider.notifier)
          .setPauseMode(isPaused: false);

      expect(container.read(isPausedModeProvider), isFalse);
    });

    test('isCyclePredictionPausedProvider: true ở thai kỳ & nuôi con, false ở các mode khác', () async {
      // Solo -> false
      expect(container.read(isCyclePredictionPausedProvider), isFalse);

      // Pregnancy -> true
      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.pregnancy);
      expect(container.read(isCyclePredictionPausedProvider), isTrue);

      // Motherhood -> true
      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.motherhood);
      expect(container.read(isCyclePredictionPausedProvider), isTrue);

      // Couple -> false
      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.couple);
      expect(container.read(isCyclePredictionPausedProvider), isFalse);
    });

    test('isBabyPhaseProvider: true cho pregnancy và motherhood', () async {
      expect(container.read(isBabyPhaseProvider), isFalse);

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.pregnancy);
      expect(container.read(isBabyPhaseProvider), isTrue);

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.motherhood);
      expect(container.read(isBabyPhaseProvider), isTrue);

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.solo);
      expect(container.read(isBabyPhaseProvider), isFalse);
    });

    test('currentLifeStageProvider cập nhật reactive khi switchStage', () async {
      expect(container.read(currentLifeStageProvider), equals(LifeStage.solo));

      await container
          .read(lifeStageControllerProvider.notifier)
          .switchStage(LifeStage.conception);

      expect(container.read(currentLifeStageProvider), equals(LifeStage.conception));
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // GROUP 5: Realtime Couple LifeStage Sync (Vợ -> Chồng)
  // ════════════════════════════════════════════════════════════════════════════
  group('Realtime Couple LifeStage Sync', () {
    test('getSavedCoupleId trả về coupleId hợp lệ từ Hive', () {
      final fakeBox = _FakeHiveBox();
      const uid = 'user_123';
      fakeBox.seed({
        UserScope.key('partner_couple_id', uid): 'couple_xyz',
      });
      final controller = LifeStageController(settingsBox: fakeBox);
      expect(controller.getSavedCoupleId(uid), equals('couple_xyz'));
    });

    test('getSavedCoupleId fallback về unscoped key khi scoped key null', () {
      final fakeBox = _FakeHiveBox();
      fakeBox.seed({
        'partner_couple_id': 'couple_fallback_456',
      });
      final controller = LifeStageController(settingsBox: fakeBox);
      expect(controller.getSavedCoupleId('uid_no_scoped'), equals('couple_fallback_456'));
    });

    test('switchStage với coupleId hoạt động an toàn (offline/no-app fallback)', () async {
      final fakeBox = _FakeHiveBox();
      const uid = 'user_wife_123';
      fakeBox.seed({
        UserScope.key('partner_couple_id', uid): 'couple_abc_456',
      });
      final controller = LifeStageController(settingsBox: fakeBox);
      await controller.switchStage(LifeStage.pregnancy, uid: uid);
      expect(controller.state.currentStage, equals(LifeStage.pregnancy));
      expect(
        fakeBox.get(UserScope.key(AppConstants.keyLifeStage, uid)),
        equals('pregnancy'),
      );
    });

    test('cancelCoupleSubscription & dispose dọn dẹp subscription an toàn', () {
      final fakeBox = _FakeHiveBox();
      final controller = LifeStageController(settingsBox: fakeBox);
      expect(controller.state.currentStage, equals(LifeStage.solo));
      controller.cancelCoupleSubscription();
      expect(() => controller.cancelCoupleSubscription(), returnsNormally);
      expect(() => controller.dispose(), returnsNormally);
    });
  });
}

