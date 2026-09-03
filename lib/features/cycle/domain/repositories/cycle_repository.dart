// lib/features/cycle/domain/repositories/cycle_repository.dart
import '../entities/cycle_info.dart';
import '../entities/period_record.dart';

/// Hợp đồng Repository quản lý toàn diện dữ liệu chu kỳ kinh nguyệt
abstract class CycleRepository {
  /// Lấy toàn bộ thông tin chu kỳ hiện tại kèm các bản ghi
  Future<CycleInfo> getCycleInfo();

  /// Cập nhật ngày bắt đầu kỳ kinh gần nhất
  Future<void> updateLastPeriodStart(DateTime date);

  /// Cập nhật độ dài chu kỳ trung bình
  Future<void> updateCycleLength(int days);

  /// Cập nhật thời lượng hành kinh trung bình
  Future<void> updatePeriodDuration(int days);

  /// Lưu hoặc cập nhật một bản ghi kỳ kinh nguyệt
  Future<void> savePeriodRecord(PeriodRecord record);

  /// Xóa một bản ghi kỳ kinh nguyệt
  Future<void> deletePeriodRecord(String id);

  /// Lấy toàn bộ danh sách các kỳ kinh nguyệt trong lịch sử
  Future<List<PeriodRecord>> getAllPeriodRecords();

  /// 1-Chạm: Đánh dấu hoặc hủy đánh dấu một ngày là ngày hành kinh
  Future<void> togglePeriodDay(DateTime date);
}
