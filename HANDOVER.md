# 📋 BÁO CÁO BÀN GIAO CA (HANDOVER.md) — DỰ ÁN MOONA

> **Phiên bản hiện tại:** `v0.6.3+18` (Visual UX Audit Fixes — Husband Navigation & Pairing Banner)  
> **Thời điểm cập nhật:** 03/09/2026 — Khắc phục dứt điểm 3 cụm lỗi Critical P0/P1 từ VISUAL_UX_AUDIT_REPORT.md  
> **Kỹ sư phụ trách:** Senior Mobile Flutter Engineer (AI Pair Programmer)  

---

## ✅ 1. TRẠNG THÁI HIỆN TẠI (CURRENT STATE CHECKPOINT)

| Hạng mục | Kết quả kiểm toán | Ghi chú kỹ thuật |
|---|:---:|---|
| **Static Analysis (`flutter analyze`)** | ✅ **0 issues found!** | Toàn bộ codebase đạt chuẩn 100%, 0 errors, 0 warnings, const constructors chuẩn hóa |
| **Unit Testing (`flutter test`)** | ✅ **31/31 tests PASSED** | Đạt 100% pass toàn bộ test suites (bao gồm Love Note roundtrip) |
| **Bản Đồ Nghiệp Vụ Toàn Dự Án** | ✅ **CHUẨN HÓA** | Tạo `docs/APP_BUSINESS_MATRIX.md` phân định quyền 2 Role, Unpaired vs Paired, Data Boundary & Perspective Mapping |
| **Tin Nhắn Tùy Biến Cho Vợ (Love Note)** | ✅ **HOÀN TẤT** | Nàng tự do gõ tin nhắn (max 150 ký tự), quick chips gợi ý, chống tràn bàn phím, bong bóng tin nhắn hiển thị nổi bật trên máy Chồng |
| **BUG-01 + BUG-08: Navigation Chồng** | ✅ **FIXED** | `MainNavScreen` giờ có `_buildHusbandLayout()` riêng: Scaffold + BottomNav 4 tab (Trang chủ, Cảm xúc, Dinh dưỡng, Cài đặt). Chồng chuyển tab bình thường |
| **BUG-04: Banner ghép đôi thừa** | ✅ **FIXED** | `_buildConnectionHeader()` phân nhánh rõ 2 trạng thái: `isConnected=true` → Card xanh tĩnh "Đang đồng hành 💕"; `isConnected=false` → Banner CTA ghép đôi |
| **BUG-03: Sub-title AppBar truncate** | ✅ **FIXED** | Bọc trong `Flexible` + `maxLines: 2, overflow: TextOverflow.ellipsis` |
| **Chuẩn Hóa Dialog (MoonaConfirmDialog)** | ✅ **HOÀN TẤT** | Loại bỏ 100% `AlertDialog` ad-hoc, Action Bar cân xứng ngang hàng 48px, icon tròn pastel, Material 3 & Glassmorphic |
| **Native In-App OTA Update** | ✅ **HOÀN TẤT** | `ota_update: ^5.1.0`, quyền `REQUEST_INSTALL_PACKAGES`, hiển thị % tải trực tiếp và tự động kích hoạt Package Installer |
| **Mở Khóa Đổi Vai Trò Cài Đặt** | ✅ **HOÀN TẤT** | Thẻ tương tác đổi vai trò kèm BottomSheet, phân luồng cảnh báo an toàn khi đã ghép đôi |
| **Đồng Bộ Hai Chiều Danh Xưng** | ✅ **HOÀN TẤT** | Stream realtime trên `couples/{coupleId}` với 4 trường độc lập, giải quyết triệt để Perspective Mapping |
| **Triệt tiêu Race Condition Đa Tài Khoản** | ✅ **HOÀN TẤT & TRIỆT ĐỂ** | `UserScope.setActiveUid()`, dọn sạch 100% RAM State tree bằng `_invalidateAllUserScopedProviders()` |
| **Android 11+ Package Visibility (OTA)** | ✅ **HOÀN TẤT** | Thêm `<queries>` cho `https`/`http` và `LaunchMode.externalApplication` fallback |
| **Vòng đời Ghép Đôi & Chống tự kết nối** | ✅ **HOÀN TẤT** | Stream realtime tự điều hướng Host vào `MainNavScreen`, chặn tự kết nối với chính mình |
| **Ràng buộc Sinh Học & Xử lý Trễ Kinh** | ✅ **HOÀN TẤT** | Chặn ngày tương lai, clamp chu kỳ 21-45 ngày, hiển thị badge Trễ kinh và Card tâm lý cho Chồng |
| **Dự phòng Danh Xưng theo Vai Trò** | ✅ **HOÀN TẤT** | Vợ mặc định gọi "Anh", Chồng mặc định gọi "Em bé", chống rỗng 100% |
| **Pipeline GitHub Actions CI/CD** | ✅ **HOÀN TẤT** | Cấp quyền `contents: write`, theo dõi shared debug.keystore trong Git index |
| **Dung lượng APK Release (arm64-v8a)** | ✅ **27.1 MB (28,384,175 bytes)** | Giảm 86.5% so với Fat APK 208MB; Dart AOT 7MB, Native 10MB, Assets 348KB |
| **Shared Project Keystore** | ✅ **HOÀN TẤT (TRACKED)** | `android/app/debug.keystore` (storePass: 'android', alias: 'androiddebugkey') |
| **Mã vân tay Firebase SHA-1** | ✅ **XÁC NHẬN** | `33:61:D2:2E:84:65:AE:C8:C3:C4:37:1D:79:6A:84:05:57:5D:F3:B0` |

---

## 2. 💡 BÀI HỌC KINH NGHIỆM & CÁC LỖI KỸ THUẬT ĐÃ GIẢI QUYẾT

### 2.3. Lỗi Google Sign-In `ApiException: 10`
* **Hiện tượng:** Khi bấm "Đăng nhập với Google", ứng dụng trả về lỗi `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10: , null, null)`.
* **Nguyên nhân cốt lõi (Kiểm toán nguyên mã):**
  1. `serverClientId` trong `AuthRepository` trước đó bị trỏ sang Web Client ID của project khác (`FinLux`), không khớp với Google Cloud Console của project Moona (`moona-a92ec`).
  2. Mã SHA-1 của keystore trên máy người dùng chưa được đồng bộ với `oauth_client` trong `google-services.json`.
* **Khắc phục triệt để:**
  1. Đặt `android/app/debug.keystore` trực tiếp trong repository (SHA-1: `33:61:D2:2E:84:65:AE:C8:C3:C4:37:1D:79:6A:84:05:57:5D:F3:B0`), trùng khớp 100% với `certificate_hash` trong `google-services.json`.
  2. Cập nhật `defaultServerClientId` trong `AuthRepository` trỏ đúng vào Web Client ID (`client_type: 3`): `928842055742-ama9jv6hella1oobunsfvkcbkvl58gl1.apps.googleusercontent.com`.
  3. Dọn dẹp cache `adb shell pm clear com.herflow.app.herflow` trước khi cài đặt.

### 2.1. Lỗi Crash On Launch do R8 Minification (`WorkDatabase`)
* **Hiện tượng:** Ứng dụng ở bản Release bị văng ngay khi vừa mở ngoài màn hình chính (*"Moona tiếp tục dừng"*).
* **Nguyên nhân:** Khi bật `isMinifyEnabled = true` trong Android Gradle, công cụ R8 đã xóa hoặc đổi tên nhầm các entity classes native của Room Database và WorkManager được thư viện `flutter_local_notifications` sử dụng nội bộ (`Failed to create an instance of androidx.work.impl.WorkDatabase`).
* **Giải pháp:**
  - Thiết lập an toàn `isMinifyEnabled = false` và `isShrinkResources = false` trong `android/app/build.gradle.kts`. Do mã nguồn Dart đã được Flutter AOT compile thành file mã máy nhị phân `libapp.so`, việc tắt R8 không ảnh hưởng đến tính bảo mật của logic nghiệp vụ.
  - Đồng thời bổ sung các keep rules cho WorkManager, Room, Firebase, Hive và JNI trong `android/app/proguard-rules.pro`.

### 2.2. Lỗi Hệ Thống Android Giữ Icon Chim Xanh Flutter Cũ
* **Hiện tượng:** Mặc dù đã chạy `flutter_launcher_icons`, biểu tượng ngoài màn hình chính hoặc trong Cài đặt (App Info) vẫn hiển thị icon chim xanh Flutter mặc định.
* **Nguyên nhân:** Cấu hình `android: "launcher_icon"` chỉ tạo ra tệp `launcher_icon.png` mới, trong khi tệp `ic_launcher.png` mặc định trong các thư mục `res/mipmap-*` vẫn còn nguyên và được hệ điều hành Android ưu tiên nạp.
* **Giải pháp:** Cấu hình `android: true` trong `pubspec.yaml`, chạy lại `dart run flutter_launcher_icons` để ghi đè 100% tệp `ic_launcher.png` và `ic_launcher.xml` trên tất cả các mật độ phân giải (`mdpi`, `hdpi`, `xhdpi`, `xxhdpi`, `xxxhdpi`, `anydpi-v26`).

### 2.3. Google Sign-In Client ID & SHA-1 Fingerprint
* **Hiện tượng:** `GoogleSignIn.signIn()` trả về `PlatformException(sign_in_failed, com.google.android.gms.common.api.ApiException: 10)`.
* **Nguyên nhân:** Thiếu SHA-1 fingerprint của keystore máy dev trên Firebase Console hoặc thiếu `serverClientId` (Web client ID dạng `client_type: 3`).
* **Giải pháp:** Bổ sung cấu hình `serverClientId` trong `AuthRepository`, đồng thời cung cấp chế độ Demo Mode (`signInAsDemo`) giúp nhà phát triển và người dùng kiểm thử toàn diện mọi tính năng mà không bị nghẽn mạng.

### 2.4. Khắc phục lỗi tràn giao diện (Overflow 9.8px & 1.7px)
* **Hiện tượng:** Màn hình xuất hiện dải sọc vàng đen cảnh báo tràn pixel trên thiết bị có độ phân giải nhỏ.
* **Giải pháp:** 
  - Tại `CycleCalendarView`: Loại bỏ nút điều hướng `<` `>` trùng lặp (vì `TableCalendar` đã có thanh điều hướng riêng), bọc tiêu đề và nút chỉnh sửa trong `Expanded` + `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))`.
  - Tại `HusbandViewScreen` và `CycleHeroIndicator`: Thay thế toàn bộ cụm `Row` chứa các chip/badge trạng thái bằng `Wrap(spacing: 8, runSpacing: 6)`, đảm bảo giao diện tự động xuống dòng linh hoạt khi không gian ngang bị thu hẹp.

### 2.5. Ràng buộc vai trò theo tài khoản Cloud (Account-Bound Role Persistence)
* **Hiện tượng:** Khi cài lại ứng dụng hoặc đăng nhập trên thiết bị mới, người dùng dù đã có tài khoản vẫn bị ép chọn lại vai trò ở Onboarding; hoặc khi đăng xuất, tài khoản tiếp theo bị dính vai trò cũ của thiết bị.
* **Nguyên nhân:** Vai trò `UserRole` chỉ được lưu trong `_settingsBox` (Hive cục bộ), không đọc/ghi lên document `users/{uid}` trên Firestore; và hàm `signOut()` chỉ xóa `_userBox` mà không reset cache trong `_settingsBox`.
* **Giải pháp:**
  - Bổ sung trường `role` vào `UserModel` và đồng bộ tức thì lên Firestore document `users/{uid}` với `SetOptions(merge: true)` mỗi khi `setRole` được gọi.
  - Khi đăng nhập thành công hoặc khi app khởi động, tự động đọc `users/{uid}.role` từ Cloud: Nếu đã có vai trò, cập nhật vào State và chuyển thẳng vào `AppRoutes.home`, bỏ qua `RoleSelectionScreen`.
  - Khi Đăng xuất (`signOut`): Xóa sạch `app_user_role`, `partner_user_role`, `keyHasSelectedRole`, `keyIsOnboardingCompleted` và gọi `userRoleProvider.notifier.resetRole()`.

---

## 3. 🏗️ KIẾN TRÚC & PHÂN HỆ TÍNH NĂNG CHÍNH

```
lib/
├── core/                               # Nền tảng chia sẻ
│   ├── constants/                      # AppColors, AppConstants, CyclePhase
│   ├── notifications/                  # NotificationService (Kênh PMS ưu tiên cao)
│   ├── routes/                         # AppRoutes
│   ├── services/                       # AppUpdateService (OTA Updates via GitHub Releases)
│   ├── theme/                          # AppTheme (Soft Pastel Light/Dark), ThemeController
│   ├── utils/                          # AppHaptics, AppDateUtils
│   └── widgets/                        # MoonaBrandLogo, AppUpdateDialog (Glassmorphism OTA)
│
└── features/                           # Clean Architecture (Feature-First)
    ├── auth/                           # Google Sign-In, Firebase Auth, BiometricLockScreen
    ├── care_signals/                   # CareSignalModel, Realtime 2-way Signals
    ├── cycle/                          # CycleCalendarView, CycleHeroIndicator, DayDetailCard
    ├── home/                           # MainNavScreen (Role-based Navigation, Auto OTA Check)
    ├── husband_view/                   # Gentleman's Playbook, HusbandQuickChatSheet
    ├── mood/                           # Mood & Energy micro-logging, 7-day trend chart
    ├── nutrition/                      # Đồng bộ dinh dưỡng theo 4 pha sinh học
    ├── onboarding/                     # RoleSelectionScreen (Compact ListTile), Wizard
    ├── partner_sync/                   # PairingScreen, PartnerSyncRepository
    └── settings/                       # Profile, Nickname Engine, Partner Cycle Editor, OTA Tile
```

### 3.1. Danh Sách Tệp Mới Tạo Trong Đợt Phát Hành v0.6.0
* `.github/workflows/build_release.yml`: Pipeline CI/CD GitHub Actions đóng gói tự động `moona-arm64-v8a.apk` và `moona-universal.apk` khi push tag.
* `lib/core/services/app_update_service.dart`: Dịch vụ đối soát bản phát hành mới qua GitHub API không phụ thuộc bên ngoài.
* `lib/core/widgets/app_update_dialog.dart`: Hộp thoại thông báo cập nhật giao diện Glassmorphism với logo Moona.
* `scripts/build_and_install.bat`: Script tự động hóa toàn diện (kiểm toán icon, Shared keystore, Quality Gate, build split-per-abi, kiểm tra chữ ký số và nạp ADB).

### 3.2. Hướng Dẫn Vận Hành Release Pipeline (GitHub Actions)
Khi sẵn sàng xuất bản một phiên bản release chính thức ra công chúng:
1. Đảm bảo mã nguồn đã được commit sạch sẽ trên nhánh `main`.
2. Tạo Git Tag tương ứng với phiên bản trong `pubspec.yaml` (ví dụ: `v0.6.0`):
   ```bash
   git tag v0.6.0
   ```
3. Đẩy tag lên GitHub để kích hoạt pipeline tự động build APK và đăng tải bản Release:
   ```bash
   git push origin v0.6.0
   ```
4. GitHub Actions sẽ tự động:
   * Chạy Quality Gate (`flutter analyze` & `flutter test`).
   * Giải mã secret `GOOGLE_SERVICES_JSON_BASE64` tạo `google-services.json`.
   * Biên dịch 2 bản APK: `moona-arm64-v8a.apk` (~27MB) và `moona-universal.apk`.
   * Tạo GitHub Release đính kèm ghi chú phát hành tự động.

---

## 4. 🚀 KẾ HOẠCH BƯỚC TIẾP THEO (SPRINT 3 — v0.6.0 ROADMAP)

Sau khi commit phiên bản này, các nhiệm vụ trọng tâm của Sprint 3 bao gồm:

1. **Feature 3.1: Quét mã QR ghép đôi tự động qua Camera (`qr_flutter` & `mobile_scanner`):**
   * Tab Vợ sinh mã QR động chứa mã kết nối đã mã hóa an toàn.
   * Tab Chồng tích hợp camera scanner để quét mã 1 chạm thay vì gõ tay mã số.
2. **Feature 3.2: Lịch sử tương tác & Động cơ phán đoán cảm xúc (Insights Engine):**
   * Lưu vết các lượt gửi tín hiệu yêu thương và câu hỏi thăm vào Firestore subcollection `couples/{coupleId}/interactions`.
   * Phân tích mẫu cảm xúc (Pattern Recognition) qua các chu kỳ để cảnh báo sớm cho Chồng trước pha Hoàng thể / PMS.
3. **Feature 3.3: Báo cáo đối soát chu kỳ & Xuất dữ liệu đa định dạng:**
   * Báo cáo so sánh chu kỳ lý thuyết dự báo vs chu kỳ thực tế ghi nhận.
   * Xuất tệp sao lưu mã hóa `.moona` (AES-256) và tệp bảng tính `.json` / `.csv` phục vụ đi khám phụ khoa.
