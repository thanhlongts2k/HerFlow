# Changelog — HerFlow

Toàn bộ những thay đổi đáng chú ý của dự án **HerFlow** được ghi nhận tại đây theo chuẩn [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) và tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] - 2026-09-03

### [Added]
- **Kiến trúc nền tảng (Architecture & Foundation):**
  - Khởi tạo cấu trúc **Feature-First Clean Architecture** chuẩn hóa cho toàn dự án với 3 tầng độc lập: `domain/`, `data/`, `presentation/`.
  - Thiết lập quản lý trạng thái bằng **Riverpod 2.x** (`flutter_riverpod: ^2.6.1`).
  - Thiết lập cơ sở dữ liệu cục bộ ngoại tuyến bằng **Hive** (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`) gồm 3 box chính: `cycleBox`, `moodBox`, `settingsBox`.
  - Hệ thống Design System màu Soft Pastel cao cấp trong `lib/core/constants/app_colors.dart` (Hồng ấm, kem vani, tím thạch anh lavender, xanh ngọc mint, cam đào).
  - Cấu hình Theme Light và Dark mode nữ tính, sang trọng với phông chữ Google Fonts Quicksand trong `lib/core/theme/app_theme.dart`.

- **Phân hệ Chu Kỳ Sinh Học (Cycle Core Engine):**
  - Thuật toán phân loại sinh học chính xác **4 Pha Chu Kỳ** trong `CycleInfo`:
    * 🩸 *Pha Hành Kinh (Menstrual):* Ngày 1..5, tính ngày bắt đầu và dự đoán kỳ tới.
    * 🌿 *Pha Nang Trứng (Follicular):* Ngày 6..12, giai đoạn phục hồi và tái tạo năng lượng.
    * ☀️ *Pha Rụng Trứng (Ovulation):* Ngày rụng trứng đỉnh điểm `(cycleLength - 14)` và cửa sổ thụ thai 6 ngày.
    * 🌙 *Pha Hoàng Thể (Luteal):* Ngày 16..28, giai đoạn tiền kinh nguyệt (PMS).
  - Lịch tương tác `TableCalendar` tùy biến (`CycleCalendarView`) tự động tô màu nền pastel của từng ô ngày theo đúng pha sinh học, đánh dấu icon giọt nước cho ngày hành kinh và ngôi sao cho ngày rụng trứng.
  - Thẻ thông tin sinh học chi tiết `CycleDayDetailCard` hiển thị động trạng thái hormone, bài tập thể thao gợi ý, xác suất thụ thai và nút 1-chạm Toggle ngày hành kinh.
  - Modal ghi nhận kỳ kinh chi tiết `LogPeriodModal` (lượng kinh Ít/Vừa/Nhiều, đang diễn ra).
  - Modal cấu hình chu kỳ sinh học `CycleSettingsSheet` (tùy chỉnh độ dài chu kỳ 21-45 ngày, thời gian hành kinh 2-10 ngày).

- **Phân hệ Nhật Ký Thể Trạng (Mood & Micro-logging):**
  - Màn hình ghi nhận 1-chạm `MoodScreen` với 5 mức năng lượng (😫 Kiệt sức $\rightarrow$ ⚡ Bùng nổ).
  - Bảng chọn FilterChips tâm trạng chủ đạo (Vui vẻ, Nhạy cảm, Cáu gắt, Lo âu, Thư thái...) và triệu chứng thể chất (Đau bụng kinh, Đau lưng, Căng ngực, Thèm ngọt, Đầy hơi, Mụn...).
  - Biểu đồ đường cong uốn lượn mềm mại thể hiện xu hướng năng lượng 7 ngày gần nhất bằng `fl_chart`.

- **Phân hệ Dinh Dưỡng Đồng Bộ (Cycle-Synced Food):**
  - Cơ sở dữ liệu dinh dưỡng 4 pha trong `NutritionLocalDataSource`:
    * Danh mục thực phẩm vàng nên ăn (Superfoods).
    * Danh mục món ăn & thức uống cần hạn chế.
    * Trà thảo mộc & đồ uống xoa dịu (Trà gừng mật ong, matcha, trà hoa cúc, lavender).
    * Gợi ý bữa ăn mẫu hoàn chỉnh kèm vi chất then chốt (Sắt, Magie, Omega-3, Kẽm).
  - Màn hình `NutritionScreen` tự động cập nhật gợi ý ăn uống đồng bộ theo pha của ngày đang chọn.

- **Phân hệ Góc Nhìn Của Anh (Husband View Offline):**
  - Tóm tắt trạng thái hôm nay của vợ dưới góc nhìn hành động cho chồng.
  - Danh sách 3 hành động ấm áp nên chủ động làm ngay và những điều tuyệt đối nên tránh.
  - Nút 1-chạm sao chép tóm tắt trạng thái định dạng sẵn vào clipboard để gửi nhanh qua Zalo/SMS.

- **Phân hệ Đồng Bộ Cặp Đôi Realtime (Partner Sync via Cloud Firestore):**
  - Cơ chế sinh và ghép đôi qua mã PIN 6 ký tự (`PairingCode`, e.g. `HF8201`) có hiệu lực trong 24 giờ.
  - Phía Vợ: Màn hình tạo mã ghép đôi, tự động mở Stream lắng nghe phản hồi của Chồng theo thời gian thực.
  - Phía Chồng: Màn hình nhập mã ghép đôi 6 ký tự xác thực Firestore.
  - Dashboard Chồng thời gian thực (`HusbandDashboardScreen`): Sử dụng `StreamProvider` (Riverpod) lắng nghe trực tiếp document `couples/{coupleId}/status/today`.
  - Hiển thị trực tiếp: Pha chu kỳ của vợ, thanh tiến trình năng lượng 1-5, chip triệu chứng và lời khuyên hành động tức thì.
  - Phân tầng bảo mật (Data Boundary): Dữ liệu nhạy cảm chỉ lưu ngoại tuyến tại Hive; Firestore chỉ lưu bản tóm tắt phục vụ ghép đôi.
  - Tệp quy tắc bảo mật Firestore `firestore.rules`.

- **Cấu hình Android & Build:**
  - Bổ sung các dependency: `firebase_core: ^4.14.0`, `cloud_firestore: ^6.9.0`.
  - Cấu hình `google-services` plugin trong `settings.gradle.kts` và `app/build.gradle.kts`.
  - Thiết lập `minSdk = 21`, `multiDexEnabled = true`, `JavaVersion.VERSION_17`.
  - Tệp `google-services.json` mẫu an toàn đảm bảo build APK thành công.

### [Changed]
- Toàn bộ các đường dẫn import nội bộ chuyển đổi sang `package:herflow/...` nhằm đảm bảo tính toàn vẹn và ngăn ngừa lỗi phân giải URI tương đối trong Dart.
- Bổ sung cấu hình `kotlin.incremental=false` và `kotlin.incremental.useClasspathSnapshot=false` trong `android/gradle.properties` để giải quyết triệt để lỗi cross-drive cache (C: vs D:) của Kotlin trên hệ điều hành Windows.

### [Fixed]
- Sửa lỗi cú pháp thiếu tham số `required Widget child` trong phương thức `_buildNutritionSection` tại `lib/features/nutrition/presentation/screens/nutrition_screen.dart`.
- Thay thế thuộc tính đã lỗi thời `activeColor` bằng `activeThumbColor` trong `SwitchListTile` tại `lib/features/cycle/presentation/widgets/log_period_modal.dart`.

### [Known Issues]
- Tệp `android/app/google-services.json` hiện đang sử dụng thông tin mẫu để phục vụ việc build APK offline. Cần thay thế bằng tệp cấu hình thực từ Firebase Console cá nhân khi triển khai hệ thống online thực tế.
- Trên môi trường thử nghiệm pure headless unit test, Firebase Firestore cần được mock hoặc bọc try/catch để tránh lỗi MissingPluginException.
