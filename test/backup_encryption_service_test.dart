import 'package:flutter_test/flutter_test.dart';
import 'package:herflow/core/security/backup_encryption_config.dart';
import 'package:herflow/core/security/backup_encryption_service.dart';

void main() {
  group('BackupEncryptionService Unit Tests', () {
    const service = BackupEncryptionService();
    const testUid = 'test_user_lan_anh_2026';

    test('deriveKey returns 32 bytes (256-bit) and is deterministic', () {
      final key1 = service.deriveKey(testUid);
      final key2 = service.deriveKey(testUid);

      expect(key1.length, BackupEncryptionConfig.keyLengthBytes);
      expect(key2.length, BackupEncryptionConfig.keyLengthBytes);
      expect(key1, equals(key2));
    });

    test('deriveKey produces distinct keys for different UIDs', () {
      final keyA = service.deriveKey('user_a');
      final keyB = service.deriveKey('user_b');

      expect(keyA, isNot(equals(keyB)));
    });

    test('deriveKey falls back safely when UID is empty', () {
      final keyEmpty = service.deriveKey('');
      final keyWhitespace = service.deriveKey('   ');

      expect(keyEmpty.length, 32);
      expect(keyEmpty, equals(keyWhitespace));
    });

    test('calculateUidHash produces unique non-empty hash', () {
      final hashA = service.calculateUidHash(testUid);
      final hashB = service.calculateUidHash('different_uid');

      expect(hashA.isNotEmpty, isTrue);
      expect(hashA, isNot(equals(hashB)));
    });

    test('Checksum SHA-256 accurately detects identical and modified data', () {
      const original = '{"cycleLength": 28, "notes": "Cảm giác vui vẻ 🌸"}';
      const modified = '{"cycleLength": 29, "notes": "Cảm giác vui vẻ 🌸"}';

      final checksumOriginal = service.calculateChecksum(original);

      expect(service.verifyChecksum(original, checksumOriginal), isTrue);
      expect(service.verifyChecksum(modified, checksumOriginal), isFalse);
    });

    test('GZIP + AES-256-CBC encryption and decryption roundtrip preserves Vietnamese and Emoji', () {
      const samplePayload = '{"phase": "menstrual", "note": "Hôm nay em hơi mệt, thèm trà sữa trân châu đường đen 🧋 và cần chàng massage lưng 💆‍♀️"}';

      final key = service.deriveKey(testUid);
      final iv = service.generateRandomIv();

      final ciphertext = service.encryptPayload(samplePayload, key, iv);
      expect(ciphertext.isNotEmpty, isTrue);

      final decrypted = service.decryptPayload(ciphertext, key, iv.base64);
      expect(decrypted, equals(samplePayload));
    });

    test('decryptPayload throws BackupCorruptedException when ciphertext is corrupted', () {
      const samplePayload = '{"data": "valid_content"}';
      final key = service.deriveKey(testUid);
      final iv = service.generateRandomIv();

      final ciphertext = service.encryptPayload(samplePayload, key, iv);
      // Giả lập làm hỏng ciphertext
      final tamperedCiphertext = 'BAD${ciphertext.substring(3)}';

      expect(
        () => service.decryptPayload(tamperedCiphertext, key, iv.base64),
        throwsA(isA<BackupEncryptionException>()),
      );
    });

    test('decryptPayload throws BackupInvalidKeyException when wrong key is provided', () {
      const samplePayload = '{"sensitive": "medical_history"}';
      final rightKey = service.deriveKey(testUid);
      final wrongKey = service.deriveKey('malicious_attacker_uid');
      final iv = service.generateRandomIv();

      final ciphertext = service.encryptPayload(samplePayload, rightKey, iv);

      expect(
        () => service.decryptPayload(ciphertext, wrongKey, iv.base64),
        throwsA(isA<BackupEncryptionException>()),
      );
    });
  });
}
