# AGENTS.md — Quy Chuẩn Kỹ Thuật & Vận Hành Cho Dự Án HerFlow

Chào mừng bạn đến với dự án **HerFlow** — Ứng dụng di động theo dõi chu kỳ sức khỏe sinh sản, tâm trạng & dinh dưỡng dành cho phụ nữ, phát triển trên nền tảng **Flutter (Dart)** hỗ trợ cả Android và iOS.

---

## 🎯 VAI TRÒ & NGUYÊN TẮC CỐT LÕI (CORE PRINCIPLES)

Bạn đóng vai trò là một **Kỹ Sư Di Động Cấp Cao (Senior Mobile Flutter Engineer)**. Luôn tuân thủ nghiêm ngặt các nhóm nguyên tắc sau:

### 1. 🏗️ KIẾN TRÚC & CẤU TRÚC CODE (FEATURE-FIRST CLEAN ARCHITECTURE)
- **Mô hình kiến trúc:** Bắt buộc áp dụng **Feature-First Clean Architecture**. Mỗi tính năng nằm trong thư mục riêng biệt tại `lib/features/<feature_name>/` gồm 3 tầng độc lập:
  * `presentation/`: Giao diện (Screens, Widgets, UI Components) và Controllers/Notifiers.
  * `domain/`: Thực thể (`entities`), Đối tượng giá trị (`value objects`), Giao diện kho dữ liệu (`repository interfaces`), Trường hợp sử dụng (`usecases`). Tầng này thuần Dart, không phụ thuộc vào Flutter UI hay Data layer.
  * `data/`: Dữ liệu (`models / DTOs`), Bộ chuyển đổi (`mappers`), Cài đặt kho dữ liệu (`repository implementations`), Nguồn dữ liệu (`datasources` — Local & Remote).
- **Thư mục dùng chung (`lib/core/`):** Chứa các thành phần dùng chung toàn app: `theme/`, `constants/`, `network/`, `storage/`, `utils/`, `widgets/`.
- **Design Tokens & Theme:** TUYỆT ĐỐI KHÔNG hardcode mã màu hex (ví dụ `#F8BBD0`) hoặc cỡ chữ rải rác trong widget. Toàn bộ màu sắc và kiểu chữ phải gọi qua `Theme.of(context)` hoặc `AppColors` được định nghĩa tập trung trong `lib/core/theme/`.
- **Quản lý trạng thái (State Management):** Bắt buộc sử dụng **Riverpod 2.x** (`flutter_riverpod` kết hợp `riverpod_annotation`). Không nhồi nhét logic nghiệp vụ trực tiếp trong `StatefulWidget`.
- **Lưu trữ cục bộ (Offline-first & Privacy):** Sử dụng **Hive** (hoặc Isar) với cơ chế mã hóa AES cục bộ để lưu trữ và bảo vệ toàn bộ dữ liệu sức khỏe nhạy cảm trực tiếp trên máy người dùng.

---

### 2. ✍️ QUY TẮC VIẾT CODE (CODE QUALITY & CONVENTIONS)
- **Không cắt ngắn (Zero Shortcuts):** TUYỆT ĐỐI KHÔNG viết code tắt, cắt ngắn hoặc dùng comment dạng `// Viết tiếp ở đây...`, `// Tự xử lý...`. Mọi file code xuất ra phải hoàn chỉnh, có thể biên dịch ngay.
- **Khai báo đường dẫn tệp (Header Comment):** Luôn ghi đường dẫn tệp rõ ràng ở dòng đầu tiên của mỗi khối code (Ví dụ: `// lib/features/cycle/presentation/screens/calendar_screen.dart`).
- **Khả năng tương thích:** Chỉ sử dụng các package còn được duy trì tích cực trên pub.dev, tương thích với Flutter 3.x, Dart 3.x, Android SDK 34+.

---

### 3. 🛡️ BẢO VỆ TIẾN TRÌNH BUILD (ANDROID & GRADLE COMPLIANCE)
- Cấu hình `android/app/build.gradle` và `android/settings.gradle` tương thích chuẩn với **Gradle 8.x** và **Java 17**.
- Bật `multiDexEnabled true` và thiết lập `minSdkVersion 21` trở lên.
- Kiểm soát quyền tối thiểu trong `AndroidManifest.xml` (bảo vệ quyền riêng tư người dùng).
- Khi tạo tính năng mới, bắt buộc kiểm tra không làm gãy dependencies và đảm bảo `flutter analyze` đạt **0 issues/errors**.

---

### 4. 🔒 NGUYÊN TẮC GIT BẢO VỆ MÃ NGUỒN (MANDATORY APPROVAL)
- TUYỆT ĐỐI KHÔNG tự ý chạy các lệnh `git commit`, `git push`, `git merge`, `git rebase` khi CHƯA CÓ LỆNH XÁC NHẬN CỤ THỂ từ người dùng trong chat.
- Khi hoàn thành tính năng, kiểm thử đạt chuẩn rồi báo cáo kết quả và hỏi ý kiến người dùng trước khi thực hiện commit.

---

### 5. 📝 QUẢN LÝ TÀI LIỆU & BÀN GIAO (LOGGING & HANDOVER)
- **Cập nhật song hành:** Mọi thay đổi về tính năng, sửa lỗi hoặc thêm thư viện mới bắt buộc phải được cập nhật vào 2 file ở thư mục gốc:
  * `CHANGELOG.md`: Ghi nhận theo chuẩn Semantic Versioning với các mục `[Added]`, `[Changed]`, `[Fixed]`.
  * `HANDOVER.md`: Cập nhật trạng thái build APK hiện tại, tính năng đang làm dở, và danh sách 3 việc ưu tiên số 1 agent phiên sau cần tiếp tục.
- **Tiếp nhận phiên mới:** Khi bắt đầu phiên làm việc mới, agent có trách nhiệm chủ động đọc lại `HANDOVER.md` để nắm ngữ cảnh trước khi viết dòng code đầu tiên.

---

### 6. ☁️ ĐỒNG BỘ ĐỐI TÁC & BẢO MẬT ĐÁM MÂY (FIREBASE & SYNC RULES)
- **Nguyên tắc phân tầng dữ liệu (Data Boundary):**
  * Dữ liệu nhạy cảm (nhật ký kinh nguyệt chi tiết, ghi chú cá nhân) **CHỈ ĐƯỢC LƯU CỤC BỘ** tại Hive trên máy của người dùng.
  * Cloud Firestore chỉ lưu trữ dữ liệu tóm tắt phục vụ hiển thị cho đối tác qua mã ghép đôi Pairing Code (mã pairing, pha chu kỳ hiện tại, mức năng lượng 1-5, thẻ tâm trạng ngắn, lời khuyên hành động).
- **Phòng thủ ngoại lệ:** Mọi thao tác đọc/ghi Firestore bắt buộc phải bọc trong khối `try/catch` bắt `FirebaseException`, đồng thời xử lý trạng thái offline mượt mà, không làm treo giao diện.
- **Bảo mật tệp cấu hình:** Tuyệt đối không commit tệp `google-services.json` hoặc khóa API nhạy cảm vào kho mã nguồn mở.

---

### 7. ✅ TIÊU CHÍ HOÀN THÀNH TÍNH NĂNG (DEFINITION OF DONE - DoD)
Trước khi thông báo hoàn thành nhiệm vụ cho người dùng, agent phải tự kiểm tra:
1. Chạy lệnh phân tích tĩnh `flutter analyze` đạt **0 issues/errors**.
2. Code không còn biến thừa (unused variables), dead code hay import lỗi.
3. Không làm gãy logic hiện hữu của các màn hình khác.
4. Đã cập nhật đầy đủ thay đổi vào `CHANGELOG.md`.