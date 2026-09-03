# 🌙 Moona — Trợ Lý Chu Kỳ Sinh Học & Kết Nối Yêu Thương Cặp Đôi

> **Phiên bản hiện tại:** `v0.5.2+12`  
> **Chu Kỳ • Cảm Xúc • Dinh Dưỡng Đồng Bộ • Kết Nối Người Thương**  
> Xây dựng trên nền tảng **Flutter (Dart)** hỗ trợ cả Android và iOS theo chuẩn **Feature-First Clean Architecture**, quản lý trạng thái bằng **Riverpod 2.x**, kết nối đồng bộ thời gian thực qua **Cloud Firestore** và lưu trữ cục bộ bảo mật ngoại tuyến bằng **Hive**.

---

## 📱 Giới Thiệu Ứng Dụng Moona

**Moona** là ứng dụng chăm sóc chu kỳ sinh học và sức khỏe phụ nữ hiện đại, đồng thời là cầu nối cảm xúc giúp hai người thấu hiểu và gắn kết bền chặt hơn mỗi ngày.

### ✨ Điểm Nổi Bật
* **Theo dõi 4 pha sinh học chu kỳ:** Thuật toán phân tích chính xác từng giai đoạn (Kinh nguyệt, Nang trứng, Rụng trứng, Hoàng thể) kèm dự báo cửa sổ thụ thai và cảnh báo sớm hội chứng tiền kinh nguyệt (PMS).
* **Động cơ dinh dưỡng & thể trạng:** Gợi ý thực phẩm, trà thảo mộc và chế độ tập luyện phù hợp với từng pha nội tiết tố.
* **Góc Nhìn Người Thương (Husband View):** Màn hình chuyên biệt dành riêng cho chàng với nhiệt kế cảm xúc của nàng, cẩm nang Gentleman's Playbook (việc nên làm & nên tránh) và thẻ tóm tắt chu kỳ.
* **Modal Chat Nhanh & Vòng lặp phản hồi 1 chạm:** Chàng chủ động gửi câu hỏi thăm thích ứng theo thể trạng nàng; Nàng phản hồi nhanh 1 chạm (🥺 Mệt mỏi, 🧋 Thèm trà sữa, 🥰 Khỏe re, 🛌 Đang nghỉ) đồng bộ realtime.
* **Hệ thống danh xưng linh hoạt (Nickname Engine):** Tùy chỉnh danh xưng thân mật giữa hai người với 7 preset phổ biến và ô nhập riêng, đồng bộ toàn diện trên mọi màn hình.
* **Đăng nhập Google & Phân vai trò linh hoạt:** Hỗ trợ đăng nhập Google Auth an toàn, luồng chọn vai trò Onboarding thanh thoát và chế độ Chàng tự thiết lập chu kỳ độc lập khi nàng chưa dùng app.

---

## 🏗️ Kiến Trúc Hệ Thống (Feature-First Clean Architecture)

```
lib/
├── core/                               # Thành phần dùng chung toàn ứng dụng
│   ├── constants/
│   │   ├── app_colors.dart             # Bảng màu Soft Pastel (Hồng hoa hồng, tím đêm, mint, lavender)
│   │   ├── app_constants.dart          # Cấu hình Box Hive, chu kỳ mặc định
│   │   └── cycle_phase.dart            # Định nghĩa 4 pha sinh học chu kỳ kinh nguyệt
│   ├── theme/
│   │   ├── app_theme.dart              # Theme Light / Dark mode chuẩn Soft Pastel
│   │   └── theme_controller.dart       # Quản lý chuyển đổi theme
│   ├── routes/                         # Cấu hình định tuyến
│   ├── notifications/                  # Thông báo cục bộ & kênh cảnh báo PMS ưu tiên cao
│   ├── utils/                          # AppHaptics, AppDateUtils
│   └── widgets/                        # MoonaBrandLogo (Logo đĩa tròn vầng trăng khuyết)
│
├── features/                           # Phân hệ tính năng độc lập (Feature-First)
│   ├── auth/                           # Google Sign-In, Firebase Auth, BiometricLockScreen
│   ├── care_signals/                   # Tín hiệu yêu thương 2 chiều & Banner tương tác
│   ├── cycle/                          # CycleCalendarView, CycleHeroIndicator, DayDetailCard
│   ├── husband_view/                   # Góc nhìn của Chàng, HusbandQuickChatSheet
│   ├── mood/                           # Nhật ký cảm xúc 1 chạm, fl_chart xu hướng năng lượng
│   ├── nutrition/                      # Dinh dưỡng đồng bộ theo 4 pha sinh học
│   ├── onboarding/                     # RoleSelectionScreen (Compact ListTile ~100-110dp)
│   ├── partner_sync/                   # Ghép đôi Firestore, bộ đệm Hive ngoại tuyến
│   ├── settings/                       # Profile, Nickname Engine, Hiệu chỉnh chu kỳ người thương
│   └── home/                           # MainNavScreen (Điều hướng theo vai trò)
│
└── main.dart                           # Khởi tạo Hive, Firebase và App Root
```

---

## 🩸 4 Pha Sinh Học Chu Kỳ Trong Moona

1. **Pha Hành Kinh (Menstrual Phase - Ngày 1..5):**
   * *Đặc điểm:* Hormone estrogen và progesterone ở mức đáy, cơ thể cần nghỉ ngơi và nạp lại năng lượng.
   * *Màu sắc:* Hồng dâu trầm (`#E26D80`).
   * *Dinh dưỡng:* Món ấm nóng, giàu chất sắt (thịt bò, canh rong biển, rau bina), trà gừng mật ong.
2. **Pha Nang Trứng (Follicular Phase - Ngày 6..12):**
   * *Đặc điểm:* Estrogen tăng dần, năng lượng dồi dào, tinh thần lạc quan, sáng tạo và tự tin.
   * *Màu sắc:* Cam đào pastel (`#F5A384`).
   * *Dinh dưỡng:* Bông cải xanh, sữa chua Hy Lạp, bơ, hạt chia, trà xanh Matcha.
3. **Pha Rụng Trứng (Ovulation Phase - Ngày 13..15):**
   * *Đặc điểm:* Đỉnh điểm năng lượng, nhiệt độ cơ thể tăng nhẹ, khả năng thụ thai cao nhất.
   * *Màu sắc:* Xanh ngọc mint (`#67B99A`).
   * *Dinh dưỡng:* Tôm hải sản giàu kẽm, măng tây, quả mọng, nước dừa tươi.
4. **Pha Hoàng Thể (Luteal Phase - Ngày 16..28):**
   * *Đặc điểm:* Progesterone chiếm ưu thế, hội chứng tiền kinh nguyệt (PMS), dễ thèm ngọt, mệt mỏi, tích nước.
   * *Màu sắc:* Tím thạch anh lavender (`#A58BC7`).
   * *Dinh dưỡng:* Chocolate đen nguyên chất, khoai lang nướng, thực phẩm giàu Magie & B6, trà hoa cúc/oải hương.

---

## 🛠️ Công Nghệ & Thư Viện Sử Dụng

* **Nền tảng:** Flutter 3.x (Dart 3.x)
* **Quản lý trạng thái:** `flutter_riverpod: ^2.6.1`
* **Xác thực & Cơ sở dữ liệu đám mây:** `firebase_core`, `firebase_auth`, `cloud_firestore`, `google_sign_in`
* **Cơ sở dữ liệu cục bộ (Offline-first):** `hive: ^2.2.3`, `hive_flutter: ^1.1.0`
* **Bảo mật sinh trắc học & Mã hóa:** `local_auth: ^2.3.0`, `encrypt: ^5.0.3` (AES-256-CBC)
* **Lịch & Biểu đồ:** `table_calendar: ^3.2.1`, `fl_chart: ^1.2.0`
* **Thông báo:** `flutter_local_notifications: ^18.0.1`, `timezone: ^0.10.0`
* **Typography:** `google_fonts: ^8.2.1` (Quicksand)
* **Xử lý ngày tháng:** `intl: ^0.20.3` (Hỗ trợ tiếng Việt)

---

## 🚀 Hướng Dẫn Kiểm Thử & Triển Khai

### 1. Kiểm tra mã nguồn tĩnh (Linter)
```bash
flutter analyze
```
*(Kết quả: 0 issues found!)*

### 2. Chạy kiểm thử tự động (Unit Tests)
```bash
flutter test
```
*(Kết quả: 20/20 tests passed 100%!)*

### 3. Build & Deploy tự động đa thiết bị
Sử dụng script PowerShell tự động kiểm tra cú pháp, build APK và cài đặt đồng thời lên tất cả thiết bị kết nối qua ADB:
```powershell
# Deploy lên toàn bộ thiết bị (Physical + Emulator)
.\scripts\deploy.ps1 -Target all

# Deploy chỉ định thiết bị vật lý
.\scripts\deploy.ps1 -Target physical

# Build và nạp bản Release
.\scripts\deploy.ps1 -Mode release -Target all
```
File APK hoàn chỉnh được xuất tại: `build/app/outputs/flutter-apk/app-debug.apk` hoặc `app-release.apk`.
