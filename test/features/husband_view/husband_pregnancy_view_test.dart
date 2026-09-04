// test/features/husband_view/husband_pregnancy_view_test.dart
//
// Widget tests cho Bước 2.4: Góc Nhìn Bố Bầu (Husband Pregnancy View)
// - Hiển thị Thẻ "Bé Yêu Của Bố Tuần Này" (tuổi thai, quả so sánh, D-Day, chiều dài, cân nặng).
// - Hiển thị Thẻ "Bí Kíp Chăm Vợ Bầu" theo Tam cá nguyệt (Do's & Don'ts).
// - Tùy biến phím tắt QuickCareSignalsRow cho Bố Bầu (Bóp chân cho vợ, Mua đồ tẩm bổ, Hỏi thăm con).
// - Safeguard Chữa Lành khi isPaused == true.
// - Hiển thị Empty State nhắc nhở khi chưa cấu hình ngày dự sinh.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/cycle/domain/entities/cycle_info.dart';
import 'package:herflow/features/cycle/domain/repositories/cycle_repository.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/husband_view/presentation/screens/husband_view_screen.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/domain/models/pregnancy_config_model.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';
import 'package:herflow/features/partner_sync/presentation/controllers/partner_sync_controller.dart';
import 'package:herflow/features/care_signals/presentation/controllers/care_signal_controller.dart';
import 'package:herflow/features/settings/domain/models/nickname_config.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';

class _FakeCycleRepository extends Fake implements CycleRepository {
  @override
  Future<CycleInfo> getCycleInfo() async {
    return CycleInfo(lastPeriodStart: DateTime.now().subtract(const Duration(days: 14)));
  }
}

class _FakeCycleController extends CycleController {
  _FakeCycleController() : super(_FakeCycleRepository()) {
    state = AsyncValue.data(
      CycleInfo(lastPeriodStart: DateTime.now().subtract(const Duration(days: 14))),
    );
  }
}

class _FakeNicknameController extends StateNotifier<NicknameConfig>
    implements NicknameController {
  _FakeNicknameController() : super(const NicknameConfig(selfCallAs: 'Anh', callPartnerAs: 'Vợ'));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late Directory tempDir;
  late Box settingsBox;

  setUpAll(() async {
    await initializeDateFormatting('vi', null);
    tempDir = await Directory.systemTemp.createTemp('husband_pregnancy_test_');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    await Hive.openBox(AppConstants.cycleBoxName);
    await Hive.openBox(AppConstants.moodBoxName);
    await Hive.openBox(AppConstants.nutritionBoxName);
    await Hive.openBox(AppConstants.userBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    UserScope.setActiveUid('test_husband_pregnancy_user');
    await settingsBox.clear();
  });

  Widget buildTestScreen({
    PregnancyConfigModel? config,
    LifeStageState lifeStageState = const LifeStageState(currentStage: LifeStage.pregnancy),
    String? coupleId = 'test_couple_123',
  }) {
    final pregnancyCtrl = PregnancyController(settingsBox: settingsBox);
    if (config != null) {
      pregnancyCtrl.state = config;
    }

    final lifeStageCtrl = LifeStageController(settingsBox: settingsBox);
    lifeStageCtrl.state = lifeStageState;

    return ProviderScope(
      overrides: [
        pregnancyConfigProvider.overrideWith((ref) => pregnancyCtrl),
        lifeStageControllerProvider.overrideWith((ref) => lifeStageCtrl),
        cycleControllerProvider.overrideWith((ref) => _FakeCycleController()),
        savedCoupleIdProvider.overrideWith((ref) => coupleId),
        partnerLiveStatusStreamProvider.overrideWith((ref) => Stream.value(null)),
        latestCareSignalStreamProvider.overrideWith((ref) => Stream.value(null)),
        nicknameConfigProvider.overrideWith((ref) => _FakeNicknameController()),
      ],
      child: const MaterialApp(
        home: HusbandViewScreen(),
      ),
    );
  }

  group('Husband Pregnancy View Tests', () {
    testWidgets('Header bar hiển thị đúng tiêu đề "Góc Nhìn Bố Bầu"', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen());
      await tester.pumpAndSettle();

      expect(find.text('Góc Nhìn Bố Bầu'), findsOneWidget);
      expect(find.textContaining('Trợ lý chăm sóc thai kỳ'), findsOneWidget);
    });

    testWidgets('Hiển thị Thẻ "Bé Yêu Của Bố Tuần Này" với đầy đủ tuổi thai, quả và D-Day', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Thai kỳ 87 ngày (~12 tuần 3 ngày -> Tuần thứ 13, quả chanh ta 🍋)
      final config = PregnancyConfigModel(
        lastMenstrualPeriod: DateTime.now().subtract(const Duration(days: 87)),
        estimatedDueDate: DateTime.now().add(const Duration(days: 193)),
        isTrackingActive: true,
      );

      await tester.pumpWidget(buildTestScreen(config: config));
      await tester.pumpAndSettle();

      // Thẻ Bé Yêu Của Bố Tuần Này
      expect(find.text('Bé Yêu Của Bố Tuần Này'), findsOneWidget);
      expect(find.textContaining('12 tuần 3 ngày • Tuần thứ 13'), findsOneWidget);
      expect(find.textContaining('Bé to bằng Quả đậu Hà Lan'), findsOneWidget);
      expect(find.textContaining('🫛'), findsOneWidget);

      // Đếm ngược D-Day
      expect(find.textContaining('Còn 193 ngày nữa gặp con 🍼'), findsOneWidget);

      // Kích thước
      expect(find.textContaining('Dài ~7.4 cm'), findsOneWidget);
      expect(find.textContaining('Nặng ~23.0 g'), findsOneWidget);

      // Cột mốc phát triển diệu kỳ
      expect(find.text('Cột mốc diệu kỳ tuần này:'), findsOneWidget);
    });

    testWidgets('Thẻ "Bí Kíp Chăm Vợ Bầu" hiển thị Do & Don\'t chính xác theo Tam cá nguyệt', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Tam cá nguyệt 1 (Tuần 8)
      final config = PregnancyConfigModel(
        lastMenstrualPeriod: DateTime.now().subtract(const Duration(days: 56)),
        estimatedDueDate: DateTime.now().add(const Duration(days: 224)),
        isTrackingActive: true,
      );

      await tester.pumpWidget(buildTestScreen(config: config));
      await tester.pumpAndSettle();

      expect(find.text('Bí Kíp Chăm Vợ Bầu Cho Bố'), findsOneWidget);
      expect(find.textContaining('Tam cá nguyệt 1: Giai đoạn nhạy cảm & ốm nghén'), findsOneWidget);
      expect(find.textContaining('NÊN CHỦ ĐỘNG LÀM CHO'), findsOneWidget);
      expect(find.textContaining('TUYỆT ĐỐI NÊN TRÁNH:'), findsOneWidget);
      expect(find.textContaining('Chủ động nấu ăn hoặc dọn dẹp'), findsOneWidget);
      expect(find.textContaining('Xịt nước hoa nồng'), findsOneWidget);
    });

    testWidgets('QuickCareSignalsRow hiển thị đúng 3 phím tắt chăm sóc Mẹ Bầu', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final config = PregnancyConfigModel(
        lastMenstrualPeriod: DateTime.now().subtract(const Duration(days: 56)),
        estimatedDueDate: DateTime.now().add(const Duration(days: 224)),
        isTrackingActive: true,
      );

      await tester.pumpWidget(buildTestScreen(config: config));
      await tester.pumpAndSettle();

      expect(find.textContaining('Chăm Sóc Mẹ Bầu 1 Chạm Tới'), findsOneWidget);
      expect(find.text('Bóp chân cho vợ'), findsOneWidget);
      expect(find.text('Mua đồ tẩm bổ'), findsOneWidget);
      expect(find.text('Hỏi thăm con'), findsOneWidget);
    });

    testWidgets('Safeguard: Khi isPaused == true, ẩn toàn bộ thẻ thai kỳ và hiển thị Chế Độ Chữa Lành', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final config = PregnancyConfigModel(
        lastMenstrualPeriod: DateTime.now().subtract(const Duration(days: 56)),
        estimatedDueDate: DateTime.now().add(const Duration(days: 224)),
        isTrackingActive: true,
      );

      await tester.pumpWidget(
        buildTestScreen(
          config: config,
          lifeStageState: const LifeStageState(
            currentStage: LifeStage.pregnancy,
            isPaused: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ẩn thẻ thai kỳ và hoa quả
      expect(find.text('Bé Yêu Của Bố Tuần Này'), findsNothing);
      expect(find.textContaining('Bé to bằng'), findsNothing);

      // Hiển thị card Đồng Hành & Vỗ Về Bạn Đời
      expect(find.text('Đồng Hành & Vỗ Về Bạn Đời'), findsOneWidget);
      expect(find.text('Chế độ Chữa Lành đang được bật'), findsOneWidget);

      // Phím tắt đổi sang vỗ về
      expect(find.textContaining('Vỗ Về & Yêu Thương'), findsOneWidget);
      expect(find.text('Ôm vỗ về'), findsOneWidget);
      expect(find.text('Nấu cháo ấm'), findsOneWidget);
    });

    testWidgets('Hiển thị card hướng dẫn khi chưa có cấu hình ngày dự sinh', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Chưa có config
      await tester.pumpWidget(buildTestScreen(config: null));
      await tester.pumpAndSettle();

      expect(find.textContaining('Hành Trình Thai Kỳ Cùng'), findsOneWidget);
      expect(find.textContaining('chưa thiết lập ngày dự sinh trên máy'), findsOneWidget);
    });
  });
}
