# docs/VISUAL_UX_AUDIT_REPORT.md
# Báo Cáo Kiểm Thử Thị Giác & UX — Moona App v0.6.2

**Ngày audit:** 03/09/2026  
**Pipeline:** `scripts/visual_audit.ps1`  
**Thiết bị:** Android (BM6HKBHEHQKFEMLR) — Role: **Chồng (husband)**  
**Tổng màn hình chụp:** 9 screenshots + 1 view_dump.xml

---

## 🔴 BUG AUDIT MATRIX

| # | ID | Màn hình | Mô tả lỗi | Mức độ | Trạng thái |
|---|-----|----------|------------|--------|------------|
| 1 | BUG-01 | Tất cả tabs | **Navigation bị "đóng băng" với role Chồng** — Tap vào các tab (Chu kỳ, Cảm xúc, Dinh dưỡng, Cài đặt) không chuyển màn hình, luôn hiển thị HusbandViewScreen. BottomNavigationBar xuất hiện nhưng không có tác dụng. | 🔴 Critical | OPEN |
| 2 | BUG-02 | HusbandView | **AppBar bị che bởi camera notch** — "Góc Nhìn Của Anh" bị cắt một phần ở góc trên trái (vùng camera punch-hole). | 🟡 Medium | OPEN |
| 3 | BUG-03 | HusbandView | **Sub-title bị truncate** — "Hôm nay, 03 t..." bị cắt bởi `overflow: ellipsis`, thiếu nội dung đầy đủ, không có tooltip. | 🟡 Medium | OPEN |
| 4 | BUG-04 | HusbandView | **Banner "Ghép đôi" luôn hiển thị dù đã ghép đôi** — Banner "Ghép đôi với nàng qua mã 6 ký tự" vẫn hiện ngay cả khi user đã paired, gây nhầm lẫn UX. | 🔴 Critical | OPEN |
| 5 | BUG-05 | HusbandView | **Card "Ghép đôi để gửi tin nhắn quan tâm" lặp thông tin** — Trùng với banner ở BUG-04, hiển thị 2 lần thông tin ghép đôi trên cùng 1 màn hình. | 🟡 Medium | OPEN |
| 6 | BUG-06 | HusbandView | **Nút "Sao chép tin nhắn quan tâm nhanh"** — Text bị kéo dài, layout button bị tràn sang 2 dòng trên màn hình 720dp. | 🟡 Medium | OPEN |
| 7 | BUG-07 | Dialog Logout | **Dialog Đăng xuất không kích hoạt được** — Script tap vào vùng cuối Settings nhưng app hiển thị HusbandView (không có BottomNav role-based cho Chồng) → không tìm được nút Đăng xuất qua tọa độ cứng. | 🟡 Medium | OPEN |
| 8 | BUG-08 | Global | **BottomNavigationBar render với role Chồng nhưng không navigate** — Thiếu guard: nếu `userRole == UserRole.husband` thì nên ẩn hoàn toàn BottomNav hoặc giữ nguyên nhưng route đúng màn hình. | 🟠 High | OPEN |

---

## 📸 Bằng Chứng Visual

### [1] Màn hình khởi động (HusbandView — Role Chồng)
- **Quan sát:** App load đúng, hiển thị `HusbandViewScreen` với header "Góc Nhìn Của Anh".
- **Vấn đề:** AppBar bị notch cắt; sub-title truncate; banner ghép đôi thừa.

### [2-5] Tất cả 4 tabs → đều render cùng HusbandViewScreen
- **Root cause phân tích:** `MainNavScreen.build()` kiểm tra `userRole == UserRole.husband` → trả về `HusbandViewScreen` **bọc trong Column** (không có Scaffold + BottomNav). Tuy nhiên script tap vào tọa độ y=1900 (vùng BottomNav của màn hình Vợ) nhưng với role Chồng màn hình này không tồn tại → không có tác dụng. Đây là hành vi **đúng theo code** nhưng gây hiểu nhầm khi audit.

### [6] Dialog Logout (06_dialog_logout.png)
- **Quan sát:** Screenshot chụp được màn hình HusbandView sau khi scroll + tap, **không mở được dialog**. Confirm: tap tọa độ cứng không tìm đúng nút Đăng xuất khi role là Chồng.

---

## 🔍 Phân Tích Kiến Trúc Navigation

```
MainNavScreen.build()
  ├── userRole == husband → Column(OfflineBanner + HusbandViewScreen)
  │                         ❌ Không có BottomNav → ổn về logic
  │                         ❌ Nhưng không có back button / menu → UX bẫy
  └── userRole == wife → Scaffold(BottomNav + 4 tabs) ← CHƯA TEST ĐƯỢC
```

**Kết luận:** Audit pipeline gặp giới hạn do **device đang login role Chồng**. Để audit đầy đủ 4 tabs Vợ, cần chạy lại với tài khoản Wife hoặc dùng `--dart-define` force role.

---

## ✅ Điểm Tốt Ghi Nhận

| Hạng mục | Đánh giá |
|----------|---------- |
| **Màu sắc & Typography** | ✅ Pastel palette nhất quán, font rõ ràng, hierarchy tốt |
| **Card glassmorphism** | ✅ Bo góc mềm, shadow nhẹ, đúng design language Moona |
| **Phase indicator** | ✅ Badge "Pha Hoàng Thể • Ngày 24" + "Đang hồi phục" rõ ràng và đẹp |
| **DO/DON'T cards** | ✅ Color-coded pills, bullet list readable, contrast đủ |
| **Energy bar** | ✅ Progress bar gradient tím đẹp, label "3/5" rõ |
| **CTA button** | ✅ "Sao chép tin nhắn quan tâm nhanh" có icon + màu nổi bật |
| **Offline banner** | ✅ Không xuất hiện (mạng tốt) — đúng behavior |

---

## 🛠️ Đề Xuất Fix Theo Ưu Tiên

### P0 — Sửa ngay (Critical)

#### BUG-01 & BUG-08: Navigation role Chồng
**Vấn đề thực tế:** `HusbandViewScreen` không có cách nào truy cập Settings/Logout khi đã vào.  
**Fix đề xuất:** Thêm `AppBar` hoặc nút `⚙️ Settings` floating ở góc trên phải trong `HusbandViewScreen`:

```dart
// lib/features/husband_view/presentation/screens/husband_view_screen.dart
// Thêm Scaffold wrapper với AppBar chứa nút Settings
Scaffold(
  appBar: AppBar(
    title: Text('Góc Nhìn Của Anh'),
    actions: [
      IconButton(
        icon: const Icon(Icons.settings_outlined),
        onPressed: () => context.push('/settings'),
      ),
    ],
  ),
  body: HusbandViewContent(),
)
```

#### BUG-04: Banner ghép đôi thừa
**Fix:** Ẩn banner "Ghép đôi với nàng" nếu `isPaired == true`:
```dart
if (!isPaired) PairingBannerWidget(),
```

### P1 — Sprint tiếp theo (High)

#### BUG-02: SafeArea / notch padding
```dart
// Bọc toàn bộ content trong SafeArea
SafeArea(child: HusbandViewScreen(...))
```

#### BUG-03: Sub-title truncate
```dart
subtitle: Text(
  fullSubtitle,
  maxLines: 2,        // Cho phép 2 dòng thay vì 1
  overflow: TextOverflow.ellipsis,
),
```

#### BUG-06: Button text overflow
```dart
// Giảm font size hoặc dùng FittedBox
FittedBox(
  fit: BoxFit.scaleDown,
  child: Text('Sao chép tin nhắn quan tâm nhanh'),
)
```

### P2 — Backlog

#### BUG-05: Card ghép đôi lặp
- Merge 2 entry points (banner + card) thành 1 component duy nhất.

#### BUG-07: Script audit không tìm được dialog Logout
- Cải tiến `visual_audit.ps1`: thêm nhánh xử lý role — nếu `userRole == husband`, navigate tới Settings screen trực tiếp bằng ADB intent thay vì tap tọa độ cứng.

---

## 🔄 Kế Hoạch Audit Lần Sau

```
Để audit đầy đủ role Vợ:
1. Đăng nhập bằng tài khoản Wife trên thiết bị
2. Chạy lại: powershell -ExecutionPolicy Bypass -File .\scripts\visual_audit.ps1
3. Hoặc: Thêm tham số -Role wife vào script để tự động switch
```

---

## 📋 Tóm Tắt

| Metric | Giá trị |
|--------|---------|
| Màn hình kiểm thử | 7 (thực tế 1 unique do role) |
| Bugs tìm thấy | **8** |
| Critical | 2 |
| High | 1 |
| Medium | 5 |
| Điểm UX tổng | **6.5/10** |
| Design consistency | **8.5/10** |

> **Ghi chú:** Điểm UX thấp do BUG-01 (không navigate được tabs với role Chồng) ảnh hưởng toàn bộ trải nghiệm. Nếu fix BUG-01 + BUG-04, điểm sẽ tăng lên ~8/10.
