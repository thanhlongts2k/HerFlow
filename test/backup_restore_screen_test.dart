// test/backup_restore_screen_test.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/features/backup/presentation/screens/backup_restore_screen.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('moona_backup_screen_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(AppConstants.settingsBoxName);
  });

  tearDownAll(() async {
    await Hive.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupRestoreScreen Widget Tests', () {
    testWidgets('renders header, cloud and local sections correctly on Viewport 1080x2400', (tester) async {
      // Thiết lập Viewport chuẩn theo Điều 10 trong AGENTS.md
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BackupRestoreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Kiểm tra tiêu đề AppBar
      expect(find.text('Sao Lưu & Khôi Phục'), findsOneWidget);

      // Kiểm tra Thẻ Bảo Mật AES-256
      expect(find.text('Bảo Mật Cấp Quân Sự AES-256'), findsOneWidget);
      expect(find.byIcon(Icons.shield_rounded), findsOneWidget);

      // Kiểm tra Phân hệ Đám Mây
      expect(find.text('Sao Lưu Đám Mây (Private Vault)'), findsOneWidget);
      expect(find.text('Sao Lưu'), findsOneWidget);
      expect(find.text('Khôi Phục'), findsOneWidget);

      // Kiểm tra Phân hệ Tệp Cục Bộ
      expect(find.text('Tệp Sao Lưu Cục Bộ (.moona)'), findsOneWidget);
      expect(find.text('Xuất Tệp'), findsOneWidget);
      expect(find.text('Nhập Tệp'), findsOneWidget);
    });

    testWidgets('tapping Cloud Khôi Phục opens MoonaConfirmDialog and cancels safely', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BackupRestoreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Nhấn nút "Khôi Phục" của Cloud
      await tester.tap(find.text('Khôi Phục'));
      await tester.pumpAndSettle();

      // Kiểm tra xuất hiện MoonaConfirmDialog cảnh báo ghi đè
      expect(find.text('Khôi Phục Từ Đám Mây?'), findsOneWidget);
      expect(find.text('Khôi phục ngay'), findsOneWidget);
      expect(find.text('Hủy'), findsOneWidget);

      // Nhấn Hủy và xác nhận Dialog biến mất an toàn
      await tester.tap(find.text('Hủy'));
      await tester.pumpAndSettle();
      expect(find.text('Khôi Phục Từ Đám Mây?'), findsNothing);
    });
  });
}
