// lib/features/backup/presentation/controllers/backup_restore_controller.dart

import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/providers/user_role_provider.dart';
import 'package:herflow/core/security/backup_encryption_service.dart';
import 'package:herflow/core/theme/theme_controller.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/cycle/presentation/controllers/cycle_controller.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/life_stage_controller.dart';
import 'package:herflow/features/lifecycle/presentation/controllers/pregnancy_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/baby_log_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/child_profile_controller.dart';
import 'package:herflow/features/motherhood/presentation/controllers/lam_status_controller.dart';
import 'package:herflow/features/settings/presentation/controllers/nickname_controller.dart';
import '../../domain/models/backup_metadata.dart';
import '../../domain/services/backup_restore_service.dart';

/// Trạng thái của tiến trình Sao lưu & Khôi phục
class BackupRestoreState {
  final bool isLoading;
  final String? operationStatus;
  final BackupMetadata? lastCloudBackup;
  final BackupMetadata? lastLocalBackup;
  final String? errorMessage;
  final String? successMessage;

  const BackupRestoreState({
    this.isLoading = false,
    this.operationStatus,
    this.lastCloudBackup,
    this.lastLocalBackup,
    this.errorMessage,
    this.successMessage,
  });

  BackupRestoreState copyWith({
    bool? isLoading,
    String? operationStatus,
    BackupMetadata? lastCloudBackup,
    BackupMetadata? lastLocalBackup,
    String? errorMessage,
    String? successMessage,
    bool clearStatus = false,
    bool clearMessages = false,
  }) {
    return BackupRestoreState(
      isLoading: isLoading ?? this.isLoading,
      operationStatus: clearStatus ? null : (operationStatus ?? this.operationStatus),
      lastCloudBackup: lastCloudBackup ?? this.lastCloudBackup,
      lastLocalBackup: lastLocalBackup ?? this.lastLocalBackup,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// Provider cung cấp BackupRestoreService
final backupRestoreServiceProvider = Provider<BackupRestoreService>((ref) {
  return BackupRestoreService();
});

/// Provider điều khiển tiến trình Sao lưu & Khôi phục
final backupRestoreControllerProvider =
    StateNotifierProvider<BackupRestoreController, BackupRestoreState>((ref) {
  final service = ref.watch(backupRestoreServiceProvider);
  return BackupRestoreController(service);
});

class BackupRestoreController extends StateNotifier<BackupRestoreState> {
  final BackupRestoreService _service;

  BackupRestoreController(this._service) : super(const BackupRestoreState()) {
    loadCachedMetadata();
  }

  /// Nạp thông tin lịch sử sao lưu đã lưu trong Hive Settings
  void loadCachedMetadata([String? uid]) {
    final effectiveUid = uid ?? UserScope.currentUid();
    if (!Hive.isBoxOpen(AppConstants.settingsBoxName)) return;

    final box = Hive.box(AppConstants.settingsBoxName);
    final cloudKey = UserScope.key('last_cloud_backup_meta', effectiveUid);
    final localKey = UserScope.key('last_local_backup_meta', effectiveUid);

    BackupMetadata? cloudMeta;
    BackupMetadata? localMeta;

    final rawCloud = box.get(cloudKey);
    if (rawCloud is String && rawCloud.isNotEmpty) {
      try {
        cloudMeta = BackupMetadata.fromMap(jsonDecode(rawCloud));
      } catch (_) {}
    }

    final rawLocal = box.get(localKey);
    if (rawLocal is String && rawLocal.isNotEmpty) {
      try {
        localMeta = BackupMetadata.fromMap(jsonDecode(rawLocal));
      } catch (_) {}
    }

    state = state.copyWith(
      lastCloudBackup: cloudMeta,
      lastLocalBackup: localMeta,
    );
  }

  /// Xuất file sao lưu .moona và mở hộp thoại chia sẻ
  Future<bool> exportLocal({String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    state = state.copyWith(
      isLoading: true,
      operationStatus: 'Đang trích xuất dữ liệu các giai đoạn...',
      clearMessages: true,
    );

    try {
      state = state.copyWith(operationStatus: 'Đang nén GZIP & mã hóa AES-256...');
      final file = await _service.exportToLocalFile(uid: effectiveUid);

      state = state.copyWith(operationStatus: 'Đang mở hộp thoại chia sẻ...');
      await _service.shareLocalBackupFile(file);

      loadCachedMetadata(effectiveUid);
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        successMessage: 'Xuất tệp sao lưu .moona thành công!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: 'Lỗi xuất tệp sao lưu: $e',
      );
      return false;
    }
  }

  /// Mở trình chọn file và khôi phục từ tệp .moona
  Future<bool> pickAndRestoreLocal(WidgetRef ref, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    state = state.copyWith(clearMessages: true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['moona', 'json'],
      );

      if (result == null || result.files.isEmpty || result.files.single.path == null) {
        return false; // Người dùng hủy chọn tệp
      }

      final filePath = result.files.single.path!;
      return await restoreFromLocalPath(filePath, ref, uid: effectiveUid);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: 'Lỗi chọn tệp sao lưu: $e',
      );
      return false;
    }
  }

  /// Thực hiện khôi phục từ đường dẫn tệp cụ thể
  Future<bool> restoreFromLocalPath(String filePath, WidgetRef ref, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    state = state.copyWith(
      isLoading: true,
      operationStatus: 'Đang giải mã và kiểm tra dữ liệu...',
      clearMessages: true,
    );

    try {
      await _service.importFromLocalFile(filePath, uid: effectiveUid);

      state = state.copyWith(operationStatus: 'Đang cập nhật trạng thái ứng dụng...');
      refreshAppStateAfterRestore(ref);

      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        successMessage: 'Khôi phục dữ liệu thành công! Toàn bộ chu kỳ & dữ liệu đã được làm mới.',
      );
      return true;
    } on BackupInvalidKeyException catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: e.message,
      );
      return false;
    } on BackupCorruptedException catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: e.message,
      );
      return false;
    } on BackupVersionMismatchException catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: 'Khôi phục dữ liệu thất bại: $e',
      );
      return false;
    }
  }

  /// Đồng bộ snapshot Hive lên Firestore
  Future<bool> syncToCloud({String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    if (effectiveUid.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng đăng nhập tài khoản để sử dụng tính năng sao lưu Đám mây.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      operationStatus: 'Đang chuẩn bị bản sao lưu...',
      clearMessages: true,
    );

    try {
      state = state.copyWith(operationStatus: 'Đang mã hóa và đồng bộ lên Đám mây...');
      final meta = await _service.exportToCloudFirestore(uid: effectiveUid);

      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        lastCloudBackup: meta,
        successMessage: 'Sao lưu lên Đám mây thành công!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: 'Lỗi sao lưu Đám mây: $e',
      );
      return false;
    }
  }

  /// Khôi phục snapshot từ Firestore
  Future<bool> restoreFromCloud(WidgetRef ref, {String? uid}) async {
    final effectiveUid = uid ?? UserScope.currentUid();
    if (effectiveUid.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Vui lòng đăng nhập tài khoản để khôi phục từ Đám mây.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      operationStatus: 'Đang tải bản sao lưu từ Đám mây...',
      clearMessages: true,
    );

    try {
      await _service.importFromCloudFirestore(uid: effectiveUid);

      state = state.copyWith(operationStatus: 'Đang cập nhật trạng thái ứng dụng...');
      refreshAppStateAfterRestore(ref);

      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        successMessage: 'Khôi phục từ Đám mây thành công!',
      );
      return true;
    } on BackupInvalidKeyException catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: e.message,
      );
      return false;
    } on BackupCorruptedException catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        clearStatus: true,
        errorMessage: 'Khôi phục từ Đám mây thất bại: $e',
      );
      return false;
    }
  }

  /// Làm mới toàn bộ State của ứng dụng thông qua ref.invalidate
  void refreshAppStateAfterRestore(WidgetRef ref) {
    // 1. Chu kỳ sinh học
    ref.invalidate(cycleControllerProvider);
    ref.invalidate(cycleRepositoryProvider);

    // 2. Giai đoạn thai kỳ & thể trạng mẹ
    ref.invalidate(pregnancyConfigProvider);

    // 3. Phân hệ Nuôi con & Mẹ bỉm
    ref.invalidate(childProfileControllerProvider);
    ref.invalidate(babyLogControllerProvider);
    ref.invalidate(lamStatusControllerProvider);

    // 4. Vòng đời, danh xưng, giao diện & vai trò
    ref.invalidate(lifeStageControllerProvider);
    ref.invalidate(nicknameConfigProvider);
    ref.invalidate(themeModeProvider);
    ref.invalidate(userRoleProvider);

    // Nạp lại metadata sau khi restore
    loadCachedMetadata();
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}
