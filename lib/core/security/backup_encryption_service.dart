// lib/core/security/backup_encryption_service.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'backup_encryption_config.dart';

/// Các ngoại lệ đặc thù của phân hệ Sao lưu & Khôi phục

abstract class BackupEncryptionException implements Exception {
  final String message;
  const BackupEncryptionException(this.message);

  @override
  String toString() => message;
}

/// Ngoại lệ khi khóa giải mã không hợp lệ hoặc tệp xuất phát từ UID/tài khoản khác
class BackupInvalidKeyException extends BackupEncryptionException {
  const BackupInvalidKeyException([super.message = 'Khóa giải mã không chính xác hoặc tệp sao lưu thuộc tài khoản khác.']);
}

/// Ngoại lệ khi tệp sao lưu bị biến đổi, hỏng hóc hoặc mã băm Checksum không khớp
class BackupCorruptedException extends BackupEncryptionException {
  const BackupCorruptedException([super.message = 'Tệp sao lưu bị lỗi hoặc đã bị chỉnh sửa trái phép (Sai mã kiểm tra).']);
}

/// Ngoại lệ khi phiên bản cấu trúc tệp không tương thích
class BackupVersionMismatchException extends BackupEncryptionException {
  const BackupVersionMismatchException([super.message = 'Phiên bản tệp sao lưu không được ứng dụng hiện tại hỗ trợ.']);
}

/// Dịch vụ mật mã hóa cao cấp chuẩn AES-256-CBC kết hợp nén GZIP và kiểm định Checksum SHA-256
class BackupEncryptionService {
  const BackupEncryptionService();

  /// Dẫn xuất khóa 256-bit (32 bytes) từ UID người dùng và Application Salt
  Uint8List deriveKey(String uid, {String? customSalt}) {
    final effectiveSalt = customSalt ?? BackupEncryptionConfig.appSalt;
    final effectiveUid = uid.trim().isEmpty ? BackupEncryptionConfig.guestFallbackSeed : uid.trim();

    // Vòng lặp băm KDF tăng cường độ an toàn chống brute-force
    var currentBytes = utf8.encode('$effectiveUid:$effectiveSalt');
    var hash = sha256.convert(currentBytes).bytes;
    for (int i = 0; i < 1000; i++) {
      hash = sha256.convert(hash).bytes;
    }
    return Uint8List.fromList(hash);
  }

  /// Tính mã băm SHA-256 an toàn đại diện cho danh tính UID
  String calculateUidHash(String uid) {
    final effectiveUid = uid.trim().isEmpty ? BackupEncryptionConfig.guestFallbackSeed : uid.trim();
    return sha256.convert(utf8.encode('MOONA_UID:$effectiveUid:${BackupEncryptionConfig.appSalt}')).toString();
  }

  /// Tính mã băm Checksum SHA-256 của nội dung JSON gốc
  String calculateChecksum(String plainJson) {
    return sha256.convert(utf8.encode(plainJson)).toString();
  }

  /// Đối soát mã băm Checksum
  bool verifyChecksum(String plainJson, String expectedChecksum) {
    final actual = calculateChecksum(plainJson);
    return actual.toLowerCase() == expectedChecksum.trim().toLowerCase();
  }

  /// Sinh ngẫu nhiên Vector Khởi Tạo (IV) 16 bytes
  enc.IV generateRandomIv() {
    return enc.IV.fromSecureRandom(BackupEncryptionConfig.ivLengthBytes);
  }

  /// Mã hóa chuỗi JSON payload: GZIP -> AES-256-CBC -> Base64 Ciphertext
  String encryptPayload(String plainJson, Uint8List keyBytes, enc.IV iv) {
    try {
      if (keyBytes.length != BackupEncryptionConfig.keyLengthBytes) {
        throw ArgumentError('Khóa AES-256 phải có độ dài đúng 32 bytes.');
      }

      // 1. Nén dữ liệu thô bằng GZIP để tối ưu dung lượng và chống vượt giới hạn Firestore 1MB
      final plainBytes = utf8.encode(plainJson);
      final compressedBytes = gzip.encode(plainBytes);

      // 2. Mã hóa bằng AES-256-CBC
      final key = enc.Key(keyBytes);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encryptBytes(compressedBytes, iv: iv);

      return encrypted.base64;
    } catch (e) {
      if (e is BackupEncryptionException) rethrow;
      throw BackupCorruptedException('Lỗi trong quá trình mã hóa dữ liệu: $e');
    }
  }

  /// Giải mã Base64 Ciphertext: Base64 -> AES-256-CBC -> Decompress GZIP -> Plain JSON
  String decryptPayload(String ciphertextBase64, Uint8List keyBytes, String ivBase64) {
    try {
      if (keyBytes.length != BackupEncryptionConfig.keyLengthBytes) {
        throw ArgumentError('Khóa AES-256 phải có độ dài đúng 32 bytes.');
      }

      final key = enc.Key(keyBytes);
      final iv = enc.IV.fromBase64(ivBase64);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));

      // 1. Giải mã AES-256
      final decryptedBytes = encrypter.decryptBytes(
        enc.Encrypted.fromBase64(ciphertextBase64.trim()),
        iv: iv,
      );

      // 2. Giải nén GZIP nếu có header gzip (0x1f, 0x8b), ngược lại giải mã trực tiếp UTF-8
      if (decryptedBytes.length >= 2 && decryptedBytes[0] == 0x1F && decryptedBytes[1] == 0x8B) {
        final decompressed = gzip.decode(decryptedBytes);
        return utf8.decode(decompressed);
      } else {
        return utf8.decode(decryptedBytes);
      }
    } on ArgumentError catch (e) {
      throw BackupInvalidKeyException('Sai khóa giải mã hoặc dữ liệu mã hóa bị hỏng: $e');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('pad') || msg.contains('mac') || msg.contains('cipher') || msg.contains('key') || msg.contains('bad decrypt')) {
        throw const BackupInvalidKeyException();
      }
      throw BackupCorruptedException('Không thể giải mã bản sao lưu: $e');
    }
  }
}
