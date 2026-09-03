# 📋 BÁO CÁO BÀN GIAO CA (HANDOVER.md) — DỰ ÁN MOONA

> **Phiên bản hiện tại:** `v0.4.0+9` (Realtime 2-Way Feedback Loop & Multi-Device Sync)
> **Thời điểm cập nhật:** 03/09/2026 — Hoàn thành Vòng lặp phản hồi 2 chiều & Đồng bộ Live 2 thiết bị
> **Kỹ sư phụ trách:** Senior Mobile Flutter Engineer (AI Pair Programmer)

---

## ✅ TRẠNG THÁI HIỆN TẠI (CHECKPOINT PHIÊN NÀY)

| Hạng mục | Kết quả |
|---|---|
| `flutter analyze` | ✅ **0 issues found!** |
| `flutter test` | ✅ **15/15 tests PASSED (100%)** |
| Deploy Đa Thiết Bị | ✅ **SUCCESS** — Xiaomi 2201116TG + Android Emulator-5554 song song |
| Vợ đổi Thể Trạng/Năng Lượng | ✅ **REALTIME SYNC** — Pin năng lượng & tâm trạng trên máy Chồng nhảy tức thì |
| Vợ gửi Tín Hiệu Yêu Thương | ✅ **REALTIME SYNC** — Máy Chồng hiện Hộp tín hiệu + 4 nút phản hồi nhanh 1 chạm |
| Chồng phản hồi 1 chạm | ✅ **REALTIME SYNC** — Máy Vợ nhận ngay Banner ngọt ngào kèm Haptic & tự ẩn sau 10s |
| Dual-Path Firestore Sync | ✅ **HOÀN TẤT** — Đồng bộ an toàn song song `couples` và `pairings`, sắp xếp in-memory |
| Multi-Device Deploy Script | ✅ **HOÀN TẤT** — `scripts/deploy.ps1 -Target all` nạp APK song song lên toàn bộ thiết bị |

---

## 1. 🚀 TRẠNG THÁI BUILD APK & KIỂM THỬ (APK BUILD & TEST STATUS)

* **Phân tích tĩnh (Static Analysis):** `flutter analyze` → ✅ **0 issues found!** (0 lỗi, 0 cảnh báo).
* **Kiểm thử đơn vị (Unit Tests):** `flutter test` → ✅ **14/14 tests PASSED (100%)**.
* **Đóng gói tối ưu (Release Optimization):**
  * Đã kích hoạt **R8 Code Shrinking / Obfuscation** (`isMinifyEnabled = true`, `isShrinkResources = true`).
  * Cấu hình an toàn `proguard-rules.pro` bảo vệ Models, Entities, Hive, Firebase và Plugins.
  * Tách biệt kiến trúc CPU qua `flutter build apk --release --split-per-abi`.
* **Kết quả APK (v0.3.0):**
  * `app-armeabi-v7a-release.apk`: **19.8 MB**
  * `app-arm64-v8a-release.apk`: **21.9 MB** ← Đang test trên Xiaomi
  * `app-x86_64-release.apk`: **23.3 MB**
* **Môi trường SDK & Nền tảng:**
  * **Flutter SDK:** `3.44.4` (Channel stable)
  * **Dart SDK:** `3.12.2`
  * **Java Runtime:** OpenJDK `17.0.12`
  * **Android Min SDK:** `21` (Hỗ trợ 99.5% thiết bị Android)
  * **Android Target SDK:** `34` (Android 14)
  * **Activity Base:** `FlutterFragmentActivity` (Tương thích `local_auth` 2.x, chống crash Android 13+)
  * **Widget Receiver:** `HusbandWidgetProvider` với `android:exported="true"` (Tương thích Android 12+)
  * **Notification Runtime:** Kênh `moona_pms_channel` ưu tiên cao, quyền runtime `POST_NOTIFICATIONS`

---

## 2. 🏗️ TÓM TẮT KIẾN TRÚC HIỆN TẠI (CURRENT ARCHITECTURE SUMMARY)

Dự án áp dụng mô hình chuẩn **Feature-First Clean Architecture**, cấu trúc thư mục hiện tại gồm các phân hệ:

| Phân hệ / Module | Đường dẫn | Trạng thái | Lưu trữ / Công nghệ |
|---|---|:---:|---|
| **Core & Design System** | `lib/core/` | ✅ Hoàn thành | Quicksand Google Fonts, AppColors Soft Pastel, AppTheme (Light/Dark) |
| **App Version Provider** | `lib/core/providers/app_version_provider.dart` | ✅ Hoàn thành (mới) | `package_info_plus`, FutureProvider, đọc version động từ pubspec |
| **Notification Service** | `lib/core/notifications/` | ✅ Hoàn thành | `flutter_local_notifications`, `timezone`, Channel PMS ưu tiên cao |
| **Haptic Feedback Utility** | `lib/core/utils/` | ✅ Hoàn thành | `AppHaptics` chuẩn hóa selection, light, medium, heavy |
| **Network & Offline Banner** | `lib/core/network/` | ✅ Hoàn thành | `connectivity_plus`, `isOnlineProvider`, `OfflineBanner` |
| **Onboarding Wizard** | `lib/features/onboarding/` | ✅ Hoàn thành | Luồng 3 bước, DatePicker, Slider chu kỳ kèm Haptic |
| **Biometric Security** | `lib/features/auth/` | ✅ Hoàn thành | `local_auth`, `BiometricLockScreen`, Lifecycle Observer |
| **Cycle Core Engine** | `lib/features/cycle/` | ✅ Hoàn thành | Thuật toán 4 pha sinh học, `isPmsWindow`, TableCalendar |
| **Mood & Micro-logging** | `lib/features/mood/` | ✅ Hoàn thành | 5 mức năng lượng, FilterChips, fl_chart xu hướng 7 ngày |
| **Nutrition Synced** | `lib/features/nutrition/` | ✅ Hoàn thành | Database dinh dưỡng 4 pha |
| **Husband View (Offline)** | `lib/features/husband_view/` | ✅ Hoàn thành | Lời khuyên cho chồng, 3 việc nên/tránh, nút copy |
| **Partner Sync (Cloud & Queue)** | `lib/features/partner_sync/` | ⚠️ Partial | Ghép đôi PIN 6 ký tự, Smart Offline Queue — **CÒN LỖI TREO UI** |
| **Android Home Widget** | `lib/features/widgets/` | ✅ Hoàn thành | `home_widget`, Native RemoteViews, `WidgetUpdateService` |
| **One-Tap Care Signals** | `lib/features/care_signals/` | ✅ Hoàn thành | 4 tín hiệu yêu thương 1-chạm (🫖 🧋 🫂 🍃) |
| **Backup & Restore AES** | `lib/features/backup/` | ✅ Hoàn thành | AES-256 file `.moona`, SHA-256 checksum |
| **Settings Screen** | `lib/features/settings/` | ❌ Chưa có | **CẦN TẠO — xem Mission 2 bên dưới** |
| **Main Navigation** | `lib/features/home/` | ✅ Hoàn thành | BottomNavigationBar 4 Tab mượt mà |

---

## 3. ⚠️ BLOCKERS & VIỆC CÒN DỞ DANG (INCOMPLETE TASKS)

### 🔴 BLOCKER 1: `cycle_settings_sheet.dart` chứa cài đặt Biometric sai vị trí
- **Vị trí:** `lib/features/cycle/presentation/widgets/cycle_settings_sheet.dart`
- **Vấn đề UX:** Switch "Khóa bằng sinh trắc học" đặt chung trong BottomSheet hiệu chỉnh chu kỳ kinh nguyệt — sai hoàn toàn về mặt kiến trúc UX.
- **Nguy cơ:** Người dùng không tìm thấy cài đặt bảo mật; dễ vô tình bật/tắt khi điều chỉnh chu kỳ.

### 🔴 BLOCKER 2: `pairing_screen.dart` treo loading vô tận
- **Vị trí:** `lib/features/partner_sync/presentation/screens/pairing_screen.dart`
- **Vấn đề:** Nhấn "Tạo mã kết nối" → loading spinner quay mãi do Firestore chưa config đầy đủ hoặc network timeout.
- **Nguy cơ Crash/Deadlock:** Không có timeout guard, không có `finally` set `isLoading = false`.

---

## 4. 🎯 KẾ HOẠCH ƯU TIÊN PHIÊN TIẾP THEO (NEXT SESSION PRIORITY MISSIONS)

---

### 🚨 MISSION 1 (HIGH PRIORITY BUGFIX): KHẮC PHỤC LỖI TREO "ĐANG TẠO MÃ..." TRÊN PAIRING_SCREEN

**Vấn đề chi tiết:**
Khi nhấn "Tạo mã kết nối" trên màn hình ghép đôi phía Vợ, ứng dụng bị quay loading vô tận do Firestore demo/network chưa phản hồi. `isLoading` không bao giờ được set về `false`.

**Giải pháp kỹ thuật BẮT BUỘC:**

1. **Timeout & State Protection:**
   - Mọi lệnh Firestore (`set`, `get`, `add`) phải có `.timeout(const Duration(seconds: 6))`.
   - Bắt buộc dùng khối `try - catch - finally` → đảm bảo `isLoading = false` trong `finally`.
   - Bắn `SnackBar` thông báo lỗi nếu có ngoại lệ.

2. **Offline/Demo Fallback Mode:**
   - Khi Firestore timeout hoặc lỗi cấu hình → tự động sinh mã local 6 ký tự `HFxxxx` (ví dụ: `HF8201`).
   - Lưu tạm vào Hive `settingsBox` / memory.
   - Hiển thị mã lên UI kèm nhãn nhỏ: *"Mã kết nối nội bộ (Thử nghiệm)"*.
   - Mục tiêu: Vẫn test được tiếp luồng nhập mã phía Chồng mà không cần Firestore thật.

**Tệp cần chỉnh sửa:**
```
lib/features/partner_sync/data/partner_sync_repository.dart
lib/features/partner_sync/presentation/controllers/partner_sync_controller.dart
lib/features/partner_sync/presentation/screens/pairing_screen.dart
```

**Mẫu code cốt lõi cần thêm vào repository:**
```dart
Future<String> generateOrGetPairingCode(String uid) async {
  try {
    final code = _generateLocalCode(); // 'HF' + Random(4 digits)
    await _firestore
        .collection('couples')
        .doc(uid)
        .set({'pairingCode': code, 'createdAt': FieldValue.serverTimestamp()})
        .timeout(const Duration(seconds: 6));
    return code;
  } on TimeoutException catch (_) {
    // Fallback: dùng mã offline
    final localCode = _generateLocalCode();
    await _settingsBox.put('offlinePairingCode', localCode);
    return localCode; // UI sẽ hiển thị nhãn "(Thử nghiệm)"
  } catch (e) {
    throw Exception('Không thể tạo mã: $e');
  }
  // finally ở Controller: state = state.copyWith(isLoading: false)
}
```

---

### 🔧 MISSION 2 (REFACTOR UX/UI): TÁCH MODULE CÀI ĐẶT THÀNH MÀN HÌNH ĐỘC LẬP (SETTINGS_SCREEN)

**Vấn đề chi tiết:**
Cài đặt sinh trắc học đang bị nhúng sai vào `CycleSettingsSheet` — vi phạm nguyên tắc Single Responsibility.

**Giải pháp kỹ thuật:**

**Bước 1 — Tinh gọn `cycle_settings_sheet.dart`:**
- Xóa bỏ toàn bộ phần Switch "Khóa bằng sinh trắc học" và mọi import liên quan.
- Đổi tiêu đề từ "Cài Đặt" → **"Hiệu Chỉnh Chu Kỳ"**.
- Chỉ giữ lại 2 bộ điều khiển:
  - Slider/NumberPicker ngày chu kỳ (21–45 ngày).
  - DatePicker ngày bắt đầu kỳ kinh gần nhất.

**Bước 2 — Tạo màn hình mới `lib/features/settings/presentation/screens/settings_screen.dart`:**

```
/settings_screen.dart
  ├── Nhóm 1: 🔐 Bảo mật
  │   ├── Switch: "Khóa bằng sinh trắc học" (keyIsBiometricEnabled)
  │   └── DropdownButton: Thời gian tự động khóa ("Ngay lập tức" / "1 phút")
  │
  ├── Nhóm 2: 🔗 Đồng bộ & Ghép đôi
  │   ├── Text: Trạng thái ghép đôi (Đã kết nối / Chưa kết nối)
  │   └── TextButton → Navigator.push(PairingScreen)
  │
  ├── Nhóm 3: 🎨 Giao diện
  │   ├── SegmentedButton / RadioGroup: Theme Sáng / Tối / Hệ thống
  │   └── Switch: "Phản hồi xúc giác (Haptic Feedback)"
  │
  └── Nhóm 4: 💾 Dữ liệu & Giới thiệu
      ├── ListTile → BackupScreen (Sao lưu & Khôi phục)
      └── Text: "Moona v${info.version} (Build ${info.buildNumber})" (dùng appVersionProvider)
```

**Bước 3 — Cập nhật `cycle_screen.dart`:**
- Đổi icon `Icons.tune_rounded` (hoặc tương tự) góc phải AppBar → `Icons.settings_outlined` → `Navigator.push('/settings')`.
- Đặt thêm 1 `IconButton` nhỏ với icon `Icons.edit_calendar_outlined` cạnh tiêu đề lịch → gọi `CycleSettingsSheet.show(context)`.

**Tệp cần tạo/chỉnh sửa:**
```
[NEW]    lib/features/settings/presentation/screens/settings_screen.dart
[MODIFY] lib/features/cycle/presentation/widgets/cycle_settings_sheet.dart
[MODIFY] lib/features/cycle/presentation/screens/cycle_screen.dart
[MODIFY] lib/main.dart  (thêm route '/settings' → SettingsScreen)
```

---

### ➕ MISSION 3 (BONUS — Version System): HOÀN THIỆN CHUẨN HÓA VERSION
- **Đã làm:**
  - ✅ `pubspec.yaml` → `version: 0.3.0+3`
  - ✅ `build.gradle.kts` → dùng `flutter.versionCode` / `flutter.versionName`
  - ✅ Tạo `lib/core/providers/app_version_provider.dart` với `PackageInfo.fromPlatform()`
- **Còn lại:**
  - ⬜ Xóa `appVersion = '0.3.0'` khỏi `app_constants.dart` (hoặc deprecate).
  - ⬜ Tích hợp `appVersionProvider` vào `SettingsScreen` (tạo ở Mission 2) để hiển thị version động.
  - ⬜ Chạy `flutter pub get` để tải `package_info_plus`.
  - ⬜ Chạy `flutter analyze` sau khi tích hợp xong.

---

## 5. 🔑 THÔNG TIN KỸ THUẬT QUAN TRỌNG (TECHNICAL CONTEXT)

### AES Encryption Keys (dùng trong BackupRepository)
```
Key:  'MoonaSec2026!Key@SecretFlow2026!'  (32 bytes)
IV:   'MoonaIV2026Init!'                  (16 bytes)
```
> ⚠️ Dùng cho mã hóa file `.moona` backup. Không thay đổi key nếu đã có user tạo file backup.

### ProGuard Rules đặc biệt (trong `proguard-rules.pro`)
```proguard
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
-keepclassmembers class * extends androidx.work.Worker {
    public <init>(android.content.Context, androidx.work.WorkerParameters);
}
```
> 🔑 Bắt buộc để tránh crash R8 với WorkManager khi `isMinifyEnabled = true`.

### Gradle subproject compileSdk override (trong `android/build.gradle.kts`)
```kotlin
subprojects {
    afterEvaluate {
        // Ép tất cả plugin dùng compileSdk 36 để tránh checkReleaseAarMetadata fail
    }
}
```

### ADB Device ID
```
adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp
```
> Dùng flag `-s` khi chạy lệnh ADB: `adb -s "adb-BM6HKBHEHQKFEMLR-..." shell ...`

---

## 6. 📸 SCREENSHOTS KIỂM THỬ THIẾT BỊ (v0.4.0)

| # | File | Nội dung |
|---|---|---|
| 25 | `docs/screenshots/25_v030_launch.png` | Splash Screen Moona |
| 26 | `docs/screenshots/26_v030_app_screen.png` | Màn hình chính sau khởi động |
| 27 | `docs/screenshots/27_v030_app_running.png` | App đang chạy trên Xiaomi |
| 28 | `docs/screenshots/28_v030_care_signals_sheet.png` | Care Signals bottom sheet |
| 29 | `docs/screenshots/29_v030_mood_tab.png` | Tab Cảm xúc — Nhật Ký Thể Trạng |
| 30 | `docs/screenshots/30_v030_care_signals_sheet.png` | Cycle Screen với AppBar tim đỏ |
| 31 | `docs/screenshots/31_v040_husband_redesign.png` | Gentleman's Companion màn hình Chồng |
| 32 | `docs/screenshots/32_v040_care_sheet.png` | Vợ mở CareSignalSheet gửi tín hiệu |
| 33 | `docs/screenshots/33_v040_signal_received.png` | Hộp tín hiệu từ Vợ + 4 nút phản hồi nhanh |
| 34 | `docs/screenshots/34_v040_signal_responded.png` | Chồng phản hồi "Gửi nàng cái ôm thật chặt" |
| 35 | `docs/screenshots/35_v040_role_wife.png` | Giao diện Vợ (4 tab BottomNav + icon Khiên + Chip Vợ) |
| 36 | `docs/screenshots/36_v040_wife_preview_husband.png` | Vợ xem trước Góc nhìn của Chồng kèm Banner hồng |
| 37 | `docs/screenshots/37_v040_role_husband.png` | Giao diện Chồng (Vào thẳng Gentleman's Companion, không BottomNav) |
| 38 | `docs/screenshots/38_v040_settings_role.png` | Màn hình Cài đặt với thẻ chọn [Tôi là Vợ] & [Tôi là Chồng] |
| 39 | `docs/screenshots/39_v040_settings_switched_to_wife.png` | Trạng thái chuyển đổi tức thời trong Cài đặt |
| 41 | `docs/screenshots/41_v040_settings_wife.png` | Cài đặt khi ở vai trò Vợ (có tile Xem trước góc nhìn Chồng) |
| 42 | `docs/screenshots/42_v040_settings_switched_to_husband.png` | Cài đặt khi chọn vai trò Chồng (tự ẩn tile xem trước) |
| 43 | `docs/screenshots/43_v040_husband_home_after_switch.png` | Màn hình Chồng chính thức sau khi đổi vai trò |
| 44 | `docs/screenshots/44_v040_xiaomi_init.png` | Khởi chạy ban đầu trên thiết bị thật Xiaomi 2201116TG |
| 45 | `docs/screenshots/45_v040_emulator_init.png` | Khởi chạy ban đầu trên máy ảo Android Emulator-5554 |
| 46 | `docs/screenshots/46_v040_xiaomi_switched_to_wife.png` | Xiaomi chọn vai trò Vợ trong Cài đặt |
| 47 | `docs/screenshots/47_v040_xiaomi_wife_home.png` | Xiaomi giao diện Vợ 4 tabs Bottom Navigation |
| 52 | `docs/screenshots/52_v040_xiaomi_mood_changed.png` | Vợ đổi mức năng lượng lên "Tràn đầy" (5/5) & tâm trạng "Hạnh phúc" |
| 53 | `docs/screenshots/53_v040_emu_synced_tranday.png` | Màn hình Chồng trên Giả lập tự động nhảy pin 5/5 & tâm trạng "Hạnh phúc" Realtime |
| 55 | `docs/screenshots/55_v040_xiaomi_care_sheet_opened.png` | Vợ mở BottomSheet Gửi Tín Hiệu Yêu Thương |
| 56 | `docs/screenshots/56_v040_emu_received_signal.png` | Chồng nhận Tín hiệu yêu thương từ Vợ |
| 64 | `docs/screenshots/64_v040_xiaomi_ready.png` | Xiaomi sẵn sàng ở chế độ Vợ (Light Mode) |
| 65 | `docs/screenshots/65_v040_emulator_ready.png` | Emulator sẵn sàng ở chế độ Chồng (Light Mode) |
| 68 | `docs/screenshots/68_v040_xiaomi_sheet_open.png` | Sheet chọn tín hiệu yêu thương hiển thị đẹp mắt |
| 69 | `docs/screenshots/69_v040_emu_received_om.png` | Chồng nhận tín hiệu "Muốn được ôm 🤗" (Vừa xong) + 4 nút phản hồi nhanh |
| 70 | `docs/screenshots/70_v040_emu_responded_ngoan.png` | Chồng bấm phản hồi "💖 Ngoan đợi anh về nhé" |
| 71 | `docs/screenshots/71_v040_xiaomi_banner_received.png` | Máy Vợ hiển thị Banner ngọt ngào từ Chồng ở đầu màn hình kèm rung Haptic |
| 72 | `docs/screenshots/72_v040_xiaomi_banner_dismissed.png` | Vợ bấm ✕ đóng Banner nhẹ nhàng mượt mà |

---

## 7. 📋 LỆNH THƯỜNG DÙNG (QUICK REFERENCE)

```bash
# Cài đặt dependencies mới (sau khi thêm package_info_plus)
flutter pub get

# Phân tích tĩnh
flutter analyze

# Chạy unit tests
flutter test

# Build release APK tách theo kiến trúc CPU
flutter build apk --release --split-per-abi

# Cài đặt APK lên thiết bị Xiaomi qua ADB
adb -s "adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp" install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Kiểm tra version APK đang cài trên máy
adb -s "adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp" shell "dumpsys package com.herflow.app.herflow | grep -E 'versionCode|versionName'"

# Chụp màn hình thiết bị
adb -s "adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp" shell screencap -p /sdcard/screen.png
adb -s "adb-BM6HKBHEHQKFEMLR-prj23i._adb-tls-connect._tcp" pull /sdcard/screen.png docs/screenshots/XX_ten_anh.png
```

---

## 8. 🎯 KẾ HOẠCH BỨC PHÁ TIẾP THEO (v0.5.0 SPRINT BREAKDOWN)

Chi tiết hồ sơ kiến trúc và đặc tả đã được lưu tại: [`docs/ROADMAP_v0.5.0.md`](file:///d:/Sources/HerFlow/docs/ROADMAP_v0.5.0.md).

### 🚀 Sprint 2A: Onboarding Phân Quyền & Hệ Thống Danh Xưng Tùy Biến
- [ ] **2A.1 Model & Addressing Engine:** `NicknameConfig` + `AddressingEngine` (Preset: "Người thương", "Em bé", "Bé iu", "Vợ yêu", "Chồng yêu", "Anh yêu" + Tự xưng).
- [ ] **2A.2 UI Cài Đặt:** Thẻ cấu hình Danh xưng 2 chiều trong `SettingsScreen`.
- [ ] **2A.3 Màn Hình Chào Mừng Lần Đầu (First-Launch Screen):** Chọn vai trò: `[ 🌸 Tôi là Phụ nữ ]` hoặc `[ 🛡️ Tôi là Người thương ]`.
- [ ] **2A.4 Điều Hướng Onboarding Tách Biệt:** Phụ nữ đi qua thiết lập chu kỳ -> CycleScreen; Người thương vào thẳng nhập mã ghép đôi -> Gentleman's Companion.

### 💌 Sprint 2B: Chồng Chủ Động Hỏi Han & Vợ Phản Hồi 1 Chạm
- [ ] **2B.1 Model & Firestore:** `CareInquiryModel` & Subcollection `care_inquiries`.
- [ ] **2B.2 Husband Dashboard:** Hộp "Chăm sóc nàng hôm nay" với câu hỏi thông minh thích ứng theo 4 pha chu kỳ + ô nhập tin ngắn.
- [ ] **2B.3 Wife Dashboard:** In-app Card câu hỏi thăm kèm 4 nút phản hồi nhanh 1 chạm (🥺 Hơi mệt, 🧋 Thèm ngọt, 🥰 Nhớ anh, 🛌 Đang nghỉ).
- [ ] **2B.4 Nghiệm thu Realtime:** Kiểm thử đồng bộ 2 thiết bị (Xiaomi + Giả lập).

### 🔑 Sprint 3: Google Sign-In & Đồng Bộ Avatar Cặp Đôi
- [ ] **3.1 Cấu hình Firebase Auth & Google Sign-In:** SHA-1 / SHA-256 trên Firebase Console.
- [ ] **3.2 Profile Sync:** Lưu PhotoUrl, Email, Display Name vào `users/{uid}` và `couples/{coupleId}`.
- [ ] **3.3 Avatar đôi UI:** Hiển thị Avatar đôi trên AppBar của Vợ và Hero Card của Chồng.
- [ ] **3.4 Release v0.5.0:** Đóng gói bản phát hành chính thức.

