# 🌸 HerFlow — Ứng Dụng Theo Dõi Chu Kỳ & Sức Khỏe Phụ Nữ

> **Chu Kỳ • Cảm Xúc • Dinh Dưỡng Đồng Bộ • Góc Nhìn Yêu Thương**  
> Xây dựng trên nền tảng **Flutter (Dart)** hỗ trợ cả Android và iOS theo chuẩn **Feature-First Clean Architecture**, quản lý trạng thái bằng **Riverpod 2.x** và lưu trữ dữ liệu ngoại tuyến bảo mật bằng **Hive**.

---

## 📱 Giới Thiệu Dự Án

**HerFlow** là người bạn đồng hành tinh tế giúp phụ nữ thấu hiểu cơ thể mình qua từng giai đoạn sinh học. Không chỉ dừng lại ở việc dự đoán ngày đèn đỏ, HerFlow kết nối sâu sắc giữa **4 pha chu kỳ**, **dao động cảm xúc/năng lượng** và **chế độ dinh dưỡng tối ưu**, đồng thời mang đến tính năng độc đáo **"Góc Nhìn Của Anh (Husband View)"** giúp người bạn đời thấu hiểu và chăm sóc nàng đúng lúc.

---

## 🏗️ Kiến Trúc Hệ Thống (Feature-First Clean Architecture)

```
lib/
├── core/                               # Thành phần dùng chung toàn ứng dụng
│   ├── constants/
│   │   ├── app_colors.dart             # Bảng màu Soft Pastel (Hồng ấm, kem, tím lavender, mint)
│   │   ├── app_constants.dart          # Cấu hình Box Hive, chu kỳ mặc định
│   │   └── cycle_phase.dart            # Định nghĩa 4 pha sinh học chu kỳ kinh nguyệt
│   ├── theme/
│   │   └── app_theme.dart              # Theme Light / Dark mode chuẩn Soft Pastel
│   ├── routes/
│   │   └── app_routes.dart             # Cấu hình định tuyến màn hình
│   └── utils/
│       └── date_utils.dart             # Tiện ích xử lý ngày tháng tiếng Việt
│
├── features/                           # Phân hệ tính năng độc lập (Feature-First)
│   ├── cycle/                          # Phân hệ Chu Kỳ Sinh Học (Bước 1)
│   │   ├── domain/                     # Pure Dart: CycleInfo entity, CycleRepository
│   │   ├── data/                       # Hive DataSource, CycleRepositoryImpl
│   │   └── presentation/               # CycleScreen, TableCalendar 4 pha, CycleController
│   │
│   ├── mood/                           # Phân hệ Nhật Ký Cảm Xúc & Thể Trạng (Bước 2)
│   │   ├── domain/                     # MoodEntry entity, MoodRepository
│   │   ├── data/                       # MoodLocalDataSource, MoodRepositoryImpl
│   │   └── presentation/               # MoodScreen, Bảng 1-chạm 5 mức năng lượng, fl_chart
│   │
│   ├── nutrition/                      # Phân hệ Dinh Dưỡng Đồng Bộ Chu Kỳ (Bước 3)
│   │   ├── domain/                     # NutritionRecommendation entity, NutritionRepository
│   │   ├── data/                       # NutritionLocalDataSource (Database 4 pha)
│   │   └── presentation/               # NutritionScreen, Thẻ gợi ý thực phẩm & trà thảo mộc
│   │
│   ├── husband_view/                   # Phân hệ Góc Nhìn Yêu Thương Cho Chồng (Bước 4)
│   │   └── presentation/               # HusbandViewScreen, Hành động nên làm/tránh, nút Copy SMS
│   │
│   └── home/                           # Khung điều hướng chính (BottomNavigationBar 4 Tab)
│       └── presentation/               # MainNavScreen
│
└── main.dart                           # Khởi tạo Hive, ProviderScope và App Root
```

---

## 🩸 4 Pha Sinh Học Chu Kỳ Trong HerFlow

1. **Pha Hành Kinh (Menstrual Phase - Ngày 1..5):**
   * *Đặc điểm:* Hormone thấp, cơ thể cần nghỉ ngơi.
   * *Màu sắc:* Hồng dâu trầm (`#E26D80`).
   * *Dinh dưỡng:* Món ấm nóng, giàu chất sắt (thịt bò, canh rong biển, rau bina), trà gừng mật ong.
2. **Pha Nang Trứng (Follicular Phase - Ngày 6..12):**
   * *Đặc điểm:* Estrogen tăng dần, năng lượng dồi dào, tinh thần lạc quan và sáng tạo.
   * *Màu sắc:* Cam đào pastel (`#F5A384`).
   * *Dinh dưỡng:* Bông cải xanh, sữa chua Hy Lạp, bơ, hạt chia, trà xanh Matcha.
3. **Pha Rụng Trứng (Ovulation Phase - Ngày 13..15):**
   * *Đặc điểm:* Đỉnh điểm năng lượng, khả năng thụ thai cao nhất.
   * *Màu sắc:* Xanh ngọc mint (`#67B99A`).
   * *Dinh dưỡng:* Tôm hải sản giàu kẽm, măng tây, quả mọng, nước dừa tươi.
4. **Pha Hoàng Thể (Luteal Phase - Ngày 16..28):**
   * *Đặc điểm:* Progesterone chiếm ưu thế, hội chứng tiền kinh nguyệt (PMS), dễ thèm ngọt, tích nước.
   * *Màu sắc:* Tím thạch anh lavender (`#A58BC7`).
   * *Dinh dưỡng:* Chocolate đen nguyên chất, khoai lang nướng, thực phẩm giàu Magie & B6, trà hoa oải hương.

---

## 🛠️ Công Nghệ Sử Dụng

* **Ngôn ngữ:** Dart 3.x / Flutter 3.x
* **Quản lý trạng thái:** `flutter_riverpod: ^2.6.1`
* **Cơ sở dữ liệu cục bộ (Offline-first):** `hive: ^2.2.3`, `hive_flutter: ^1.1.0`
* **Hiển thị lịch & biểu đồ:** `table_calendar: ^3.2.1`, `fl_chart: ^1.2.0`
* **Typography & Thiết kế:** `google_fonts: ^8.2.1` (Quicksand Font)
* **Xử lý ngày & Bản địa hóa:** `intl: ^0.20.3` (Hỗ trợ tiếng Việt đầy đủ)

---

## 🚀 Hướng Dẫn Chạy & Build

### 1. Kiểm tra mã nguồn tĩnh (Linter)
```bash
flutter analyze
```
*(Kết quả: 0 issues found!)*

### 2. Chạy kiểm thử tự động (Unit Tests)
```bash
flutter test
```
*(Kết quả: 5/5 tests passed!)*

### 3. Chạy ứng dụng trên thiết bị / Máy ảo
```bash
flutter run
```

### 4. Đóng gói file APK cài đặt
```bash
# Build bản debug APK thử nghiệm
flutter build apk --debug

# Build bản tối ưu nhẹ theo kiến trúc chip (khuyên dùng để cài lên điện thoại)
flutter build apk --split-per-abi
```
File APK hoàn chỉnh được xuất tại: `build/app/outputs/flutter-apk/app-debug.apk`.

---

## 📋 Lộ Trình Triển Khai (Roadmap Status)

- [x] **Bước 1:** Thiết lập Engine chu kỳ (Cycle Core Engine, thuật toán 4 pha, TableCalendar trang trí theo pha).
- [x] **Bước 2:** Hệ thống ghi nhận cảm xúc & thể trạng (Micro-logging 1-chạm, lưu Hive, biểu đồ fl_chart).
- [x] **Bước 3:** Đề xuất dinh dưỡng đồng bộ chu kỳ (Cycle-Synced Food Database, thẻ gợi ý theo pha).
- [x] **Bước 4:** Husband View (Góc nhìn yêu thương, tóm tắt thể trạng, hành động nên làm/tránh, 1-Click Copy).
- [x] **Bước 5:** Build và xuất file APK thành công (`app-debug.apk` 0 lỗi).
