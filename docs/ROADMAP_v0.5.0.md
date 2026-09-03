# 🗺️ TÀI LIỆU THIẾT KẾ KIẾN TRÚC & ĐẶC TẢ KỸ THUẬT MOONA (ROADMAP v0.5.0 & v0.6.0)

> **Dự án:** Moona — Trợ Lý Chu Kỳ Sinh Học & Kết Nối Cặp Đôi  
> **Trạng thái:** 
> - **v0.5.0:** ĐÃ HOÀN THÀNH & NGHIỆM THU (Google Auth, Role Onboarding, Nickname Engine, Tự lập chu kỳ độc lập).
> - **v0.6.0:** CHUẨN BỊ TRIỂN KHAI (QR Pairing, Lịch sử tương tác & Phán đoán cảm xúc, Báo cáo đối soát & Xuất dữ liệu).  
> **Thời điểm cập nhật:** 03/09/2026  
> **Kiến trúc áp dụng:** Clean Architecture (Feature-First) + Riverpod 2.x + Cloud Firestore + Hive Local Storage + AES-256 Encryption.

---

## 📑 MỤC LỤC
0. [Chuẩn Hóa Nguyên Tắc Quản Lý Phiên Bản (SemVer Standard)](#0-chuẩn-hóa-nguyên-tắc-quản-lý-phiên-bản-semver-standard)
1. [Hệ Thống Danh Xưng Linh Hoạt (Nickname Engine) — [ĐÃ HOÀN THÀNH v0.5.0]](#1-hệ-thống-danh-xưng-linh-hoạt-nickname-engine--đã-hoàn-thành-v050)
2. [Luồng Onboarding Phân Vai Trò & Chu Kỳ Độc Lập — [ĐÃ HOÀN THÀNH v0.5.0]](#2-luồng-onboarding-phân-vai-trò--chu-kỳ-độc-lập--đã-hoàn-thành-v050)
3. [Đăng Nhập Google & Định Danh Đám Mây — [ĐÃ HOÀN THÀNH v0.5.0]](#3-đăng-nhập-google--định-danh-đám-mây--đã-hoàn-thành-v050)
4. [Phân Hệ Lịch Sử Tương Tác & Phán Đoán Cảm Xúc (Insights Engine) — [v0.6.0]](#4-phân-hệ-lịch-sử-tương-tác--phán-đoán-cảm-xúc-insights-engine--v060)
5. [Luồng Cấp Quyền & Ghép Đôi Bằng Mã QR (QR Code Pairing) — [v0.6.0]](#5-luồng-cấp-quyền--ghép-đôi-bằng-mã-qr-qr-code-pairing--v060)
6. [Báo Cáo Đối Soát Chu Kỳ & Xuất Nhập Dữ Liệu (Data Export & Audit) — [v0.6.0]](#6-báo-cáo-đối-soát-chu-kỳ--xuất-nhập-dữ-liệu-data-export--audit--v060)
7. [Phân Kỳ Sprint & Tiêu Chí Nghiệm Thu (Sprint Breakdown & Acceptance Criteria)](#7-phân-kỳ-sprint--tiêu-chí-nghiệm-thu-sprint-breakdown--acceptance-criteria)

---

## 0. CHUẨN HÓA NGUYÊN TẮC QUẢN LÝ PHIÊN BẢN (SEMVER STANDARD)

Nhằm đảm bảo tính ổn định, dễ truy vết lịch sử phát hành và đồng bộ giữa `pubspec.yaml`, `CHANGELOG.md` và `HANDOVER.md`, toàn bộ dự án tuân thủ nghiêm ngặt chuẩn Semantic Versioning:

### 0.1. Định dạng phiên bản: `MAJOR.MINOR.PATCH+BUILD`
Ví dụ: `0.5.0+10`, `0.6.0+11`

| Thành phần | Quy tắc tăng chỉ số | Ví dụ áp dụng trong Moona |
|---|---|---|
| **MAJOR (X.0.0)** | Tăng khi có **thay đổi kiến trúc lớn làm phá vỡ tính tương thích ngược** (Breaking changes), tái cấu trúc toàn bộ database Firestore mà phiên bản cũ không đọc được, hoặc đại tu toàn bộ giao diện/core engine. | `1.0.0`: Phiên bản phát hành chính thức lên Google Play Store với đầy đủ hệ sinh thái Cloud Functions, AI Coach và Widget. |
| **MINOR (0.X.0)** | Tăng khi **hoàn thành và đóng gói một cụm tính năng lớn mới** (Major Feature Modules) mà vẫn giữ tính tương thích ngược. | • `v0.4.0`: Phân vai trò Vợ/Chồng & Realtime Care Signals.<br>• `v0.5.0`: Google Auth, Role Onboarding, Nickname Engine, Chu kỳ độc lập.<br>• `v0.6.0`: QR Pairing, Interaction History & Emotion Insights, Data Export. |
| **PATCH (0.0.X)** | Tăng khi thực hiện **sửa lỗi (Bug fixes), tối ưu hiệu năng nhỏ**, chỉnh sửa câu chữ hoặc điều chỉnh padding/color nhẹ mà không bổ sung tính năng mới. | • `v0.5.1`: Vá lỗi hiển thị avatar khi mất mạng.<br>• `v0.5.2`: Tối ưu hiệu năng render Lịch. |
| **BUILD (+N)** | Số nguyên tăng dần tự động **sau mỗi lần build APK/Deploy**. Không bao giờ giảm hoặc reset về 0. | `+9` -> `+10` -> `+11`... |

### 0.2. Quy tắc bắt buộc đối với AI Coding Agent:
1. **Tuyệt đối không tự ý nhảy số MINOR/MAJOR tùy tiện** giữa các commit phụ hoặc khi chỉ mới hoàn thành một phần nhỏ của sprint.
2. Việc tăng số MINOR chỉ được thực hiện khi đã:
   - Vượt qua 100% unit tests (`flutter test`).
   - Sạch 100% static analysis (`flutter analyze` đạt 0 issues).
   - Đã biên dịch và deploy APK thành công lên thiết bị.
3. Luôn cập nhật đồng thời 3 tệp khi tăng phiên bản: `pubspec.yaml` (dòng `version:`), `CHANGELOG.md` (mục `[Added]`, `[Changed]`, `[Fixed]`) và `HANDOVER.md`.

---

## 1. HỆ THỐNG DANH XƯNG LINH HOẠT (NICKNAME ENGINE) — [ĐÃ HOÀN THÀNH v0.5.0]

### 1.1. Hiện trạng triển khai
- Đã tạo model `NicknameConfig` (`lib/features/settings/domain/models/nickname_config.dart`) gồm:
  * `callPartnerAs`: Bạn gọi người ấy là gì (mặc định: `"Người thương"`).
  * `selfCallAs`: Bạn tự xưng với người ấy là gì (mặc định: `"Người thương"`).
- Danh sách 7 Presets lựa chọn nhanh: `["Người thương", "Em bé", "Bé iu", "Vợ yêu", "Chồng yêu", "Anh yêu", "Bạn đời"]` kèm ô nhập tùy biến ("Tự gõ").
- Đã tạo `NicknameController` & `nicknameConfigProvider` (`lib/features/settings/presentation/controllers/nickname_controller.dart`), tự động lưu vào Hive `settingsBox` và đồng bộ lên document Firestore `couples/{coupleId}`.
- Đã tích hợp vào UI:
  * Phía Chồng (`HusbandViewScreen`): Subtitle AppBar, Hero Card, Hộp tín hiệu, Quick Response chips.
  * Phía Vợ (`CycleScreen`): AppBar Couple Badge hiển thị danh xưng Chồng; Banner phản hồi hiển thị đúng tên xưng hô của Chồng.
  * Cài Đặt (`SettingsScreen`): Thẻ Live Preview đối thoại mẫu.

---

## 2. LUỒNG ONBOARDING PHÂN VAI TRÒ & CHU KỲ ĐỘC LẬP — [ĐÃ HOÀN THÀNH v0.5.0]

### 2.1. Hiện trạng triển khai
- Đã xây dựng `RoleSelectionScreen` (`lib/features/onboarding/presentation/screens/role_selection_screen.dart`):
  * **Thẻ 1 [ 🌸 Tôi là Phụ nữ ]:** Dẫn vào quy trình thiết lập chu kỳ chi tiết cho nữ giới (Ngày kinh gần nhất, độ dài chu kỳ, số ngày hành kinh).
  * **Thẻ 2 [ 🛡️ Tôi là Người thương ]:** Mở BottomSheet gồm 2 tùy chọn:
    1. `[ 🔗 Đã có mã ghép đôi từ nàng ]`: Mở màn hình nhập mã kết nối Firestore như thông thường.
    2. `[ 📝 Tự thiết lập chu kỳ của nàng ]`: Dành riêng cho Chàng muốn tự theo dõi độc lập khi nàng chưa dùng app. Chàng chọn ngày kinh gần nhất + độ dài chu kỳ -> App lưu vào Hive và mở thẳng Dashboard Chàng.
- Đã xây dựng `_buildCycleSummaryCard` trên `HusbandViewScreen`:
  * Hiển thị số ngày còn lại đến kỳ kinh tiếp theo, khoảng thời gian cửa sổ rụng trứng.
  * Cung cấp nút mở modal Lịch chu kỳ sinh học của nàng (`CycleCalendarView` + `CyclePhaseLegend`).
  * Trong Cài Đặt (`SettingsScreen`), bổ sung mục "Chu Kỳ Của [Tên nàng]" với modal `_showEditPartnerCycleModal` cho phép chàng hiệu chỉnh lại thông số chu kỳ bất kỳ lúc nào.

### 2.2. Cơ Chế Ràng Buộc Vai Trò Theo Tài Khoản & Dọn Dẹp UI Tạm Thời (Post-Auth Cleanup)
1. **Nguyên tắc ràng buộc vai trò (Account-Bound Role):**
   - Khi hoàn tất Google Sign-In & Onboarding lần đầu: `userRole` (`UserRole.wife` / `UserRole.husband`) được khóa chặt vào Document `users/{uid}` trên Cloud Firestore và lưu bền vững tại Hive cục bộ (`keyUserRole`).
   - Khi người dùng đổi thiết bị hoặc gỡ cài đặt app: Chỉ cần đăng nhập lại bằng tài khoản Google, ứng dụng tự động đối soát Firestore, phục hồi chính xác vai trò đã lưu và điều hướng thẳng vào giao diện tương ứng (không bắt người dùng chọn lại vai trò).
2. **Chính sách dọn dẹp thành phần thử nghiệm tạm (Deprecation Policy):**
   - **Xóa bỏ nút chuyển vai trò tạm:** Khi luồng Login + Role Onboarding đi vào vận hành ổn định, loại bỏ hoàn toàn nút Floating Action Chip chuyển role nhanh (`🌸 Mode: Vợ ⇄` / `🛡️ Mode: Chồng ⇄`) trên màn hình chính (`CycleScreen`, `HusbandViewScreen`).
   - **Màn hình Cài đặt (`SettingsScreen`):** Chuyển mục chọn vai trò từ thẻ tương tác đổi trực tiếp (`_RoleCard`) thành thẻ thông tin tĩnh dạng **Read-only Badge** hiển thị vai trò hiện tại của tài khoản. Người dùng chỉ có thể thay đổi vai trò khi thực hiện **Đăng xuất (Sign Out)** hoặc **Reset dữ liệu tài khoản**.

---

## 3. ĐĂNG NHẬP GOOGLE & ĐỊNH DANH ĐÁM MÂY — [ĐÃ HOÀN THÀNH v0.5.0]

### 3.1. Hiện trạng triển khai
- Bổ sung thư viện chính thức: `firebase_auth: ^6.6.1` và `google_sign_in: ^6.2.2`.
- Đã xây dựng kiến trúc Clean Architecture:
  * Domain: `UserModel` (`uid`, `displayName`, `email`, `photoUrl`, `createdAt`).
  * Data: `AuthRepository` với phương thức `signInWithGoogle()`, `signInAsDemo()`, `signOut()`, tự động ghi cache `userBox` và document Firestore `users/{uid}`.
  * Presentation: `AuthController`, `currentUserProvider`, `isLoggedInProvider`.
  * UI: `LoginScreen` phong cách Liquid Glass với nút Google chính thức và nút "Trải nghiệm Demo" 1 chạm.
  * Thẻ Profile người dùng tại `SettingsScreen` với Avatar Google và nút Đăng xuất an toàn.
- Keystore Fingerprints đã trích xuất:
  * **SHA-1:** `EA:A9:EA:AB:B7:B9:9A:1F:F1:81:64:BF:76:2E:E1:75:C5:32:7F:47`
  * **SHA-256:** `4C:A0:DA:B2:A3:D4:94:7D:B4:08:89:D2:11:A8:13:03:AB:77:05:FD:5B:A0:F5:87:F7:D8:D4:1D:0A:76:99:89`

---

## 4. PHÂN HỆ LỊCH SỬ TƯƠNG TÁC & PHÁN ĐOÁN CẢM XÚC (INSIGHTS ENGINE) — [v0.6.0]

### 4.1. Cấu trúc dữ liệu Interaction Log
Mọi hành vi giao tiếp giữa hai người (gửi tín hiệu yêu thương, chồng phản hồi, trả lời câu hỏi thăm) đều được ghi lại vào dòng thời gian để phục vụ thống kê và nhận diện xu hướng cảm xúc:

- **Firestore Path:** `couples/{coupleId}/interactions/{interactionId}`
- **Schema Chi Tiết:**
  ```json
  {
    "id": "uuid-v4-string",
    "coupleId": "couple-uuid-456",
    "senderUid": "google-uid-123",
    "senderRole": "wife",
    "type": "care_signal", // "care_signal" | "husband_response" | "check_in_question"
    "content": "Muốn được ôm 🤗",
    "responseContent": "💖 Ngoan đợi anh về nhé", // (nếu là care_signal đã phản hồi)
    "cyclePhase": "luteal", // "menstrual" | "follicular" | "ovulation" | "luteal"
    "cycleDay": 24,
    "timestamp": "2026-09-03T15:30:00.000Z"
  }
  ```

### 4.2. Thuật toán nhận diện quy luật cảm xúc (Emotion Pattern Recognition)
Hệ thống không chỉ hiển thị dữ liệu tĩnh mà sẽ tự động học hỏi qua các chu kỳ của nàng:
1. **Phân tích tần suất:** Gom nhóm các tín hiệu và nhật ký cảm xúc theo `(cycleDay, cyclePhase)` của 3 chu kỳ gần nhất.
2. **Nhận diện ngày nhạy cảm (Vulnerability Cluster):** Nếu hệ thống nhận thấy nàng thường xuyên gửi tín hiệu "Đau bụng", "Mệt mỏi" hoặc ghi nhận "Cáu kỉnh" vào các ngày 23 đến 26 chu kỳ:
   * Hệ thống đánh dấu đây là **Vùng nhạy cảm cao (High-Sensitivity Window)**.
3. **Cơ chế Cảnh báo sớm 24h (24h Pre-PMS Early Warning):**
   * Khi chu kỳ hiện tại đạt **Ngày 22** (trước 24h khi bước vào Vùng nhạy cảm), hệ thống tự động:
     - Đẩy Smart Notification lên máy Chồng: *"Ngày mai [Tên nàng] bước vào giai đoạn nhạy cảm nhất chu kỳ. Chàng hãy chủ động mua đồ ấm và dành nhiều sự kiên nhẫn hơn nhé! 💕"*.
     - Ghim thẻ "Dự Báo Thể Trạng Nàng 24h Tới" lên đầu Dashboard Chồng.

---

## 5. LUỒNG CẤP QUYỀN & GHÉP ĐÔI BẰNG MÃ QR (QR CODE PAIRING) — [v0.6.0]

### 5.1. Luồng cấp quyền theo ngữ cảnh (Contextual Permissions)
Tránh việc đòi hỏi quyền dồn dập ngay khi vừa mở app gây khó chịu cho người dùng:
1. **Quyền Thông báo đẩy (`POST_NOTIFICATIONS` trên Android 13+):**
   - Chỉ hiển thị sau khi người dùng đã đăng nhập Google thành công và trước khi vào màn hình chính.
   - Hiển thị Dialog thiết kế phong cách Soft Pastel giải thích rõ ràng giá trị: *"Bật thông báo để không bao giờ bỏ lỡ tín hiệu yêu thương và lời nhắn ngọt ngào từ người thương của bạn"*.
2. **Quyền Camera (`CAMERA`):**
   - Tuyệt đối không xin quyền khi mở app.
   - Chỉ khi người dùng bấm vào nút *"📷 Quét mã QR của nàng"* trên màn hình Ghép Đôi, ứng dụng mới hiển thị hộp thoại xin quyền Camera.

### 5.2. Cơ chế ghép đôi 1 chạm bằng QR Code (QR Code Pairing)
- **Thư viện tích hợp:** `qr_flutter: ^4.1.0` (phía Vợ sinh mã) và `mobile_scanner: ^5.2.3` (phía Chồng quét mã).
- **Phía Vợ (Tạo mã QR):**
  * Trên tab "Dành cho Vợ" của màn hình Ghép đôi, hiển thị mã QR lớn ở trung tâm.
  * Payload mã hóa trong QR Code dạng JSON:
    ```json
    {
      "app": "moona",
      "version": "1.0",
      "pairingCode": "MOONA8",
      "wifeUid": "google-uid-123",
      "wifeName": "Lan Anh",
      "createdAt": 1725350400000
    }
    ```
- **Phía Chồng (Quét mã QR):**
  * Chồng mở camera quét qua màn hình của Vợ.
  * Ứng dụng tự động nhận diện JSON payload, kiểm tra `app == "moona"`, trích xuất `pairingCode` và gọi ngay hàm `pairWithCode()` ngầm mà Chồng không cần gõ bất kỳ ký tự nào.
  * Hiển thị hiệu ứng rung haptic thành công + pháo hoa chúc mừng cặp đôi kết nối.

---

## 6. BÁO CÁO ĐỐI SOÁT CHU KỲ & XUẤT NHẬP DỮ LIỆU (DATA EXPORT & AUDIT) — [v0.6.0]

### 6.1. Báo cáo đối soát chu kỳ (Cycle Audit Report)
Giúp người dùng và bác sĩ phụ khoa có cái nhìn trực quan, minh bạch về độ chuẩn xác của chu kỳ sinh học:
- **Bảng đối soát 2 chiều:**
  * **Chu kỳ cấu hình lý thuyết (Settings):** Độ dài chu kỳ khai báo ban đầu (ví dụ: 28 ngày), độ dài hành kinh (ví dụ: 5 ngày).
  * **Chu kỳ thực tế ghi nhận (Actual Period Records):** Lịch sử các kỳ kinh nguyệt thực tế đã log qua các tháng (ngày bắt đầu thực tế, ngày kết thúc, số ngày hành kinh thực tế).
  * **Chỉ số dao động (Cycle Variability Index):** Đánh giá chu kỳ đều đặn (± 1-2 ngày) hay biến động cao (± 5-7 ngày) kèm khuyến nghị y khoa.
- **Dòng thời gian tương tác (Care Interaction Timeline):**
  * Thống kê tổng số lần Vợ gửi tín hiệu, số lần Chồng phản hồi, tỷ lệ tương tác chăm sóc trong từng pha chu kỳ.

### 6.2. Định dạng xuất/nhập dữ liệu đa dạng
1. **Tệp sao lưu mã hóa cao cấp `.moona` (AES-256):**
   - Bảo mật tuyệt đối dữ liệu nhạy cảm của phụ nữ.
   - Mã hóa toàn bộ dữ liệu (chu kỳ, nhật ký tâm trạng, ghi chú, lịch sử tương tác) bằng thuật toán AES-256-CBC, khóa giải mã được dẫn xuất từ mật khẩu/PIN cá nhân bằng SHA-256.
   - Hỗ trợ tính năng Nhập (Restore) trên máy mới chỉ trong vài giây.
2. **Tệp xem nhanh `.json` & `.csv`:**
   - Dành cho người dùng muốn đối soát dữ liệu trên máy tính (Excel, Google Sheets).
   - Xuất file `.csv` định dạng chuẩn quốc tế dễ dàng in ấn hoặc gửi qua Zalo/Email cho bác sĩ phụ khoa khi đi khám.

---

## 7. PHÂN KỲ SPRINT & TIÊU CHÍ NGHIỆM THU (SPRINT BREAKDOWN & ACCEPTANCE CRITERIA)

```
Moona Master Roadmap
├── SPRINT 1 (v0.4.0) — [✅ HOÀN THÀNH]
│   ├── [1.1] Phân định vai trò UserRole (Vợ / Chồng) & Giao diện động
│   ├── [1.2] Realtime Care Signals 2 chiều (Vợ gửi -> Chồng nhận -> Chồng phản hồi -> Vợ nhận Banner)
│   ├── [1.3] Dual Firestore collection sync (couples & pairings) + In-memory sorting
│   └── [1.4] Kịch bản build & deploy song song đa thiết bị (scripts/deploy.ps1 -Target all)
│
├── SPRINT 2 (v0.5.0 - v0.5.2) — [✅ HOÀN THÀNH & NGHIỆM THU]
│   ├── [2.1] [x] Xác thực Google Sign-In & Firebase Auth (LoginScreen + Demo Mode fallback)
│   ├── [2.2] [x] Onboarding phân vai trò ban đầu (RoleSelectionScreen dạng compact ngang ~100-110dp)
│   ├── [2.3] [x] Tự lập chu kỳ độc lập cho Người thương (DatePicker + Cycle Counters + Hero Summary Card)
│   ├── [2.4] [x] Động cơ danh xưng tùy biến (Nickname Engine: 7 presets, Custom input, Live Preview)
│   ├── [2.5] [x] Đồng bộ danh xưng & Avatar lên toàn bộ UI Vợ, Chồng và Cài Đặt
│   ├── [2.6] [x] Modal Chat Nhanh hỏi thăm nàng (HusbandQuickChatSheet) & Vòng lặp phản hồi 1 chạm
│   ├── [2.7] [x] Đồng bộ nhận diện thương hiệu Moona Launcher Icon toàn hệ thống Android
│   └── [2.8] [x] Sửa triệt để lỗi crash R8/ProGuard và các lỗi tràn pixel (overflow)
│
└── SPRINT 3 (v0.6.0) — [🚀 CHUẨN BỊ TRIỂN KHAI]
    ├── SPRINT 3A: Cấp Quyền Ngữ Cảnh & Ghép Đôi Bằng Mã QR
    │   ├── [3A.1] Post-Login Contextual Dialog xin quyền POST_NOTIFICATIONS
    │   ├── [3A.2] Tích hợp qr_flutter: Sinh mã QR động tại tab Vợ kèm thông tin bảo mật
    │   ├── [3A.3] Tích hợp mobile_scanner: Quét mã QR tại tab Chồng kèm xin quyền Camera ngữ cảnh
    │   └── [3A.4] Nghiệm lưu ghép đôi 1 chạm không cần nhập bàn phím
    │
    ├── SPRINT 3B: Lịch Sử Tương Tác & Phán Đoán Cảm Xúc (Insights Engine)
    │   ├── [3B.1] Firestore subcollection `couples/{coupleId}/interactions` & Repository
    │   ├── [3B.2] Tự động lưu vết mọi tín hiệu yêu thương và câu hỏi thăm vào Interaction Log
    │   ├── [3B.3] Thuật toán Emotion Pattern Recognition phân tích vùng nhạy cảm 3 chu kỳ
    │   └── [3B.4] Cơ chế 24h Early Warning: Thông báo thông minh cảnh báo sớm cho Chồng trước pha PMS
    │
    └── SPRINT 3C: Báo Cáo Đối Soát Chu Kỳ & Xuất/Nhập Dữ Liệu
        ├── [3C.1] UI Báo cáo đối soát: So sánh Chu kỳ lý thuyết vs Chu kỳ thực tế ghi nhận
        ├── [3C.2] Module xuất dữ liệu sao lưu mã hóa AES-256 (.moona)
        ├── [3C.3] Module xuất bảng tính nhanh (.json, .csv) phục vụ khám phụ khoa
        └── [3C.4] Kiểm thử toàn diện 100% pass, flutter analyze 0 issues, deploy v0.6.0
```

---

## 8. TIÊU CHÍ NGHIỆM THU SPRINT 3 (v0.6.0 ACCEPTANCE CRITERIA)
- [ ] Vợ mở tab ghép đôi: Xuất hiện mã QR sắc nét, cập nhật realtime.
- [ ] Chồng bấm "Quét mã QR": Hiện dialog xin quyền Camera -> Chấp nhận -> Quét mã thành công trong < 1 giây và ghép đôi tức thì.
- [ ] Mọi lượt gửi tín hiệu và phản hồi được lưu vào `interactions` kèm `cyclePhase` và `cycleDay`.
- [ ] Chồng nhận cảnh báo sớm trước 24h khi nàng sắp bước vào ngày thường xuyên mệt mỏi trong pha Hoàng thể.
- [ ] Người dùng xuất được file `.moona` mã hóa và file `.csv` chứa lịch sử chu kỳ thực tế.
- [ ] Toàn bộ unit tests đạt 100% pass, `flutter analyze` đạt 0 lỗi, quy tắc SemVer được tuân thủ nghiêm ngặt.
