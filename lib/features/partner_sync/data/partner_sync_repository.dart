// lib/features/partner_sync/data/partner_sync_repository.dart
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:herflow/core/constants/app_constants.dart';
import 'package:herflow/core/utils/user_scope.dart';
import 'package:herflow/features/care_signals/domain/models/care_signal_model.dart';
import '../domain/models/pairing_model.dart';
import '../domain/models/partner_status_model.dart';

/// Repository giao tiếp Cloud Firestore và lưu trạng thái ghép đôi cặp đôi vào Hive.
/// Mọi tương tác Firestore đều có timeout 5s và offline fallback tự động.
class PartnerSyncRepository {
  final FirebaseFirestore _firestore;
  final Box _settingsBox;

  static const _kFirestoreTimeout = Duration(seconds: 5);

  static const String keyCoupleId = 'partner_couple_id';
  static const String keyUserRole = 'partner_user_role'; // 'wife' | 'husband'
  static const String keyPairingCode = 'partner_pairing_code';
  static const String keyWifeUserId = 'partner_wife_user_id';
  static const String keyOfflinePairingCode = 'partner_offline_pairing_code';

  PartnerSyncRepository({
    FirebaseFirestore? firestore,
    Box? settingsBox,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName);

  String _k(String baseKey, [String? explicitUid]) => UserScope.key(baseKey, explicitUid);

  // === LOCAL STORAGE GETTERS ===
  String? getSavedCoupleId([String? explicitUid]) {
    final uid = explicitUid ?? UserScope.currentUid();
    final scoped = _settingsBox.get(_k(keyCoupleId, uid)) as String?;
    if (scoped != null && scoped.isNotEmpty) return scoped;
    if (uid.isEmpty) return _settingsBox.get(keyCoupleId) as String?;
    return null;
  }

  String? getSavedUserRole([String? explicitUid]) {
    final uid = explicitUid ?? UserScope.currentUid();
    final scoped = _settingsBox.get(_k(keyUserRole, uid)) as String?;
    if (scoped != null && scoped.isNotEmpty) return scoped;
    if (uid.isEmpty) return _settingsBox.get(keyUserRole) as String?;
    return null;
  }

  String? getSavedPairingCode([String? explicitUid]) {
    final uid = explicitUid ?? UserScope.currentUid();
    final scoped = _settingsBox.get(_k(keyPairingCode, uid)) as String?;
    if (scoped != null && scoped.isNotEmpty) return scoped;
    if (uid.isEmpty) return _settingsBox.get(keyPairingCode) as String?;
    return null;
  }

  bool get isConnected => getSavedCoupleId() != null && getSavedCoupleId()!.isNotEmpty;

  /// Lưu coupleId cho người dùng hiện tại
  Future<void> saveCoupleId(String coupleId, [String? explicitUid]) async {
    final uid = explicitUid ?? UserScope.currentUid();
    await _settingsBox.put(_k(keyCoupleId, uid), coupleId);
  }

  /// Trả về true nếu mã ghép đôi hiện tại là mã nội bộ (offline fallback)
  bool get isOfflineCode {
    final uid = UserScope.currentUid();
    final savedCode = _settingsBox.get(_k(keyOfflinePairingCode, uid)) as String?;
    return savedCode != null && getSavedPairingCode() == savedCode;
  }

  /// Lấy hoặc tạo userId ẩn danh cho Vợ
  String getOrCreateWifeUserId() {
    final uid = UserScope.currentUid();
    var wifeId = _settingsBox.get(_k(keyWifeUserId, uid)) as String?;
    if (wifeId == null || wifeId.isEmpty) {
      wifeId = uid.isNotEmpty ? uid : const Uuid().v4();
      _settingsBox.put(_k(keyWifeUserId, uid), wifeId);
    }
    return wifeId;
  }

  // === 1. PHÍA VỢ: TẠO MÃ GHÉP ĐÔI 6 KÝ TỰ ===
  /// Sinh ngẫu nhiên mã ghép đôi 6 ký tự.
  /// Ưu tiên ghi lên Firestore; nếu timeout/lỗi → tự động dùng mã nội bộ HFxxxx.
  Future<PairingCodeResult> createPairingCode() async {
    final code = _generateRandomCode();
    final wifeId = getOrCreateWifeUserId();
    final coupleId = const Uuid().v4();
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(hours: 24));

    final pairing = PairingModel(
      pairingCode: code,
      wifeUserId: wifeId,
      coupleId: coupleId,
      status: PairingStatus.pending,
      createdAt: now,
      expiresAt: expiresAt,
    );

    try {
      // Ghi vào collection pairings/{pairingCode} với timeout bảo vệ
      await _firestore
          .collection('pairings')
          .doc(code)
          .set(pairing.toMap())
          .timeout(_kFirestoreTimeout);

      // Lưu tạm cấu hình phía Vợ vào Hive (gắn tiền tố UID người dùng)
      final uid = UserScope.currentUid();
      await _settingsBox.put(_k(keyPairingCode, uid), code);
      await _settingsBox.put(_k(keyCoupleId, uid), coupleId);
      await _settingsBox.put(_k(keyUserRole, uid), 'wife');
      // Xóa cờ offline nếu đã online thành công
      await _settingsBox.delete(_k(keyOfflinePairingCode, uid));

      if (uid.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set({
          'coupleId': coupleId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return PairingCodeResult(pairing: pairing, isOffline: false);
    } on TimeoutException {
      // Timeout — dùng mã nội bộ offline fallback
      return _saveOfflineFallbackCode(code, coupleId, now, expiresAt, wifeId);
    } on FirebaseException {
      // Lỗi Firebase (network, config chưa kích hoạt) — dùng fallback
      return _saveOfflineFallbackCode(code, coupleId, now, expiresAt, wifeId);
    } on PlatformException {
      return _saveOfflineFallbackCode(code, coupleId, now, expiresAt, wifeId);
    } catch (_) {
      return _saveOfflineFallbackCode(code, coupleId, now, expiresAt, wifeId);
    }
  }

  /// Lưu mã offline vào Hive và trả về kết quả với cờ isOffline = true
  Future<PairingCodeResult> _saveOfflineFallbackCode(
    String code,
    String coupleId,
    DateTime createdAt,
    DateTime expiresAt,
    String wifeId,
  ) async {
    final offlinePairing = PairingModel(
      pairingCode: code,
      wifeUserId: wifeId,
      coupleId: coupleId,
      status: PairingStatus.pending,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );

    final uid = UserScope.currentUid();
    await _settingsBox.put(_k(keyPairingCode, uid), code);
    await _settingsBox.put(_k(keyCoupleId, uid), coupleId);
    await _settingsBox.put(_k(keyUserRole, uid), 'wife');
    await _settingsBox.put(_k(keyOfflinePairingCode, uid), code); // đánh dấu offline

    return PairingCodeResult(pairing: offlinePairing, isOffline: true);
  }

  /// Lắng nghe trạng thái của mã ghép đôi theo thời gian thực (phía Vợ chờ Chồng nhập)
  Stream<PairingModel?> watchPairingStatus(String pairingCode) {
    return _firestore
        .collection('pairings')
        .doc(pairingCode)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return PairingModel.fromFirestore(snapshot);
    }).handleError((error) {
      return null;
    });
  }

  // === 2. PHÍA CHỒNG: NHẬP MÃ GHÉP ĐÔI ===
  /// Xác thực mã kết nối 6 ký tự và ghép đôi thành công, có timeout bảo vệ
  Future<PairingModel> connectWithPairingCode(String rawCode) async {
    final cleanCode = rawCode.trim().toUpperCase();
    if (cleanCode.length != 6) {
      throw Exception('Mã kết nối phải bao gồm đúng 6 ký tự.');
    }

    try {
      final doc = await _firestore
          .collection('pairings')
          .doc(cleanCode)
          .get()
          .timeout(_kFirestoreTimeout);

      if (!doc.exists || doc.data() == null) {
        throw Exception('Mã kết nối không tồn tại. Vui lòng kiểm tra lại!');
      }

      final pairing = PairingModel.fromFirestore(doc);

      if (pairing.isExpired) {
        throw Exception('Mã kết nối này đã hết hạn sau 24 giờ. Vui lòng tạo mã mới!');
      }

      if (pairing.status == PairingStatus.connected) {
        // Nếu đã connected, vẫn cho phép kết nối nếu cùng coupleId
        final uid = UserScope.currentUid();
        await _settingsBox.put(_k(keyCoupleId, uid), pairing.coupleId);
        await _settingsBox.put(_k(keyUserRole, uid), 'husband');
        await _settingsBox.put(_k(keyPairingCode, uid), cleanCode);

        if (uid.isNotEmpty) {
          await _firestore.collection('users').doc(uid).set({
            'coupleId': pairing.coupleId,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        return pairing;
      }

      // Cập nhật trạng thái sang "connected" trên Firestore với timeout
      await _firestore
          .collection('pairings')
          .doc(cleanCode)
          .update({'status': PairingStatus.connected.name})
          .timeout(_kFirestoreTimeout);

      // Lưu coupleId vào Hive phía Chồng (gắn tiền tố UID người dùng)
      final uid = UserScope.currentUid();
      await _settingsBox.put(_k(keyCoupleId, uid), pairing.coupleId);
      await _settingsBox.put(_k(keyUserRole, uid), 'husband');
      await _settingsBox.put(_k(keyPairingCode, uid), cleanCode);

      if (uid.isNotEmpty) {
        await _firestore.collection('users').doc(uid).set({
          'coupleId': pairing.coupleId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return pairing.copyWith(status: PairingStatus.connected);
    } on TimeoutException {
      throw Exception('Kết nối quá thời gian (5 giây). Vui lòng kiểm tra mạng và thử lại!');
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firestore khi kết nối: ${e.message}');
    } on PlatformException catch (e) {
      throw Exception('Lỗi thiết bị: ${e.message}');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  static const String keyIsPendingSync = 'is_pending_sync';
  static const String keyPendingStatusData = 'pending_status_data';

  /// Kiểm tra xem có dữ liệu đang chờ đồng bộ hay không
  bool isPendingSync() => _settingsBox.get(keyIsPendingSync, defaultValue: false) as bool;

  // === 3. ĐỒNG BỘ DỮ LIỆU THỜI GIAN THỰC (REALTIME STATUS SYNC) ===
  /// Vợ tự động đẩy trạng thái hôm nay lên Cloud (couples/{coupleId}/status/today)
  Future<void> pushTodayStatus(PartnerStatusModel status, {bool isOnline = true}) async {
    final coupleId = status.coupleId.isNotEmpty ? status.coupleId : getSavedCoupleId();
    if (coupleId == null || coupleId.isEmpty) return;

    if (!isOnline) {
      // Lưu cờ và dữ liệu vào hàng đợi ngoại tuyến của Hive
      await _settingsBox.put(keyIsPendingSync, true);
      await _settingsBox.put(keyPendingStatusData, status.toMap());
      return;
    }

    try {
      final statusMap = status.toMap();

      // 1. Ghi vào subcollection couples/{coupleId}/status/today
      await _firestore
          .collection('couples')
          .doc(coupleId)
          .collection('status')
          .doc('today')
          .set(statusMap, SetOptions(merge: true))
          .timeout(_kFirestoreTimeout);

      // 2. Ghi đồng thời vào document pairings/{pairingCode}
      final pairingCode = _settingsBox.get(keyPairingCode) as String?;
      if (pairingCode != null && pairingCode.isNotEmpty) {
        try {
          await _firestore
              .collection('pairings')
              .doc(pairingCode)
              .set(statusMap, SetOptions(merge: true))
              .timeout(_kFirestoreTimeout);
        } catch (e) {
          debugPrint('pushTodayStatus pairings sync note: $e');
        }
      }

      // Đẩy thành công -> xóa cờ pending
      await _settingsBox.put(keyIsPendingSync, false);
      await _settingsBox.delete(keyPendingStatusData);
    } on TimeoutException {
      await _settingsBox.put(keyIsPendingSync, true);
      await _settingsBox.put(keyPendingStatusData, status.toMap());
    } on FirebaseException catch (_) {
      // Offline fallback: lưu lại cờ pending
      await _settingsBox.put(keyIsPendingSync, true);
      await _settingsBox.put(keyPendingStatusData, status.toMap());
    } catch (_) {
      await _settingsBox.put(keyIsPendingSync, true);
      await _settingsBox.put(keyPendingStatusData, status.toMap());
    }
  }

  /// Tự động xả hàng đợi khi mạng được khôi phục
  Future<void> flushPendingSync() async {
    if (!isPendingSync()) return;
    final data = _settingsBox.get(keyPendingStatusData);
    if (data is Map) {
      final coupleId = getSavedCoupleId();
      if (coupleId == null || coupleId.isEmpty) return;

      try {
        final map = Map<String, dynamic>.from(data);
        await _firestore
            .collection('couples')
            .doc(coupleId)
            .collection('status')
            .doc('today')
            .set(map, SetOptions(merge: true))
            .timeout(_kFirestoreTimeout);

        final pairingCode = _settingsBox.get(keyPairingCode) as String?;
        if (pairingCode != null && pairingCode.isNotEmpty) {
          try {
            await _firestore
                .collection('pairings')
                .doc(pairingCode)
                .set(map, SetOptions(merge: true))
                .timeout(_kFirestoreTimeout);
          } catch (_) {}
        }

        await _settingsBox.put(keyIsPendingSync, false);
        await _settingsBox.delete(keyPendingStatusData);
      } catch (_) {
        // Vẫn giữ pending nếu kết nối chưa ổn định
      }
    }
  }

  /// Chồng lắng nghe trực tiếp luồng dữ liệu trạng thái của Vợ theo thời gian thực
  Stream<PartnerStatusModel?> watchPartnerTodayStatus(String coupleId) {
    if (coupleId.isEmpty) return Stream.value(null);

    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('status')
        .doc('today')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return PartnerStatusModel.fromFirestore(snapshot);
    }).handleError((_) {
      return null;
    });
  }

  // === 4. TÍN HIỆU YÊU THƯƠNG 2 CHIỀU (CARE SIGNALS) ===
  static const String keyLatestLocalSignal = 'latest_local_care_signal';

  /// Vợ gửi tín hiệu yêu thương lên Firestore & lưu Hive local
  Future<void> sendCareSignal(CareSignalModel signal) async {
    // 1. Lưu Hive local làm bộ đệm
    await _settingsBox.put(keyLatestLocalSignal, signal.toMap());

    // 2. Ghi lên Firestore nếu đã kết nối cặp đôi
    final coupleId = signal.coupleId.isNotEmpty ? signal.coupleId : getSavedCoupleId();
    final pairingCode = _settingsBox.get(keyPairingCode) as String?;

    if (coupleId != null && coupleId.isNotEmpty) {
      try {
        await _firestore
            .collection('couples')
            .doc(coupleId)
            .collection('care_signals')
            .doc(signal.id)
            .set(signal.toMap(), SetOptions(merge: true))
            .timeout(_kFirestoreTimeout);
      } catch (e) {
        debugPrint('PartnerSyncRepository: sendCareSignal couples error: $e');
      }
    }

    if (pairingCode != null && pairingCode.isNotEmpty) {
      try {
        await _firestore
            .collection('pairings')
            .doc(pairingCode)
            .collection('care_signals')
            .doc(signal.id)
            .set(signal.toMap(), SetOptions(merge: true))
            .timeout(_kFirestoreTimeout);
      } catch (e) {
        debugPrint('PartnerSyncRepository: sendCareSignal pairings error: $e');
      }
    }
  }

  /// Chồng phản hồi nhanh 1 chạm lên tín hiệu của Vợ
  Future<void> respondCareSignal({
    required String signalId,
    required String responseMessage,
  }) async {
    final coupleId = getSavedCoupleId();
    final pairingCode = _settingsBox.get(keyPairingCode) as String?;
    final now = DateTime.now();
    final updatePayload = {
      'responseMessage': responseMessage,
      'respondedAt': now.toIso8601String(),
      'isRead': true,
    };

    // 1. Cập nhật Hive local
    final localData = _settingsBox.get(keyLatestLocalSignal);
    if (localData is Map) {
      final map = Map<String, dynamic>.from(localData);
      map['responseMessage'] = responseMessage;
      map['respondedAt'] = now.toIso8601String();
      map['isRead'] = true;
      await _settingsBox.put(keyLatestLocalSignal, map);
    }

    // 2. Cập nhật Firestore couples collection
    if (coupleId != null && coupleId.isNotEmpty) {
      try {
        await _firestore
            .collection('couples')
            .doc(coupleId)
            .collection('care_signals')
            .doc(signalId)
            .set(updatePayload, SetOptions(merge: true))
            .timeout(_kFirestoreTimeout);
      } catch (e) {
        debugPrint('PartnerSyncRepository: respondCareSignal couples error: $e');
      }
    }

    // 3. Cập nhật Firestore pairings collection
    if (pairingCode != null && pairingCode.isNotEmpty) {
      try {
        await _firestore
            .collection('pairings')
            .doc(pairingCode)
            .collection('care_signals')
            .doc(signalId)
            .set(updatePayload, SetOptions(merge: true))
            .timeout(_kFirestoreTimeout);
      } catch (e) {
        debugPrint('PartnerSyncRepository: respondCareSignal pairings error: $e');
      }
    }
  }

  /// Lắng nghe tín hiệu yêu thương mới nhất từ Firestore theo thời gian thực (fallback Hive)
  Stream<CareSignalModel?> watchLatestCareSignal(String coupleId) {
    final pairingCode = _settingsBox.get(keyPairingCode) as String?;

    if (coupleId.isEmpty && (pairingCode == null || pairingCode.isEmpty)) {
      final local = _settingsBox.get(keyLatestLocalSignal);
      if (local is Map) {
        try {
          return Stream.value(CareSignalModel.fromMap(Map<String, dynamic>.from(local)));
        } catch (_) {}
      }
      return Stream.value(null);
    }

    // Ưu tiên lắng nghe subcollection của coupleId hoặc pairingCode
    final targetRef = coupleId.isNotEmpty
        ? _firestore.collection('couples').doc(coupleId).collection('care_signals')
        : _firestore.collection('pairings').doc(pairingCode).collection('care_signals');

    return targetRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        final local = _settingsBox.get(keyLatestLocalSignal);
        if (local is Map) {
          return CareSignalModel.fromMap(Map<String, dynamic>.from(local));
        }
        return null;
      }

      // Sắp xếp in-memory theo sentAt giảm dần để tránh lỗi composite index Firestore
      final list = snapshot.docs
          .map((doc) => CareSignalModel.fromMap(doc.data()))
          .toList();
      list.sort((a, b) => b.sentAt.compareTo(a.sentAt));
      final latest = list.first;

      // Cập nhật bộ đệm Hive local
      _settingsBox.put(keyLatestLocalSignal, latest.toMap());
      return latest;
    }).handleError((e) {
      debugPrint('PartnerSyncRepository: watchLatestCareSignal error: $e');
      final local = _settingsBox.get(keyLatestLocalSignal);
      if (local is Map) {
        return CareSignalModel.fromMap(Map<String, dynamic>.from(local));
      }
      return null;
    });
  }

  /// Ngắt kết nối ghép đôi giữa hai thiết bị
  Future<void> disconnectCouple([String? explicitUid]) async {
    final uid = explicitUid ?? UserScope.currentUid();
    await _settingsBox.delete(_k(keyCoupleId, uid));
    await _settingsBox.delete(_k(keyUserRole, uid));
    await _settingsBox.delete(_k(keyPairingCode, uid));
    await _settingsBox.delete(_k(keyOfflinePairingCode, uid));

    // Dọn dẹp cả legacy non-prefixed
    await _settingsBox.delete(keyCoupleId);
    await _settingsBox.delete(keyUserRole);
    await _settingsBox.delete(keyPairingCode);
    await _settingsBox.delete(keyOfflinePairingCode);

    if (uid.isNotEmpty) {
      try {
        await _firestore.collection('users').doc(uid).update({
          'coupleId': FieldValue.delete(),
        });
      } catch (_) {}
    }
  }

  /// Hàm tiện ích sinh mã 6 ký tự viết hoa (ví dụ: HF8201, HF3924...)
  String _generateRandomCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ'; // Bỏ I và O để tránh nhầm số 1 và 0
    const numbers = '23456789'; // Bỏ 0 và 1
    final rnd = Random();

    // Tiền tố HF (HerFlow) + 4 ký tự ngẫu nhiên
    final codeBuffer = StringBuffer('HF');
    for (int i = 0; i < 4; i++) {
      if (i % 2 == 0) {
        codeBuffer.write(numbers[rnd.nextInt(numbers.length)]);
      } else {
        codeBuffer.write(letters[rnd.nextInt(letters.length)]);
      }
    }
    return codeBuffer.toString();
  }
}

/// Kết quả tạo mã ghép đôi — phân biệt online/offline fallback
class PairingCodeResult {
  final PairingModel pairing;
  /// true = mã được tạo cục bộ do Firestore không khả dụng (chế độ thử nghiệm)
  final bool isOffline;

  const PairingCodeResult({required this.pairing, required this.isOffline});
}
