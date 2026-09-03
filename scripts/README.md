# 🚀 Moona — Scripts Tự Động Hoá Build & Deploy

Thư mục này chứa các script tự động hóa cho luồng build và cài đặt APK lên thiết bị Android thật.

---

## 📂 Cấu trúc

```
scripts/
  deploy.ps1         ← Script chính (PowerShell) — build + analyze + install
README.md            ← File này

run_app.bat          ← Nhấp đúp để build DEBUG và cài ngay
release_deploy.bat   ← Nhấp đúp để build RELEASE và cài ngay
```

---

## ⚡ Cách sử dụng nhanh

### Option 1: Nhấp đúp trong File Explorer

| File | Chức năng |
|---|---|
| `run_app.bat` | Build **Debug** → cài → mở app |
| `release_deploy.bat` | Build **Release** (R8 + split-per-abi) → cài → mở app |

### Option 2: PowerShell (tuỳ chỉnh)

```powershell
# Build và deploy debug (mặc định)
.\scripts\deploy.ps1

# Build và deploy release
.\scripts\deploy.ps1 -Mode release
```

> **Yêu cầu:** PowerShell phải có quyền chạy script.
> Nếu bị chặn, chạy terminal với quyền Admin và gõ:
> ```powershell
> Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
> ```

---

## 🔄 Luồng xử lý tự động (5 bước)

```
1. ADB Check       → Kiểm tra thiết bị kết nối, chọn thiết bị đầu tiên
       ↓
2. Static Analysis → flutter analyze (dừng ngay nếu có lỗi)
       ↓
3. Build APK       → debug hoặc release --split-per-abi
       ↓
4. APK Resolution  → Ưu tiên arm64-v8a → armeabi-v7a → x86_64 → fat APK
       ↓
5. Deploy & Launch → adb install -r → adb shell am start
```

---

## 🛠️ Yêu cầu tiên quyết

- **Flutter SDK** đã cài và trong PATH (`flutter --version`)
- **Android SDK Platform Tools** đã cài (`adb --version`)
- **USB Debugging** đã bật trên thiết bị Android
- **Cáp USB** kết nối và thiết bị đã **xác nhận kết nối debug**

---

## 🐛 Xử lý lỗi thường gặp

| Lỗi | Nguyên nhân | Cách sửa |
|---|---|---|
| "Không tìm thấy thiết bị" | USB Debugging tắt | Vào Cài đặt → Tùy chọn nhà phát triển → Bật USB Debugging |
| "unauthorized" | Chưa xác nhận trên điện thoại | Xem màn hình điện thoại và nhấn "Cho phép" |
| "INSTALL_FAILED_VERSION_DOWNGRADE" | Version cũ hơn bản cài sẵn | Gỡ bản cũ rồi chạy lại, hoặc tăng `versionCode` trong `pubspec.yaml` |
| "flutter analyze" lỗi | Có lỗi code | Chạy `flutter analyze` và sửa lỗi trước |
| App không tự mở | Package name sai | Kiểm tra `applicationId` trong `android/app/build.gradle.kts` |

---

## 📋 Package Info Moona

| Thuộc tính | Giá trị |
|---|---|
| Application ID | `com.herflow.app.herflow` |
| Main Activity | `com.herflow.app.herflow.MainActivity` |
| APK Output (debug) | `build\app\outputs\flutter-apk\app-debug.apk` |
| APK Output (release arm64) | `build\app\outputs\flutter-apk\app-arm64-v8a-release.apk` |
