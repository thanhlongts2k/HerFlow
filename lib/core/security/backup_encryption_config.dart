// lib/core/security/backup_encryption_config.dart

/// Cấu hình bảo mật tập trung cho phân hệ Sao lưu & Khôi phục dữ liệu (Backup & Restore).
///
/// Tuân thủ Điều 8 trong `AGENTS.md` (Secrets & Privacy Hygiene):
/// - Cô lập toàn bộ tham số thuật toán mật mã khỏi logic nghiệp vụ.
/// - Không hardcode khóa runtime nhạy cảm, sử dụng cơ chế dẫn xuất khóa (KDF).
class BackupEncryptionConfig {
  BackupEncryptionConfig._();

  /// Tiền tố Magic Header nhận diện định dạng tệp sao lưu độc quyền của Moona.
  static const String magicHeader = 'MOONA_BACKUP';

  /// Phiên bản cấu trúc container sao lưu hiện tại.
  static const int currentFormatVersion = 1;

  /// Độ dài khóa AES-256 tính theo byte (32 bytes = 256 bits).
  static const int keyLengthBytes = 32;

  /// Độ dài Vector Khởi Tạo (IV) tính theo byte (16 bytes = 128 bits cho AES block size).
  static const int ivLengthBytes = 16;

  /// Số vòng lặp băm PBKDF2/KDF chuẩn để chống tấn công brute-force.
  static const int kdfIterations = 10000;

  /// Chuỗi Salt phân tán ứng dụng (Application Salt) dùng cho quá trình dẫn xuất khóa.
  static const String appSalt = 'Moona_FemTech_Vault_Salt_v1_2026';

  /// Khóa giả định cho phiên khách chưa đăng nhập (Guest Mode Fallback).
  static const String guestFallbackSeed = 'Moona_Guest_Local_Vault_Seed_2026';

  /// Đuôi tệp chuẩn của Moona.
  static const String backupFileExtension = 'moona';
}
