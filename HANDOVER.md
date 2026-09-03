# 📋 BÁO CÁO BÀN GIAO CA (HANDOVER.md) — DỰ ÁN HERFLOW

> **Phiên bản:** `v0.1.0`  
> **Thời điểm cập nhật:** 03/09/2026  
> **Kỹ sư phụ trách:** Senior Mobile Flutter Engineer (AI Pair Programmer)

---

## 1. 🚀 TRẠNG THÁI BUILD APK (APK BUILD STATUS)

* **Lệnh build gần nhất:** `flutter build apk --debug`
* **Kết quả:** ✅ **BUILD SUCCESSFUL (100% PASS)**
* **Thời gian biên dịch:** `32.9s`
* **Đường dẫn tệp xuất:** `build/app/outputs/flutter-apk/app-debug.apk` (Kích thước: `153.4 MB`)
* **Môi trường SDK & Nền tảng:**
  * **Flutter SDK:** `3.44.4` (Channel stable)
  * **Dart SDK:** `3.12.2`
  * **Java Runtime:** OpenJDK `17.0.12`
  * **Android Compile SDK:** `36` (hoặc `flutter.compileSdkVersion`)
  * **Android Min SDK:** `21` (Hỗ trợ 99.5% thiết bị Android đang lưu hành)
  * **Android Target SDK:** `34` (Android 14)
  * **MultiDex:** `true` (Đã kích hoạt trong `defaultConfig`)
  * **Gradle Plugin / Kotlin:** `AGP 9.0.1` / Kotlin `2.3.20` kết hợp `kotlin.incremental=false`

---

## 2. 🏗️ TÓM TẮT KIẾN TRÚC HIỆN TẠI (CURRENT ARCHITECTURE SUMMARY)

Dự án áp dụng mô hình chuẩn **Feature-First Clean Architecture**, cấu trúc thư mục hiện tại gồm 6 phân hệ cốt lõi:

| Phân hệ / Module | Đường dẫn | Trạng thái | Lưu trữ / Công nghệ |
|---|---|:---:|---|
| **Core & Design System** | `lib/core/` | ✅ Hoàn thành | Quicksand Google Fonts, AppColors Soft Pastel, AppTheme (Light/Dark) |
| **Cycle Core Engine** | `lib/features/cycle/` | ✅ Hoàn thành | Thuật toán 4 pha sinh học, TableCalendar tùy biến, 1-chạm Toggle ngày kinh |
| **Mood & Micro-logging** | `lib/features/mood/` | ✅ Hoàn thành | 5 mức năng lượng, FilterChips tâm trạng/triệu chứng, fl_chart xu hướng 7 ngày |
| **Nutrition Synced** | `lib/features/nutrition/` | ✅ Hoàn thành | Database dinh dưỡng 4 pha (thực phẩm vàng, món hạn chế, trà thảo mộc, bữa ăn mẫu) |
| **Husband View (Offline)** | `lib/features/husband_view/` | ✅ Hoàn thành | Lời khuyên cho chồng, 3 việc nên làm/tránh, nút 1-chạm sao chép tin nhắn |
| **Partner Sync (Cloud)** | `lib/features/partner_sync/` | ✅ Hoàn thành | Ghép đôi mã PIN 6 ký tự, Stream realtime document `couples/{coupleId}/status/today` |
| **Main Navigation** | `lib/features/home/` | ✅ Hoàn thành | BottomNavigationBar 4 Tab chuyển đổi mượt mà |

### Trạng thái Tích hợp Dữ liệu:
* **Cơ sở dữ liệu cục bộ (Local Hive):**
  * `herflow_cycle_box`: Lưu ngày bắt đầu, độ dài chu kỳ, thời lượng hành kinh và danh sách `PeriodRecord`.
  * `herflow_mood_box`: Lưu nhật ký cảm xúc & triệu chứng thể chất theo từng ngày (`YYYY-MM-DD`).
  * `herflow_settings_box`: Lưu `coupleId`, vai trò người dùng (`wife`/`husband`), và mã `pairingCode`.
* **Cơ sở dữ liệu đám mây (Cloud Firestore):**
  * Đã định nghĩa Schema tối giản: `pairings/{pairingCode}` (hiệu lực 24h) và `couples/{coupleId}/status/today`.
  * Đã tạo tệp cấu hình bảo mật `firestore.rules` tại thư mục gốc.
  * Toàn bộ thao tác Firestore đều được bọc trong khối `try/catch` bắt `FirebaseException` và `PlatformException`, bảo vệ ứng dụng chạy mượt mà kể cả khi mất mạng.

---

## 3. ⚠️ VIỆC CÒN DỞ DANG & RỦI RO (BLOCKERS & INCOMPLETE TASKS)

1. **Tệp cấu hình Firebase Production:**
   * Tệp `android/app/google-services.json` hiện là tệp giả lập (mock template) để phục vụ cho việc build APK không bị lỗi `missing google-services.json`. Khi người dùng muốn kết nối với dự án Firebase Console thực tế của mình, họ cần thay thế bằng tệp thật từ console.firebase.google.com.
2. **Cảnh báo Kotlin Gradle Plugin (KGP) trong `firebase_core`:**
   * Khi build Gradle xuất hiện cảnh báo: `Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP): firebase_core`. Đây là cảnh báo tương thích tương lai từ Flutter SDK mới, hiện tại build APK vẫn hoàn thành 100% không ảnh hưởng runtime.
3. **Mã hóa Hive Box (Encryption at Rest):**
   * Hiện các box Hive đang lưu dưới dạng key-value JSON chưa mã hóa AES. Cần nâng cấp lên `Hive.openBox(..., encryptionCipher: HiveAesCipher(...))` trước khi đưa lên production.

---

## 4. 🎯 KẾ HOẠCH HÀNH ĐỘNG PHIÊN TIẾP THEO (NEXT STEPS)

Khi mở phiên làm việc mới, Agent tiếp theo cần tập trung ngay vào 3 nhiệm vụ ưu tiên sau:

1. **Ưu tiên 1 — Tích hợp Thông Báo Đẩy & Nhắc Nhở Cục Bộ (`flutter_local_notifications`):**
   * Cài đặt thông báo tự động nhắc nhở trước ngày bắt đầu kỳ kinh 1-2 ngày ("Nàng ơi, kỳ kinh dự kiến sẽ bắt đầu sau 2 ngày nữa").
   * Thông báo nhắc nhở uống nước ấm vào buổi sáng và ghi nhận nhật ký thể trạng vào 20:00 tối mỗi ngày.
2. **Ưu tiên 2 — Xuất Báo Cáo Chu Kỳ (Export PDF / Excel):**
   * Cho phép người dùng xuất báo cáo tổng kết 3 chu kỳ gần nhất để mang đi tư vấn với bác sĩ phụ khoa.
3. **Ưu tiên 3 — Hoàn thiện cấu hình iOS (Runner & Firebase iOS):**
   * Bổ sung `GoogleService-Info.plist` mẫu vào thư mục `ios/Runner/` và cấu hình quyền tối thiểu trong `Info.plist` cho iOS build pipeline.

---

## 5. ⚡ LỆNH CHẠY KIỂM THỬ NHANH (QUICK TEST COMMANDS)

Các lệnh shell tiêu chuẩn để kiểm tra toàn vẹn mã nguồn trước khi bàn giao:

```bash
# 1. Kiểm tra phân tích cú pháp tĩnh (Target: 0 issues)
flutter analyze

# 2. Chạy toàn bộ Unit Tests của hệ thống (Target: 100% Pass)
flutter test

# 3. Thử nghiệm biên dịch gói APK Android Debug
flutter build apk --debug

# 4. Kiểm tra mã nguồn chưa được commit
git status
```
