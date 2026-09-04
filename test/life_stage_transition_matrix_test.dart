// ignore_for_file: subtype_of_sealed_class, annotate_overrides
// test/life_stage_transition_matrix_test.dart
//
// Test suite chuyên biệt kiểm tra toàn bộ Ma Trận Chuyển Đổi Trạng Thái 4x4 (16 Cases)
// và 6 Cặp Chuyển Đổi Hai Chiều (Bidirectional Round-Trip) giữa 4 giai đoạn sống cặp đôi
// (Chung Đôi, Chuẩn Bị Bầu, Thai Kỳ, Nuôi Con).
//
// Tuân thủ quy định AGENTS.md Điều 11 & 12: Kỷ luật Ma trận Trạng thái & Biên dữ liệu.

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

  /// Kiểm tra 1 bước chuyển đổi đơn lẻ [fromStage] -> [toStage] trong Ma trận 4x4
  Future<void> assertSingleTransition({
    required LifeStage fromStage,
    required LifeStage toStage,
  }) async {
    // 1. Thiết lập trạng thái ban đầu: fromStage
    UserScope.setActiveUid(wifeUid);
    await wifeController.switchStage(fromStage, uid: wifeUid);
    expect(wifeController.state.currentStage, equals(fromStage));

    // Chồng bắt đầu lắng nghe stream từ document couples/{coupleId}
    UserScope.setActiveUid(husbandUid);
    husbandController.startListeningToCouple(coupleId, husbandUid);
    await Future.delayed(const Duration(milliseconds: 25));

    // Xác minh ban đầu Chồng đã ở đúng fromStage
    expect(husbandController.state.currentStage, equals(fromStage));
    expect(
      husbandHive.get(UserScope.key(AppConstants.keyLifeStage, husbandUid)),
      equals(fromStage.toStorageString()),
    );

    // 2. Vợ thực hiện chuyển đổi sang toStage
    UserScope.setActiveUid(wifeUid);
    await wifeController.switchStage(toStage, uid: wifeUid);

    // 3. Xác minh Vợ đã đổi sang toStage trên RAM và Hive của Vợ
    expect(wifeController.state.currentStage, equals(toStage));
    expect(
      wifeHive.get(UserScope.key(AppConstants.keyLifeStage, wifeUid)),
      equals(toStage.toStorageString()),
    );

    // 4. Xác minh Firestore couples/{coupleId} nhận đúng toStage
    final firestoreData = fakeFirestore.getDocumentData('couples/$coupleId');
    expect(firestoreData, isNotNull);
    expect(firestoreData!['currentStage'], equals(toStage.toStorageString()));
    expect(firestoreData['lifeStage'], equals(toStage.toStorageString()));

    // Đợi stream của Chồng nhận event
    await Future.delayed(const Duration(milliseconds: 25));

    // 5. Xác minh Chồng tự động đồng bộ sang toStage trên RAM và Hive của Chồng
    expect(
      husbandController.state.currentStage,
      equals(toStage),
      reason: 'Chồng phải tự chuyển sang ${toStage.displayName} khi Vợ chọn',
    );
    expect(
      husbandHive.get(UserScope.key(AppConstants.keyLifeStage, husbandUid)),
      equals(toStage.toStorageString()),
      reason: 'Hive của Chồng phải lưu đúng ${toStage.displayName}',
    );
  }

  /// Hàm tiện ích kiểm tra chu trình chuyển đổi 2 chiều hoàn chỉnh:
  /// Stage A -> Stage B, sau đó Stage B -> Stage A.
  Future<void> assertBidirectionalTransition({
    required LifeStage stageA,
    required LifeStage stageB,
  }) async {
    // Chiều đi: A -> B
    await assertSingleTransition(fromStage: stageA, toStage: stageB);

    // Chiều về: B -> A
    await assertSingleTransition(fromStage: stageB, toStage: stageA);
  }

  // ════════════════════════════════════════════════════════════════════════════
  // PHẦN A: MA TRẬN ĐẦY ĐỦ 4x4 (16 TRƯỜNG HỢP CHUYỂN ĐỔI TOÀN DIỆN)
  // ════════════════════════════════════════════════════════════════════════════

  const coupleStages = [
    LifeStage.couple,
    LifeStage.conception,
    LifeStage.pregnancy,
    LifeStage.motherhood,
  ];

  group('Full 4x4 State Transition Matrix (16 Cases):', () {
    int testIndex = 1;
    for (final fromStage in coupleStages) {
      for (final toStage in coupleStages) {
        final isIdempotent = fromStage == toStage;
        final caseTitle = 'Case $testIndex/16: [${fromStage.name} -> ${toStage.name}] '
            '(${fromStage.displayName} -> ${toStage.displayName}) '
            '${isIdempotent ? "[Idempotent / No-op]" : "[State Transition]"}';

        test(caseTitle, () async {
          await assertSingleTransition(
            fromStage: fromStage,
            toStage: toStage,
          );
        });

        testIndex++;
      }
    }
  });

  // ════════════════════════════════════════════════════════════════════════════
  // PHẦN B: 6 CẶP CHUYỂN ĐỔI HAI CHIỀU (BIDIRECTIONAL ROUND-TRIP TESTS)
  // ════════════════════════════════════════════════════════════════════════════

  group('Bidirectional Round-Trip: 6 Cặp Giai Đoạn Cặp Đôi', () {
    test('Cặp 1: Chung Đôi <---> Chuẩn Bị Bầu (couple <-> conception)', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.couple,
        stageB: LifeStage.conception,
      );
    });

    test('Cặp 2: Chung Đôi <---> Thai Kỳ (couple <-> pregnancy)', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.couple,
        stageB: LifeStage.pregnancy,
      );
    });

    test('Cặp 3: Chung Đôi <---> Nuôi Con (couple <-> motherhood)', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.couple,
        stageB: LifeStage.motherhood,
      );
    });

    test('Cặp 4: Chuẩn Bị Bầu <---> Thai Kỳ (conception <-> pregnancy)', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.conception,
        stageB: LifeStage.pregnancy,
      );
    });

    test('Cặp 5: Chuẩn Bị Bầu <---> Nuôi Con (conception <-> motherhood)', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.conception,
        stageB: LifeStage.motherhood,
      );
    });

    test('Cặp 6: Thai Kỳ <---> Nuôi Con (pregnancy <-> motherhood)', () async {
      await assertBidirectionalTransition(
        stageA: LifeStage.pregnancy,
        stageB: LifeStage.motherhood,
      );
    });
  });
}
