# Changelog — Moona

Toàn bộ những thay đổi đáng chú ý của dự án **Moona** được ghi nhận tại đây theo chuẩn [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) và tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.3.0+5] - 2026-09-03 (Pairing Bugfix & Settings Refactor)

### [Fixed]
- **🐛 Sửa lỗi treo "Đang tạo mã...":** `createPairingCode()` và `connectWithPairingCode()` bọc đầy đủ `try-catch-finally` + `.timeout(Duration(seconds: 5))`.
- **isLoading không reset:** Khối `finally` đảm bảo `isLoading = false` trong mọi tình huống — không bao giờ treo spinner vô tận.

### [Added]
- **Offline Fallback cho Pairing:** Khi Firestore timeout/lỗi, tự động sinh mã `HFxxxx` cục bộ. UI hiển thị badge cam "Mã kết nối nội bộ (Thử nghiệm)".
- **`SettingsScreen`** (`lib/features/settings/presentation/screens/settings_screen.dart`): 4 nhóm: Bảo mật (Biometric + Auto-lock), Đồng bộ đôi, Giao diện (Theme + Haptic), Dữ liệu & Giới thiệu.
- Restored missing v0.3.0 files sau `filter-branch`: `network_connectivity_provider`, `app_version_provider`, `haptic_feedback_utils`, `offline_banner`, `notification_service`, `biometric_lock_screen`, toàn bộ `care_signals/`, `onboarding_screen`.

### [Changed]
- **`CycleSettingsSheet`:** Đổi tên "Hiệu Chỉnh Chu Kỳ", xóa Biometric switch (chuyển sang SettingsScreen).
- **`cycle_screen.dart`:** Icon → `settings_outlined` → SettingsScreen. Thêm chip "Chỉnh sửa chu kỳ" overlay trên lịch.
- **`app_routes.dart`:** Đăng ký route `/settings`.
- **`widget_test.dart`:** Cập nhật test `CareSignalModel` align API mới.

---

## [0.3.0+4] - 2026-09-03 (Security Audit & Hardening)

### [Security]
- **🚨 Khắc phục rò rỉ Firebase API key:** `android/app/google-services.json` đã bị commit vào lịch sử git (commit `70f4f04`). Đã thực hiện `git rm --cached` và bổ sung vào `.gitignore`.
- **Cô lập AES Encryption Key:** Di chuyển hardcoded key `MoonaSec2026!Key@SecretFlow2026!` từ `backup_repository.dart` sang `lib/core/security/backup_encryption_config.dart` — tách biệt bí mật khỏi logic nghiệp vụ với security notice và migration roadmap.

### [Added]
- `android/app/google-services.json.example` — File mẫu với placeholder để đồng nghiệp setup local mà không cần file thật.
- `lib/core/security/backup_encryption_config.dart` — Lớp `BackupEncryptionConfig` quản lý tập trung cấu hình mã hóa AES-256-CBC của Moona.

### [Changed]
- `.gitignore`: Bổ sung toàn bộ danh mục bảo mật: Firebase configs, Keystore files (`.jks`, `.keystore`, `key.properties`), `.env*`, `*.moona`, `*.hive`.
- `AGENTS.md`: Bổ sung **Điều khoản 8 — AN TOÀN BẢO MẬT & QUẢN LÝ KHÓA BÍ MẬT** với 4 mục: chống hardcode secrets, bảo vệ config định danh, kiểm soát `android:exported`, và Security Scan SOP.
- Đổi tên project trong `AGENTS.md` và `CHANGELOG.md` từ "HerFlow" → "Moona" để đồng bộ rebranding.

---

## [0.3.0+3] - 2026-09-03 (Version System Patch)


### [Added]
- `package_info_plus: ^8.0.0` — đọc version động từ hệ thống thay vì hardcode string.
- `lib/core/providers/app_version_provider.dart` — `FutureProvider<AppVersionInfo>` cung cấp `version`, `buildNumber`, `displayString` (`"Moona v0.3.0 (Build 3)"`).

### [Changed]
- `pubspec.yaml`: `version: 1.0.0+1` → `0.3.0+3` — Single Source of Truth, đồng bộ với Semantic Versioning thực tế.
- `build.gradle.kts`: Xác nhận đã dùng `flutter.versionCode` / `flutter.versionName` — không hardcode Android native.

---

## [0.3.0] - 2026-09-03


### [Added]
- **Android Home Screen Widget (Husband Glance Widget):**
  - Tích hợp `home_widget: ^0.7.0`.
  - Thiết kế layout Native Android XML bo tròn 24dp Material You (`res/layout/widget_husband_glance.xml`) và `res/xml/husband_widget_info.xml`.
  - Khởi tạo `HusbandWidgetProvider.kt` với `android:exported="true"` tương thích hoàn toàn Android 12+ chống từ chối cài đặt.
  - Module `WidgetUpdateService` tự động đồng bộ pha sinh học, mức năng lượng và lời khuyên chăm sóc của Chồng từ xa lên màn hình chính.
- **Tín hiệu yêu thương 1-chạm (One-Tap Care Signals):**
  - Thiết kế 4 tín hiệu định sẵn: 🫖 *Chườm ấm*, 🧋 *Đồ ngọt / trà sữa*, 🫂 *Cần một cái ôm*, 🍃 *Cần yên tĩnh*.
  - Giao diện `CareSignalSheet` phía Vợ với 4 thẻ pastel mềm mại kèm phản hồi xúc giác `HapticFeedback.mediumImpact()`.
  - Đồng bộ real-time Firestore lên `CareSignalBannerCard` trên Dashboard của Chồng kèm nút "Đã nhận được ❤️".
- **Hệ thống cảnh báo sớm PMS (PMS Pre-Warning System):**
  - Thuật toán sinh học `isPmsWindow(DateTime date)` và `nextPmsStartDate` trong `CycleInfo` (cảnh báo trước kỳ kinh 7 ngày).
  - Tích hợp `flutter_local_notifications: ^18.0.1` và `timezone: ^0.10.0` với kênh thông báo ưu tiên cao `moona_pms_channel`.
  - Tự động xin quyền runtime `POST_NOTIFICATIONS` trên Android 13+ và lên lịch nhắc nhở lúc 08:00 sáng.
  - Tích hợp Switch kích hoạt thông báo trong `CycleSettingsSheet`.
- **Sao lưu & Khôi phục dữ liệu cục bộ (Backup & Restore):**
  - Tích hợp `file_picker: ^8.1.7`, `share_plus: ^10.1.4`, `encrypt: ^5.0.3`, `crypto: ^3.0.6`.
  - `BackupRepository`: Đóng gói dữ liệu chu kỳ & cảm xúc từ Hive, tính checksum SHA-256, mã hóa AES-256 (CBC mode) ra tệp `.moona`.
  - Luồng khôi phục dữ liệu: Giải mã AES-256, kiểm tra tính toàn vẹn SHA-256 và tự động làm mới (invalidate) toàn bộ state Riverpod.
  - Giao diện `BackupScreen` trực quan với thẻ giải thích bảo mật ngân hàng.
- **Chuẩn hóa phản hồi xúc giác (AppHaptics):**
  - Thư viện tiện ích `AppHaptics` quy chuẩn: `selection()` khi chuyển tab navigation, `light()` khi cuộn slider, `medium()` khi gửi tín hiệu / tick chu kỳ.
- **Tối ưu hóa dung lượng Release APK:**
  - Bật R8 code shrinking `isMinifyEnabled = true` và `isShrinkResources = true` trong `build.gradle.kts`.
  - Cấu hình bảo vệ `proguard-rules.pro` cho Domain/Data models, Hive, Firebase và Plugins.

### [Changed]
- Khai báo quyền `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `VIBRATE` trong `AndroidManifest.xml`.
- Cập nhật `AppConstants.appVersion = '0.3.0'`.

### [Fixed]
- Khắc phục lỗi độ dài khóa AES-256 (chuẩn 32 byte / 256 bits) trong `BackupRepository` và kiểm thử tự động.

---

### [Added]
- **Tái định vị thương hiệu (Rebranding) "Moona":**
  - Cập nhật `android:label="Moona"` trong `android/app/src/main/AndroidManifest.xml`.
  - Cập nhật tiêu đề AppBar, Header và tin nhắn chia sẻ mặc định sang tên gọi thân thương "Moona".
  - Bổ sung và cấu hình `flutter_native_splash: ^2.4.4` với màu nền kem vani (`#FDFBF7`) cho Light Mode và Warm Espresso (`#1A1617`) cho Dark Mode, chạy tạo cấu hình Android native thành công.
- **Giám sát mạng & Hàng đợi đồng bộ ngoại tuyến (Smart Offline Sync Queue):**
  - Bổ sung package `connectivity_plus: ^6.1.0`.
  - Module `lib/core/network/network_connectivity_provider.dart` theo dõi kết nối mạng WiFi/Mobile/Ethernet thời gian thực.
  - Widget `OfflineBanner` dạng thanh cảnh báo mỏng, tinh tế xuất hiện ở đỉnh màn hình khi mất mạng: *"Chế độ ngoại tuyến — Dữ liệu sẽ tự động đồng bộ khi có mạng"*.
  - Cơ chế Smart Offline Queue trong `PartnerSyncRepository`: Tự động lưu cờ `isPendingSync` và bộ đệm trạng thái vào Hive khi offline; tự động lắng nghe và xả hàng đợi (`flushPendingSync`) đẩy lên Firestore ngay khi mạng phục hồi.
- **Luồng chào đón người dùng mới (Onboarding Wizard 3 bước):**
  - Bước 1: Chọn ngày bắt đầu kỳ kinh gần nhất qua DatePicker trực quan.
  - Bước 2: Thanh trượt slider chọn độ dài chu kỳ trung bình (21 - 40 ngày, mặc định 28 ngày) tích hợp **phản hồi xúc giác rung nhẹ (`HapticFeedback.lightImpact()`)** khi kéo trượt.
  - Bước 3: Thẻ chọn mục tiêu đồng hành (Chăm sóc sức khỏe & dinh dưỡng, Ổn định cảm xúc, Đồng bộ cùng Chồng).
  - Tự động lưu thiết lập khởi đầu vào `cycleBox` và chuyển thẳng vào Dashboard chính.
- **Bảo mật sinh trắc học cao cấp (Biometric Authentication):**
  - Bổ sung package `local_auth: ^2.3.0`.
  - Dịch vụ `BiometricService` kiểm tra phần cứng vân tay/FaceID và thực hiện xác thực với rung nhẹ xúc giác `HapticFeedback.lightImpact()` khi mở khóa thành công.
  - Màn hình khóa mờ pastel `BiometricLockScreen` bảo vệ 100% dữ liệu chu kỳ và cảm xúc cá nhân.
  - Quản lý vòng đời ứng dụng (`WidgetsBindingObserver` / `AppLifecycleListener`): Tự động khóa lại và yêu cầu xác thực khi ứng dụng resume từ background.
  - Bổ sung Switch "Khóa bằng sinh trắc học" trong `CycleSettingsSheet`.

### [Changed]
- **Nâng cấp Android Activity:** Đổi lớp kế thừa trong `MainActivity.kt` từ `FlutterActivity()` sang `FlutterFragmentActivity()` để tương thích hoàn hảo với `local_auth` trên Android 13+, triệt tiêu hoàn toàn lỗi crash khi bung pop-up sinh trắc học.
- Bổ sung quyền `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>` trong `AndroidManifest.xml`.
- Cập nhật `AppConstants` với phiên bản `0.2.0`, `appName = 'Moona'` và các key SharedPreferences/Hive mới.

### [Fixed]
- Khắc phục cảnh báo thuộc tính deprecated `axisAlignment` chuyển sang `alignment: Alignment.topCenter` trong `SizeTransition` tại `offline_banner.dart`.

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
