# AGENTS.md — Quy Chuẩn Kỹ Thuật & Vận Hành Cho Dự Án Moona

Chào mừng bạn đến với dự án **Moona** — Ứng dụng di động theo dõi chu kỳ sức khỏe sinh sản, tâm trạng & dinh dưỡng dành cho phụ nữ, phát triển trên nền tảng **Flutter (Dart)** hỗ trợ cả Android và iOS.

---

## 🎯 VAI TRÒ & NGUYÊN TẮC CỐT LÕI (CORE PRINCIPLES)

Bạn đóng vai trò là một **Kỹ Sư Di Động Cấp Cao (Senior Mobile Flutter Engineer)**. Luôn tuân thủ nghiêm ngặt các nhóm nguyên tắc sau:

### 0. 🗺️ RÀNG BUỘC MA TRẬN NGHIỆP VỤ TOÀN DỰ ÁN (GLOBAL BUSINESS MATRIX MANDATE)
- **Bắt buộc đối chiếu ma trận:** Trước khi code, sửa lỗi hoặc refactor bất kỳ controller/UI nào, BẮT BUỘC đối chiếu với `docs/APP_BUSINESS_MATRIX.md`. Mọi thay đổi phải tuân thủ quyền hạn (RW/RO) của từng Role.
- **Cô lập vai trò tuyệt đối (Zero Regression):** Tuyệt đối không để xảy ra tình trạng sửa Tab/Logic của Chồng làm gãy luồng của Vợ, hoặc ngược lại. Mọi widget/controller dùng chung phải kiểm tra `userRoleProvider`.
- **Toàn vẹn đa tài khoản (UserScope):** Mọi key Hive liên quan đến tài khoản BẮT BUỘC đi qua `UserScope.key(baseKey, uid)`. Tuyệt đối không dùng key phẳng không có tiền tố UID khi đã đăng nhập.
- **Đồng bộ hai chiều đối xứng (Bi-directional Integrity):** Giữ đúng cấu trúc 4 trường độc lập (Perspective Mapping) cho danh xưng và Care Signals trên Firestore `couples/{coupleId}`.

---

### 1. 🏗️ KIẾN TRÚC & CẤU TRÚC CODE (FEATURE-FIRST CLEAN ARCHITECTURE)
- **Mô hình kiến trúc:** Bắt buộc áp dụng **Feature-First Clean Architecture**. Mỗi tính năng nằm trong thư mục riêng biệt tại `lib/features/<feature_name>/` gồm 3 tầng độc lập:
  * `presentation/`: Giao diện (Screens, Widgets, UI Components) và Controllers/Notifiers.
  * `domain/`: Thực thể (`entities`), Đối tượng giá trị (`value objects`), Giao diện kho dữ liệu (`repository interfaces`), Trường hợp sử dụng (`usecases`). Tầng này thuần Dart, không phụ thuộc vào Flutter UI hay Data layer.
  * `data/`: Dữ liệu (`models / DTOs`), Bộ chuyển đổi (`mappers`), Cài đặt kho dữ liệu (`repository implementations`), Nguồn dữ liệu (`datasources` — Local & Remote).
- **Thư mục dùng chung (`lib/core/`):** Chứa các thành phần dùng chung toàn app: `theme/`, `constants/`, `network/`, `storage/`, `utils/`, `widgets/`, `security/`.
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

---

### 8. 🛡️ AN TOÀN BẢO MẬT & QUẢN LÝ KHÓA BÍ MẬT (SECRETS & PRIVACY HYGIENE)

#### ⛔ TUYỆT ĐỐI KHÔNG hardcode bí mật trong mã nguồn
- Không lưu khóa mã hóa database (AES keys), API keys, tokens hoặc mật khẩu dịch vụ trực tiếp dưới dạng chuỗi trong bất kỳ file Dart nào tại `lib/`.
- **Lộ trình đúng chuẩn theo mức độ nhạy cảm:**
  * *Cấu hình build-time không bí mật:* Dùng `--dart-define=KEY=VALUE` trong lệnh `flutter build`.
  * *Khóa mã hóa runtime:* Sinh ngẫu nhiên mỗi lần cài đặt, lưu vào **Android Keystore / iOS Keychain** qua `flutter_secure_storage`.
  * *Config dịch vụ đám mây:* Đặt trong tệp cấu hình platform-specific (`google-services.json`, `.env`) — KHÔNG bao giờ commit lên Git.
- **Quy tắc hiện tại cho `BackupEncryptionConfig`:** Key AES backup đang được centralize tại `lib/core/security/backup_encryption_config.dart` để cô lập khỏi logic nghiệp vụ. Kế hoạch migration sang Keystore được ghi nhận tại `ROADMAP.md` (v0.5.0).

#### 🔐 Bảo vệ tệp cấu hình định danh
- **Bắt buộc nằm trong `.gitignore`:** `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`, `lib/firebase_options.dart`, `android/key.properties`, `*.jks`, `*.keystore`.
- **Luôn cung cấp file mẫu:** Khi tạo project mới hoặc thêm dịch vụ, luôn tạo file `<tên>.example` (ví dụ: `google-services.json.example`) với toàn bộ placeholder để đồng nghiệp setup local.
- **Kiểm tra tracking:** Trước mỗi commit, chạy `git ls-files | grep -E "google-services|\.jks|\.keystore|key\.properties|\.env"` để đảm bảo không có file nhạy cảm nào đang bị track.

#### 🔓 Kiểm soát quyền truy cập Android (`android:exported`)
- Thẻ `<receiver>`, `<activity>`, `<service>` trong `AndroidManifest.xml`:
  * Chỉ đặt `android:exported="true"` khi **thực sự cần** nhận tương tác từ hệ điều hành hoặc ứng dụng khác (ví dụ: Widget provider, Deep link Activity).
  * **Bắt buộc** đặt `android:exported="false"` cho tất cả các component nội bộ khác để chống khai thác chéo ứng dụng (inter-app exploit).
  * Mọi `<receiver>` cho Android 12+ phải khai báo tường minh thuộc tính `android:exported` — không được để thiếu (Android sẽ từ chối cài đặt).

#### 🔍 Quét bí mật định kỳ (Security Scan SOP)
Trước mỗi release build hoặc khi bắt đầu phiên làm việc mới với codebase lạ, agent phải chạy:
```bash
# 1. Kiểm tra file nhạy cảm đang bị Git track
git ls-files | grep -E "google-services\.json|\.jks|\.keystore|key\.properties|\.env"

# 2. Quét API key / secret trong code Dart
grep -r --include="*.dart" -E "AIza|sk-|api_key\s*=\s*['\"]|password\s*=\s*['\"]" lib/

# 3. Kiểm tra lịch sử commit
git log --all --full-history --oneline -- "**/google-services.json" "**/*.jks" "**/.env*"
```
Nếu phát hiện vi phạm: dùng `git rm --cached <file>` → thêm vào `.gitignore` → báo ngay cho người dùng.

---

### 9. ⚙️ NGUYÊN TẮC AN TOÀN VÒNG ĐỜI WIDGET & QUẢN LÝ BIẾN (RUNTIME SAFETY)
1. CẤM TUYỆT ĐỐI DÙNG `late final` CHO CONTROLLER TỪ CALLBACK:
   - Các controller nhận từ callback của thư viện (ví dụ: onCalendarCreated, onMapReady, onPageChanged): BẮT BUỘC khai báo Nullable (`PageController?`, `ScrollController?`) và thao tác bằng toán tử null-aware `?.`.
   - Tuyệt đối không dùng `late final` hoặc `late` cho bất kỳ biến nào có nguy cơ bị gán lại khi Widget cha rebuild (như khi người dùng đổi Theme, đổi State hoặc xoay màn hình).
   - Chỉ dùng `late final` trong State khi và chỉ khi biến đó được gán duy nhất 1 lần trong `initState()` từ các nguồn dữ liệu đồng bộ.

2. NGUYÊN TẮC GIẢI PHÓNG TÀI NGUYÊN (DISPOSE SAFETY):
   - Controller tự tạo bằng `initState()`: Bắt buộc dispose trong hàm `dispose()` của State.
   - Controller do thư viện bên thứ 3 tự khởi tạo và truyền qua callback (như `TableCalendar`): TUYỆT ĐỐI KHÔNG tự ý gọi `dispose()`, để thư viện tự quản lý vòng đời tránh xung đột giải phóng vùng nhớ.

3. TÍNH BẢO TOÀN KHI REBUILD (REBUILD IDEMPOTENCY):
   - Phương thức `build()` và các callback UI phải đảm bảo tính idempotent: chạy lại nhiều lần vẫn cho ra kết quả an toàn, không làm biến đổi state ngầm và không văng ngoại lệ.

4. BẢO VỆ LIFECYCLE VỚI DIALOG NATIVE:
   - Mọi tương tác bung pop-up hệ thống (Biometric, FilePicker, ShareSheet, Permission): Bắt buộc dùng cờ chặn (Guarding Flag) để triệt tiêu sự kiện `AppLifecycleState.inactive` và `resumed` giả mạo do hệ điều hành kích hoạt.