# 🗺️ BẢN ĐỒ NGHIỆP VỤ & MA TRẬN PHÂN QUYỀN TOÀN DỰ ÁN (MOONA BUSINESS MATRIX)

> **Tài liệu quy chuẩn kiến trúc & nghiệp vụ cốt lõi (Source of Truth)**  
> **Dự án:** Moona (HerFlow) — Ứng dụng theo dõi chu kỳ & đồng hành cặp đôi  
> **Áp dụng cho:** Tất cả AI Coding Agents, Kỹ sư Mobile Flutter, Reviewers  
> **Ngày phê duyệt:** 03/09/2026 — Phiên bản v1.0.0  

---

## 🎯 1. NGUYÊN TẮC BẤT DI BẤT DỊCH (NON-NEGOTIABLE ARCHITECTURAL DIRECTIVES)

1. **RÀNG BUỘC BẢN ĐỒ NGHIỆP VỤ (MATRIX COMPLIANCE):**
   - Trước khi thêm tính năng, sửa bug hoặc refactor bất kỳ controller/UI nào, BẮT BUỘC đối chiếu với tài liệu này (`docs/APP_BUSINESS_MATRIX.md`).
   - Mọi thay đổi không được vượt quá quyền hạn (Permission Scope) được định nghĩa trong ma trận phân quyền.

2. **CÔ LẬP VAI TRÒ TUYỆT ĐỐI (ROLE ISOLATION & ZERO REGRESSION):**
   - Tuyệt đối không để xảy ra tình trạng sửa UI/Logic tab của **Chồng** làm gãy luồng của **Vợ**, hoặc ngược lại.
   - Các màn hình chia sẻ (Shared Screens như `MoodScreen`, `NutritionScreen`, `SettingsScreen`) phải kiểm tra `userRoleProvider` để hiển thị chế độ Đọc/Ghi/Gợi ý hành vi phù hợp.

3. **TOÀN VẸN ĐA TÀI KHOẢN (USER-SCOPED STORAGE INTEGRITY):**
   - Mọi key lưu trữ trong Hive Box (`settingsBox`, `cycleBox`, `moodBox`) liên quan đến tài khoản cá nhân BẮT BUỘC phải đi qua `UserScope.key(baseKey, uid)`.
   - Khi chuyển tài khoản hoặc đăng xuất, BẮT BUỘC dọn sạch RAM State tree và thiết lập `UserScope.setActiveUid()`.

4. **ĐỒNG BỘ 2 CHIỀU ĐỐI XỨNG (BI-DIRECTIONAL SYNC INTEGRITY):**
   - Dữ liệu cặp đôi (`couples/{coupleId}`) phải được thiết kế đối xứng 4 trường cho danh xưng, trạng thái live status và tín hiệu phản hồi chăm sóc (`CareSignalModel`).

---

## 🧭 2. CẤU TRÚC ĐIỀU HƯỚNG TỔNG THỂ (NAVIGATION MAP — MAIN NAV SCREEN)

Hệ thống điều hướng cấp cao nhất (`MainNavScreen`) sử dụng 2 cây giao diện hoàn toàn độc lập dựa trên `userRoleProvider`:

```
                                  [ MainNavScreen ]
                                          │
                  ┌───────────────────────┴───────────────────────┐
                  ▼                                               ▼
         Role VỢ (UserRole.wife)                     Role CHỒNG (UserRole.husband)
   ┌───────────────────────────────┐               ┌───────────────────────────────┐
   │ Tab 0: Chu kỳ (CycleScreen)   │               │ Tab 0: Trang chủ Chồng        │
   │ Tab 1: Cảm xúc (MoodScreen)   │               │        (HusbandViewScreen)    │
   │ Tab 2: Dinh dưỡng             │               │ Tab 1: Cảm xúc nàng           │
   │        (NutritionScreen)      │               │        (MoodScreen - RO View) │
   │ Tab 3: Cài đặt                │               │ Tab 2: Dinh dưỡng chăm sóc    │
   │        (SettingsScreen)       │               │        (NutritionScreen)      │
   └───────────────────────────────┘               │ Tab 3: Cài đặt                │
                                                   │        (SettingsScreen)       │
                                                   └───────────────────────────────┘
```

### Chi tiết 4 Tab theo từng Role

| Index | Role VỢ (`UserRole.wife`) | Role CHỒNG (`UserRole.husband`) | Hành vi tương tác & Phân quyền |
|:---:|---|---|---|
| **Tab 0** | **Chu kỳ (`CycleScreen`)**<br>• Calendar 4 pha sinh học<br>• Hero Indicator & Vòng tròn chu kỳ<br>• Nút ghi nhận ngày kinh (`LogPeriodModal`)<br>• Cài đặt chu kỳ cá nhân | **Trang chủ (`HusbandViewScreen`)**<br>• Thấu hiểu pha chu kỳ nàng hôm nay<br>• Mức năng lượng & tâm trạng realtime<br>• Banner trạng thái ghép đôi (Live Status)<br>• Cẩm nang "Nên làm ngay / Điều cấm kỵ"<br>• Quick Action gửi tin nhắn/tín hiệu | **Vợ:** RW (Ghi đè, sửa đổi, cập nhật ngày kinh)<br>**Chồng:** RO + Care Actions (Xem thông điệp, copy tin nhắn gợi ý, gửi Care Signal) |
| **Tab 1** | **Cảm xúc (`MoodScreen`)**<br>• Micro-logging năng lượng (1-5)<br>• Chọn tâm trạng & triệu chứng cơ thể<br>• Biểu đồ xu hướng năng lượng 7 ngày | **Cảm xúc nàng (`MoodScreen`)**<br>• Chế độ hiển thị nhật ký thể trạng nàng<br>• Theo dõi mức pin năng lượng & tâm lý<br>• Xem các triệu chứng nàng đang gặp phải | **Vợ:** RW (Ghi nhật ký cảm xúc hàng ngày)<br>**Chồng:** RO (Theo dõi trạng thái để ứng xử tế nhị, không tự ghi đè tâm trạng của nàng) |
| **Tab 2** | **Dinh dưỡng (`NutritionScreen`)**<br>• Gợi ý ăn uống theo 4 pha chu kỳ<br>• Thực phẩm nên bổ sung / nên tránh<br>• Cẩm nang phục hồi sinh học cho nàng | **Cẩm nang chăm sóc (`NutritionScreen`)**<br>• Gợi ý món ăn / thức uống nên mua cho nàng<br>• Danh mục thực phẩm xoa dịu cơn đau<br>• Tuyệt chiêu nấu nướng & chăm sóc | **Vợ:** RO (Xem cẩm nang dinh dưỡng tự chăm sóc)<br>**Chồng:** RO + Care Prep (Xem gợi ý mua đồ ăn, pha trà ấm cho vợ) |
| **Tab 3** | **Cài đặt (`SettingsScreen`)**<br>• Hồ sơ cá nhân & Đổi vai trò<br>• Danh xưng 2 chiều (`NicknameController`)<br>• Trạng thái ghép đôi (`PairingScreen`)<br>• Sao lưu / Khôi phục (.moona AES)<br>• Cài đặt thông số chu kỳ cá nhân<br>• Đăng xuất | **Cài đặt (`SettingsScreen`)**<br>• Hồ sơ cá nhân & Đổi vai trò<br>• Danh xưng 2 chiều (`NicknameController`)<br>• Trạng thái ghép đôi (`PairingScreen`)<br>• Sao lưu / Khôi phục (.moona AES)<br>• Hiệu chỉnh chu kỳ ước tính của nàng<br>• Đăng xuất | **Cả hai:** RW cho profile cá nhân, danh xưng, ghép đôi và bảo mật sinh trắc học |

---

## 📊 3. MA TRẬN PHÂN QUYỀN DỮ LIỆU CỐT LÕI (DATA ACCESS & PERMISSION MATRIX)

| Miền Dữ Liệu (Domain) | Thực thể / Trường Dữ Liệu | Quyền của VỢ | Quyền của CHỒNG | Nơi Lưu Trữ (Storage Layer) | Phạm Vi Đồng Bộ (Sync Scope) |
|---|---|:---:|:---:|---|---|
| **Chu kỳ (Cycle)** | Ngày bắt đầu/kết thúc kinh nguyệt | **RW** | **RO** | Hive `cycle_records_box` (Cục bộ Vợ) | Không đẩy chi tiết lên Cloud (Bảo vệ riêng tư) |
| | Độ dài chu kỳ (21-45), hành kinh (2-10) | **RW** | **RO (Ước tính)** | Hive `settings_box` | Đồng bộ tóm tắt khi ghép đôi |
| | Pha chu kỳ hiện tại (4 pha) | **RW** | **RO** | Tính toán từ chu kỳ cục bộ | Đẩy tên pha lên `couples/{id}` (Live Status) |
| | Lịch sử chu kỳ chi tiết qua các tháng | **RW** | **None** | Hive cục bộ Vợ | Tuyệt đối không chia sẻ |
| **Cảm xúc (Mood)** | Mức năng lượng (1-5) hôm nay | **RW** | **RO** | Hive `mood_records_box` + Firestore | Đồng bộ realtime lên Live Status |
| | Thẻ tâm trạng (Thư thái, cáu gắt...) | **RW** | **RO** | Hive `mood_records_box` + Firestore | Đồng bộ realtime lên Live Status |
| | Triệu chứng thể chất (Đau bụng, mụn...) | **RW** | **RO** | Hive `mood_records_box` | Hiển thị tóm tắt cho Chồng |
| | Ghi chú nhật ký riêng tư (Notes) | **RW** | **None** | Hive `mood_records_box` (AES Encrypted) | Cục bộ 100%, không đồng bộ |
| **Tín hiệu (Signals)** | Gửi yêu cầu chăm sóc (Ôm, Trà, Snuggle) | **RW (Tạo)** | **RO (Nhận)** | Firestore `couples/{id}/signals` | Realtime 2 chiều |
| | Phản hồi tín hiệu ("Anh đang đến đây") | **RO (Nhận)** | **RW (Gửi)** | Firestore `couples/{id}/signals` | Realtime 2 chiều |
| | Gửi tin nhắn hỏi thăm nhanh | **RO (Nhận)** | **RW (Gửi)** | Firestore `couples/{id}/signals` | Realtime 2 chiều |
| **Danh xưng (Nicknames)** | Mình gọi bạn ấy là gì (`callPartnerAs`) | **RW** | **RW** | Hive `settings_box` + Firestore | Realtime 2 chiều (Perspective Mapping) |
| | Mình tự xưng là gì (`selfCallAs`) | **RW** | **RW** | Hive `settings_box` + Firestore | Realtime 2 chiều (Perspective Mapping) |
| **Ghép đôi (Pairing)** | Sinh mã 6 ký tự kết nối | **RW (Host)** | **None** | Firestore `pairings/{code}` (TTL 24h) | Tạm thời phục vụ ghép đôi |
| | Quét/Nhập mã ghép đôi | **None** | **RW (Client)**| Firestore `pairings/{code}` | Kích hoạt tạo Document `couples/{id}` |
| | Ngắt kết nối cặp đôi | **RW** | **RW** | Firestore `couples/{id}` + Local Hive | Xóa `coupleId` 2 bên |

---

## 🔄 4. TRẠNG THÁI KẾT NỐI: UNPAIRED (OFFLINE) VS PAIRED (REALTIME SYNC)

Hệ thống Moona hoạt động theo mô hình **Offline-First & Privacy-First**. Ứng dụng phải hoạt động trơn tru ngay cả khi không có mạng hoặc chưa ghép đôi:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          1. TRẠNG THÁI UNPAIRED (CHƯA GHÉP ĐÔI)             │
├─────────────────────────────────────────────────────────────────────────────┤
│ • Lưu trữ: 100% dữ liệu nằm trong Hive cục bộ với UserScope.                │
│ • Vợ: Sử dụng toàn bộ tính năng chu kỳ, tâm trạng, dinh dưỡng cá nhân.      │
│ • Chồng: Hiển thị giao diện với dữ liệu ước tính mẫu (Demo Mode)            │
│          kèm Banner CTA "Ghép đôi với nàng qua mã 6 ký tự để nhận Live".    │
│ • Tín hiệu yêu thương: Chế độ Local Simulator (thử nghiệm giao diện).       │
│ • Danh xưng: Sử dụng cấu hình mặc định (Vợ gọi "Anh", Chồng gọi "Em bé").   │
└─────────────────────────────────────────────────────────────────────────────┘
                                      │
                         [ Ghép đôi thành công qua mã ]
                                      │
                                      ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           2. TRẠNG THÁI PAIRED (ĐÃ GHÉP ĐÔI)                │
├─────────────────────────────────────────────────────────────────────────────┤
│ • Document cặp đôi: Firestore `couples/{coupleId}` hoạt động liên tục.      │
│ • Vợ: Khi ghi nhận tâm trạng/chu kỳ → ngầm đẩy tóm tắt Live Status lên Cloud│
│ • Chồng: Lắng nghe Stream `partnerLiveStatusStreamProvider` thời gian thực; │
│          hiển thị Banner xanh tĩnh "Đang đồng hành cùng [Tên] 💕".          │
│ • Tín hiệu yêu thương (Care Signals): Stream 2 chiều tức thì kèm rung Haptic│
│ • Danh xưng 4 trường: Tự động đảo ngôi xưng hô theo góc nhìn (Perspective). │
│ • Phòng vệ mạng: Mọi call Firestore đều có Timeout (5s-8s) và Offline Cache.│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 👥 5. CƠ CHẾ ĐỒNG BỘ HAI CHIỀU DANH XƯNG (PERSPECTIVE MAPPING)

Để tránh hiện tượng xưng hô lệch ngôi (VD: Chồng thấy vợ xưng là "Anh"), cấu trúc Firestore `couples/{coupleId}` lưu trữ 4 trường độc lập:

```json
{
  "wifeCallsHusband": "Anh yêu",
  "wifeSelfCall": "Em bé",
  "husbandCallsWife": "Bé iu",
  "husbandSelfCall": "Anh",
  "updatedAt": "2026-09-03T15:00:00Z"
}
```

### Bảng Ánh Xạ Góc Nhìn (Perspective Mapping Table)

| Cấu hình tại UI Local | Khi người dùng là VỢ | Khi người dùng là CHỒNG |
|---|---|---|
| **Bạn gọi người ấy là:** (`callPartnerAs`) | Đọc/Ghi `wifeCallsHusband` | Đọc/Ghi `husbandCallsWife` |
| **Bạn tự xưng là:** (`selfCallAs`) | Đọc/Ghi `wifeSelfCall` | Đọc/Ghi `husbandSelfCall` |
| **Người ấy gọi bạn là:** (`partnerCallsMeAs`) | Đọc từ `husbandCallsWife` | Đọc từ `wifeCallsHusband` |
| **Người ấy tự xưng là:** (`partnerSelfCallAs`) | Đọc từ `husbandSelfCall` | Đọc từ `wifeSelfCall` |

---

## 🔒 6. BẢO MẬT & PHẠM VI LƯU TRỮ (DATA BOUNDARY & USERSCOPE)

```
┌──────────────────────────────────────────────────────────────────────────┐
│                         NGUYÊN TẮC RÀNH MẠCH DỮ LIỆU                     │
├──────────────────────────────────────────────────────────────────────────┤
│ 1. NHẠY CẢM (Nhật ký chu kỳ chi tiết, ghi chú, bệnh lý, triệu chứng):   │
│    └──> CHỈ LƯU TẠI HIVE LOCAL (MÃ HÓA AES-256 QUA BACKUP CONFIG)       │
│                                                                          │
│ 2. TÓM TẮT ĐỒNG BỘ (Pha hiện tại, pin 1-5, mood tag, care signal):       │
│    └──> LƯU TẠI FIRESTORE `couples/{coupleId}` CHO PARTNER XEM           │
│                                                                          │
│ 3. CÔ LẬP ĐA TÀI KHOẢN (Multi-account on Same Device):                   │
│    └──> Mọi key Hive phải bọc `UserScope.key(key, uid)`                  │
│    └──> Ví dụ: `u123_app_user_role`, `u123_partner_couple_id`            │
└──────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 7. QUY TRÌNH KIỂM TOÁN CODE TRƯỚC KHI COMMIT (CHECKLIST FOR AGENTS)

Mỗi khi chỉnh sửa code, AI Agent BẮT BUỘC tự kiểm tra danh sách sau:
- [ ] Tính năng vừa sửa có nằm trong quyền (RW/RO) của Role hiện tại không?
- [ ] Đã kiểm tra xem có ảnh hưởng đến Role đối diện không? (Test cả Role Vợ lẫn Role Chồng).
- [ ] Các provider dùng chung có bị reset nhầm khi đổi tab không?
- [ ] Các key lưu Hive mới có được bọc qua `UserScope.key()` không?
- [ ] Chạy `flutter analyze` đạt **0 issues/errors**.
- [ ] Chạy `flutter test` pass **100%**.
- [ ] Cập nhật tóm tắt vào `CHANGELOG.md` và `HANDOVER.md`.
