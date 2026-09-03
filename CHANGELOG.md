# Changelog — Moona

Toàn bộ những thay đổi đáng chú ý của dự án **Moona** được ghi nhận tại đây theo chuẩn [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) và tuân thủ [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
