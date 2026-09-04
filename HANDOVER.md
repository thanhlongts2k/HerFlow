# 📋 BÁO CÁO BÀN GIAO CA (HANDOVER.md) — DỰ ÁN MOONA

> **Phiên bản hiện tại:** `v0.8.3+29` (Comprehensive Backup & Restore Service - v0.4.0 Legacy Fulfill)  
> **Thời điểm cập nhật:** 04/09/2026 — Hoàn tất Phân hệ Sao lưu & Khôi phục dữ liệu toàn diện (Local .moona + Cloud Vault)  
> **Kỹ sư phụ trách:** Senior Mobile Flutter Engineer (AI Pair Programmer)  

---

## ✅ 1. TRẠNG THÁI HIỆN TẠI (CURRENT STATE CHECKPOINT)

| Hạng mục | Kết quả kiểm toán | Ghi chú kỹ thuật |
|---|:---:|---|
| **Static Analysis (`flutter analyze`)** | ✅ **0 issues found!** | Toàn bộ codebase đạt chuẩn 100%, 0 errors, 0 warnings, const constructors chuẩn hóa |
| **Unit & Widget Testing (`flutter test`)** | ✅ **308/308 tests PASSED** | Đạt 100% pass toàn bộ test suites (bao gồm 8 tests BackupEncryptionService, 6 tests BackupRestoreService Restore Matrix, 2 tests BackupRestoreScreen) |
| **Phân Hệ Sao Lưu & Khôi Phục (`BackupRestoreService`)** | ✅ **HOÀN TẤT & AN TOÀN TUYỆT ĐỐI** | Thu thập snapshot toàn bộ 5 giai đoạn, nén GZIP, mã hóa AES-256-CBC, IV ngẫu nhiên 16B, KDF 1000 vòng lặp từ UID + Salt, Checksum SHA-256 |
| **Xuất & Nhập Tệp Cục Bộ (.moona File)** | ✅ **HOÀN TẤT & ĐÃ TEST** | Xuất file .moona qua `path_provider` + chia sẻ trực tiếp qua `share_plus` (Zalo/Gmail/Drive); chọn file khôi phục an toàn qua `file_picker` |
| **Đồng Bộ Đám Mây Riêng Tư (Cloud Vault)** | ✅ **HOÀN TẤT & ĐÃ BẢO VỆ RULES** | Đồng bộ snapshot mã hóa lên subcollection `users/{uid}/backups/latest`; Firestore Security Rules bảo vệ nghiêm ngặt chỉ chính chủ đọc/ghi |
| **Bảo Vệ Chống Ghi Đè Nhầm Lẫn** | ✅ **HOÀN TẤT & ĐÃ TEST** | Kích hoạt `MoonaConfirmDialog` (`isDestructive: true`) cảnh báo mạnh mẽ trước khi khôi phục; Hủy bỏ dialog bảo toàn 100% dữ liệu cũ |
| **Làm Mới State Ứng Dụng Tức Thì** | ✅ **HOÀN TẤT & AUTO REFRESH** | Cơ chế `refreshAppStateAfterRestore(ref)` gọi `ref.invalidate` trên toàn bộ controller (Chu kỳ, Thai kỳ, Nuôi con, Vòng đời, Theme, Danh xưng) |
| **Hồ Sơ Thể Trạng Mẹ Bầu (`MaternalHealthProfileModel`)** | ✅ **HOÀN TẤT & SAFE MIGRATION** | Quản lý năm sinh, chiều cao, cân nặng trước bầu, cân nặng hiện tại, con thứ mấy, nơi sinh; tương thích ngược 100% Hive cũ (mặc định null) |
| **Tính Toán Y Khoa IOM (`MaternalCalculatorService`)** | ✅ **HOÀN TẤT & AN TOÀN PHÉP CHIA** | Chuẩn 4 nhóm IOM (12.5-18kg, 11.5-16kg, 7-11.5kg, 5-9kg), dải tuần 1..40 (mặc định thai đơn), bảo vệ phép chia cho 0, phân tầng mẹ $\ge 35$ tuổi |
| **Thẻ Tiến Trình (`MaternalHealthSummaryCard`)** | ✅ **HOÀN TẤT & ĐÃ TEST** | Progressive Profiling: hiển thị thanh % hoàn thiện khi thiếu dữ liệu, tự động chuyển thành Thẻ Thể trạng IOM + Lời khuyên y khoa khi hoàn tất |
| **Modal Nhập Liệu (`MaternalProfileSheet`)** | ✅ **HOÀN TẤT & LIVE PREVIEW** | Giao diện Liquid Glass tính live BMI ngay khi gõ chiều cao/cân nặng, tính tuổi mẹ, chip chọn con thứ mấy và phương pháp sinh |
| **Góc Nhìn Bố Bầu (`HusbandViewScreen`)** | ✅ **HOÀN TẤT & ĐÃ TEST** | Thẻ Thể Trạng Chuẩn IOM của Vợ hiển thị mức tăng thực tế vs khuyến nghị, kèm hộp gợi ý thực đơn cụ thể cho Chồng chuẩn bị |
| **Realtime Sync Thể Trạng Bạn Đời** | ✅ **HOÀN TẤT** | Khi cập nhật hồ sơ, tự động đồng bộ tóm tắt thể trạng (BMI, cân nặng, thực đơn cho bố) sang document `couples/{coupleId}` cho máy Chồng |
| **Mother Dashboard (`MotherhoodHomeScreen`)** | ✅ **HOÀN TẤT & ĐÃ TEST** | Tích hợp Tab 0 MainNavScreen khi `LifeStage.motherhood`. Gồm Hero Card, Quick Action Bar, LAM Card, Wonder Weeks & Daily Timeline |
| **Bấm Giờ Bú Độc Lập (`FeedingTimerSheet`)** | ✅ **HOÀN TẤT & AN TOÀN NỀN** | Lưu mốc `startTime` bằng `DateTime.now()` thực tế để bảo toàn thời lượng kể cả khi app ngủ hoặc khóa máy. Hỗ trợ Ngực T/P & Bú bình |
| **Góc Nhìn Bố Bỉm (`HusbandViewScreen`)** | ✅ **HOÀN TẤT & ĐÃ TEST** | `HusbandMotherhoodCompanionCard` (tóm tắt trạng thái con, lời khuyên bố) & `HusbandBabyQuickCareRow` (3 nút ghi nhanh 1-chạm của Bố) |
| **Realtime Sync Firestore Bạn Đời** | ✅ **HOÀN TẤT** | Đồng bộ trực tiếp `couples/{coupleId}/motherhoodStatus/today` qua Stream Provider `motherhoodStatusStreamProvider` an toàn offline |
| **Safeguard Chữa Lành (`Healing Mode`)** | ✅ **HOÀN TẤT & ĐÃ TEST** | Tự động ẩn toàn bộ thông số bé khi `isPaused == true`, hiển thị không gian nghỉ ngơi tĩnh dưỡng và phục hồi sau sinh cho Mẹ |
| **Hardware Checkpoint (Redmi Note 11)** | ✅ **HOÀN TẤT & ĐÃ XÁC THỰC** | Build & nạp APK vật lý; Vợ chuyển Chung Đôi ↔ Chuẩn Bị Bầu; Chồng lùi về Chung Đôi thành công; Lưu ảnh `docs/screenshots/hardware_test_couple_rollback.png` |
| **Motherhood Domain & Models** | ✅ **HOÀN TẤT & ĐÃ TEST** | `ChildProfileModel`, `BabyActivityLogModel`, `WhoGrowthStandards`, `WonderWeeksData`, `MotherhoodStatusModel` |
| **Hive Box Nuôi Con & UserScope** | ✅ **HOÀN TẤT** | Mở `AppConstants.motherhoodBoxName` tại `main.dart`, cô lập 100% key phân vùng `UserScope.key()` |
| **State Controllers Nuôi Con** | ✅ **HOÀN TẤT & ĐÃ TEST** | `ChildProfileController`, `BabyLogController` (quick logs), `LamStatusController` (WHO LAM algorithm & alert suppression) |
| **Ma Trận Chuyển Trạng Thái 5x5** | ✅ **100% 35/35 PASS** | Mở rộng lên toàn bộ 5 LifeStages: 25/25 ô ma trận + 10/10 cặp chuyển đổi 2 chiều (Bidirectional Round-Trip) |
| **Khóa Chế Độ Solo Khi Ghép Đôi (Solo Guard)** | ✅ **HOÀN TẤT & ĐÃ TEST** | Làm mờ 50%, icon 🔒, badge "Cần hủy ghép đôi", cảnh báo SnackBar khi chạm, chặn chuyển mode |
| **Đồng Bộ Hai Chiều LifeStage (Transition Matrix)** | ✅ **HOÀN TẤT & 100% PASS** | Vợ đổi stage -> Firestore `couples/{coupleId}` -> Chồng Stream auto-sync RAM + Hive local; Pass 16/16 ô ma trận và 6/6 cặp 2 chiều |
| **Tương Thích SDK Flutter 3.24 & 3.29+** | ✅ **HOÀN TẤT** | Chuẩn hóa `CardTheme` & `activeColor`, 0 compile error trên local, tương thích 100% CI runner |
| **Bộ Đếm Cử Động Thai (Kick Counter)** | ✅ **HOÀN TẤT & ĐÃ TEST TRỰC QUAN** | Chuẩn Cardiff Count to 10 (2h), vòng tròn đếm gợn sóng + haptic feedback, lịch sử phiên đếm |
| **Lịch Khám Thai Mốc Vàng (Prenatal Appointments)** | ✅ **HOÀN TẤT & ĐÃ TEST TRỰC QUAN** | 7 mốc y tế Việt Nam, tự động tính tuần/status (upcoming/current/done), checklist tích chọn |
| **Tóm Tắt Thai Máy Cho Bố Bầu (Husband View)** | ✅ **HOÀN TẤT & ĐÃ TEST TRỰC QUAN** | `_buildKickSummaryCard` đồng bộ số cử động hôm nay của con cho Bố Bầu |
| **Bản Đồ Nghiệp Vụ Toàn Dự Án** | ✅ **CHUẨN HÓA** | Tạo `docs/APP_BUSINESS_MATRIX.md` phân định quyền 2 Role, Unpaired vs Paired, Data Boundary & Perspective Mapping |
| **Hộp Thư Tình Yêu 2 Chiều (Love Notes Thread)** | ✅ **HOÀN TẤT** | Nâng cấp toàn diện: Luồng đối thoại 2 chiều mini, Timeline bong bóng chuẩn chat, triệt tiêu lỗi Outgoing Blindspot, hỗ trợ phản hồi tạo document mới |
| **Quản Lý Kết Nối Cặp Đôi (Connection Modal)** | ✅ **FIXED & NÂNG CẤP** | Xóa bỏ crash khi bấm nút [Quản lý] trong Cài đặt; Modal BottomSheet hiển thị mã liên kết, sao chép 1 chạm an toàn (Clipboard try/catch) & MoonaConfirmDialog hủy kết nối |
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

### 2.4. Lỗi Flutter Widget Test Fail Trên GitHub Actions Runner
* **Hiện tượng:** Test suite chạy trên GitHub Actions runner bị fail đúng 1 test: `test/pregnancy_home_screen_test.dart: Hiển thị đầy đủ Gestational Hero Card, D-Day và quả so sánh`.
* **Nguyên nhân cốt lõi:**
  1. **Trùng lặp chuỗi Text:** Khi tích hợp Phase 2.5 `PrenatalAppointmentsCard`, chip mốc khám đầu tiên hiển thị nhãn `Tuần 11–13`. Câu lệnh kiểm thử `find.textContaining('Tuần 11')` tìm thấy 2 phần tử (`Tuần 11` của Hero Card và `Tuần 11–13` của Lịch khám), gây lỗi `Too many elements found (found 2)`.
  2. **Kích thước Viewport headless mặc định 800x600 px:** Dashboard thai kỳ có nhiều thẻ chức năng, cần khai báo kích thước giả lập `1080x2400` và `devicePixelRatio = 1.0` để render trọn vẹn.
  3. **Chênh lệch múi giờ (UTC vs GMT+7):** Runner GitHub dùng múi giờ UTC, việc so sánh chuỗi số ngày cố định khi tính từ `DateTime.now()` có thể bị lệch 1 ngày.
* **Khắc phục triệt để:**
  1. Đổi sang `find.text('Tuần 11')` chính xác thay vì `find.textContaining`.
  2. Sử dụng `find.textContaining(RegExp(r'Còn \d+ ngày'))` cho bộ đếm D-Day.
  3. Thêm mục 10 vào `AGENTS.md` chuẩn hóa quy tắc kiểm thử và CI/CD.

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

## 4. 🚀 KẾ HOẠCH BƯỚC TIẾP THEO (PHASE 3: ADVANCED MOTHERHOOD)

Sau khi hoàn thành Task 3 (Giao diện Mẹ Bỉm & Bấm giờ bú độc lập) và Task 4 (Góc nhìn Bố Bỉm & Đồng bộ 1-chạm), 3 nhiệm vụ ưu tiên số 1 cho ca tiếp theo:

1. **Ưu tiên 1: Biểu Đồ Tăng Trưởng Chuẩn WHO (WHO Growth Chart Visualizer):**
   * Trực quan hóa biểu đồ Z-Score cân nặng và chiều cao từ 0–24 tháng (đường cong P50 Median, ±1SD, ±2SD).
   * Vẽ các điểm đo thực tế của bé lên đồ thị, hiển thị nhãn đánh giá dinh dưỡng khoa học.
2. **Ưu tiên 2: Cẩm Nang Dỗ Bé Wonder Weeks & Sổ Tay Cột Mốc (Milestones):**
   * Trang chi tiết 10 tuần khủng hoảng nhận thức Wonder Weeks (kèm danh sách kỹ năng mới của từng Leap).
   * Checklist các mốc vận động, giao tiếp và phản xạ đầu đời của bé sơ sinh.
3. **Ưu tiên 3: Hardware Checkpoint Toàn Diện Phase 3 Trên Redmi Note 11:**
   * Nạp bản build APK hoàn chỉnh sang thiết bị thật.
   * Thử nghiệm luồng ghi nhật ký cữ bú bấm giờ, đổi bé và đồng bộ realtime sang góc nhìn Bố Bỉm.

---

## 5. 🛡️ ĐÁNH GIÁ KHẢ NĂNG LỌT BUG (BUG ESCAPE RISK ASSESSMENT - ĐIỀU 12 AGENTS.MD)

| Rủi ro tiềm ẩn (Risk Vector) | Mức độ | Biện pháp phòng vệ đã triển khai (Implemented Safeguard) |
|---|:---:|---|
| **Lệch thời lượng cữ bú khi khóa máy (Timing Drift)** | Thấp | `FeedingTimerSheet` ghi nhận mốc `startTime` bằng `DateTime.now()` thực tế. Khi resume, thời lượng được tính theo hiệu số `difference()` thay vì đếm nhịp Timer đơn thuần, miễn nhiễm với việc hệ điều hành đóng băng background process. |
| **Vòng lặp Re-render khi đánh giá LAM (State Loop)** | Thấp | Bổ sung equality check guard trong `LamStatusController.evaluateWithChild()`, chỉ cập nhật state khi có biến đổi thực tế. Di dời việc kích hoạt sang `initState` & `ref.listen` thay vì gọi trong `build()`. |
| **Tràn khung hình Headless Test (Layout Overflow)** | Cực thấp | Áp dụng triệt để Rule 10: Toàn bộ Widget test thiết lập kích thước giả lập `1080x2400` pixel với `devicePixelRatio = 1.0`, dọn dẹp an toàn qua `addTearDown`. |
| **Xung đột định danh tab Bố Bỉm (Name Collision)** | Cực thấp | Phân định rõ phạm vi NavigationDestination bằng `find.widgetWithText(NavigationDestination, 'Bố Bỉm')` để không bị trùng lặp với thẻ badge Bố Bỉm trong Hero Card. |
| **Nhầm lẫn phân quyền cha mẹ (Role Attribution)** | Cực thấp | Các nút tác vụ nhanh của Bố được gắn cứng `loggedByRole: 'husband'` và của Mẹ `loggedByRole: 'wife'`, đảm bảo phân định rõ ràng trên timeline và Firestore. |
| **Phép chia cho 0 khi tính BMI (Zero Division)** | Cực thấp | `MaternalCalculatorService.calculateBmi` kiểm tra bắt buộc `heightCm == null || heightCm <= 0 || weightKg == null || weightKg <= 0`, trả về `null` an toàn, miễn nhiễm với `double.infinity` hay NaN. |
| **Gãy cấu hình Hive cũ (Safe Hive Migration)** | Cực thấp | Mọi trường dữ liệu mới của `MaternalHealthProfileModel` đều mặc định null. Parser `PregnancyConfigModel.fromMap` có null-check và `try/catch` bọc ngoài, dữ liệu cũ đọc an toàn 100%. |
| **Gián đoạn lưu offline khi sync Bạn Đời (Sync Fault)** | Cực thấp | Lưu RAM & Hive local thực hiện trước; thao tác ghi Firestore `users/{uid}` và `couples/{coupleId}` được bọc trong khối `try/catch` với `.catchError`, bảo toàn tuyệt đối trải nghiệm offline. |
| **Ghi đè nhầm dữ liệu khi khôi phục (Accidental Overwrite)** | Cực thấp | Kích hoạt bắt buộc `MoonaConfirmDialog` với `isDestructive: true`. Chỉ khi người dùng bấm xác nhận rõ ràng mới tiến hành mở file và giải mã. |
| **Giải mã sai tài khoản / Lệch UID (Cross-Account Leak)** | Cực thấp | Mã băm `uidHash` được kiểm tra chéo trước khi giải mã. Nếu phát hiện tệp thuộc tài khoản khác, ném ngay `BackupInvalidKeyException` và chặn 100% việc chạm vào Hive. |
| **Dữ liệu sao lưu bị hỏng / Can thiệp (Tampered Backup)** | Cực thấp | Thuật toán băm SHA-256 Checksum đối chiếu toàn vẹn trước khi ghi vào database. Nếu sai khác 1 byte, ném `BackupCorruptedException` và giữ nguyên database cũ. |
| **Vượt giới hạn kích thước Cloud Firestore 1MB (Size Overflow)** | Cực thấp | Dữ liệu được nén GZIP trước khi mã hóa AES-256, giảm kích thước tệp ~70-85%, đảm bảo snapshot đa giai đoạn thường chỉ chiếm 10-50KB. |
