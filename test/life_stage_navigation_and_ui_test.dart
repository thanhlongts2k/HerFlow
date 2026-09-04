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
        'Chế độ Thai kỳ (Pregnancy) hiển thị Banner lộ trình Phase 2/3',
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

      // Banner thông báo Phase 2/3 xuất hiện
      expect(find.textContaining('Chế độ Thai Kỳ'), findsOneWidget);
      expect(find.textContaining('Phase 2'), findsOneWidget);
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
      expect(find.text('Đón Bé'), findsOneWidget);
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
      expect(find.text('Vai Trò Ứng Dụng'), findsNothing);
      expect(find.text('Hồ Sơ & Danh Xưng'), findsNothing);
      expect(find.text('Đồng Bộ Cặp Đôi'), findsNothing);
    });
  });
}
