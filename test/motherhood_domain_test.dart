// test/motherhood_domain_test.dart
//
// Bộ kiểm thử chuyên biệt cho Tầng Domain & State Management của Module Nuôi Con (Motherhood).
// Bao gồm:
//   1. ChildProfileModel: tính tuổi ngày/tháng/tuần, tuổi hiệu chỉnh sinh non.
//   2. BabyActivityLogModel: tính duration, serialization JSON, phân quyền cha mẹ.
//   3. WhoGrowthStandards: tra cứu Z-Score chuẩn WHO cho bé trai & bé gái, phân loại thể trạng.
//   4. WonderWeeksData: dự báo khủng hoảng Wonder Weeks Leaps 1-5 và tuần bão tố (storm period).
//   5. LamStatusController: đánh giá 3 điều kiện y khoa LAM, ức chế cảnh báo trễ kinh.
//   6. ChildProfileController & BabyLogController: CRUD local với Box fake & đồng bộ Bạn đời.

// ignore_for_file: subtype_of_sealed_class

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/motherhood/domain/models/child_profile_model.dart';
import 'package:herflow/features/motherhood/domain/models/baby_activity_log_model.dart';
import 'package:herflow/features/motherhood/domain/models/who_growth_standards.dart';
import 'package:herflow/features/motherhood/domain/models/wonder_weeks_model.dart';
import 'package:herflow/features/motherhood/domain/models/motherhood_status_model.dart';
import 'package:herflow/features/motherhood/presentation/controllers/child_profile_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/lam_status_controller.dart';

class _FakeMotherhoodBox extends Fake implements Box {
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
}

void main() {
  group('1. ChildProfileModel Tests', () {
    final fixedNow = DateTime(2026, 9, 4, 12, 0);

    test('Tính tuổi ngày, tháng, tuần chính xác', () {
      final child = ChildProfileModel(
        childId: 'c1',
        parentUid: 'p1',
        name: 'Bé Bơ',
        birthDate: DateTime(2026, 6, 4), // 92 ngày trước
        createdAt: DateTime(2026, 6, 4),
      );

      expect(child.getAgeInDays(fixedNow), equals(92));
      expect(child.getAgeInMonths(fixedNow), equals(3));
      expect(child.getAgeInWeeks(fixedNow), equals(13));
      expect(child.getAgeDisplay(fixedNow), contains('3 tháng'));
    });

    test('Bé sinh non tính đúng tuổi hiệu chỉnh (corrected age)', () {
      final child = ChildProfileModel(
        childId: 'c2',
        parentUid: 'p1',
        name: 'Bé Đậu Sinh Non',
        birthDate: DateTime(2026, 5, 1),
        estimatedDueDate: DateTime(2026, 6, 1), // Dự sinh trễ hơn ngày sinh 1 tháng
        createdAt: DateTime(2026, 5, 1),
      );

      final chronologicalWeeks = child.getAgeInWeeks(fixedNow);
      final correctedWeeks = child.getCorrectedAgeInWeeks(fixedNow);

      expect(chronologicalWeeks, greaterThan(correctedWeeks));
      expect(chronologicalWeeks - correctedWeeks, inInclusiveRange(4, 5));
    });

    test('Serialization to/from JSON bảo toàn toàn bộ thuộc tính', () {
      final child = ChildProfileModel(
        childId: 'c3',
        parentUid: 'p3',
        name: 'Bé Miu',
        birthDate: DateTime(2026, 1, 15),
        gender: 'girl',
        birthWeightKg: 3.2,
        birthHeightCm: 49.5,
        isBreastfeedingExclusively: true,
        createdAt: DateTime(2026, 1, 15),
      );

      final json = child.toJson();
      final restored = ChildProfileModel.fromJson(json);

      expect(restored.childId, equals(child.childId));
      expect(restored.name, equals(child.name));
      expect(restored.gender, equals('girl'));
      expect(restored.birthWeightKg, equals(3.2));
      expect(restored.birthHeightCm, equals(49.5));
      expect(restored.isBreastfeedingExclusively, isTrue);
    });
  });

  group('2. BabyActivityLogModel Tests', () {
    test('Tính duration theo endTime khi không cung cấp durationMinutes', () {
      final start = DateTime(2026, 9, 4, 14, 0);
      final end = DateTime(2026, 9, 4, 14, 45);

      final log = BabyActivityLogModel(
        id: 'log1',
        childId: 'c1',
        loggedByUid: 'u1',
        type: ActivityType.sleep,
        timestamp: start,
        endTime: end,
      );

      expect(log.calculatedDurationMinutes, equals(45));
    });

    test('Ưu tiên durationMinutes khi được cung cấp trực tiếp', () {
      final log = BabyActivityLogModel(
        id: 'log2',
        childId: 'c1',
        loggedByUid: 'u1',
        type: ActivityType.feeding,
        timestamp: DateTime(2026, 9, 4, 10, 0),
        durationMinutes: 20,
        feedingType: FeedingType.breastLeft,
      );

      expect(log.calculatedDurationMinutes, equals(20));
      expect(log.type.label, equals('Cữ bú'));
    });

    test('Serialization JSON bảo toàn enum và thuộc tính phân quyền', () {
      final log = BabyActivityLogModel(
        id: 'log3',
        childId: 'c1',
        loggedByUid: 'husband_123',
        loggedByRole: 'husband',
        type: ActivityType.diaper,
        timestamp: DateTime(2026, 9, 4, 15, 0),
        diaperType: DiaperType.both,
        notes: 'Thay tã sau khi ngủ dậy',
      );

      final json = log.toJson();
      final restored = BabyActivityLogModel.fromJson(json);

      expect(restored.loggedByRole, equals('husband'));
      expect(restored.type, equals(ActivityType.diaper));
      expect(restored.diaperType, equals(DiaperType.both));
      expect(restored.notes, equals('Thay tã sau khi ngủ dậy'));
    });
  });

  group('3. WhoGrowthStandards Tests', () {
    test('Đánh giá Z-Score cân nặng cho Bé Trai 3 tháng', () {
      // Median bé trai 3 tháng là 6.4kg
      final zMedian = WhoGrowthStandards.evaluateWeightZScore(
        weightKg: 6.4,
        ageMonths: 3,
        gender: 'boy',
      );
      expect(zMedian, closeTo(0.0, 0.05));
      expect(WhoGrowthStandards.getGrowthStatusLabel(zMedian), contains('P50'));

      // 4.5kg (< -2SD = 5.0kg)
      final zLow = WhoGrowthStandards.evaluateWeightZScore(
        weightKg: 4.5,
        ageMonths: 3,
        gender: 'boy',
      );
      expect(zLow, lessThan(-2.0));
      expect(WhoGrowthStandards.getGrowthStatusLabel(zLow), contains('< -2SD'));
    });

    test('Đánh giá Z-Score cân nặng cho Bé Gái 6 tháng', () {
      // Median bé gái 6 tháng là 7.3kg, sd1Pos là 8.2kg (+1SD)
      final zMedian = WhoGrowthStandards.evaluateWeightZScore(
        weightKg: 8.2,
        ageMonths: 6,
        gender: 'girl',
      );
      expect(zMedian, closeTo(1.0, 0.05));
      expect(WhoGrowthStandards.getGrowthStatusLabel(zMedian), contains('P50'));

      // 8.8kg (> +1SD, < +2SD = 9.3kg) -> Phát triển vượt chuẩn
      final zOver = WhoGrowthStandards.evaluateWeightZScore(
        weightKg: 8.8,
        ageMonths: 6,
        gender: 'girl',
      );
      expect(zOver, greaterThan(1.0));
      expect(WhoGrowthStandards.getGrowthStatusLabel(zOver), contains('+1SD'));
    });
  });

  group('4. WonderWeeksData Tests', () {
    test('Xác định đúng Leap 4 ở tuần 19 (khủng hoảng ngủ tháng thứ 4)', () {
      final leap = WonderWeeksData.getLeapForWeek(19);
      expect(leap, isNotNull);
      expect(leap!.leapIndex, equals(4));
      expect(leap.peakWeek, equals(19));
      expect(leap.title, contains('Khủng hoảng ngủ'));
      expect(WonderWeeksData.isStormPeriod(19), isTrue);
    });

    test('Tuần bình yên ngoài bão tố (Sunny week)', () {
      // Tuần 10 nằm giữa Leap 2 (7-9) và Leap 3 (11-13)
      expect(WonderWeeksData.isStormPeriod(10), isFalse);
      expect(WonderWeeksData.getLeapForWeek(10), isNull);
    });
  });

  group('5. LamStatusController Tests', () {
    late _FakeMotherhoodBox box;
    late LamStatusController controller;

    setUp(() {
      UserScope.clear();
      box = _FakeMotherhoodBox();
      controller = LamStatusController(motherhoodBox: box, defaultUid: 'u_wife');
    });

    test('Đạt cả 3 điều kiện: Bé < 6 tháng, bú mẹ hoàn toàn, chưa có kinh -> LAM hiệu lực', () {
      final child = ChildProfileModel(
        childId: 'c1',
        parentUid: 'u_wife',
        name: 'Bé Mầm',
        birthDate: DateTime.now().subtract(const Duration(days: 60)), // 2 tháng tuổi
        isBreastfeedingExclusively: true,
        createdAt: DateTime.now(),
      );

      controller.evaluateWithChild(child);

      expect(controller.state.isEligible, isTrue);
      expect(controller.state.shouldSuppressLatePeriodAlert, isTrue);
      expect(controller.state.statusMessage, contains('LAM đang có hiệu lực'));
    });

    test('Khi kinh nguyệt trở lại -> Hủy LAM và bật cảnh báo tránh thai', () async {
      final child = ChildProfileModel(
        childId: 'c1',
        parentUid: 'u_wife',
        name: 'Bé Mầm',
        birthDate: DateTime.now().subtract(const Duration(days: 60)),
        isBreastfeedingExclusively: true,
        createdAt: DateTime.now(),
      );

      controller.evaluateWithChild(child);
      expect(controller.state.isEligible, isTrue);

      // Mẹ đánh dấu có kinh lại
      await controller.setMensesReturned(true, uid: 'u_wife');

      expect(controller.state.isEligible, isFalse);
      expect(controller.state.shouldSuppressLatePeriodAlert, isFalse);
      expect(controller.state.statusMessage, contains('Kinh nguyệt đã trở lại'));
    });

    test('Khi bé qua 6 tháng tuổi -> Hủy hiệu lực LAM', () {
      final olderChild = ChildProfileModel(
        childId: 'c2',
        parentUid: 'u_wife',
        name: 'Bé Lớn',
        birthDate: DateTime.now().subtract(const Duration(days: 200)), // > 6 tháng
        isBreastfeedingExclusively: true,
        createdAt: DateTime.now(),
      );

      controller.evaluateWithChild(olderChild);

      expect(controller.state.isEligible, isFalse);
      expect(controller.state.shouldSuppressLatePeriodAlert, isFalse);
      expect(controller.state.statusMessage, contains('qua 6 tháng tuổi'));
    });
  });

  group('6. ChildProfileController & BabyLogController CRUD Tests', () {
    late _FakeMotherhoodBox box;

    setUp(() {
      UserScope.clear();
      box = _FakeMotherhoodBox();
    });

    test('ChildProfileController: Thêm, sửa, chọn active child, xóa bé', () async {
      final controller = ChildProfileController(motherhoodBox: box, defaultUid: 'test_u');

      final baby1 = ChildProfileModel(
        childId: 'b1',
        parentUid: 'test_u',
        name: 'Bé Na',
        birthDate: DateTime(2026, 3, 1),
        createdAt: DateTime(2026, 3, 1),
      );

      final baby2 = ChildProfileModel(
        childId: 'b2',
        parentUid: 'test_u',
        name: 'Bé Sóc',
        birthDate: DateTime(2026, 7, 1),
        createdAt: DateTime(2026, 7, 1),
      );

      // 1. Thêm bé 1
      await controller.addChild(baby1, uid: 'test_u');
      expect(controller.state.children.length, equals(1));
      expect(controller.state.activeChild?.name, equals('Bé Na'));

      // 2. Thêm bé 2
      await controller.addChild(baby2, uid: 'test_u');
      expect(controller.state.children.length, equals(2));

      // 3. Đổi active child sang bé 2
      await controller.setActiveChild('b2', uid: 'test_u');
      expect(controller.state.activeChild?.name, equals('Bé Sóc'));

      // 4. Cập nhật tên bé 1
      final updatedBaby1 = baby1.copyWith(name: 'Bé Na Na');
      await controller.updateChild(updatedBaby1, uid: 'test_u');
      expect(controller.state.children.firstWhere((c) => c.childId == 'b1').name, equals('Bé Na Na'));

      // 5. Xóa bé 2 -> active child tự động lùi về bé 1
      await controller.deleteChild('b2', uid: 'test_u');
      expect(controller.state.children.length, equals(1));
      expect(controller.state.activeChild?.name, equals('Bé Na Na'));
    });

    test('BabyLogController: Ghi chép nhanh cữ bú, tã bỉm, giấc ngủ và tính toán thống kê ngày', () async {
      final controller = BabyLogController(motherhoodBox: box, defaultUid: 'test_u');

      // Quick log feeding
      await controller.quickLogFeeding(
        childId: 'b1',
        type: FeedingType.breastLeft,
        durationMinutes: 15,
        uid: 'test_u',
      );

      // Quick log diaper
      await controller.quickLogDiaper(
        childId: 'b1',
        type: DiaperType.dirty,
        notes: 'Phân hoa cà hoa cải',
        uid: 'test_u',
      );

      // Quick log sleep
      await controller.quickLogSleep(
        childId: 'b1',
        startTime: DateTime.now().subtract(const Duration(minutes: 60)),
        endTime: DateTime.now(),
        durationMinutes: 60,
        uid: 'test_u',
      );

      expect(controller.state.logs.length, equals(3));
      expect(controller.state.todayFeedingCount, equals(1));
      expect(controller.state.todayDiaperCount, equals(1));
      expect(controller.state.todaySleepDurationMinutes, equals(60));
      expect(controller.state.lastFeeding?.feedingType, equals(FeedingType.breastLeft));
      expect(controller.state.lastDiaper?.diaperType, equals(DiaperType.dirty));
    });

    test('MotherhoodStatusModel serialization', () {
      final status = MotherhoodStatusModel(
        coupleId: 'c_999',
        activeChildId: 'b1',
        activeChildName: 'Bé Mầm',
        activeChildAgeDisplay: '2 tháng 10 ngày',
        lastFeedingSummary: 'Bú mẹ ngực trái (15p)',
        lastDiaperSummary: 'Tã bẩn',
        lastSleepDurationMinutes: 60,
        isStormPeriod: true,
        currentLeapTitle: 'Wonder Week 4',
        updatedAt: DateTime(2026, 9, 4, 16, 0),
        updatedByRole: 'wife',
      );

      final map = status.toMap();
      final restored = MotherhoodStatusModel.fromMap(map);

      expect(restored.coupleId, equals('c_999'));
      expect(restored.activeChildName, equals('Bé Mầm'));
      expect(restored.lastFeedingSummary, equals('Bú mẹ ngực trái (15p)'));
      expect(restored.isStormPeriod, isTrue);
      expect(restored.updatedByRole, equals('wife'));
    });
  });
}
