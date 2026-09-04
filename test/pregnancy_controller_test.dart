// test/pregnancy_controller_test.dart
//
// Unit & Widget tests cho Phase 2 (Bước 2.2):
// - State management thai kỳ (PregnancyController).
// - Các computed providers: currentGestationalAgeProvider, currentFetalWeekDataProvider.
// - Giao diện thiết lập ngày dự sinh (PregnancySetupSheet).
//
// Chạy: flutter test test/pregnancy_controller_test.dart

import 'dart:convert';
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
import 'package:herflow/features/lifecycle/presentation/widgets/pregnancy_setup_sheet.dart';

void main() {
  late Directory tempDir;
  late Box settingsBox;

  setUpAll(() async {
    await initializeDateFormatting('vi', null);
    tempDir = await Directory.systemTemp.createTemp('pregnancy_test_');
    Hive.init(tempDir.path);
    settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
  });

  tearDownAll(() async {
    await settingsBox.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    UserScope.setActiveUid('test_pregnancy_user');
    await settingsBox.clear();
  });

  group('PregnancyController Unit Tests', () {
    test('Khởi tạo ban đầu với box rỗng -> state là null', () {
      final controller = PregnancyController(settingsBox: settingsBox);
      expect(controller.state, isNull);
    });

    test('Khởi tạo với dữ liệu JSON hợp lệ trong Hive -> nạp đúng state', () async {
      final lmp = DateTime(2026, 1, 1);
      final edd = DateTime(2026, 10, 8);
      final model = PregnancyConfigModel(
        lastMenstrualPeriod: lmp,
        estimatedDueDate: edd,
        isTrackingActive: true,
      );

      await settingsBox.put(
        UserScope.key(AppConstants.keyPregnancyConfig),
        jsonEncode(model.toMap()),
      );

      final controller = PregnancyController(settingsBox: settingsBox);
      expect(controller.state, isNotNull);
      expect(controller.state?.lastMenstrualPeriod, equals(lmp));
      expect(controller.state?.estimatedDueDate, equals(edd));
      expect(controller.state?.isTrackingActive, isTrue);
    });

    test('Khởi tạo với legacy keyPregnancyDueDate -> tự tính LMP và nạp state', () async {
      final edd = DateTime(2026, 10, 8);
      await settingsBox.put(
        UserScope.key(AppConstants.keyPregnancyDueDate),
        edd.toIso8601String(),
      );

      final controller = PregnancyController(settingsBox: settingsBox);
      expect(controller.state, isNotNull);
      expect(controller.state?.estimatedDueDate, equals(edd));
      expect(controller.state?.lastMenstrualPeriod, equals(DateTime(2026, 1, 1)));
    });

    test('setPregnancyByLmp: tính đúng EDD (+280 ngày), lưu Hive và cập nhật state', () async {
      final controller = PregnancyController(settingsBox: settingsBox);
      final lmp = DateTime(2026, 3, 1);

      await controller.setPregnancyByLmp(lmp);

      expect(controller.state, isNotNull);
      expect(controller.state?.lastMenstrualPeriod, equals(lmp));
      // 2026 không nhuận: Mar 1 + 280 ngày = Dec 6, 2026
      expect(controller.state?.estimatedDueDate, equals(DateTime(2026, 12, 6)));
      expect(controller.state?.isTrackingActive, isTrue);

      // Kiểm tra lưu Hive
      final storedJson = settingsBox.get(UserScope.key(AppConstants.keyPregnancyConfig)) as String?;
      expect(storedJson, isNotNull);
      final map = jsonDecode(storedJson!) as Map<String, dynamic>;
      expect(map['lastMenstrualPeriod'], equals(lmp.toIso8601String()));
      expect(map['estimatedDueDate'], equals(DateTime(2026, 12, 6).toIso8601String()));

      final storedDueDate = settingsBox.get(UserScope.key(AppConstants.keyPregnancyDueDate)) as String?;
      expect(storedDueDate, equals(DateTime(2026, 12, 6).toIso8601String()));
    });

    test('setPregnancyByEdd: tính đúng LMP (-280 ngày), lưu Hive và cập nhật state', () async {
      final controller = PregnancyController(settingsBox: settingsBox);
      final edd = DateTime(2026, 12, 6);

      await controller.setPregnancyByEdd(edd);

      expect(controller.state, isNotNull);
      expect(controller.state?.estimatedDueDate, equals(edd));
      expect(controller.state?.lastMenstrualPeriod, equals(DateTime(2026, 3, 1)));
      expect(controller.state?.isTrackingActive, isTrue);

      // Kiểm tra lưu Hive
      final storedJson = settingsBox.get(UserScope.key(AppConstants.keyPregnancyConfig)) as String?;
      expect(storedJson, isNotNull);
    });

    test('clearPregnancy: xóa sạch state và các key liên quan trong Hive', () async {
      final controller = PregnancyController(settingsBox: settingsBox);
      await controller.setPregnancyByLmp(DateTime(2026, 3, 1));
      expect(controller.state, isNotNull);

      await controller.clearPregnancy();

      expect(controller.state, isNull);
      expect(settingsBox.get(UserScope.key(AppConstants.keyPregnancyConfig)), isNull);
      expect(settingsBox.get(UserScope.key(AppConstants.keyPregnancyDueDate)), isNull);
    });
  });

  group('Computed Providers Tests', () {
    test('currentGestationalAgeProvider tính chính xác tuổi thai từ state', () {
      final container = ProviderContainer(
        overrides: [
          pregnancyConfigProvider.overrideWith((ref) {
            final c = PregnancyController(settingsBox: settingsBox);
            c.state = PregnancyConfigModel(
              lastMenstrualPeriod: DateTime.now().subtract(const Duration(days: 73)),
              estimatedDueDate: DateTime.now().add(const Duration(days: 207)),
              isTrackingActive: true,
            );
            return c;
          }),
        ],
      );
      addTearDown(container.dispose);

      final age = container.read(currentGestationalAgeProvider);
      expect(age, isNotNull);
      expect(age?.totalDaysPregnant, equals(73));
      expect(age?.currentWeek, equals(10)); // 73 ~/ 7 = 10
      expect(age?.currentDayOfWeek, equals(3)); // 73 % 7 = 3
      expect(age?.currentWeekOrdinal, equals(11));
      expect(age?.trimester, equals(Trimester.first));
      expect(age?.formattedAge, equals('10 tuần 3 ngày'));
    });

    test('currentFetalWeekDataProvider trả về đúng thông tin hoa quả theo tuần thai', () {
      final container = ProviderContainer(
        overrides: [
          pregnancyConfigProvider.overrideWith((ref) {
            final c = PregnancyController(settingsBox: settingsBox);
            c.state = PregnancyConfigModel(
              lastMenstrualPeriod: DateTime.now().subtract(const Duration(days: 73)),
              estimatedDueDate: DateTime.now().add(const Duration(days: 207)),
              isTrackingActive: true,
            );
            return c;
          }),
        ],
      );
      addTearDown(container.dispose);

      final fetalWeek = container.read(currentFetalWeekDataProvider);
      expect(fetalWeek, isNotNull);
      expect(fetalWeek?.week, equals(11));
      expect(fetalWeek?.fruitName, equals('Quả sung ngọt'));
      expect(fetalWeek?.fruitEmoji, equals('🍈'));
      expect(fetalWeek?.approxLengthCm, equals(4.1));
    });

    test('Providers trả null khi chưa có thai kỳ hoặc isTrackingActive = false', () {
      final container = ProviderContainer(
        overrides: [
          pregnancyConfigProvider.overrideWith((ref) {
            final c = PregnancyController(settingsBox: settingsBox);
            c.state = const PregnancyConfigModel(isTrackingActive: false);
            return c;
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(currentGestationalAgeProvider), isNull);
      expect(container.read(currentFetalWeekDataProvider), isNull);
    });
  });

  group('PregnancySetupSheet Widget Tests', () {
    testWidgets('Hiển thị tiêu đề, các segment và live preview ban đầu', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakePregnancyController = PregnancyController(settingsBox: settingsBox);
      final fakeLifeStageController = LifeStageController(settingsBox: settingsBox);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pregnancyConfigProvider.overrideWith((ref) => fakePregnancyController),
            lifeStageControllerProvider.overrideWith((ref) => fakeLifeStageController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PregnancySetupSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề và phụ đề
      expect(find.text('Hành Trình Đón Bé Yêu'), findsOneWidget);
      expect(find.text('Thiết lập ngày để đồng hành 40 tuần thai kỳ'), findsOneWidget);

      // Kiểm tra 2 segment chọn phương thức tính
      expect(find.text('Kỳ kinh cuối (LMP)'), findsOneWidget);
      expect(find.text('Ngày dự sinh (EDD)'), findsOneWidget);

      // Kiểm tra thẻ ngày chọn và nút Submit
      expect(find.textContaining('Ngày đầu của kỳ kinh cuối:'), findsOneWidget);
      expect(find.text('Bắt Đầu Theo Dõi Thai Kỳ'), findsOneWidget);

      // Kiểm tra Live Preview hiển thị
      expect(find.textContaining('Bé hiện tại:'), findsOneWidget);
      expect(find.textContaining('Dự kiến sinh:'), findsOneWidget);
    });

    testWidgets('Chuyển đổi segment sang EDD -> cập nhật nhãn ngày tương ứng', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakePregnancyController = PregnancyController(settingsBox: settingsBox);
      final fakeLifeStageController = LifeStageController(settingsBox: settingsBox);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pregnancyConfigProvider.overrideWith((ref) => fakePregnancyController),
            lifeStageControllerProvider.overrideWith((ref) => fakeLifeStageController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PregnancySetupSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Chạm chọn tab 'Ngày dự sinh (EDD)'
      await tester.tap(find.text('Ngày dự sinh (EDD)'));
      await tester.pumpAndSettle();

      // Nhãn đổi sang hướng dẫn EDD
      expect(find.textContaining('Ngày dự sinh (theo bác sĩ/siêu âm):'), findsOneWidget);
      expect(find.textContaining('Dự kiến sinh:'), findsOneWidget);
    });

    testWidgets('Bấm Bắt Đầu Theo Dõi Thai Kỳ -> lưu config và đổi LifeStage sang pregnancy', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakePregnancyController = PregnancyController(settingsBox: settingsBox);
      final fakeLifeStageController = LifeStageController(settingsBox: settingsBox);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            pregnancyConfigProvider.overrideWith((ref) => fakePregnancyController),
            lifeStageControllerProvider.overrideWith((ref) => fakeLifeStageController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: PregnancySetupSheet(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bấm nút Submit
      await tester.runAsync(() async {
        await tester.tap(find.text('Bắt Đầu Theo Dõi Thai Kỳ'));
        for (int i = 0; i < 20; i++) {
          if (fakeLifeStageController.state.currentStage == LifeStage.pregnancy) break;
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump(); // Cập nhật frame sau khi async hoàn tất

      // State thai kỳ được lưu
      expect(fakePregnancyController.state, isNotNull);
      expect(fakePregnancyController.state?.isTrackingActive, isTrue);

      // LifeStage chuyển sang pregnancy
      expect(fakeLifeStageController.state.currentStage, equals(LifeStage.pregnancy));
    });
  });
}
