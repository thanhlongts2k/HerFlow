// test/life_stage_navigation_and_ui_test.dart
//
// Widget & Integration tests cho Step 1.3:
// - Dynamic Navigation (DP-03 Safeguard chống RangeError).
// - Cập nhật UI Settings (LifeStageCard, Role Guard Q3, Gating Couple Settings).
//
// Chạy: flutter test test/life_stage_navigation_and_ui_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/constants/user_role.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/auth/domain/models/user_model.dart';
import 'package:herflow/features/auth/presentation/controllers/auth_controller.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import 'package:herflow/features/care_signals/presentation/controllers/care_signal_controller.dart';
import 'package:herflow/features/home/presentation/screens/main_nav_screen.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/partner_sync/data/partner_sync_repository.dart';
import 'package:herflow/features/partner_sync/domain/models/partner_status_model.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/settings/domain/models/nickname_config.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';
import 'package:herflow/features/settings/presentation/screens/settings_screen.dart';

class _FakeUserRoleNotifier extends UserRoleNotifier {
  _FakeUserRoleNotifier(super.box, {UserRole initial = UserRole.wife}) {
    state = initial;
  }
}

class _FakeAuthController extends StateNotifier<AsyncValue<UserModel?>>
    implements AuthController {
  _FakeAuthController([UserModel? user]) : super(AsyncValue.data(user));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeNicknameController extends StateNotifier<NicknameConfig>
    implements NicknameController {
  _FakeNicknameController() : super(const NicknameConfig());

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePartnerSyncRepository extends Fake implements PartnerSyncRepository {
  final String? coupleId;
  _FakePartnerSyncRepository({this.coupleId});

  @override
  String? getSavedCoupleId([String? explicitUid]) => coupleId;

  @override
  String? getSavedUserRole([String? explicitUid]) => 'wife';

  @override
  String? getSavedPairingCode([String? explicitUid]) => null;

  @override
  bool get isOfflineCode => false;

  @override
  Future<void> flushPendingSync() async {}

  @override
  bool isPendingSync() => false;

  @override
  Stream<PartnerStatusModel?> watchPartnerTodayStatus(String coupleId) =>
      Stream.value(null);

  @override
  Stream<CareSignalModel?> watchLatestCareSignal(String coupleId) =>
      Stream.value(null);

  @override
  Stream<List<CareSignalModel>> watchCoupleSignalsStream(String coupleId,
          {int limit = 30}) =>
      Stream.value([]);
}

void main() {
  late Directory tempDir;
  late Box settingsBox;

  setUpAll(() async {
    await initializeDateFormatting('vi', null);
    tempDir = await Directory.systemTemp.createTemp('moona_test_');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    await Hive.openBox(AppConstants.cycleBoxName);
    await Hive.openBox(AppConstants.moodBoxName);
    await Hive.openBox(AppConstants.nutritionBoxName);
    await Hive.openBox(AppConstants.userBoxName);
  });

  setUp(() {
    UserScope.clear();
    settingsBox.clear();
  });

  List<dynamic> baseOverrides({
    required LifeStageController lifeStageController,
    UserRole role = UserRole.wife,
    String? coupleId,
  }) {
    return [
      lifeStageControllerProvider.overrideWith((ref) => lifeStageController),
      userRoleProvider.overrideWith(
          (ref) => _FakeUserRoleNotifier(settingsBox, initial: role)),
      authControllerProvider.overrideWith((ref) => _FakeAuthController()),
      currentUserProvider.overrideWith((ref) => null),
      partnerSyncRepositoryProvider.overrideWith(
          (ref) => _FakePartnerSyncRepository(coupleId: coupleId)),
      savedCoupleIdProvider.overrideWith((ref) => coupleId),
      partnerLiveStatusStreamProvider.overrideWith((ref) => Stream.value(null)),
      latestCareSignalStreamProvider.overrideWith((ref) => Stream.value(null)),
      coupleCareSignalsStreamProvider.overrideWith((ref) => Stream.value([])),
      nicknameConfigProvider.overrideWith((ref) => _FakeNicknameController()),
    ];
  }

  Widget buildTestWidget({
    required Widget child,
    List<dynamic> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        ...overrides,
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Dynamic Navigation & DP-03 Safeguard Tests', () {
    testWidgets(
        'Couple Mode + Role Husband hiển thị 4 tab Chồng và an toàn khi clamp index',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.couple,
        isPaused: false,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const MainNavScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.husband,
            coupleId: 'couple_123',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Kiểm tra tab của Chồng: label 'Trang chủ' với icon khiên
      expect(find.text('Trang chủ'), findsOneWidget);
      expect(find.widgetWithIcon(NavigationDestination, Icons.shield_rounded), findsOneWidget);
      expect(find.text('Cảm xúc'), findsOneWidget);
      expect(find.text('Dinh dưỡng'), findsOneWidget);
      expect(find.text('Cài đặt'), findsOneWidget);
    });

    testWidgets(
        'Solo Mode: role Chồng tự động chuyển về giao diện Nàng (không có tab Trang chủ Chồng)',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.solo,
        isPaused: false,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const MainNavScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.husband,
            coupleId: null,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Giao diện Nàng: tab 'Chu kỳ' thay vì 'Trang chủ'
      expect(find.text('Chu kỳ'), findsOneWidget);
      expect(find.widgetWithIcon(NavigationDestination, Icons.calendar_month_rounded), findsOneWidget);
      expect(find.widgetWithIcon(NavigationDestination, Icons.shield_outlined), findsNothing);
      expect(find.widgetWithIcon(NavigationDestination, Icons.shield_rounded), findsNothing);
    });

    testWidgets(
        'DP-03 Safeguard: Out-of-bounds currentIndex được clamp an toàn, không crash RangeError',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.solo,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const MainNavScreen(),
          overrides: [
            ...baseOverrides(
              lifeStageController: fakeController,
              role: UserRole.wife,
            ),
            currentBottomNavIndexProvider
                .overrideWith((ref) => 99), // Index bất thường ngoài bounds
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Màn hình vẫn render an toàn (clamp về index 3 = Cài đặt), không quăng RangeError
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Chế độ Chuẩn Bị Bầu (Conception) hiển thị Banner lộ trình Phase 2/3 và bấm nút đóng sẽ ẩn banner',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.conception,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const MainNavScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.wife,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Banner thông báo Phase 2/3 xuất hiện cho Conception
      expect(find.textContaining('Chế độ Chuẩn Bị Bầu'), findsOneWidget);
      expect(find.textContaining('Phase 2'), findsOneWidget);

      // Bấm nút đóng [✕]
      final closeBtn = find.byIcon(Icons.close_rounded);
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Banner đã biến mất
      expect(find.textContaining('Chế độ Chuẩn Bị Bầu'), findsNothing);
    });

    testWidgets(
        'Chế độ Thai kỳ (Pregnancy) role Vợ: Tab 0 hiển thị Thai Kỳ, tự động ẩn Banner Phase 2',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.pregnancy,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const MainNavScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.wife,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tab 0 có icon và nhãn Thai Kỳ
      expect(find.text('Thai Kỳ'), findsOneWidget);
      expect(find.byIcon(Icons.pregnant_woman_rounded), findsOneWidget);

      // Banner lộ trình Phase 2 tự động ẩn vì PregnancyHomeScreen đã hoàn thiện
      expect(find.textContaining('Phase 2'), findsNothing);
      expect(find.textContaining('Chế độ Thai Kỳ'), findsNothing);
    });

    testWidgets(
        'Chế độ Thai kỳ (Pregnancy) + Role Husband hiển thị góc nhìn Bố Bầu với tab Bố Bầu',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.pregnancy,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const MainNavScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.husband,
            coupleId: 'couple_123',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tab 0 biến chuyển thành 'Bố Bầu' với icon em bé
      expect(find.text('Bố Bầu'), findsOneWidget);
      expect(find.widgetWithIcon(NavigationDestination, Icons.child_care_rounded), findsOneWidget);
      expect(find.text('Chu kỳ'), findsNothing); // Không bị ép về giao diện Nàng

      // Banner góc nhìn Bố Bầu xuất hiện
      expect(find.textContaining('Góc nhìn Bố Bầu'), findsOneWidget);
    });

    testWidgets(
        'Chế độ Nuôi Con (Motherhood) + Role Husband hiển thị góc nhìn Bố Bỉm với tab Bố Bỉm',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.motherhood,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const MainNavScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.husband,
            coupleId: 'couple_123',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tab 0 biến chuyển thành 'Bố Bỉm'
      expect(find.text('Bố Bỉm'), findsOneWidget);
      expect(find.widgetWithIcon(NavigationDestination, Icons.family_restroom_rounded), findsOneWidget);

      // Banner góc nhìn Bố Bỉm xuất hiện
      expect(find.textContaining('Góc nhìn Bố Bỉm'), findsOneWidget);
    });
  });

  group('SettingsScreen LifeStage UI & Role Guard Tests', () {
    testWidgets('LifeStage Card hiển thị đúng icon và tên giai đoạn hiện tại',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.couple,
        isPaused: false,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const SettingsScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.wife,
            coupleId: 'couple_123',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tìm thấy thẻ Giai đoạn cuộc sống
      expect(find.text('Chung Đôi'), findsOneWidget);
      expect(find.text('💑'), findsOneWidget);
      expect(find.text('Đang hoạt động'), findsOneWidget);
      expect(find.text('Chế độ Tạm dừng / Chữa lành'), findsOneWidget);
    });

    testWidgets(
        'Role Chồng: Thẻ LifeStage hiển thị "Chỉ xem" và chạm vào hiện SnackBar từ chối',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.couple,
        isPaused: false,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const SettingsScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.husband,
            coupleId: 'couple_123',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Thẻ hiển thị 'Chỉ xem'
      expect(find.text('Chỉ xem'), findsOneWidget);

      // Chạm vào thẻ
      await tester.tap(find.text('Chung Đôi'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Xuất hiện SnackBar bảo vệ quyền Vợ
      expect(find.textContaining('Giai đoạn do Vợ làm chủ tiến trình'),
          findsOneWidget);
    });

    testWidgets('Role Vợ chạm vào thẻ mở BottomSheet 5 giai đoạn cuộc sống',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.solo,
        isPaused: false,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const SettingsScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.wife,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Chạm vào thẻ
      await tester.tap(find.text('Nàng'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // BottomSheet mở ra đầy đủ 5 lựa chọn
      expect(find.text('Giai Đoạn Cuộc Sống'), findsOneWidget);
      expect(find.text('🌸'), findsWidgets);
      expect(find.text('Chuẩn Bị Bầu'), findsOneWidget);
      expect(find.text('Thai Kỳ'), findsOneWidget);
      expect(find.text('Nuôi Con'), findsOneWidget);
    });

    testWidgets(
        'Khi LifeStage là Solo: ẩn hoàn toàn các cấu hình Cặp đôi trong Settings',
        (tester) async {
      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.solo,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const SettingsScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.wife,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Ẩn nhóm vai trò và hồ sơ danh xưng cặp đôi
      expect(find.text('VAI TRÒ ỨNG DỤNG'), findsNothing);
      expect(find.text('🌸 Vai trò: Phụ nữ (Vợ)'), findsNothing);
      expect(find.text('HỒ SƠ & DANH XƯNG'), findsNothing);
      expect(find.text('ĐỒNG BỘ CẶP ĐÔI'), findsNothing);
    });

    testWidgets(
        'Khi LifeStage là Thai Kỳ (Pregnancy): Vẫn hiển thị các cấu hình Cặp đôi trong Settings',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeController = LifeStageController(settingsBox: settingsBox);
      fakeController.state = const LifeStageState(
        currentStage: LifeStage.pregnancy,
      );

      await tester.pumpWidget(
        buildTestWidget(
          child: const SettingsScreen(),
          overrides: baseOverrides(
            lifeStageController: fakeController,
            role: UserRole.wife,
            coupleId: 'couple_123',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Không bị ẩn các cấu hình cặp đôi vì pregnancy vẫn hỗ trợ bạn đời
      expect(find.text('VAI TRÒ ỨNG DỤNG'), findsOneWidget);
      expect(find.text('🌸 Vai trò: Phụ nữ (Vợ)'), findsOneWidget);
      expect(find.text('HỒ SƠ & DANH XƯNG'), findsOneWidget);
      expect(find.text('ĐỒNG BỘ CẶP ĐÔI'), findsOneWidget);
    });
  });
}
