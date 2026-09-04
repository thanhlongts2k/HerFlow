// ignore_for_file: subtype_of_sealed_class, annotate_overrides
// test/life_stage_transition_matrix_test.dart
//
// Test suite chuyên biệt kiểm tra toàn bộ ma trận chuyển đổi 2 chiều (Bidirectional Transition Matrix)
// giữa 4 giai đoạn sống có hỗ trợ người đồng hành (Chung Đôi, Chuẩn Bị Bầu, Thai Kỳ, Nuôi Con).
//
// Chạy: flutter test test/life_stage_transition_matrix_test.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';

// ── In-Memory Fake Hive Box ───────────────────────────────────────────────────

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

// ── In-Memory Fake Firestore with Reactive Stream ───────────────────────────

class _FakeDocumentSnapshot extends Fake implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? _data;
  final bool _exists;

  _FakeDocumentSnapshot(this._data, this._exists);

  @override
  bool get exists => _exists;

  @override
  Map<String, dynamic>? data() => _data;
}

class _FakeDocumentReference extends Fake implements DocumentReference<Map<String, dynamic>> {
  @override
  final String path;
  @override
  final _FakeFirebaseFirestore firestore;
  final StreamController<DocumentSnapshot<Map<String, dynamic>>> _streamController =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();

  _FakeDocumentReference(this.path, this.firestore);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    final current = firestore._storage[path] ?? <String, dynamic>{};
    if (options?.merge == true) {
      firestore._storage[path] = {...current, ...data};
    } else {
      firestore._storage[path] = Map<String, dynamic>.from(data);
    }
    _streamController.add(_FakeDocumentSnapshot(firestore._storage[path], true));
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots({
    bool includeMetadataChanges = false,
    ListenSource source = ListenSource.defaultSource,
  }) async* {
    final current = firestore._storage[path];
    if (current != null) {
      yield _FakeDocumentSnapshot(current, true);
    }
    yield* _streamController.stream;
  }
}

class _FakeCollectionReference extends Fake implements CollectionReference<Map<String, dynamic>> {
  final String collectionPath;
  @override
  final _FakeFirebaseFirestore firestore;

  _FakeCollectionReference(this.collectionPath, this.firestore);

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) {
    final docPath = '$collectionPath/${path ?? "default"}';
    return firestore._docs.putIfAbsent(
      docPath,
      () => _FakeDocumentReference(docPath, firestore),
    );
  }
}

class _FakeFirebaseFirestore extends Fake implements FirebaseFirestore {
  final Map<String, Map<String, dynamic>> _storage = {};
  final Map<String, _FakeDocumentReference> _docs = {};

  @override
  CollectionReference<Map<String, dynamic>> collection(String collectionPath) {
    return _FakeCollectionReference(collectionPath, this);
  }

  Map<String, dynamic>? getDocumentData(String path) => _storage[path];
}

// ── Test Suite ───────────────────────────────────────────────────────────────

void main() {
  const coupleId = 'test_couple_matrix_999';
  const wifeUid = 'wife_uid_123';
  const husbandUid = 'husband_uid_456';

  late _FakeFirebaseFirestore fakeFirestore;
  late _FakeHiveBox wifeHive;
  late _FakeHiveBox husbandHive;
  late LifeStageController wifeController;
  late LifeStageController husbandController;

  setUp(() {
    UserScope.clear();
    fakeFirestore = _FakeFirebaseFirestore();

    // 1. Setup Hive cho Vợ
    wifeHive = _FakeHiveBox();
    wifeHive.seed({
      UserScope.key('partner_couple_id', wifeUid): coupleId,
      'partner_couple_id': coupleId,
    });

    // 2. Setup Hive cho Chồng
    husbandHive = _FakeHiveBox();
    husbandHive.seed({
      UserScope.key('partner_couple_id', husbandUid): coupleId,
      'partner_couple_id': coupleId,
    });

    // 3. Khởi tạo Controller cho Vợ & Chồng cùng kết nối vào FakeFirestore
    wifeController = LifeStageController(
      settingsBox: wifeHive,
      firestore: fakeFirestore,
    );

    husbandController = LifeStageController(
      settingsBox: husbandHive,
      firestore: fakeFirestore,
      defaultUid: husbandUid,
    );
  });

  tearDown(() {
    wifeController.dispose();
    husbandController.dispose();
  });

  /// Hàm tiện ích kiểm tra chu trình chuyển đổi 2 chiều hoàn chỉnh:
  /// Stage A -> Stage B, sau đó Stage B -> Stage A.
  Future<void> assertBidirectionalTransition({
    required LifeStage stageA,
    required LifeStage stageB,
  }) async {
    // Thiết lập trạng thái ban đầu: Stage A
    UserScope.setActiveUid(wifeUid);
    await wifeController.switchStage(stageA, uid: wifeUid);
    expect(wifeController.state.currentStage, equals(stageA));

    // Chồng bắt đầu lắng nghe stream từ document couples/{coupleId}
    UserScope.setActiveUid(husbandUid);
    husbandController.startListeningToCouple(coupleId, husbandUid);
    await Future.delayed(const Duration(milliseconds: 20));

    // Verify Chồng nhận được Stage A ban đầu
    expect(husbandController.state.currentStage, equals(stageA));

    // ──────────────────────────────────────────────────────────────────────────
    // CHIỀU ĐI: Vợ chuyển từ Stage A -> Stage B
    // ──────────────────────────────────────────────────────────────────────────
    UserScope.setActiveUid(wifeUid);
    await wifeController.switchStage(stageB, uid: wifeUid);

    // 1. Xác minh Vợ đã đổi sang Stage B trên RAM và Hive của Vợ
    expect(wifeController.state.currentStage, equals(stageB));
    expect(
      wifeHive.get(UserScope.key(AppConstants.keyLifeStage, wifeUid)),
      equals(stageB.toStorageString()),
    );

    // 2. Xác minh Firestore couples/{coupleId} nhận đúng Stage B
    final firestoreDataB = fakeFirestore.getDocumentData('couples/$coupleId');
    expect(firestoreDataB, isNotNull);
    expect(firestoreDataB!['currentStage'], equals(stageB.toStorageString()));
    expect(firestoreDataB['lifeStage'], equals(stageB.toStorageString()));

    // Đợi stream của Chồng nhận event
    await Future.delayed(const Duration(milliseconds: 20));

    // 3. Xác minh Chồng tự động đồng bộ sang Stage B trên RAM và Hive của Chồng
    expect(
      husbandController.state.currentStage,
      equals(stageB),
      reason: 'Chồng phải tự chuyển sang ${stageB.displayName} khi Vợ chọn',
    );
    expect(
      husbandHive.get(UserScope.key(AppConstants.keyLifeStage, husbandUid)),
      equals(stageB.toStorageString()),
    );

    // ──────────────────────────────────────────────────────────────────────────
    // CHIỀU VỀ: Vợ chuyển ngược lại từ Stage B -> Stage A
    // ──────────────────────────────────────────────────────────────────────────
    UserScope.setActiveUid(wifeUid);
    await wifeController.switchStage(stageA, uid: wifeUid);

    // 4. Xác minh Vợ đã đổi về Stage A trên RAM và Hive của Vợ
    expect(wifeController.state.currentStage, equals(stageA));
    expect(
      wifeHive.get(UserScope.key(AppConstants.keyLifeStage, wifeUid)),
      equals(stageA.toStorageString()),
    );

    // 5. Xác minh Firestore couples/{coupleId} nhận đúng Stage A
    final firestoreDataA = fakeFirestore.getDocumentData('couples/$coupleId');
    expect(firestoreDataA, isNotNull);
    expect(firestoreDataA!['currentStage'], equals(stageA.toStorageString()));
    expect(firestoreDataA['lifeStage'], equals(stageA.toStorageString()));

    // Đợi stream của Chồng nhận event
    await Future.delayed(const Duration(milliseconds: 20));

    // 6. Xác minh Chồng tự động đồng bộ quay về Stage A trên RAM và Hive của Chồng
    expect(
      husbandController.state.currentStage,
      equals(stageA),
      reason: 'Chồng phải tự chuyển quay về ${stageA.displayName} khi Vợ chọn',
    );
    expect(
      husbandHive.get(UserScope.key(AppConstants.keyLifeStage, husbandUid)),
      equals(stageA.toStorageString()),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TOÀN BỘ MA TRẬN 6 CẶP CHUYỂN ĐỔI 2 CHIỀU GIỮA 4 GIAI ĐOẠN CẶP ĐÔI
  // ════════════════════════════════════════════════════════════════════════════

  group('Transition Matrix: Cặp 1 (couple <---> conception)', () {
    test('Chung Đôi <-> Chuẩn Bị Bầu đồng bộ 2 chiều tức thì giữa Vợ và Chồng', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.couple,
        stageB: LifeStage.conception,
      );
    });
  });

  group('Transition Matrix: Cặp 2 (couple <---> pregnancy)', () {
    test('Chung Đôi <-> Thai Kỳ đồng bộ 2 chiều tức thì giữa Vợ và Chồng', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.couple,
        stageB: LifeStage.pregnancy,
      );
    });
  });

  group('Transition Matrix: Cặp 3 (couple <---> motherhood)', () {
    test('Chung Đôi <-> Nuôi Con đồng bộ 2 chiều tức thì giữa Vợ và Chồng', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.couple,
        stageB: LifeStage.motherhood,
      );
    });
  });

  group('Transition Matrix: Cặp 4 (conception <---> pregnancy)', () {
    test('Chuẩn Bị Bầu <-> Thai Kỳ đồng bộ 2 chiều tức thì giữa Vợ và Chồng', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.conception,
        stageB: LifeStage.pregnancy,
      );
    });
  });

  group('Transition Matrix: Cặp 5 (conception <---> motherhood)', () {
    test('Chuẩn Bị Bầu <-> Nuôi Con đồng bộ 2 chiều tức thì giữa Vợ và Chồng', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.conception,
        stageB: LifeStage.motherhood,
      );
    });
  });

  group('Transition Matrix: Cặp 6 (pregnancy <---> motherhood)', () {
    test('Thai Kỳ <-> Nuôi Con đồng bộ 2 chiều tức thì giữa Vợ và Chồng', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.pregnancy,
        stageB: LifeStage.motherhood,
      );
    });
  });
}
