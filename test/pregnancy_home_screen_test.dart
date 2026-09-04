// test/pregnancy_home_screen_test.dart
//
// Widget tests cho Phase 2 (Bước 2.3): PregnancyHomeScreen
// - Hiển thị Empty State khi chưa có cấu hình thai kỳ.
// - Hiển thị đúng tuần thai, D-Day và quả so sánh khi đã cấu hình.
// - Chuyển tuần tương tác trên Week Carousel.
// - Mở PregnancySetupSheet khi bấm nút sửa ngày hoặc từ empty state.
// - Hiển thị Healing View khi isPaused == true.
//
// Chạy: flutter test test/pregnancy_home_screen_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/lifecycle/domain/models/life_stage.dart';
import 'package:herflow/features/lifecycle/domain/models/pregnancy_config_model.dart';
import 'package:herflow/features/lifecycle/domain/services/pregnancy_calculator_service.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';
import 'package:herflow/features/lifecycle/presentation/screens/pregnancy_home_screen.dart';
import 'package:herflow/features/lifecycle/presentation/widgets/pregnancy_setup_sheet.dart';

void main() {
  late Directory tempDir;
  late Box settingsBox;

  setUpAll(() async {
    await initializeDateFormatting('vi', null);
    tempDir = await Directory.systemTemp.createTemp('pregnancy_home_test_');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
  });

  tearDownAll(() async {
    await settingsBox.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    UserScope.setActiveUid('test_home_user');
    await settingsBox.clear();
  });

  Widget buildTestScreen({
    PregnancyConfigModel? config,
    LifeStageState lifeStageState = const LifeStageState(currentStage: LifeStage.pregnancy),
    PregnancyController? pregnancyController,
    LifeStageController? lifeStageController,
  }) {
    final effectivePregnancyCtrl = pregnancyController ?? PregnancyController(settingsBox: settingsBox);
    if (config != null) {
      effectivePregnancyCtrl.state = config;
    }

    final effectiveLifeStageCtrl = lifeStageController ?? LifeStageController(settingsBox: settingsBox);
    effectiveLifeStageCtrl.state = lifeStageState;

    return ProviderScope(
      overrides: [
        pregnancyConfigProvider.overrideWith((ref) => effectivePregnancyCtrl),
        lifeStageControllerProvider.overrideWith((ref) => effectiveLifeStageCtrl),
      ],
      child: const MaterialApp(
        home: PregnancyHomeScreen(),
      ),
    );
  }

  group('PregnancyHomeScreen Empty State Tests', () {
    testWidgets('Hiển thị Empty State khi chưa có cấu hình thai kỳ', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(config: null));
      await tester.pumpAndSettle();

      expect(find.textContaining('Chào Mừng Đến Với'), findsOneWidget);
      expect(find.text('Bắt Đầu Theo Dõi Thai Kỳ'), findsOneWidget);
    });

    testWidgets('Bấm Bắt Đầu Theo Dõi Thai Kỳ từ Empty State -> mở PregnancySetupSheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestScreen(config: null));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Bắt Đầu Theo Dõi Thai Kỳ'));
      await tester.pumpAndSettle();

      // PregnancySetupSheet mở lên
      expect(find.byType(PregnancySetupSheet), findsOneWidget);
      expect(find.textContaining('Hành Trình Đón Bé Yêu'), findsOneWidget);
    });
  });

  group('PregnancyHomeScreen Active Dashboard Tests', () {
    testWidgets('Hiển thị đầy đủ Gestational Hero Card, D-Day và quả so sánh', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Giả lập LMP = 77 ngày trước (11 tuần 0 ngày -> đang ở tuần thứ 12: Quả chanh ta 🍋)
      final lmp = DateTime.now().subtract(const Duration(days: 77));
      final edd = PregnancyCalculatorService.calculateDueDateFromLMP(lmp);
      final config = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: edd,
        isTrackingActive: true,
      );

      await tester.pumpWidget(buildTestScreen(config: config));
      await tester.pumpAndSettle();

      // 1. Header Bar
      expect(find.text('Hành Trình Đón Bé'), findsOneWidget);
      expect(find.byIcon(Icons.edit_calendar_rounded), findsOneWidget);

      // 2. Hero Card: Tuần tuổi thai & Tam cá nguyệt
      expect(find.textContaining('Tuần 11'), findsOneWidget);
      expect(find.textContaining('Tam cá nguyệt 1'), findsWidgets);
      expect(find.textContaining('D-Day: Còn'), findsOneWidget);

      // 3. Fetal Comparison Card: Quả chanh ta 🍋
      expect(find.textContaining('Bé to bằng Quả chanh ta'), findsOneWidget);
      expect(find.text('🍋'), findsWidgets);
      expect(find.text('Chiều dài'), findsOneWidget);
      expect(find.text('Cân nặng'), findsOneWidget);
      expect(find.textContaining('Cột mốc kỳ diệu tuần này:'), findsOneWidget);
      expect(find.textContaining('Lời khuyên cho mẹ tuần này'), findsOneWidget);
    });

    testWidgets('Week Carousel: Chuyển tuần tương tác xem trước Tuần 20 (Quả chuối tiêu 🍌)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lmp = DateTime.now().subtract(const Duration(days: 77)); // Tuần 12
      final config = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: PregnancyCalculatorService.calculateDueDateFromLMP(lmp),
        isTrackingActive: true,
      );

      await tester.pumpWidget(buildTestScreen(config: config));
      await tester.pumpAndSettle();

      // Đang hiển thị Quả chanh ta ban đầu
      expect(find.textContaining('Bé to bằng Quả chanh ta'), findsOneWidget);

      // Cuộn danh sách tuần ngang để tìm và bấm vào Tuần 20 (T.20)
      await tester.drag(find.byType(ListView), const Offset(-600, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('T.20'));
      await tester.pumpAndSettle();

      // Card so sánh cập nhật sang Quả chuối tiêu 🍌 (Tuần 20)
      expect(find.textContaining('Bé to bằng Quả chuối tiêu'), findsOneWidget);
      expect(find.text('🍌'), findsWidgets);
      expect(find.textContaining('Đang xem tuần thứ 20'), findsOneWidget);

      // Nút "Về tuần hiện tại" xuất hiện
      expect(find.textContaining('Về tuần hiện tại'), findsOneWidget);

      // Bấm nút quay về tuần hiện tại
      await tester.tap(find.textContaining('Về tuần hiện tại'));
      await tester.pumpAndSettle();

      // Quay trở lại Quả chanh ta của tuần 12
      expect(find.textContaining('Bé to bằng Quả chanh ta'), findsOneWidget);
    });

    testWidgets('Bấm icon lịch trên Header Bar -> mở PregnancySetupSheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lmp = DateTime.now().subtract(const Duration(days: 84));
      final config = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: PregnancyCalculatorService.calculateDueDateFromLMP(lmp),
        isTrackingActive: true,
      );

      await tester.pumpWidget(buildTestScreen(config: config));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_calendar_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PregnancySetupSheet), findsOneWidget);
    });
  });

  group('PregnancyHomeScreen Healing Mode Tests', () {
    testWidgets('Hiển thị Healing View khi isPaused == true (ẩn toàn bộ tuần thai & quả)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final lmp = DateTime.now().subtract(const Duration(days: 84));
      final config = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: PregnancyCalculatorService.calculateDueDateFromLMP(lmp),
        isTrackingActive: true,
      );

      await tester.pumpWidget(
        buildTestScreen(
          config: config,
          lifeStageState: const LifeStageState(
            currentStage: LifeStage.pregnancy,
            isPaused: true,
            pauseReason: 'personal',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header đổi sang Chế Độ Chữa Lành
      expect(find.text('Chế Độ Chữa Lành'), findsOneWidget);

      // Card Chữa Lành xuất hiện
      expect(find.text('Không Gian Yên Bình & Chữa Lành'), findsOneWidget);
      expect(find.text('🕊️'), findsWidgets);
      expect(find.textContaining('HerFlow luôn ở bên bạn'), findsOneWidget);
      expect(find.text('Tiếp Tục Theo Dõi Thai Kỳ'), findsOneWidget);

      // Ẩn hoàn toàn thẻ tuần thai và quả
      expect(find.textContaining('Hành Trình 40 Tuần'), findsNothing);
      expect(find.textContaining('Bé to bằng'), findsNothing);
      expect(find.textContaining('D-Day: Còn'), findsNothing);
    });
  });
}
