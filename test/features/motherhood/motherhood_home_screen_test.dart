// test/features/motherhood/motherhood_home_screen_test.dart
//
// Widget Tests cho Giai Đoạn Nuôi Con (Motherhood Phase 3):
// - Kiểm thử Empty State khi chưa có hồ sơ em bé.
// - Kiểm thử Dashboard Nuôi Con khi có bé hoạt động (Hero Card, Quick Action Bar, LAM Card, Wonder Weeks, Timeline).
// - Kiểm thử Chế độ Chữa Lành (Healing Mode) khi isPaused == true.
// - Kiểm thử Thẻ Tóm Tắt & Thanh Tác Vụ Nhanh của Bố Bỉm (Husband Companion & Quick Care).
//
// Tuân thủ Điều 10 AGENTS.md: Thiết lập Viewport 1080x2400 để chống tràn khung hình headless test.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/motherhood/domain/models/baby_activity_log_model.dart';
import 'package:herflow/features/motherhood/domain/models/child_profile_model.dart';
import 'package:herflow/features/motherhood/domain/models/motherhood_status_model.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/child_profile_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/lam_status_controller.dart';
import 'package:herflow/features/motherhood/presentation/screens/motherhood_home_screen.dart';
import 'package:herflow/features/motherhood/presentation/widgets/baby_quick_action_bar.dart';
import 'package:herflow/features/motherhood/presentation/widgets/baby_summary_hero_card.dart';
import 'package:herflow/features/motherhood/presentation/widgets/husband_baby_quick_care_row.dart';
import 'package:herflow/features/motherhood/presentation/widgets/husband_motherhood_companion_card.dart';

// ignore: subtype_of_sealed_class
class _FakeBox extends Fake implements Box {
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
  Future<int> clear() async {
    _data.clear();
    return 0;
  }

  @override
  bool containsKey(dynamic key) => _data.containsKey(key);

  @override
  bool get isOpen => true;

  @override
  Future<void> close() async {}
}

void main() {
  late _FakeBox settingsBox;
  late _FakeBox motherhoodBox;

  setUpAll(() async {
    await initializeDateFormatting('vi', null);
  });

  setUp(() async {
    UserScope.setActiveUid('test_mother_user');
    settingsBox = _FakeBox();
    motherhoodBox = _FakeBox();
  });

  Widget buildTestScreen({
    ChildProfileState? childProfileState,
    BabyLogState? babyLogState,
    LifeStageState lifeStageState =
        const LifeStageState(currentStage: LifeStage.motherhood),
    bool isPaused = false,
    Widget child = const MotherhoodHomeScreen(),
  }) {
    final effectiveChildProfileCtrl =
        ChildProfileController(motherhoodBox: motherhoodBox);
    if (childProfileState != null) {
      effectiveChildProfileCtrl.state = childProfileState;
    }

    final effectiveBabyLogCtrl =
        BabyLogController(motherhoodBox: motherhoodBox);
    if (babyLogState != null) {
      effectiveBabyLogCtrl.state = babyLogState;
    }

    final effectiveLifeStageCtrl =
        LifeStageController(settingsBox: settingsBox);
    effectiveLifeStageCtrl.state = lifeStageState;

    final effectiveLamStatusCtrl =
        LamStatusController(motherhoodBox: motherhoodBox);

    return ProviderScope(
      overrides: [
        childProfileControllerProvider
            .overrideWith((ref) => effectiveChildProfileCtrl),
        babyLogControllerProvider.overrideWith((ref) => effectiveBabyLogCtrl),
        lamStatusControllerProvider
            .overrideWith((ref) => effectiveLamStatusCtrl),
        lifeStageControllerProvider
            .overrideWith((ref) => effectiveLifeStageCtrl),
        isPausedModeProvider.overrideWith((ref) => isPaused),
      ],
      child: MaterialApp(
        theme: ThemeData.light(),
        home: child,
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // 1. EMPTY STATE
  // ════════════════════════════════════════════════════════════════════════════
  group('MotherhoodHomeScreen - Empty State Tests', () {
    testWidgets('Hiển thị Empty State khi chưa có hồ sơ em bé', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestScreen(
          childProfileState: const ChildProfileState(
            children: [],
            isLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chào Mừng Mẹ Đến Với Nuôi Con 🌸'), findsOneWidget);
      expect(find.text('Thêm Hồ Sơ Bé Yêu'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byType(BabySummaryHeroCard), findsNothing);
      expect(find.byType(BabyQuickActionBar), findsNothing);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 2. DASHBOARD VỚI BÉ HOẠT ĐỘNG
  // ════════════════════════════════════════════════════════════════════════════
  group('MotherhoodHomeScreen - Active Baby Dashboard Tests', () {
    final now = DateTime.now();
    final testChild = ChildProfileModel(
      childId: 'child_test_01',
      parentUid: 'test_mother_user',
      name: 'Bé Bắp',
      birthDate: now.subtract(const Duration(days: 42)),
      gender: 'boy',
      birthWeightKg: 3.2,
      birthHeightCm: 50.0,
      createdAt: now.subtract(const Duration(days: 42)),
    );

    final testFeedingLog = BabyActivityLogModel(
      id: 'feed_01',
      childId: 'child_test_01',
      loggedByUid: 'test_mother_user',
      type: ActivityType.feeding,
      timestamp: now.subtract(const Duration(minutes: 90)),
      feedingType: FeedingType.breastLeft,
      durationMinutes: 15,
      loggedByRole: 'mother',
    );

    final testDiaperLog = BabyActivityLogModel(
      id: 'diaper_01',
      childId: 'child_test_01',
      loggedByUid: 'test_husband_user',
      type: ActivityType.diaper,
      timestamp: now.subtract(const Duration(minutes: 45)),
      diaperType: DiaperType.clean,
      loggedByRole: 'husband',
    );

    testWidgets('Hiển thị đầy đủ Hero Card, Action Bar, LAM Card và Timeline',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestScreen(
          childProfileState: ChildProfileState(
            children: [testChild],
            activeChildId: testChild.childId,
            isLoading: false,
          ),
          babyLogState: BabyLogState(
            logs: [testFeedingLog, testDiaperLog],
            selectedDate: DateTime(now.year, now.month, now.day),
            isLoading: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tên bé hiển thị ở Header AppBar và Thẻ Hero Card
      expect(find.text('Bé Bắp'), findsNWidgets(2));

      // Kiểm tra Hero Card và Quick Action Bar
      expect(find.byType(BabySummaryHeroCard), findsOneWidget);
      expect(find.byType(BabyQuickActionBar), findsOneWidget);

      // Kiểm tra 4 nút 1-chạm của Action Bar (scoped to BabyQuickActionBar)
      expect(
        find.descendant(
          of: find.byType(BabyQuickActionBar),
          matching: find.text('Bú sữa'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BabyQuickActionBar),
          matching: find.text('Giấc ngủ'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BabyQuickActionBar),
          matching: find.text('Thay tã'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(BabyQuickActionBar),
          matching: find.text('Đo bé'),
        ),
        findsOneWidget,
      );

      // Kiểm tra Thẻ Đánh Giá LAM WHO
      expect(find.text('Ngừa Thai Tự Nhiên LAM (WHO)'), findsOneWidget);

      // Kiểm tra Dòng thời gian sinh hoạt trong ngày
      expect(find.textContaining('Nhật Ký Hôm Nay'), findsOneWidget);
      expect(find.text('Bú mẹ ngực trái • 15 phút'), findsOneWidget);
      expect(find.text('Tã sạch ✨'), findsOneWidget);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 3. CHẾ ĐỘ CHỮA LÀNH (HEALING MODE)
  // ════════════════════════════════════════════════════════════════════════════
  group('MotherhoodHomeScreen - Healing Mode Safeguard Tests', () {
    final now = DateTime.now();
    final testChild = ChildProfileModel(
      childId: 'child_test_02',
      parentUid: 'test_mother_user',
      name: 'Bé Mầm',
      birthDate: now.subtract(const Duration(days: 20)),
      gender: 'girl',
      createdAt: now.subtract(const Duration(days: 20)),
    );

    testWidgets('Hiển thị Healing View và ẩn theo dõi khi isPaused == true',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestScreen(
          childProfileState: ChildProfileState(
            children: [testChild],
            activeChildId: testChild.childId,
            isLoading: false,
          ),
          isPaused: true,
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra thông điệp Chữa lành
      expect(find.text('Không Gian Chữa Lành & Phục Hồi 🕊️'), findsOneWidget);
      expect(find.text('Khôi Phục Giao Diện Nuôi Con'), findsOneWidget);

      // Đảm bảo không render các chỉ số theo dõi
      expect(find.byType(BabySummaryHeroCard), findsNothing);
      expect(find.byType(BabyQuickActionBar), findsNothing);
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // 4. GÓC NHÌN BỐ BỈM (HUSBAND MOTHERHOOD COMPANION)
  // ════════════════════════════════════════════════════════════════════════════
  group('Husband Motherhood Companion Widget Tests', () {
    final now = DateTime.now();
    final testStatus = MotherhoodStatusModel(
      coupleId: 'couple_test_01',
      activeChildId: 'child_test_03',
      activeChildName: 'Bé Đậu',
      activeChildAgeDisplay: '1 tháng 5 ngày',
      isStormPeriod: true,
      currentLeapTitle: 'Wonder Week 5: Thế giới của các giác quan',
      lastFeedingTime: now.subtract(const Duration(minutes: 60)),
      lastFeedingSummary: 'Bú mẹ ngực trái • 20 phút',
      lastDiaperTime: now.subtract(const Duration(minutes: 30)),
      lastDiaperSummary: 'Tã ướt 💧',
      lastSleepTime: now.subtract(const Duration(minutes: 120)),
      lastSleepDurationMinutes: 90,
      careTip: 'Đỡ đần vợ cữ bú đêm',
      updatedAt: now,
    );

    testWidgets(
        'HusbandMotherhoodCompanionCard hiển thị trạng thái bé và lời khuyên cho bố',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestScreen(
          child: Scaffold(
            body: HusbandMotherhoodCompanionCard(
              status: testStatus,
              isDark: false,
              partnerName: 'Vợ',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bé Đậu'), findsOneWidget);
      expect(find.text('1 tháng 5 ngày'), findsOneWidget);
      expect(find.textContaining('Wonder Week 5'), findsOneWidget);
      expect(find.textContaining('Tuần bão tố'), findsOneWidget);
      expect(find.textContaining('Gợi ý cho Bố'), findsOneWidget);
    });

    testWidgets('HusbandBabyQuickCareRow hiển thị 3 tác vụ nhanh của Bố',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestScreen(
          child: const Scaffold(
            body: HusbandBabyQuickCareRow(
              isDark: false,
              partnerName: 'Vợ',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Bố Đỡ Đần Cùng Vợ'), findsOneWidget);
      expect(find.text('Cho bú bình'), findsOneWidget);
      expect(find.text('Đã thay tã'), findsOneWidget);
      expect(find.text('Đã ru ngủ'), findsOneWidget);
    });
  });
}
