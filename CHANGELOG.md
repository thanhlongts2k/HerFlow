# Changelog — Moona

Toàn bộ những thay đổi đáng chú ý của dự án **Moona** được ghi nhận tại đây theo chuẩn [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) và tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.7.2+25] - 2026-09-04 (Phase 2.5: Fetal Kick Counter & Prenatal Appointments)

### [Added]
- **🔒 Khóa Chế Độ Solo (Solo Guard) Khi Đã Ghép Đôi (`SettingsScreen`):**
  * Khi `isPaired == true`, tùy chọn "🌸 Nàng" (Solo) bị làm mờ (opacity 0.5), gắn icon khóa 🔒 và badge "Cần hủy ghép đôi".
  * Chặn chuyển đổi chế độ và hiển thị SnackBar cảnh báo: *"Bạn đang trong chế độ Cặp Đôi. Vui lòng hủy kết nối trước khi chuyển về chế độ Nàng."*.
- **🔄 Đồng Bộ Realtime Giai Đoạn Cuộc Sống Cặp Đôi (`LifeStageController`):**
  * Vợ đổi stage (`switchStage`) → tự động cập nhật `currentStage` lên Firestore document `couples/{coupleId}` (merge: true).
  * Chồng tự động lắng nghe Stream `couples/{coupleId}` → cập nhật RAM state và Hive local của Chồng realtime để toàn bộ giao diện đổi đồng bộ.

- **👶 Bộ Đếm Cử Động Thai Chuẩn Y Khoa Cardiff "Count to 10" (`KickCounterSheet`):**
  * Giao diện đếm cử động thai đẹp mắt với nút Tap lớn bo tròn, Ripple Effect, rung Haptic phản hồi mỗi lần bé đạp.
  * Thuật toán Cardiff: đủ 10 cử động trong ≤ 2 giờ → auto-complete; vượt 2 giờ → cảnh báo timeout.
  * Thanh tiến trình 10 nấc trực quan, hiển thị thời gian phiên đếm realtime.
  * Lịch sử phiên đếm theo ngày, tóm tắt tổng cử động + số phiên hoàn thành.
  * Banner nổi bật nhắc nhở từ tuần 28 trở đi trên `PregnancyHomeScreen`.
- **📅 Thẻ Lịch Khám Thai 7 Mốc Vàng (`PrenatalAppointmentsCard`):**
  * 7 mốc siêu âm và xét nghiệm tiêu chuẩn sản khoa: NT+Double Test/NIPT (11–13), Triple Test (16–18), Siêu âm 4D hình thái học (20–24), OGTT (24–28), Doppler + NST (32), Kiểm tra ngôi thai + CTG (36), Khám cuối (38–40).
  * Tự động highlight mốc khám kế tiếp dựa trên tuần thai hiện tại.
  * Tick hoàn thành và đặt ngày hẹn thực tế cho từng mốc.
- **💑 Thẻ Tóm Tắt Cử Động Thai Cho Bố Bầu (`_buildKickSummaryCard`):**
  * Hiển thị trên `HusbandViewScreen` từ tuần 28+, đồng bộ dữ liệu realtime qua `todayKickSummaryProvider`.
  * Bấm vào mở `KickCounterSheet` để Bố có thể cùng đếm cử động với Mẹ.

### [Fixed]
- **Khắc Phục Triệt Để Lỗi Đồng Bộ Hai Chiều LifeStage Vợ - Chồng (`LifeStageController`):**
  * Sửa lỗi chuyển ngược về Chung Đôi (`conception -> couple`): bổ sung `await` khi ghi Firestore `couples/{coupleId}` và cập nhật song song cả 2 trường `currentStage` và `lifeStage`.
  * Cập nhật đồng bộ cả Hive key phân vùng `UserScope.key(keyLifeStage, uid)` và fallback unscoped key `keyLifeStage`.
  * Bổ sung `_listenerUid` cho `LifeStageController` để đảm bảo khi stream callback kích hoạt ngầm, dữ liệu luôn lưu đúng vùng lưu trữ của Chồng (không bị ghi đè sang tài khoản Vợ).
  * Kích hoạt cập nhật `authControllerProvider.updateLifeStage()` khi Chồng nhận event stream từ Vợ.
  * Tự động khởi động stream listener cho Chồng trong `loadForUser` nếu đã có `coupleId`.
- **Tương Thích Đa Phiên Bản Flutter SDK (Flutter 3.24 Local & 3.29+ CI Runner):**
  * `app_theme.dart`: Chuyển `CardThemeData` thành `CardTheme` (tương thích cả Flutter 3.24 lẫn 3.29+).
  * `cycle_settings_sheet.dart`, `log_period_modal.dart`, `settings_screen.dart`: Chuyển `activeThumbColor` thành `activeColor` chuẩn Material Switch API.
  * Triệt tiêu hoàn toàn 7 lỗi compile analyzer trên môi trường local và đảm bảo CI runner đạt 0 issues.
- **CI Test Stability (`test/pregnancy_home_screen_test.dart`)**:
  * Đổi assertion `find.textContaining('Tuần 11')` thành `find.text('Tuần 11')` chính xác để không xung đột với chip mốc khám thai `Tuần 11–13` của `PrenatalAppointmentsCard`.
  * Chuyển assertion D-Day sang mẫu regex linh hoạt `RegExp(r'Còn \d+ ngày')` chống lệch ngày do chênh lệch múi giờ giữa máy cá nhân và GitHub Actions runner (UTC vs GMT+7).
  * Áp dụng Viewport chuẩn 1080x2400 cho toàn bộ test case dashboard thai kỳ.
- **Quy chuẩn CI/CD trong `AGENTS.md`**: Bổ sung mục 10 quy định bất biến về Viewport test, Timezone UTC Safety, và Quality Gate DoD.
- Fix `Colors.white87` không tồn tại trong Flutter Colors class → `Colors.white.withAlpha(222)` trong `husband_view_screen.dart` và `prenatal_appointments_card.dart`.
- Fix `const LinearGradient` missing trong `pregnancy_home_screen.dart`.

### [Tests]
- **Transition Matrix Test Suite (`test/life_stage_transition_matrix_test.dart`):**
  * Kiểm thử toàn diện Ma Trận Chuyển Đổi Trạng Thái 4x4 (16/16 cases): gồm 4 trường hợp giữ nguyên (idempotent / no-op) và 12 trường hợp chuyển đổi giữa các trạng thái `{couple, conception, pregnancy, motherhood}`.
  * Kiểm thử 6/6 cặp chuyển đổi hai chiều hoàn chỉnh (Bidirectional Round-Trip: A -> B -> A).
  * Xác minh đầy đủ: Vợ đổi X -> Y, Firestore nhận Y (cả 2 trường `currentStage` và `lifeStage`), Chồng nhận stream Y (State RAM + Hive của Chồng khớp chính xác Y).
- `flutter analyze` — **0 issues** | `flutter test` — **238/238 PASS (100%)**.

---

## [0.7.1+24] - 2026-09-04 (Husband Pregnancy View & Trimester Companion)

### [Added]
- **👶 Góc Nhìn Bố Bầu Chuyên Biệt (`HusbandViewScreen` khi Vợ ở `LifeStage.pregnancy`):**
  * **Thẻ "Bé Yêu Của Bố Tuần Này":** Tự động đồng bộ tuổi thai chuẩn sản khoa (`Tuần X + Y ngày • Tuần thứ Z`), hình tượng quả so sánh trực quan kèm emoji (🥑 Bơ, 🍌 Chuối, 🫐 Việt quất...), đếm ngược D-Day ngày gặp con, cùng chiều dài và cân nặng thai nhi tiêu chuẩn.
  * **Tiến trình 40 tuần & Cột mốc diệu kỳ:** Thanh tiến trình bo góc Liquid Glass hiển thị trực quan các bước ngoặt phát triển sinh học của bé theo tuần.
  * **Bố cục Wrap chống tràn 100%:** Thiết kế co giãn thông minh, tự động xuống dòng mượt mà trên mọi kích thước màn hình thiết bị.
- **💡 Thẻ Bí Kíp Chăm Vợ Bầu Cho Bố (Trimester Cheat-Sheet):**
  * Tự động tổng hợp danh mục `Nên làm (Do's)` và `Cần tránh (Don'ts)` chuyên sâu cá nhân hóa theo từng Tam cá nguyệt (T1, T2, T3), giúp bố chủ động chăm sóc mẹ bầu chu đáo và thấu hiểu.
- **⚡ Phím Tắt Chăm Sóc Care Signals Bố Bầu:**
  * Bộ 3 phím tắt 1 chạm chuyên biệt cho thai kỳ: 💆‍♂️ *Bóp chân cho vợ* (giảm phù nề), 🍲 *Mua đồ tẩm bổ* (chuẩn bị bữa phụ bổ dưỡng), 👶 *Hỏi thăm con* (thai giáo và trò chuyện cùng bé).
- **🛡️ Cơ Chế Phòng Vệ Healing Mode (Safeguard):**
  * Tự động nhận diện khi Vợ bật chế độ Tạm Dừng (`isPaused == true`) để ẩn toàn bộ thẻ thai kỳ/D-Day, chuyển sang giao diện vỗ về dịu dàng và hướng dẫn Bố cách đồng hành chữa lành cùng bạn đời.
- **🔋 Trạng Thái Mẹ Bầu & Phím Tắt Chia Sẻ:**
  * Thẻ pin năng lượng và thể trạng mẹ bầu giúp bố nắm bắt tức thì; nút copy tóm tắt tuần thai vào Clipboard để gửi nhanh qua Zalo/SMS.
- **🔄 Mở Khóa Hoán Đổi Vai Trò Vợ <-> Chồng:**
  * Cho phép hoán đổi vai trò Vợ/Chồng kèm dialog xác nhận `MoonaConfirmDialog` ngay cả khi đang kết nối cặp đôi, đồng bộ realtime an toàn giữa Hive và Firestore.

---

## [0.7.0+23] - 2026-09-04 (Female Lifecycle Platform Foundation & Modular Architecture)

### [Added]
- **🌸 Kiến Trúc Nền Tảng 5 Giai Đoạn Sống (Female Lifecycle Platform):**
  * Chuyển dịch kiến trúc toàn diện từ ứng dụng cặp đôi sang Nền tảng Chăm sóc Sức khỏe Nữ giới theo Vòng đời với 5 giai đoạn cốt lõi:
    - 🌸 **Nàng (Solo):** Theo dõi chu kỳ kinh nguyệt & chăm sóc bản thân độc lập, bảo mật riêng tư, không phụ thuộc kết nối cặp đôi.
    - 💑 **Chung Đôi (Couple):** Đồng bộ realtime với người thương, góc nhìn Chồng và tín hiệu yêu thương chăm sóc.
    - 🌱 **Chuẩn Bị Bầu (Conception):** Cửa sổ thụ thai chuyên sâu, theo dõi nhiệt độ cơ thể cơ bản (BBT), dự đoán rụng trứng và lịch yêu tối ưu.
    - 🤰 **Thai Kỳ (Pregnancy):** Đồng hành thai kỳ theo 40 tuần thai, chỉ số thai nhi, kích thước bé, lịch khám định kỳ & nhật ký thai nghén.
    - 🍼 **Nuôi Con (Motherhood):** Quản lý hồ sơ nhiều bé, nhật ký cữ bú/ngủ/bỉm, biểu đồ tăng trưởng chiều cao & cân nặng chuẩn WHO.
  * Tích hợp `LifeStage` enum, `LifeStageConfig`, `LifeStageState` và `LifeStageController` quản lý trạng thái tập trung qua Riverpod.
  * Tích hợp chế độ tạm dừng / nghỉ ngơi (`Pause Mode` / `Loss Mode`) tôn trọng cảm xúc và quyền riêng tư của phụ nữ khi gặp biến cố thai kỳ hoặc mất mát.
- **🧭 Dynamic Navigation Tự Co Giãn Tab Thông Minh:**
  * `MainNavigationWrapper` tự động tính toán danh sách tab theo giai đoạn sống hiện tại:
    - Chế độ Solo (Nàng, Chuẩn Bị Bầu, Thai Kỳ, Nuôi Con): Co giãn thành 4 tab an toàn (ẩn hoàn toàn tab Cặp đôi).
    - Chế độ Cặp đôi (Chung Đôi): Hiển thị đầy đủ 5 tab (Chu kỳ, Cảm xúc, Cặp đôi, Dinh dưỡng, Cài đặt).
- **🛡️ Bộ 4 Tầng Phòng Vệ Kiến Trúc (DP-01 -> DP-04):**
  * **DP-01 (Safe Hive Migration):** Khởi tạo `UserPreferencesHiveBox` và `MigrationService` tự động chuyển đổi an toàn người dùng cũ `v0.6.x` sang `LifeStage.couple` mà không làm mất dữ liệu.
  * **DP-02 (Navigation Clamping):** Tự động ép chỉ số tab về phạm vi hợp lệ (`math.min`) khi chuyển đổi giữa các giai đoạn sống, triệt tiêu lỗi `IndexOutOfBoundsException`.
  * **DP-03 (Role Guarding Q3):** Khóa an toàn người dùng vai trò Chồng ở chế độ `LifeStage.couple` cố định, ngăn chặn sai lệch luồng dữ liệu.
  * **DP-04 (Realtime Stream Gating):** Tự động ngắt các luồng lắng nghe cặp đôi (`cancelSubscriptions`) khi người dùng ở chế độ Solo, tiết kiệm pin và băng thông.
- **🎛️ Thẻ Giai Đoạn Cuộc Sống Tại Màn Hình Cài Đặt (`SettingsScreen`):**
  * Thẻ hiển thị trực quan giai đoạn hiện tại, badge trạng thái hoạt động và công tắc Chế độ nghỉ ngơi / Tạm dừng.
  * BottomSheet chuyển đổi mượt mà giữa 5 giai đoạn cuộc sống với hình ảnh minh họa, mô tả chi tiết và phản hồi xác nhận.

---

## [0.6.7+22] - 2026-09-04 (Actionable Husband Insights & Companion Experience)

### [Added]
- **🧭 Thẻ "Chế Độ Ứng Xử" Theo Chu Kỳ (Contextual Behavior Banner):**
  * Tự động nhận diện giai đoạn chu kỳ sinh học của Vợ để kích hoạt chế độ ứng xử tâm lý phù hợp:
    - *Hoàng thể / Tiền kinh nguyệt (Luteal):* "Chế độ Cưng chiều & Nhường nhịn" — Lời nhắc ưu tiên lắng nghe, nhường nhịn và ôm ấp khi nội tiết tố sụt giảm.
    - *Hành kinh (Menstrual):* "Chế độ Chăm sóc & Tiếp sức (Kỳ dâu)" — Lời nhắc chuẩn bị nước ấm, túi chườm và gánh vác việc nhà khi nàng đau mỏi.
    - *Nang trứng & Rụng trứng (Follicular/Ovulation):* "Chế độ Kết nối & Đồng hành" — Lời nhắc tận dụng thời điểm năng lượng đỉnh cao để hẹn hò, chia sẻ kế hoạch mới.
- **🛡️ Bảng "Bí Kíp Sinh Tồn" 1 Chạm (Do's & Don'ts Cheat-Sheet):**
  * Thiết kế dạng Card collapsible (gập/mở mượt mà) cung cấp danh sách hành động `DO` (Nên chủ động làm ngay) và `DON'T` (Tuyệt đối nên tránh) theo từng pha cụ thể.
  * Giúp chàng tránh các câu nói gây tổn thương và chủ động chăm sóc tinh tế không cần nhắc.
- **⚡ Phím Tắt "Cứu Nguy 1 Chạm" (Quick Care Signals):**
  * Bộ 3 nút bấm nhanh đặt ngay dưới hero card giúp Chồng gửi tức thì các hành động yêu thương thiết thực:
    - 🧋 *Mua đồ ngọt:* Tự động gửi tin nhắn mua đồ ngọt / trà sữa mang qua cho nàng.
    - 💆‍♂️ *Massage:* Tự động gửi tin nhắn massage vai gáy thư giãn trước khi ngủ.
    - 🫂 *Ôm sạc pin:* Gửi cái ôm ấm áp sạc pin năng lượng cho nàng.
  * Đồng bộ trực tiếp qua Firestore với phản hồi rung xúc giác haptic và thông báo SnackBar nổi.
- **🔋 Chỉ Số "Pin Năng Lượng" (Energy Battery Indicator):**
  * Widget thanh pin 5 vạch phân đoạn (Segmented Battery Bar) đồng bộ từ thể trạng mới nhất của Vợ.
  * Đổi màu thích ứng và cung cấp chú thích hướng dẫn hành động tương ứng với mức pin (Cạn kiệt, Pin yếu, Ổn định, Dồi dào, Cực đại).

### [Changed]
- **✨ Tối Ưu Hóa Giao Diện Màn Hình Chồng (`HusbandViewScreen`):**
  * Tinh giản và kết hợp danh mục ẩm thực bồi bổ thành card thực đơn riêng biệt bổ trợ cho bảng bí kíp sinh tồn.
  * Tối ưu khoảng cách, độ tương phản và hiệu ứng chuyển đổi giữa Dark Mode và Light Mode.

---

## [0.6.6+21] - 2026-09-04 (Cold Start Seamless Splash & UI Optimization)

### [Fixed]
- **⚡ Triệt Tiêu Lỗi Màn Hình Đen Khi Khởi Động (Cold Start Seamless Launch Fix):**
  * Tầng Native: Cấu hình `LaunchTheme` và `NormalTheme` với màu nền chuẩn thương hiệu (Kem vani `#FDFBF7` cho Light mode và Warm Espresso `#191418` cho Dark mode) thay vì phụ thuộc vào nền đen `#000000` mặc định của hệ điều hành.
  * Hỗ trợ toàn diện Android 12+ (API 31+) với các tệp cấu hình `values-v31/styles.xml` và `values-night-v31/styles.xml`, tích hợp chuẩn `SplashScreen API` (`windowSplashScreenBackground`, `windowSplashScreenAnimatedIcon`).
  * Tầng Dart Engine: Chuyển đổi tác vụ khôi phục vai trò từ Cloud Firestore sang luồng xử lý bất đồng bộ trong nền (non-blocking). Ứng dụng đọc trạng thái trực tiếp từ cache Hive tức thì, kích hoạt `runApp()` trong ~50ms mà không bị chặn bởi độ trễ mạng Firestore.

### [Changed]
- **🧹 Tối Giản Giao Diện Cài Đặt (Refined Settings UI):**
  * Gỡ bỏ hoàn toàn thẻ "Xem trước Góc nhìn của Chồng" trên giao diện Cài đặt của Vợ để tránh gây xao nhãng và giữ trải nghiệm cá nhân hóa chuyên biệt.
  * Dọn sạch các import và liên kết điều hướng preview không còn sử dụng.

---

## [0.6.5+20] - 2026-09-04 (Native In-App OTA Updater with Dio & AndroidX FileProvider)

### [Added]
- **🚀 Hệ Thống Tự Động Cập Nhật Trong Ứng Dụng (Native In-App OTA Updater):**
  * Thay thế triệt để cơ chế mở trình duyệt tải file APK thủ công bằng luồng tải và cài đặt trực tiếp không gián đoạn trong ứng dụng.
  * Sử dụng **Dio** để tải file APK từ GitHub Releases với luồng Stream tiến trình thời gian thực (`Stream<OtaDownloadProgress>`).
  * Đo lường và hiển thị chi tiết: Phần trăm (`%`), dung lượng đã tải (`MB / MB`), tốc độ truyền dữ liệu thực tế (`MB/s`) mỗi 300ms mượt mà và hỗ trợ `CancelToken` hủy tải bất cứ lúc nào.
- **🛡️ Cầu Nối Native Android Hiện Đại (MethodChannel & AndroidX FileProvider):**
  * Thiết lập kênh giao tiếp `com.herflow.app/installer` trên Kotlin `MainActivity.kt`.
  * Cấu hình `androidx.core.content.FileProvider` với quyền `REQUEST_INSTALL_PACKAGES` và `file_paths.xml` an toàn.
  * Kích hoạt `Intent.ACTION_VIEW` cùng cờ `FLAG_GRANT_READ_URI_PERMISSION`, tương thích tuyệt đối với Android 10, 11, 12, 13, 14 và Xiaomi HyperOS/MIUI.
  * Tự động kiểm tra quyền cài đặt ứng dụng không rõ nguồn gốc (`canRequestPackageInstalls()`), mở 1 chạm tới `ACTION_MANAGE_UNKNOWN_APP_SOURCES`.
  * Tích hợp `WidgetsBindingObserver`: Tự động nhận diện khi người dùng vừa cấp quyền và quay lại app để lập tức kích hoạt PackageInstaller.
- **✨ Nâng Cấp Giao Diện Hộp Thoại Cập Nhật (`AppUpdateDialog`):**
  * Thiết kế hiện đại với biểu tượng Moona phát sáng, badge thông tin phiên bản và dung lượng.
  * Thanh tiến trình `LinearProgressIndicator` bo góc mượt mà, pill hiển thị tốc độ MB/s nổi bật.
  * Các thẻ trạng thái thông minh: Đang tải, Hướng dẫn cấp quyền, Sẵn sàng cài đặt và Tải lại qua trình duyệt web dự phòng.

---

## [0.6.4+19] - 2026-09-03 (Bidirectional Mini Love Notes Thread & Outgoing Blindspot Elimination)

### [Added]
- **💬 Hộp Thư Yêu Thương 2 Chiều (`LoveNotesThreadModal`):**
  * Nâng cấp luồng tin nhắn thành hộp thoại Timeline 2 chiều mini hoàn chỉnh giữa Vợ và Chồng.
  * Phân biệt rõ ràng bong bóng chat của Bản thân (bên phải, màu hồng thương hiệu) và Người thương (bên trái, pastel).
  * Hiển thị thiệp tín hiệu (Care Signal Badge) nổi bật cho các yêu cầu hành động (Ôm, Nước ấm, Cà phê...).
  * Thanh soạn thảo cố định đáy modal tích hợp Quick Suggestion Chips và TextField gõ tự do (chống tràn bàn phím).
- **🔄 Phản Hồi Tạo Document Độc Lập:**
  * Sửa đổi cơ chế phản hồi nhanh của Chồng/Vợ: Mỗi lượt phản hồi tạo một Document mới độc lập trong subcollection `care_signals` thay vì merge đè vào tin cũ.
  * Bổ sung `CareSignalType.reply` và Stream `coupleCareSignalsStreamProvider` lắng nghe tới 30 tin nhắn gần nhất.
- **✨ Triệt Tiêu Lỗi Outgoing Blindspot:**
  * Banner trên trang chủ của Vợ (`CycleScreen`) và Chồng (`HusbandViewScreen`) cập nhật trạng thái thời gian thực cả khi vừa gửi đi lẫn khi nhận được tin.
  * Nhấn vào Banner hoặc Icon Trái tim trên AppBar lập tức mở `LoveNotesThreadModal`.

### [Fixed]
- **🛠️ Khắc Phục Dứt Điểm Lỗi Crash Khi Bấm Nút [Quản lý] Trạng Thái Kết Nối:**
  * Thay thế chuyển hướng `PairingScreen` bằng Modal BottomSheet `_showConnectionManagementSheet` chuyên dụng trong Cài đặt.
  * Hiển thị mã liên kết rút gọn kèm nút sao chép 1 chạm an toàn (bọc `try/catch` Clipboard, chống null fallback và hiện SnackBar).
  * Xác thực hủy kết nối cặp đôi với cảnh báo đỏ qua `MoonaConfirmDialog`.

---

## [0.6.3+18] - 2026-09-03 (Establish Business Matrix, Husband 4-Tab Layout & Visual UX Hardening)

### [Added]
- **💌 Tính Năng Gửi Tin Nhắn Tùy Biến Cho Vợ (Wife Custom Love Note & Care Signal Sheet):**
  * Nâng cấp `CareSignalSheet`: Bổ sung ô nhập liệu tự do (tối đa 150 ký tự, có bộ đếm) để Nàng nhắn bất cứ điều gì cho Chàng (thèm đồ ăn, cần ôm, tâm sự...).
  * 6 Quick Suggestion Chips gợi ý cảm xúc nhanh một chạm.
  * Tối ưu UX bàn phím: Chống tràn pixel và che khuất nút gửi khi bàn phím ảo bung lên.
  * Nút "Gửi cho [Anh] 💕" cá nhân hóa theo danh xưng, cờ chống spam và thông báo gửi thành công.
- **💬 Hiển Thị Bong Bóng Tin Nhắn Tình Cảm Trên Giao Diện Chồng (Husband Love Note Bubble):**
  * Hiển thị nổi bật lời nhắn Nàng tự gõ với định dạng trích dẫn ngọt ngào (`💌 Lời nhắn từ [Em bé]: "[Nội dung]"`).
  * Bộ nút phản hồi nhanh 1 chạm: *"❤️ Anh biết rồi nhé"*, *"🚗 Anh qua với em ngay"*, *"🛵 Anh đang mua đồ ăn về nè"*, *"🫂 Gửi nàng cái ôm thật chặt"*, *"☕ Anh pha nước ấm cho em liền"*.
- **🗺️ Ban Hành Bản Đồ Nghiệp Vụ Toàn Dự Án (`docs/APP_BUSINESS_MATRIX.md`):**
  * Định nghĩa chi tiết ma trận phân quyền 2 vai trò: Vợ (RW dữ liệu chu kỳ/cảm xúc), Chồng (RO + Care Actions).
  * Quy chuẩn trạng thái kết nối: Unpaired (Offline Demo) vs Paired (Realtime Sync qua `couples/{coupleId}`).
  * Bản đồ điều hướng 4 Tab độc lập cho Vợ và Chồng trong `MainNavScreen`.
  * Cơ chế đồng bộ đối xứng 4 trường danh xưng (Perspective Mapping) và bảo vệ dữ liệu cục bộ AES.
- **🛡️ Cập Nhật Quy Tắc Ràng Buộc Kiến Trúc Cốt Lõi Vào `AGENTS.md`:**
  * Bổ sung Điều 0: Bắt buộc đối chiếu `APP_BUSINESS_MATRIX.md` trước khi code/refactor.
  * Nguyên tắc Zero Regression: Cô lập hoàn toàn luồng Vợ và luồng Chồng, không để sửa một bên làm gãy bên kia.
  * Bảo đảm tính toàn vẹn đa tài khoản (`UserScope`) và đồng bộ hai chiều.

### [Changed]
- **🧭 Phân Tách Layout 4 Tab Hoàn Chỉnh Cho Vai Trò Chồng (`MainNavScreen`):**
  * Xây dựng `_buildHusbandLayout()` với `IndexedStack` và `NavigationBar` 4 tab độc lập: Trang chủ, Cảm xúc, Dinh dưỡng, Cài đặt.
  * Chồng có thể chuyển tab mượt mà, truy cập đầy đủ `SettingsScreen` và thực hiện Đăng xuất.
- **💕 Nâng Cấp Tab 1 (Cảm xúc nàng - `MoodScreen`):**
  * Chuyển toàn bộ các bộ chọn mức năng lượng, thẻ tâm trạng và triệu chứng sang chế độ **Read-Only** cho Chồng.
  * Tích hợp bảng "Tín Hiệu Yêu Thương & Chăm Sóc Nàng" với các nút 1-chạm gửi cái ôm 🤗, mang nước ấm 🍵, nhắn nhủ nghỉ ngơi 🛋️, hoặc mở nhanh hộp thư gửi tin nhắn riêng.
- **🥗 Nâng Cấp Tab 2 (Dinh dưỡng chăm sóc - `NutritionScreen`):**
  * Điều chỉnh góc nhìn sang "Chàng chuẩn bị cho Nàng": Lời dặn dò quý ông theo 4 pha sinh học, danh mục thực phẩm nên mua & nấu, thức uống nên pha bưng tận tay và thực đơn gợi ý.

### [Fixed]
- **📱 BUG-01 & BUG-08:** Khắc phục triệt để hiện tượng BottomNav Chồng bị đóng băng/trỏ về 1 màn hình và mất lối vào Cài đặt.
- **🔗 BUG-04:** Sửa logic hiển thị banner kết nối trong `HusbandViewScreen` — phân tách rõ trạng thái đã ghép đôi (card xanh tĩnh) và chưa ghép đôi (banner CTA).
- **🔤 BUG-03:** Sửa lỗi phụ đề AppBar bị cắt ngắn bằng cách bọc trong `Flexible` + `maxLines: 2`.

---

## [0.6.2+17] - 2026-09-03 (Native OTA In-App Download, Role Switching & Bi-directional Nickname Sync)

### [Added]
- **📥 Native In-App OTA Update với Thanh Tiến Trình % Thực Tế:**
  * Bổ sung gói `ota_update: ^5.0.0` và quyền `REQUEST_INSTALL_PACKAGES` trong `AndroidManifest.xml`.
  * `AppUpdateDialog` hỗ trợ tự tải tệp APK và hiển thị thanh tiến trình % trực tiếp (`LinearProgressIndicator`).
  * Tự động gọi Intent Package Installer của Android ngay khi hoàn tất tải về; có nút fallback tải qua trình duyệt ngoại vi nếu từ chối quyền.
- **🔄 Mở Khóa Tính Năng Đổi Vai Trò (Vợ / Chồng) Trong Cài Đặt:**
  * Thêm thẻ tương tác "Vai trò của bạn" kèm BottomSheet lựa chọn trực quan giữa 🌸 Vợ và 🛡️ Chồng.
  * Phân luồng logic: Nếu chưa ghép đôi (`!isPaired`), chuyển đổi tức thì và lưu vào Hive scoped + Firestore `users/{uid}`. Nếu đã ghép đôi (`isPaired`), cảnh báo hoán đổi vị trí trước khi đồng bộ lên `couples/{coupleId}`.
- **💑 Đồng Bộ Hai Chiều Hồ Sơ & Danh Xưng Cặp Đôi (Bi-directional Sync):**
  * Chuẩn hóa schema trên `couples/{coupleId}` với 4 trường: `wifeCallPartner`, `wifeSelfCall`, `husbandCallPartner`, `husbandSelfCall`.
  * Lắng nghe Realtime Stream qua `StreamSubscription` trên `couples/{coupleId}`, nạp tức thì vào `NicknameConfigProvider` mà không cần khởi động lại app.
  * Logic Perspective Mapping: Vợ thấy cách Chồng gọi mình và Chồng xưng với mình; Chồng thấy cách Vợ gọi mình và Vợ xưng với mình, không bao giờ bị lệch pha danh xưng.
- **✨ Chuẩn Hóa Toàn Diện Hệ Thống Hộp Thoại & Pop-up (MoonaConfirmDialog):**
  * Xây dựng `MoonaConfirmDialog` kế thừa Material 3 và Soft Glassmorphic: Container tròn bo góc pastel chứa icon (~56x56), tiêu đề đậm căn giữa, thông điệp rõ ràng và Action Bar cân xứng ngang hàng (50:50) cao chuẩn 48px.
  * Xóa bỏ 100% các `AlertDialog` ad-hoc gây tình trạng nút lệch dòng, bất cân xứng trên toàn dự án.
  * Áp dụng đồng bộ: Hộp thoại Đăng xuất, Hủy kết nối cặp đôi, Hoán đổi vai trò, Đổi danh xưng tùy chỉnh, và các Modal chu kỳ.
  * Bổ sung cơ chế phòng vệ cho `AppHaptics`: Kiểm tra `Hive.isBoxOpen` an toàn, chống crash khi khởi tạo hoặc chạy Unit Test.

---

## [0.6.1+16] - 2026-09-03 (Cross-Account State Isolation, Late Period Logic & Android 11 Visibility)

### [Fixed]
- **🛡️ Trị Dứt Điểm Race Condition Khi Chuyển Đổi Tài Khoản:**
  * Bổ sung `UserScope.setActiveUid()` và `UserScope.clear()` khóa chặt UID người dùng tức thì khi đăng nhập/đăng xuất trước khi Provider re-evaluate.
  * Trong `AuthController.signOut()` và đăng nhập mới, kích hoạt `_invalidateAllUserScopedProviders()` xóa sạch toàn bộ RAM State tree của tài khoản cũ.
  * Loại bỏ hoàn toàn fallback sang key không có tiền tố trong `UserRoleNotifier`.
- **📱 Cấu hình Package Visibility cho Android 11+:** Bổ sung `<queries>` trong `AndroidManifest.xml` hỗ trợ `launchUrl(LaunchMode.externalApplication)` tải OTA APK mượt mà.
- **🔗 Tối ưu Vòng Đời Ghép Đôi (Pairing Lifecycle):**
  * Stream realtime tự động phát hiện và điều hướng người tạo mã (Host) vào `MainNavScreen` ngay khi đối tác nhập mã kết nối thành công.
  * Chặn triệt để hành vi tự ghép đôi với chính mình trong `connectWithPairingCode`.
- **🌸 Ràng Buộc Sinh Học & Xử Lý Trễ Kinh (Late Period):**
  * Chặn chọn ngày chu kỳ trong tương lai; ràng buộc giới hạn chu kỳ 21-45 ngày và hành kinh 2-10 ngày.
  * Thêm logic `isLate` & `getDaysLate`: Màn hình Vợ hiển thị badge "Trễ kinh X ngày", Màn hình Chồng hiển thị thẻ tâm lý gợi ý vỗ về và chăm sóc chu đáo.
- **💕 Danh Xưng Mặc Định Tinh Tế Theo Vai Trò:**
  * Nàng gọi chàng mặc định là "Anh", Chàng gọi nàng mặc định là "Em bé". Chặn đứng hoàn toàn ô hiển thị bị trống.

---

## [0.6.0+15] - 2026-09-03 (In-App OTA Updates, GitHub Actions CI/CD & Unpaired Logic Hardening)

### [Added]
- **🚀 Tính năng Cập nhật Tự Động Trong Ứng Dụng (In-App OTA Updates):**
  * `AppUpdateService` tự động kết nối GitHub Releases API (`thanhlongts2k/HerFlow`) sử dụng `HttpClient` thuần, bảo toàn dung lượng nhẹ của app.
  * Tự động kiểm tra bản phát hành mới định kỳ mỗi 24 giờ trong nền và hỗ trợ kiểm tra thủ công 1 chạm tại màn hình Cài đặt.
  * Hộp thoại Glassmorphism hiện đại `AppUpdateDialog` hiển thị changelog, kích thước gói APK và nút tải trực tiếp bản `arm64-v8a` tối ưu.
- **⚙️ Pipeline CI/CD GitHub Actions Đóng Gói Tự Động (`.github/workflows/build_release.yml`):**
  * Kích hoạt tự động khi gắn tag phiên bản `v*` hoặc qua `workflow_dispatch`.
  * Khôi phục an toàn `google-services.json` từ GitHub Secret `GOOGLE_SERVICES_JSON_BASE64` cho repo Public.
  * Quality Gate tự động: `flutter analyze` & `flutter test` trước khi build.
  * Biên dịch song song cả bản tách chip `moona-arm64-v8a.apk` (~27MB) và bản phổ thông `moona-universal.apk`, tự động đăng tải lên GitHub Releases.

### [Changed]
- **🔒 Chuẩn Hóa Logic Khi Chưa Ghép Đôi (`isPaired == false`):**
  * Màn hình Chồng: Ẩn hoàn toàn tính năng Hỏi thăm & Nhắn nhủ nhanh, thay bằng thẻ hướng dẫn ghép đôi thân thiện.
  * Màn hình Vợ: Ẩn banner thông báo tin nhắn và phản hồi từ Chồng khi tài khoản chưa kết nối.
  * Hộp thoại Tín hiệu yêu thương (`CareSignalSheet`): Hiển thị banner cảnh báo và nút ghép đôi nhanh, vô hiệu hóa gửi tin khi chưa có đối tác.

### [Fixed]
- **🛡️ Trị Dứt Điểm Race Condition Khi Chuyển Đổi Tài Khoản:**
  * Bổ sung `UserScope.setActiveUid()` và `UserScope.clear()` khóa chặt UID người dùng tức thì khi đăng nhập/đăng xuất trước khi Provider re-evaluate.
  * Trong `AuthController.signOut()` và đăng nhập mới, kích hoạt `_invalidateAllUserScopedProviders()` xóa sạch toàn bộ RAM State tree của tài khoản cũ.
  * Loại bỏ hoàn toàn fallback sang key không có tiền tố trong `UserRoleNotifier`.
- **📱 Cấu hình Package Visibility cho Android 11+:** Bổ sung `<queries>` trong `AndroidManifest.xml` hỗ trợ `launchUrl(LaunchMode.externalApplication)` tải OTA APK mượt mà.
- **🔗 Tối ưu Vòng Đời Ghép Đôi (Pairing Lifecycle):**
  * Stream realtime tự động phát hiện và điều hướng người tạo mã (Host) vào `MainNavScreen` ngay khi đối tác nhập mã kết nối thành công.
  * Chặn triệt để hành vi tự ghép đôi với chính mình trong `connectWithPairingCode`.
- **🌸 Ràng Buộc Sinh Học & Xử Lý Trễ Kinh (Late Period):**
  * Chặn chọn ngày chu kỳ trong tương lai; ràng buộc giới hạn chu kỳ 21-45 ngày và hành kinh 2-10 ngày.
  * Thêm logic `isLate` & `getDaysLate`: Màn hình Vợ hiển thị badge "Trễ kinh X ngày", Màn hình Chồng hiển thị thẻ tâm lý gợi ý vỗ về và chăm sóc chu đáo.
- **💕 Danh Xưng Mặc Định Tinh Tế Theo Vai Trò:**
  * Nàng gọi chàng mặc định là "Anh", Chàng gọi nàng mặc định là "Em bé". Chặn đứng hoàn toàn ô hiển thị bị trống.
- **⚙️ Sửa Lỗi CI Signing & Quyền Ghi GitHub Actions:**
  * Theo dõi `debug.keystore` dùng chung trong Git repository để `validateSigningRelease` thành công trên runner GitHub Actions.
  * Cấp quyền `permissions: contents: write` cho workflow để `softprops/action-gh-release` đăng tải bản phát hành thành công.
- **🧹 Dọn dẹp Màn hình Cài đặt:**
  * Xóa bỏ nút chữ lơ lửng "Đổi vai trò" ở góc trên bên phải để bảo vệ tính bất biến của luồng phân quyền tài khoản.
  * Khắc phục bộ xem trước danh xưng khi người dùng chọn 2 danh xưng trùng nhau (ví dụ đều là "Người thương"), tự động hiển thị phân biệt rõ ràng `[Bạn]` và `[Người ấy]`.
- **🎯 Chuẩn hóa Quality Gate 100%:**
  * Khắc phục 14 cảnh báo `prefer_const_constructors` trong `husband_view_screen.dart` và `settings_screen.dart`.
  * Đảm bảo `flutter analyze` đạt 0 issues và toàn bộ 20 unit tests pass 100%.

---

## [0.5.4+14] - 2026-09-03 (Release Size Optimization 27MB, Upright Moon Icon & Firestore Role Fix)

### [Added]
- **🔒 Quy tắc bảo mật Firestore Users (`firestore.rules`):** Bổ sung rule `match /users/{userId}` cho phép đọc/ghi vai trò người dùng phục vụ đồng bộ đám mây và ghép đôi.
- **⚡ Tối ưu hoá dung lượng APK Split-per-ABI:** Đóng gói bản Release `app-arm64-v8a-release.apk` chỉ còn 27.1 MB (giảm 86.5% so với Fat APK 208 MB).
- **🔑 Chuẩn hóa Shared Debug Keystore trong Repo (`android/app/debug.keystore`):** Cấu hình Gradle đọc trực tiếp keystore của project cho cả Debug và Release, đồng bộ chữ ký SHA-1 giữa máy công ty và máy ở nhà để loại trừ dứt điểm lỗi Google Sign-In `ApiException: 10`.

### [Changed]
- **🚀 Khôi phục vai trò tự động khi đăng nhập và khởi động:**
  * Bổ sung `_checkCloudRoleAsync` trong `AuthController._init()` để tự động đối soát Firestore và nạp vai trò vào State khi app mở.
  * `LoginScreen`: Nếu tài khoản đã có `role` trên Cloud, điều hướng thẳng vào `AppRoutes.home`, bỏ qua hoàn toàn `RoleSelectionScreen`.

### [Fixed]
- Sửa lỗi cú pháp Flutter UI (`CardThemeData` -> `CardTheme`, `activeThumbColor` -> `activeColor`).
- Sửa cấu hình Gradle 8.9, AGP 8.7.0, Kotlin 2.0.21, NDK 27, `minSdk = 23`.

---

## [0.5.3+13] - 2026-09-03 (Account-Bound Role Synchronization & Cross-Device Cloud Persistence)

### [Added]
- **☁️ Ràng Buộc Vai Trò Theo Tài Khoản Cloud (`Account-Bound User Role`):**
  * Bổ sung trường `role` ("wife" | "husband") trong [UserModel](file:///d:/Sources/HerFlow/lib/features/auth/domain/models/user_model.dart) và đồng bộ trực tiếp lên Cloud Firestore document `users/{uid}`.
  * Thêm hàm `getUserRoleFromFirestore(uid)` và `syncUserRoleToFirestore(uid, role)` trong [AuthRepository](file:///d:/Sources/HerFlow/lib/features/auth/data/auth_repository.dart).
  * `UserRoleNotifier.setRole(role, {uid})`: Tự động đẩy vai trò lên Cloud Firestore document `users/{uid}` ngay khi người dùng chọn vai trò.

### [Changed]
- **🚀 Luồng Đăng Nhập & Khôi Phục Vai Trò Đa Thiết Bị:**
  * Khi đăng nhập Google thành công, hệ thống tự động đọc `users/{uid}.role` từ Firestore.
  * Nếu đã có vai trò: Cập nhật ngay vào Hive + `userRoleProvider`, bỏ qua hoàn toàn màn hình chọn vai trò và điều hướng thẳng vào `AppRoutes.home`.
  * Nếu là tài khoản mới tinh: Điều hướng vào `RoleSelectionScreen`.
- **🔄 Khôi Phục Vai Trò Ngay Khi Khởi Động (`lib/main.dart`):**
  * Trường hợp app bị xóa cài lại hoặc đăng nhập trên thiết bị mới, `main()` tự động khôi phục vai trò từ Cloud Firestore để mở thẳng màn hình chính.

### [Fixed]
- **🧹 Dọn Sạch Cache Khi Đăng Xuất (`Sign Out`):**
  * Khi người dùng bấm Đăng xuất tại Cài đặt, hệ thống xóa triệt để `app_user_role`, `partner_user_role`, `keyHasSelectedRole`, `keyIsOnboardingCompleted` và gọi `userRoleProvider.notifier.resetRole()`.
  * Ngăn chặn 100% tình trạng tài khoản sau đăng nhập bị nhận nhầm vai trò lưu tạm của tài khoản trước.

---

## [0.5.2+12] - 2026-09-03 (Husband Quick Chat, 1-Touch Response Loop, Brand Launcher Icons & Stability)

### [Added]
- **💬 Modal Chat Nhanh Hỏi Thăm Nàng (`HusbandQuickChatSheet`):**
  * Thêm BottomSheet cho phép Người thương (Chồng) gửi câu hỏi thăm/quan tâm thích ứng thông minh theo thể trạng và pha chu kỳ của nàng.
  * Tự động thay đổi bộ câu hỏi gợi ý: Pha Kinh nguyệt / Hoàng thể (chăm sóc, chườm ấm, đồ ăn ngon, nghỉ ngơi) vs Pha Nang trứng / Rụng trứng (hẹn hò, đón tan làm, dạo mát).
  * Ô nhập tin nhắn tự do bo góc trang nhã với placeholder tự động chèn danh xưng của nàng (`callPartnerAs`).
- **⚡ Vòng Lặp Phản Hồi 1 Chạm 2 Chiều (`_HusbandResponseBanner`):**
  * Màn hình Vợ (`CycleScreen`) tự động phát hiện tin nhắn từ Chồng, kích hoạt rung haptic nhẹ và hiển thị banner nổi bật trên đầu màn hình.
  * Hiển thị ngay 4 nút phản hồi nhanh 1 chạm cho nàng:
    + 🥺 *"Hơi mệt và mỏi lưng anh ơi"*
    + 🧋 *"Em thèm trà sữa / đồ ngọt"*
    + 🥰 *"Em khỏe re, nhớ anh nè"*
    + 🛌 *"Em đang nằm nghỉ chút"*
  * Khi Vợ bấm chọn: Gọi `respondCareSignal` đẩy dữ liệu lên Cloud Firestore -> Màn hình Chồng tự động chuyển sang trạng thái đã phản hồi ngay tức thì.
- **🌙 Bộ Biểu Tượng Hệ Thống Moona Đồng Bộ (`ic_launcher`):**
  * Thiết kế logo chuẩn nghệ thuật Moona: Đĩa tròn gradient hồng hoa hồng sang tím đêm kèm vầng trăng khuyết vàng dịu dàng.
  * Cấu hình `flutter_launcher_icons` với `android: true` để ghi đè toàn diện `ic_launcher` trên toàn bộ thư mục mật độ `res/mipmap-*` và màn hình Quản lý ứng dụng (App Info) của hệ điều hành Android.
  * Tạo widget nhận diện thương hiệu tái sử dụng [MoonaBrandLogo](file:///d:/Sources/HerFlow/lib/core/widgets/moona_brand_logo.dart) đồng bộ trong `LoginScreen` và `SettingsScreen`.

### [Changed]
- **🎭 Tối Ưu Thẻ Chọn Vai Trò Onboarding (`RoleSelectionScreen`):**
  * Tái cấu trúc 2 thẻ chọn vai trò ("Tôi là Phụ nữ" / "Tôi là Người thương") từ dạng khối dọc cồng kềnh sang dạng thẻ ngang nhỏ gọn (Compact ListTile, ~100-110dp).
- **🔒 Phân Quyền Màn Hình Ghép Đôi (`PairingScreen`):**
  * Tách biệt theo vai trò `userRole`: Người thương (Chồng) chỉ hiển thị ô nhập mã của nàng; Bạn nữ (Vợ) chỉ hiển thị mã số và nút chia sẻ.

### [Fixed]
- **🛡️ Khắc Phục Triệt Để Crash On Launch Do R8 Minification:**
  * Sửa lỗi `Failed to create an instance of androidx.work.impl.WorkDatabase` do R8 xóa nhầm native classes của WorkManager và Room.
  * Thiết lập an toàn `isMinifyEnabled = false` và `isShrinkResources = false` trong `android/app/build.gradle.kts`.
- **📏 Khắc Phục Triệt Để Lỗi Bể Giao Diện (Overflow 9.8px & 1.7px):**
  * `CycleCalendarView`: Loại bỏ nút điều hướng tháng `<` `>` thừa (đã có sẵn trong `TableCalendar`), bọc tiêu đề trong `Expanded` + `Flexible` tránh tràn 9.8px.
  * `HusbandViewScreen` & `CycleHeroIndicator`: Thay thế `Row` thành `Wrap` cho các cụm chip trạng thái, bảo đảm co giãn hoàn hảo trên thiết bị có màn hình hẹp.

---

## [0.5.1+11] - 2026-09-03 (Moona Crescent Moon Launcher Icon & Post-Auth Cleanup)

### [Added]
- **🌙 Bộ biểu tượng ứng dụng chính thức Moona (Official Launcher Icons):**
  * Thiết kế và tạo logo vầng trăng khuyết nghệ thuật (Moona Crescent Moon) chuẩn 1024x1024 px trên nền màu tím đêm `#1E1B2E`.
  * Tích hợp `flutter_launcher_icons`: sinh trọn bộ icon Android đa độ phân giải (`mipmap-mdpi`, `mipmap-hdpi`, `mipmap-xhdpi`, `mipmap-xxhdpi`, `mipmap-xxxhdpi`).
  * Cấu hình Android Adaptive Icon (`mipmap-anydpi-v26/launcher_icon.xml`) với viền an toàn 16% và màu nền `#1E1B2E`.
  * Cập nhật `AndroidManifest.xml` trỏ cả `android:icon` và `android:roundIcon` vào `@mipmap/launcher_icon`.
- **🔑 Hỗ trợ serverClientId cho Google Sign-In:**
  * Bổ sung tham số `serverClientId` trong `AuthRepository` để sẵn sàng nhận Web Client ID (client_type: 3).

### [Changed]
- **🧹 Dọn dẹp thành phần thử nghiệm tạm thời:**
  * Loại bỏ hoàn toàn Floating Action Chip chuyển vai trò nhanh trên màn hình chính (`_buildDebugRoleSwitcher` trong `MainNavScreen`).
  * Chuyển mục Vai trò trong Cài đặt (`SettingsScreen`) sang dạng Read-only Badge có huy hiệu "Cố định".

---

## [0.5.0+10] - 2026-09-03 (Google Auth, Role Onboarding, Nickname Engine & Independent Partner Cycle)

### [Added]
- **🔐 Tích hợp Xác thực Google Sign-In & Firebase Auth toàn diện:**
  * Thêm màn hình Đăng nhập `LoginScreen` phong cách Liquid Glass trang nhã.
  * Hỗ trợ đăng nhập 1 chạm với tài khoản Google thực tế và chế độ Demo tiện lợi (`signInAsDemo`).
  * Lưu trữ hồ sơ người dùng cục bộ (`userBox`) và đồng bộ lên Firestore `users/{uid}` (Avatar, Tên hiển thị, Email).
- **🎭 Onboarding Phân vai trò & Chu kỳ độc lập cho Người thương:**
  * Màn hình `RoleSelectionScreen` chào đón với Avatar người dùng và 2 thẻ lựa chọn lớn:
    - `[ 🌸 Tôi là Phụ nữ ]`: Điều hướng vào quy trình thiết lập chu kỳ chi tiết cho bạn nữ.
    - `[ 🛡️ Tôi là Người thương ]`: Mở BottomSheet gồm 2 phương án:
      * `[ 🔗 Đã có mã ghép đôi từ nàng ]`: Nhập mã kết nối Firestore như thông thường.
      * `[ 📝 Tự thiết lập chu kỳ của nàng ]`: Cho phép Chàng tự thiết lập ngày kinh gần nhất, độ dài chu kỳ và số ngày hành kinh để theo dõi độc lập khi nàng chưa dùng app.
- **🏷️ Động cơ danh xưng tùy biến (Nickname Engine):**
  * Model `NicknameConfig` với các thiết lập: `callPartnerAs` (Bạn gọi người ấy là) & `selfCallAs` (Bạn tự xưng là).
  * Danh sách preset phong phú: `['Người thương', 'Em bé', 'Bé iu', 'Vợ yêu', 'Chồng yêu', 'Anh yêu', 'Bạn đời']` kèm ô nhập tùy ý ("Tự gõ").
  * Lưu trữ bền vững tại Hive `settingsBox` và đồng bộ lên Firestore `couples/{coupleId}`.
  * Live Preview hiển thị câu đối thoại tương tác sinh động ngay trong Cài Đặt.
- **🌸 Tích hợp giao diện hiển thị danh xưng & chu kỳ nàng:**
  * **Phía Vợ (`CycleScreen`):**
    - AppBar hiển thị Couple Badge có tên xưng hô của Chồng (`🛡️ [Danh xưng]`).
    - Banner phản hồi từ Chồng hiển thị chính xác danh xưng Chồng tự xưng.
  * **Phía Chồng (`HusbandViewScreen`):**
    - Subtitle AppBar, Hero Card, Hộp tín hiệu và Quick Chips tự động thay đổi theo danh xưng cấu hình.
    - Thẻ tóm tắt chu kỳ sinh học của nàng (`_buildCycleSummaryCard`) hiển thị ngày kỳ kinh tới, cửa sổ rụng trứng và nút mở Lịch chi tiết (`_showPartnerCalendarModal`).
  * **Mục Cài Đặt (`SettingsScreen`):**
    - Thẻ hồ sơ người dùng Google (`_buildUserProfileCard`) kèm nút Đăng xuất an toàn.
    - Nhóm tùy chỉnh Danh xưng (`_buildNicknameSection`).
    - Nhóm hiệu chỉnh chu kỳ của người thương (`_buildPartnerCycleSection` & `_showEditPartnerCycleModal`).

### [Changed]
- **🧹 Dọn dẹp thành phần thử nghiệm & Khóa vai trò theo tài khoản (Post-Auth Cleanup):**
  * Gỡ bỏ hoàn toàn nút Floating Action Chip chuyển role nhanh tạm thời trên màn hình chính (`_buildDebugRoleSwitcher` trong `MainNavScreen`).
  * Chuyển đổi mục "Vai trò ứng dụng" trong Cài đặt (`SettingsScreen`) từ nút bấm tương tác sang thẻ thông tin tĩnh dạng **Read-only Badge** có huy hiệu "Cố định", giải thích rõ vai trò gắn chặt với tài khoản Google đang đăng nhập và chỉ cho phép đổi khi đăng xuất hoặc đặt lại tài khoản.

---

## [0.4.0+9] - 2026-09-03 (Realtime 2-Way Feedback Loop & Multi-Device Sync)

### [Added]
- **🔄 Vòng lặp phản hồi tương tác 2 chiều Realtime hoàn chỉnh (2-Way Realtime Feedback Loop):**
  * **Phía Vợ (CycleScreen):**
    - Lắng nghe realtime `Stream<CareSignalModel?>` qua `latestCareSignalStreamProvider`.
    - Tự động hiển thị `_HusbandResponseBanner` nổi bật ở đầu màn hình ngay khi Chồng phản hồi: `💖 Lời nhắn từ Chồng yêu 💕`, hiển thị nội dung tin nhắn của Chồng kèm ngữ cảnh tín hiệu ban đầu (`Phản hồi cho: "Muốn được ôm 🤗"`).
    - Tự động kích hoạt hiệu ứng rung nhẹ xúc giác `AppHaptics.light()` khi nhận tin nhắn phản hồi.
    - Hỗ trợ nút đóng nhanh `✕` và timer tự động ẩn sau 10 giây.
  * **Phía Chồng (HusbandViewScreen):**
    - Nhận tín hiệu yêu thương thời gian thực với đầy đủ 4 nút phản hồi nhanh 1 chạm.
    - Chồng bấm phản hồi -> Đổi ngay sang badge xác nhận `"Bạn đã phản hồi: '[Tin nhắn]'"` kèm SnackBar thông báo.
- **⚡ Tự động đồng bộ thể trạng Vợ lên Cloud (Wife Status Auto-Sync):**
  * Nâng cấp `PartnerStatusModel` bổ sung trường `cycleDay` và `moodSummary`.
  * Hook tự động kích hoạt `syncTodayStatus()` ngay khi Vợ cập nhật tâm trạng/mức năng lượng trong ngày tại `SelectedDateMoodController`.
  * Tự động gọi `syncCurrentWifeStatusToCloud()` khi mở màn hình `CycleScreen`.
  * Màn hình Chồng lập tức cập nhật thời gian thực mà không cần thao tác vuốt hay tải lại trang.
- **🛡️ Cơ chế Dual-Collection Firestore & In-Memory Sorting chống lỗi index:**
  * Đồng bộ song song vào cả `couples/{coupleId}` và `pairings/{pairingCode}` với `.set(..., SetOptions(merge: true))`, loại bỏ hoàn toàn rủi ro lỗi `NOT_FOUND` của `.update()`.
  * Triển khai sắp xếp in-memory theo `sentAt` giảm dần, loại bỏ phụ thuộc vào composite index của Firestore.
- **🚀 Kịch bản Deploy đa thiết bị tự động (`scripts/deploy.ps1 -Target all`):**
  * Tự động quét toàn bộ thiết bị đang kết nối ADB (cả máy thật và giả lập).
  * Build APK một lần duy nhất và nạp đồng thời lên tất cả thiết bị.

---

## [0.4.0+2] - 2026-09-03 (Role-Based Architecture & Dynamic Navigation)

### [Added]
- **👥 Phân định vai trò người dùng (Role-Based Architecture):**
  * Định nghĩa `enum UserRole { wife, husband }` kèm extension helper (`isWife`, `isHusband`, `displayName`, `shortName`, `emoji`) trong `lib/core/constants/user_role.dart`.
  * Xây dựng `userRoleProvider` (Riverpod `StateNotifier`) đọc/ghi trạng thái từ Hive (`app_user_role` & `partner_user_role`) để toàn bộ ứng dụng cập nhật real-time.
- **📱 Cấu trúc giao diện động theo vai trò (Dynamic Main View):**
  * **Vai trò Vợ (`UserRole.wife`):**
    - Hiển thị Bottom Navigation 4 tab đầy đủ dành cho phái nữ: [0: Chu kỳ, 1: Cảm xúc, 2: Dinh dưỡng, 3: Cài đặt].
    - Nút icon Khiên (`Icons.shield_outlined`) trên AppBar và ListTile trong Cài Đặt cho phép Vợ "Xem trước Góc nhìn của Chồng" (`HusbandViewScreen(isWifePreview: true)` có banner giải thích và nút đóng).
    - Màn hình Ghép đôi: Mặc định mở tab 0 "Dành cho Vợ" (Tạo mã ghép đôi).
  * **Vai trò Chồng (`UserRole.husband`):**
    - Mở app vào THẲNG màn hình "Góc Nhìn Của Anh" (Gentleman's Companion), loại bỏ hoàn toàn Bottom Navigation theo dõi chu kỳ phái nữ.
    - AppBar có nút Cài đặt và trạng thái đồng bộ Live.
    - Màn hình Ghép đôi: Mặc định mở tab 1 "Dành cho Chồng" (Nhập mã ghép đôi từ nàng).
- **🎛️ Bộ công cụ chuyển vai trò tiện lợi trên 1 thiết bị:**
  * Thêm nhóm "Vai Trò Ứng Dụng" trong `SettingsScreen` với 2 thẻ chọn `_RoleCard`: `[ 🌸 Tôi là Vợ ]` và `[ 🛡️ Tôi là Chồng ]`, chuyển đổi ngay lập tức không cần khởi động lại.
  * Bổ sung nút chuyển role nhanh dạng Floating Action Chip (chỉ kích hoạt ở `kDebugMode`): `🌸 Mode: Vợ ⇄` / `🛡️ Mode: Chồng ⇄` ở góc màn hình, kiểm thử 1 máy chỉ với 1 chạm.
- **🧪 Unit Tests:**
  * Bổ sung 3 test cases cho `UserRole` và các helper extension trong `test/widget_test.dart` (14/14 tests pass 100%).

---

## [0.4.0+1] - 2026-09-03 (Husband View Redesign & 2-Way Care Signals)

### [Added]
- **👔 Redesign toàn diện màn hình "Góc nhìn anh" (Gentleman's Companion):**
  * Thiết kế lại giao diện theo phong cách nam tính, lịch lãm (Dark Slate / Deep Navy kết hợp Warm Amber).
  * **Hero Card nhiệt kế thể trạng:** Hiển thị rõ tên pha chu kỳ, ngày chu kỳ, lời giải thích tinh tế viết riêng cho nam giới, và thanh đo Pin năng lượng trực quan (🪫 Cạn kiệt, 🔋 Đang hồi phục, ⚡ Tràn đầy).
  * **Gentleman's Playbook (Tuyệt chiêu cho chàng):** Phân 3 khối rõ ràng:
    - 🎯 *Nên làm ngay:* Chườm ấm, chuẩn bị trà gừng, làm việc nhà giúp nàng.
    - 🚫 *Điều cấm kỵ:* Không tranh cãi lý lẽ, không hỏi dồn dập "Sao em cứ cáu thế?", không trễ hẹn.
    - 💡 *Gợi ý món nàng thích:* Trà thảo mộc, súp ấm, socola ngọt thanh.
  * **Banner kết nối thông minh:** Tự động lắng nghe Live Firestore khi đã ghép đôi, hoặc hiển thị từ Hive local kèm lối tắt kết nối nhanh.
- **💕 Tín hiệu yêu thương tương tác 2 chiều (2-Way Care Signals):**
  * Nâng cấp `CareSignalModel` hỗ trợ `responseMessage`, `respondedAt`, `isResponded`.
  * Phía Vợ (`CareSignalSheet`): Chạm gửi tín hiệu trực tiếp lên Firestore (`pairings/{coupleId}/care_signals`) và Hive local, loại bỏ hoàn toàn thông báo tạm.
  * Phía Chồng: Hiển thị hộp tín hiệu nổi bật với thời gian tương đối (Vừa xong, X phút trước).
  * **Bộ 4 nút phản hồi nhanh 1 chạm cho Chồng:**
    - 🛵 *"Anh đang mua đồ ăn về nè"*
    - 🫂 *"Gửi nàng cái ôm thật chặt"*
    - 💖 *"Ngoan đợi anh về nhé"*
    - ☕ *"Anh pha nước ấm cho em liền"*
  * Chồng bấm phản hồi -> Cập nhật trực tiếp lên Firestore và đổi badge sang trạng thái "Bạn đã phản hồi".

---

## [0.3.0+7] - 2026-09-03 (Cycle Projection Engine & Actual vs Predicted Calendar)

### [Fixed]
- **🧹 Dọn sạch dữ liệu rác cũ (Dirty mock data):**
  - Khắc phục hiện tượng tháng 8 hiển thị 3 kỳ kinh (02-06, 11-15, 28-31) gây phi thực tế: Thêm cơ chế migration `_cleanDirtyRecords()` trong `CycleLocalDataSource` tự động thanh lọc các bản ghi rác và khóa mốc chuẩn duy nhất 11/08 - 15/08.
  - Loại bỏ hoàn toàn việc thuật toán modulo tự động vẽ các kỳ kinh ảo ngược về quá khứ trước mốc chuẩn (`anchorStart`).
- **🔲 Khắc phục lỗi đè nút "Chỉnh sửa chu kỳ":**
  - Xóa bỏ `Stack` overlay trên lịch trong `cycle_screen.dart`.
  - Tách nút "Chỉnh sửa chu kỳ" thành Action Chip thanh lịch nằm trên thanh tiêu đề của thẻ lịch, không còn đè lên nút "Month" hay phím chuyển tháng của `TableCalendar`.
- **🛡️ Khắc phục triệt để lỗi crash `LateInitializationError` trên `CycleCalendarView`:**
  - Chuyển `_pageController` sang dạng nullable `PageController? _pageController` (bỏ `late`, bỏ `final`).
  - Gán an toàn trong `onCalendarCreated: (pageController) { _pageController = pageController; }`.
  - Giữ trạng thái `_focusedDay` an toàn trong state, tự cập nhật qua `onPageChanged` và `didUpdateWidget`.
  - Sử dụng toán tử null-aware `_pageController?.previousPage` và `_pageController?.nextPage` cho các phím chuyển tháng.
  - Không gọi `dispose()` trên `_pageController` trong `State.dispose()`, để `TableCalendar` tự quản lý vòng đời tránh double-dispose.

### [Added]
- **🔮 Phân định rạch ròi Thực tế vs Dự kiến:**
  - Bổ sung `isActualPeriod`, `isPredictedPeriod`, `isPredicted` vào `CycleDayInfo` và `CycleInfo`.
  - Hiển thị trực quan trên lịch:
    * **Thực tế:** Nền hồng đậm (`AppColors.primary`), icon giọt nước đặc (`Icons.water_drop_rounded`) màu trắng.
    * **Dự kiến:** Nền hồng pastel bán trong suốt, viền hồng (`Border.all`), icon giọt nước nét mảnh (`Icons.water_drop_outlined`).
    * **Rụng trứng:** Icon ngôi sao xanh mint (`Icons.star_rounded`).
  - Thêm thanh chú thích mini (`MiniLegend`) ngay bên dưới lịch (Thực tế • Dự kiến • Rụng trứng).
- **📈 Thuật toán chiếu dự đoán tương lai (Projection Engine):**
  - Lấy mốc chuẩn 11/08 làm Anchor Period, tự động chiếu các chu kỳ tiếp theo trong 3 - 6 tháng (08/09 - 12/09, 06/10 - 10/10...) cùng ngày rụng trứng tương ứng.
  - Bổ sung 3 unit tests mới trong `test/widget_test.dart` xác thực tính toán dự phóng (11/11 tests pass).

---

## [0.3.0+6] - 2026-09-03 (Biometric Deadlock Fix, Realtime Theme & Deploy Tools)

### [Fixed]
- **🚨 Biometric Lock Screen Deadlock:**
  - Khắc phục triệt để lỗi treo cứng "Đang xác thực...": Bọc hàm khởi tạo trong `WidgetsBinding.instance.addPostFrameCallback`.
  - Thêm cờ `_isAuthenticating` chặn gọi authenticate chồng chéo khi nhận sự kiện `resumed`.
  - Khối `try-catch-finally` bảo đảm reset `_isAuthenticating = false` trong mọi tình huống (kể cả khi người dùng hủy hoặc xác thực thất bại).
  - Đổi text nút bấm sang "Chạm để thử lại" khi thất bại.
  - Thêm 2 cơ chế thoát hiểm an toàn: Nút "Mở khóa bằng mật mã máy" (Device PIN/Pattern) và nút "Bỏ qua xác thực (Vào app)" để người dùng không bao giờ bị kẹt ngoài ứng dụng.
- **🎨 Chuyển đổi Theme tức thì không cần khởi động lại app:**
  - Tạo `lib/core/theme/theme_controller.dart` với `themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>`.
  - Chuyển `MoonaApp` trong `lib/main.dart` thành `ConsumerWidget` lắng nghe `themeModeProvider` thời gian thực.
  - Kết nối trực tiếp `SegmentedButton` trong `SettingsScreen` với `themeModeProvider.notifier.setThemeMode(...)`.

### [Added]
- **Bộ công cụ tự động biên dịch và nạp APK lên thiết bị qua ADB:**
  - `scripts/deploy.ps1`: Tự động hóa 5 bước (kiểm tra ADB, `flutter analyze`, build APK debug/release, giải quyết tệp APK, nạp qua `adb install -r -d -t` và tự mở ứng dụng).
  - `run_app.bat`: Nhấp đúp để build debug và deploy nhanh.
  - `run_app_release.bat`: Nhấp đúp để build release (R8/split-per-abi) và deploy.
  - Bổ sung tài nguyên Android Native: `husband_widget_info.xml`, `husband_widget_layout.xml`, `HusbandWidgetProvider.kt`, `strings.xml`.

---

## [0.3.0+5] - 2026-09-03 (Pairing Bugfix & Settings Refactor)

### [Fixed]
- **🐛 Sửa lỗi treo "Đang tạo mã...":** `createPairingCode()` và `connectWithPairingCode()` bọc đầy đủ `try-catch-finally` + `.timeout(Duration(seconds: 5))`.
- **isLoading không reset:** Khối `finally` đảm bảo `isLoading = false` trong mọi tình huống — không bao giờ treo spinner vô tận.

### [Added]
- **Offline Fallback cho Pairing:** Khi Firestore timeout/lỗi, tự động sinh mã `HFxxxx` cục bộ. UI hiển thị badge cam "Mã kết nối nội bộ (Thử nghiệm)".
- **`SettingsScreen`** (`lib/features/settings/presentation/screens/settings_screen.dart`): 4 nhóm: Bảo mật (Biometric + Auto-lock), Đồng bộ đôi, Giao diện (Theme + Haptic), Dữ liệu & Giới thiệu.
- Restored missing v0.3.0 files sau `filter-branch`: `network_connectivity_provider`, `app_version_provider`, `haptic_feedback_utils`, `offline_banner`, `notification_service`, `biometric_lock_screen`, toàn bộ `care_signals/`, `onboarding_screen`.

### [Changed]
- **`CycleSettingsSheet`:** Đổi tên "Hiệu Chỉnh Chu Kỳ", xóa Biometric switch (chuyển sang SettingsScreen).
- **`cycle_screen.dart`:** Icon → `settings_outlined` → SettingsScreen. Thêm chip "Chỉnh sửa chu kỳ" overlay trên lịch.
- **`app_routes.dart`:** Đăng ký route `/settings`.
- **`widget_test.dart`:** Cập nhật test `CareSignalModel` align API mới.

---

## [0.3.0+4] - 2026-09-03 (Security Audit & Hardening)

### [Security]
- **🚨 Khắc phục rò rỉ Firebase API key:** `android/app/google-services.json` đã bị commit vào lịch sử git (commit `70f4f04`). Đã thực hiện `git rm --cached` và bổ sung vào `.gitignore`.
- **Cô lập AES Encryption Key:** Di chuyển hardcoded key `MoonaSec2026!Key@SecretFlow2026!` từ `backup_repository.dart` sang `lib/core/security/backup_encryption_config.dart` — tách biệt bí mật khỏi logic nghiệp vụ với security notice và migration roadmap.

### [Added]
- `android/app/google-services.json.example` — File mẫu với placeholder để đồng nghiệp setup local mà không cần file thật.
- `lib/core/security/backup_encryption_config.dart` — Lớp `BackupEncryptionConfig` quản lý tập trung cấu hình mã hóa AES-256-CBC của Moona.

### [Changed]
- `.gitignore`: Bổ sung toàn bộ danh mục bảo mật: Firebase configs, Keystore files (`.jks`, `.keystore`, `key.properties`), `.env*`, `*.moona`, `*.hive`.
- `AGENTS.md`: Bổ sung **Điều khoản 8 — AN TOÀN BẢO MẬT & QUẢN LÝ KHÓA BÍ MẬT** với 4 mục: chống hardcode secrets, bảo vệ config định danh, kiểm soát `android:exported`, và Security Scan SOP.
- Đổi tên project trong `AGENTS.md` và `CHANGELOG.md` từ "HerFlow" → "Moona" để đồng bộ rebranding.

---

## [0.3.0+3] - 2026-09-03 (Version System Patch)


### [Added]
- `package_info_plus: ^8.0.0` — đọc version động từ hệ thống thay vì hardcode string.
- `lib/core/providers/app_version_provider.dart` — `FutureProvider<AppVersionInfo>` cung cấp `version`, `buildNumber`, `displayString` (`"Moona v0.3.0 (Build 3)"`).

### [Changed]
- `pubspec.yaml`: `version: 1.0.0+1` → `0.3.0+3` — Single Source of Truth, đồng bộ với Semantic Versioning thực tế.
- `build.gradle.kts`: Xác nhận đã dùng `flutter.versionCode` / `flutter.versionName` — không hardcode Android native.

---

## [0.3.0] - 2026-09-03


### [Added]
- **Android Home Screen Widget (Husband Glance Widget):**
  - Tích hợp `home_widget: ^0.7.0`.
  - Thiết kế layout Native Android XML bo tròn 24dp Material You (`res/layout/widget_husband_glance.xml`) và `res/xml/husband_widget_info.xml`.
  - Khởi tạo `HusbandWidgetProvider.kt` với `android:exported="true"` tương thích hoàn toàn Android 12+ chống từ chối cài đặt.
  - Module `WidgetUpdateService` tự động đồng bộ pha sinh học, mức năng lượng và lời khuyên chăm sóc của Chồng từ xa lên màn hình chính.
- **Tín hiệu yêu thương 1-chạm (One-Tap Care Signals):**
  - Thiết kế 4 tín hiệu định sẵn: 🫖 *Chườm ấm*, 🧋 *Đồ ngọt / trà sữa*, 🫂 *Cần một cái ôm*, 🍃 *Cần yên tĩnh*.
  - Giao diện `CareSignalSheet` phía Vợ với 4 thẻ pastel mềm mại kèm phản hồi xúc giác `HapticFeedback.mediumImpact()`.
  - Đồng bộ real-time Firestore lên `CareSignalBannerCard` trên Dashboard của Chồng kèm nút "Đã nhận được ❤️".
- **Hệ thống cảnh báo sớm PMS (PMS Pre-Warning System):**
  - Thuật toán sinh học `isPmsWindow(DateTime date)` và `nextPmsStartDate` trong `CycleInfo` (cảnh báo trước kỳ kinh 7 ngày).
  - Tích hợp `flutter_local_notifications: ^18.0.1` và `timezone: ^0.10.0` với kênh thông báo ưu tiên cao `moona_pms_channel`.
  - Tự động xin quyền runtime `POST_NOTIFICATIONS` trên Android 13+ và lên lịch nhắc nhở lúc 08:00 sáng.
  - Tích hợp Switch kích hoạt thông báo trong `CycleSettingsSheet`.
- **Sao lưu & Khôi phục dữ liệu cục bộ (Backup & Restore):**
  - Tích hợp `file_picker: ^8.1.7`, `share_plus: ^10.1.4`, `encrypt: ^5.0.3`, `crypto: ^3.0.6`.
  - `BackupRepository`: Đóng gói dữ liệu chu kỳ & cảm xúc từ Hive, tính checksum SHA-256, mã hóa AES-256 (CBC mode) ra tệp `.moona`.
  - Luồng khôi phục dữ liệu: Giải mã AES-256, kiểm tra tính toàn vẹn SHA-256 và tự động làm mới (invalidate) toàn bộ state Riverpod.
  - Giao diện `BackupScreen` trực quan với thẻ giải thích bảo mật ngân hàng.
- **Chuẩn hóa phản hồi xúc giác (AppHaptics):**
  - Thư viện tiện ích `AppHaptics` quy chuẩn: `selection()` khi chuyển tab navigation, `light()` khi cuộn slider, `medium()` khi gửi tín hiệu / tick chu kỳ.
- **Tối ưu hóa dung lượng Release APK:**
  - Bật R8 code shrinking `isMinifyEnabled = true` và `isShrinkResources = true` trong `build.gradle.kts`.
  - Cấu hình bảo vệ `proguard-rules.pro` cho Domain/Data models, Hive, Firebase và Plugins.

### [Changed]
- Khai báo quyền `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `USE_EXACT_ALARM`, `VIBRATE` trong `AndroidManifest.xml`.
- Cập nhật `AppConstants.appVersion = '0.3.0'`.

### [Fixed]
- Khắc phục lỗi độ dài khóa AES-256 (chuẩn 32 byte / 256 bits) trong `BackupRepository` và kiểm thử tự động.

---

### [Added]
- **Tái định vị thương hiệu (Rebranding) "Moona":**
  - Cập nhật `android:label="Moona"` trong `android/app/src/main/AndroidManifest.xml`.
  - Cập nhật tiêu đề AppBar, Header và tin nhắn chia sẻ mặc định sang tên gọi thân thương "Moona".
  - Bổ sung và cấu hình `flutter_native_splash: ^2.4.4` với màu nền kem vani (`#FDFBF7`) cho Light Mode và Warm Espresso (`#1A1617`) cho Dark Mode, chạy tạo cấu hình Android native thành công.
- **Giám sát mạng & Hàng đợi đồng bộ ngoại tuyến (Smart Offline Sync Queue):**
  - Bổ sung package `connectivity_plus: ^6.1.0`.
  - Module `lib/core/network/network_connectivity_provider.dart` theo dõi kết nối mạng WiFi/Mobile/Ethernet thời gian thực.
  - Widget `OfflineBanner` dạng thanh cảnh báo mỏng, tinh tế xuất hiện ở đỉnh màn hình khi mất mạng: *"Chế độ ngoại tuyến — Dữ liệu sẽ tự động đồng bộ khi có mạng"*.
  - Cơ chế Smart Offline Queue trong `PartnerSyncRepository`: Tự động lưu cờ `isPendingSync` và bộ đệm trạng thái vào Hive khi offline; tự động lắng nghe và xả hàng đợi (`flushPendingSync`) đẩy lên Firestore ngay khi mạng phục hồi.
- **Luồng chào đón người dùng mới (Onboarding Wizard 3 bước):**
  - Bước 1: Chọn ngày bắt đầu kỳ kinh gần nhất qua DatePicker trực quan.
  - Bước 2: Thanh trượt slider chọn độ dài chu kỳ trung bình (21 - 40 ngày, mặc định 28 ngày) tích hợp **phản hồi xúc giác rung nhẹ (`HapticFeedback.lightImpact()`)** khi kéo trượt.
  - Bước 3: Thẻ chọn mục tiêu đồng hành (Chăm sóc sức khỏe & dinh dưỡng, Ổn định cảm xúc, Đồng bộ cùng Chồng).
  - Tự động lưu thiết lập khởi đầu vào `cycleBox` và chuyển thẳng vào Dashboard chính.
- **Bảo mật sinh trắc học cao cấp (Biometric Authentication):**
  - Bổ sung package `local_auth: ^2.3.0`.
  - Dịch vụ `BiometricService` kiểm tra phần cứng vân tay/FaceID và thực hiện xác thực với rung nhẹ xúc giác `HapticFeedback.lightImpact()` khi mở khóa thành công.
  - Màn hình khóa mờ pastel `BiometricLockScreen` bảo vệ 100% dữ liệu chu kỳ và cảm xúc cá nhân.
  - Quản lý vòng đời ứng dụng (`WidgetsBindingObserver` / `AppLifecycleListener`): Tự động khóa lại và yêu cầu xác thực khi ứng dụng resume từ background.
  - Bổ sung Switch "Khóa bằng sinh trắc học" trong `CycleSettingsSheet`.

### [Changed]
- **Nâng cấp Android Activity:** Đổi lớp kế thừa trong `MainActivity.kt` từ `FlutterActivity()` sang `FlutterFragmentActivity()` để tương thích hoàn hảo với `local_auth` trên Android 13+, triệt tiêu hoàn toàn lỗi crash khi bung pop-up sinh trắc học.
- Bổ sung quyền `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>` trong `AndroidManifest.xml`.
- Cập nhật `AppConstants` với phiên bản `0.2.0`, `appName = 'Moona'` và các key SharedPreferences/Hive mới.

### [Fixed]
- Khắc phục cảnh báo thuộc tính deprecated `axisAlignment` chuyển sang `alignment: Alignment.topCenter` trong `SizeTransition` tại `offline_banner.dart`.

---

## [0.1.0] - 2026-09-03

### [Added]
- **Kiến trúc nền tảng (Architecture & Foundation):**
  - Khởi tạo cấu trúc **Feature-First Clean Architecture** chuẩn hóa cho toàn dự án với 3 tầng độc lập: `domain/`, `data/`, `presentation/`.
  - Thiết lập quản lý trạng thái bằng **Riverpod 2.x** (`flutter_riverpod: ^2.6.1`).
  - Thiết lập cơ sở dữ liệu cục bộ ngoại tuyến bằng **Hive** (`hive: ^2.2.3`, `hive_flutter: ^1.1.0`) gồm 3 box chính: `cycleBox`, `moodBox`, `settingsBox`.
  - Hệ thống Design System màu Soft Pastel cao cấp trong `lib/core/constants/app_colors.dart` (Hồng ấm, kem vani, tím thạch anh lavender, xanh ngọc mint, cam đào).
  - Cấu hình Theme Light và Dark mode nữ tính, sang trọng với phông chữ Google Fonts Quicksand trong `lib/core/theme/app_theme.dart`.

- **Phân hệ Chu Kỳ Sinh Học (Cycle Core Engine):**
  - Thuật toán phân loại sinh học chính xác **4 Pha Chu Kỳ** trong `CycleInfo`:
    * 🩸 *Pha Hành Kinh (Menstrual):* Ngày 1..5, tính ngày bắt đầu và dự đoán kỳ tới.
    * 🌿 *Pha Nang Trứng (Follicular):* Ngày 6..12, giai đoạn phục hồi và tái tạo năng lượng.
    * ☀️ *Pha Rụng Trứng (Ovulation):* Ngày rụng trứng đỉnh điểm `(cycleLength - 14)` và cửa sổ thụ thai 6 ngày.
    * 🌙 *Pha Hoàng Thể (Luteal):* Ngày 16..28, giai đoạn tiền kinh nguyệt (PMS).
  - Lịch tương tác `TableCalendar` tùy biến (`CycleCalendarView`) tự động tô màu nền pastel của từng ô ngày theo đúng pha sinh học, đánh dấu icon giọt nước cho ngày hành kinh và ngôi sao cho ngày rụng trứng.
  - Thẻ thông tin sinh học chi tiết `CycleDayDetailCard` hiển thị động trạng thái hormone, bài tập thể thao gợi ý, xác suất thụ thai và nút 1-chạm Toggle ngày hành kinh.
  - Modal ghi nhận kỳ kinh chi tiết `LogPeriodModal` (lượng kinh Ít/Vừa/Nhiều, đang diễn ra).
  - Modal cấu hình chu kỳ sinh học `CycleSettingsSheet` (tùy chỉnh độ dài chu kỳ 21-45 ngày, thời gian hành kinh 2-10 ngày).

- **Phân hệ Nhật Ký Thể Trạng (Mood & Micro-logging):**
  - Màn hình ghi nhận 1-chạm `MoodScreen` với 5 mức năng lượng (😫 Kiệt sức $\rightarrow$ ⚡ Bùng nổ).
  - Bảng chọn FilterChips tâm trạng chủ đạo (Vui vẻ, Nhạy cảm, Cáu gắt, Lo âu, Thư thái...) và triệu chứng thể chất (Đau bụng kinh, Đau lưng, Căng ngực, Thèm ngọt, Đầy hơi, Mụn...).
  - Biểu đồ đường cong uốn lượn mềm mại thể hiện xu hướng năng lượng 7 ngày gần nhất bằng `fl_chart`.

- **Phân hệ Dinh Dưỡng Đồng Bộ (Cycle-Synced Food):**
  - Cơ sở dữ liệu dinh dưỡng 4 pha trong `NutritionLocalDataSource`:
    * Danh mục thực phẩm vàng nên ăn (Superfoods).
    * Danh mục món ăn & thức uống cần hạn chế.
    * Trà thảo mộc & đồ uống xoa dịu (Trà gừng mật ong, matcha, trà hoa cúc, lavender).
    * Gợi ý bữa ăn mẫu hoàn chỉnh kèm vi chất then chốt (Sắt, Magie, Omega-3, Kẽm).
  - Màn hình `NutritionScreen` tự động cập nhật gợi ý ăn uống đồng bộ theo pha của ngày đang chọn.

- **Phân hệ Góc Nhìn Của Anh (Husband View Offline):**
  - Tóm tắt trạng thái hôm nay của vợ dưới góc nhìn hành động cho chồng.
  - Danh sách 3 hành động ấm áp nên chủ động làm ngay và những điều tuyệt đối nên tránh.
  - Nút 1-chạm sao chép tóm tắt trạng thái định dạng sẵn vào clipboard để gửi nhanh qua Zalo/SMS.

- **Phân hệ Đồng Bộ Cặp Đôi Realtime (Partner Sync via Cloud Firestore):**
  - Cơ chế sinh và ghép đôi qua mã PIN 6 ký tự (`PairingCode`, e.g. `HF8201`) có hiệu lực trong 24 giờ.
  - Phía Vợ: Màn hình tạo mã ghép đôi, tự động mở Stream lắng nghe phản hồi của Chồng theo thời gian thực.
  - Phía Chồng: Màn hình nhập mã ghép đôi 6 ký tự xác thực Firestore.
  - Dashboard Chồng thời gian thực (`HusbandDashboardScreen`): Sử dụng `StreamProvider` (Riverpod) lắng nghe trực tiếp document `couples/{coupleId}/status/today`.
  - Hiển thị trực tiếp: Pha chu kỳ của vợ, thanh tiến trình năng lượng 1-5, chip triệu chứng và lời khuyên hành động tức thì.
  - Phân tầng bảo mật (Data Boundary): Dữ liệu nhạy cảm chỉ lưu ngoại tuyến tại Hive; Firestore chỉ lưu bản tóm tắt phục vụ ghép đôi.
  - Tệp quy tắc bảo mật Firestore `firestore.rules`.

- **Cấu hình Android & Build:**
  - Bổ sung các dependency: `firebase_core: ^4.14.0`, `cloud_firestore: ^6.9.0`.
  - Cấu hình `google-services` plugin trong `settings.gradle.kts` và `app/build.gradle.kts`.
  - Thiết lập `minSdk = 21`, `multiDexEnabled = true`, `JavaVersion.VERSION_17`.
  - Tệp `google-services.json` mẫu an toàn đảm bảo build APK thành công.

### [Changed]
- Toàn bộ các đường dẫn import nội bộ chuyển đổi sang `package:herflow/...` nhằm đảm bảo tính toàn vẹn và ngăn ngừa lỗi phân giải URI tương đối trong Dart.
- Bổ sung cấu hình `kotlin.incremental=false` và `kotlin.incremental.useClasspathSnapshot=false` trong `android/gradle.properties` để giải quyết triệt để lỗi cross-drive cache (C: vs D:) của Kotlin trên hệ điều hành Windows.

### [Fixed]
- Sửa lỗi cú pháp thiếu tham số `required Widget child` trong phương thức `_buildNutritionSection` tại `lib/features/nutrition/presentation/screens/nutrition_screen.dart`.
- Thay thế thuộc tính đã lỗi thời `activeColor` bằng `activeThumbColor` trong `SwitchListTile` tại `lib/features/cycle/presentation/widgets/log_period_modal.dart`.

### [Known Issues]
- Tệp `android/app/google-services.json` hiện đang sử dụng thông tin mẫu để phục vụ việc build APK offline. Cần thay thế bằng tệp cấu hình thực từ Firebase Console cá nhân khi triển khai hệ thống online thực tế.
- Trên môi trường thử nghiệm pure headless unit test, Firebase Firestore cần được mock hoặc bọc try/catch để tránh lỗi MissingPluginException.
