# 📋 BÁO CÁO BÀN GIAO CA (HANDOVER.md) — DỰ ÁN MOONA

> **Phiên bản hiện tại:** `v0.5.2+12` (Clean State Ready For Commit)  
> **Thời điểm cập nhật:** 03/09/2026 — Hoàn tất tự rà soát an ninh, dọn dẹp mã nguồn & đồng bộ tài liệu  
> **Kỹ sư phụ trách:** Senior Mobile Flutter Engineer (AI Pair Programmer)  

---

## ✅ 1. TRẠNG THÁI HIỆN TẠI (CURRENT STATE CHECKPOINT)

| Hạng mục | Kết quả kiểm toán | Ghi chú kỹ thuật |
|---|:---:|---|
| **Static Analysis (`flutter analyze`)** | ✅ **0 issues found!** | Toàn bộ codebase sạch 100%, 0 errors, 0 warnings |
| **Unit Testing (`flutter test`)** | ✅ **20/20 tests PASSED** | Đạt 100% pass, bao gồm test serialization `CareSignalModel` mới |
| **Xác thực Google Sign-In & Firebase Auth** | ✅ **HOÀN TẤT** | Hỗ trợ Google Sign-In thật và Demo Mode dự phòng |
| **Role Onboarding & Chu kỳ độc lập** | ✅ **HOÀN TẤT** | Thẻ chọn vai trò dạng ngang nhỏ gọn (~100-110dp); Chàng tự lập chu kỳ |
| **Động cơ danh xưng (Nickname Engine)** | ✅ **HOÀN TẤT** | 7 Presets + Tự nhập, đồng bộ Firestore và Live Preview đối thoại |
| **Modal Chat Nhanh (`HusbandQuickChatSheet`)** | ✅ **HOÀN TẤT** | Gợi ý thông minh thích ứng 4 pha chu kỳ & ô nhập tin nhắn tự do |
| **Vòng lặp phản hồi 1 chạm (Wife Banner)** | ✅ **HOÀN TẤT** | 4 nút phản hồi nhanh (🥺, 🧋, 🥰, 🛌) đồng bộ tức thì sang máy Chồng |
| **Đồng bộ Launcher Icon Moona** | ✅ **HOÀN TẤT** | Logo vầng trăng khuyết vàng trên đĩa tròn gradient hồng-tím (`android: true`) |
| **Độ ổn định Runtime (R8 ProGuard Fix)** | ✅ **HOÀN TẤT** | Tắt minifyEnabled an toàn, loại bỏ triệt để lỗi crash `WorkDatabase` |
| **Kiểm toán bảo mật & rò rỉ dữ liệu** | ✅ **PASSED** | `.gitignore` bảo vệ đầy đủ, không hardcode secrets, không in PII |
| **Deploy thử nghiệm thực tế** | ✅ **SUCCESS** | Nạp và chạy mượt mà trên thiết bị qua `scripts/deploy.ps1 -Target all` |

---

## 2. 💡 BÀI HỌC KINH NGHIỆM & CÁC LỖI KỸ THUẬT ĐÃ GIẢI QUYẾT

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

---

## 3. 🏗️ KIẾN TRÚC & PHÂN HỆ TÍNH NĂNG CHÍNH

```
lib/
├── core/                               # Nền tảng chia sẻ
│   ├── constants/                      # AppColors, AppConstants, CyclePhase
│   ├── notifications/                  # NotificationService (Kênh PMS ưu tiên cao)
│   ├── routes/                         # AppRoutes
│   ├── theme/                          # AppTheme (Soft Pastel Light/Dark), ThemeController
│   ├── utils/                          # AppHaptics, AppDateUtils
│   └── widgets/                        # MoonaBrandLogo (Reusable brand asset)
│
└── features/                           # Clean Architecture (Feature-First)
    ├── auth/                           # Google Sign-In, Firebase Auth, BiometricLockScreen
    ├── care_signals/                   # CareSignalModel, Realtime 2-way Signals
    ├── cycle/                          # CycleCalendarView, CycleHeroIndicator, DayDetailCard
    ├── home/                           # MainNavScreen (Role-based Navigation)
    ├── husband_view/                   # Gentleman's Playbook, HusbandQuickChatSheet
    ├── mood/                           # Mood & Energy micro-logging, 7-day trend chart
    ├── nutrition/                      # Đồng bộ dinh dưỡng theo 4 pha sinh học
    ├── onboarding/                     # RoleSelectionScreen (Compact ListTile), Wizard
    ├── partner_sync/                   # PairingScreen, PartnerSyncRepository
    └── settings/                       # Profile, Nickname Engine, Partner Cycle Editor
```

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
