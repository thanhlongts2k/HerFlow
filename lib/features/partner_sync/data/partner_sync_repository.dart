// lib/features/partner_sync/data/partner_sync_repository.dart
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:herflow/core/constants/app_constants.dart';
import '../domain/models/pairing_model.dart';
import '../domain/models/partner_status_model.dart';

/// Repository giao tiếp Cloud Firestore và lưu trạng thái ghép đôi cặp đôi vào Hive
class PartnerSyncRepository {
  final FirebaseFirestore _firestore;
  final Box _settingsBox;

  static const String keyCoupleId = 'partner_couple_id';
  static const String keyUserRole = 'partner_user_role'; // 'wife' | 'husband'
  static const String keyPairingCode = 'partner_pairing_code';
  static const String keyWifeUserId = 'partner_wife_user_id';

  PartnerSyncRepository({
    FirebaseFirestore? firestore,
    Box? settingsBox,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName);

  // === LOCAL STORAGE GETTERS ===
  String? getSavedCoupleId() => _settingsBox.get(keyCoupleId) as String?;
  String? getSavedUserRole() => _settingsBox.get(keyUserRole) as String?;
  String? getSavedPairingCode() => _settingsBox.get(keyPairingCode) as String?;
  bool get isConnected => getSavedCoupleId() != null && getSavedCoupleId()!.isNotEmpty;

  /// Lấy hoặc tạo userId ẩn danh cho Vợ
  String getOrCreateWifeUserId() {
    var uid = _settingsBox.get(keyWifeUserId) as String?;
    if (uid == null || uid.isEmpty) {
      uid = const Uuid().v4();
      _settingsBox.put(keyWifeUserId, uid);
    }
    return uid;
  }

  // === 1. PHÍA VỢ: TẠO MÃ GHÉP ĐÔI 6 KÝ TỰ ===
  /// Sinh ngẫu nhiên mã ghép đôi 6 ký tự viết hoa (ví dụ HF8201) và lưu lên Firestore
  Future<PairingModel> createPairingCode() async {
    try {
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

      // Ghi vào collection pairings/{pairingCode}
      await _firestore.collection('pairings').doc(code).set(pairing.toMap());

      // Lưu tạm cấu hình phía Vợ vào Hive
      await _settingsBox.put(keyPairingCode, code);
      await _settingsBox.put(keyCoupleId, coupleId);
      await _settingsBox.put(keyUserRole, 'wife');

      return pairing;
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firebase khi tạo mã: ${e.message}');
    } on PlatformException catch (e) {
      throw Exception('Lỗi hệ thống: ${e.message}');
    } catch (e) {
      throw Exception('Không thể tạo mã ghép đôi: $e');
    }
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
  /// Xác thực mã kết nối 6 ký tự và ghép đôi thành công
  Future<PairingModel> connectWithPairingCode(String rawCode) async {
    try {
      final cleanCode = rawCode.trim().toUpperCase();
      if (cleanCode.length != 6) {
        throw Exception('Mã kết nối phải bao gồm đúng 6 ký tự.');
      }

      final doc = await _firestore.collection('pairings').doc(cleanCode).get();
      if (!doc.exists || doc.data() == null) {
        throw Exception('Mã kết nối không tồn tại. Vui lòng kiểm tra lại!');
      }

      final pairing = PairingModel.fromFirestore(doc);

      if (pairing.isExpired) {
        throw Exception('Mã kết nối này đã hết hạn sau 24 giờ. Vui lòng tạo mã mới!');
      }

      if (pairing.status == PairingStatus.connected) {
        // Nếu đã connected, vẫn cho phép kết nối nếu cùng coupleId
        await _settingsBox.put(keyCoupleId, pairing.coupleId);
        await _settingsBox.put(keyUserRole, 'husband');
        await _settingsBox.put(keyPairingCode, cleanCode);
        return pairing;
      }

      // Cập nhật trạng thái sang "connected" trên Firestore
      await _firestore.collection('pairings').doc(cleanCode).update({
        'status': PairingStatus.connected.name,
      });

      // Lưu coupleId vào Hive phía Chồng
      await _settingsBox.put(keyCoupleId, pairing.coupleId);
      await _settingsBox.put(keyUserRole, 'husband');
      await _settingsBox.put(keyPairingCode, cleanCode);

      return pairing.copyWith(status: PairingStatus.connected);
    } on FirebaseException catch (e) {
      throw Exception('Lỗi Firestore khi kết nối: ${e.message}');
    } on PlatformException catch (e) {
      throw Exception('Lỗi thiết bị: ${e.message}');
    } catch (e) {
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // === 3. ĐỒNG BỘ DỮ LIỆU THỜI GIAN THỰC (REALTIME STATUS SYNC) ===
  /// Vợ tự động đẩy trạng thái hôm nay lên Cloud (couples/{coupleId}/status/today)
  Future<void> pushTodayStatus(PartnerStatusModel status) async {
    try {
      final coupleId = status.coupleId.isNotEmpty ? status.coupleId : getSavedCoupleId();
      if (coupleId == null || coupleId.isEmpty) return;

      await _firestore
          .collection('couples')
          .doc(coupleId)
          .collection('status')
          .doc('today')
          .set(status.toMap(), SetOptions(merge: true));
    } on FirebaseException catch (_) {
      // Offline cache tự xử lý ngầm, không crash app
    } catch (_) {
      // Phòng thủ an toàn không làm gián đoạn trải nghiệm người dùng
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

  /// Ngắt kết nối ghép đôi giữa hai thiết bị
  Future<void> disconnectCouple() async {
    await _settingsBox.delete(keyCoupleId);
    await _settingsBox.delete(keyUserRole);
    await _settingsBox.delete(keyPairingCode);
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
