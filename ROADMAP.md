# 🗺️ LỘ TRÌNH PHÁT TRIỂN DỰ ÁN MOONA (ROADMAP)

Tài liệu thiết kế kiến trúc chi tiết được lưu trữ tại [docs/ROADMAP_v0.5.0.md](docs/ROADMAP_v0.5.0.md) và [docs/FEMTECH_LIFECYCLE_ARCHITECTURE_PLAN.md](docs/FEMTECH_LIFECYCLE_ARCHITECTURE_PLAN.md).

---

## 📌 TỔNG QUAN CÁC CỘT MỐC ĐÃ HOÀN THÀNH

- [x] **v0.4.0**: Phân định vai trò Vợ/Chồng, Realtime Care Signals 2 chiều, Dual Firestore Collection Sync.
- [x] **v0.5.0**: Google Sign-In, Role Onboarding, Nickname Engine linh hoạt, Theo dõi chu kỳ độc lập.
- [x] **v0.6.0 - v0.6.7**: QR Code Pairing, Love Notes Thread, Native In-App OTA Update, MoonaConfirmDialog chuẩn hóa.
- [x] **v0.7.0 (Phase 1)**: Kiến trúc Vòng đời 5 giai đoạn (LifeStage Matrix 16/16), Cơ chế Pause & Healing Mode.
- [x] **v0.7.5 (Phase 2)**: Chế độ Chuẩn Bị Bầu (Conception Mode) & Thai Kỳ (Pregnancy Mode).
- [x] **v0.8.0 (Phase 2.5)**: Bộ Đếm Cử Động Thai Chuẩn Cardiff (Kick Counter) & Lịch Khám Thai 7 Mốc Vàng (Prenatal Appointments).
- [x] **v0.8.1+27 (Phase 3)**: Dashboard Mẹ Bỉm (Motherhood Home), Bấm Giờ Bú Độc Lập (Feeding Timer), Góc Nhìn Bố Bỉm (Husband Companion), Ngừa Thai Tự Nhiên LAM WHO & Wonder Weeks.
- [x] **v0.8.2+28**: Hồ Sơ Thể Trạng Mẹ Bầu (Maternal Health Profile), Thu Thập Dữ Liệu Theo Tiến Trình (Progressive Profiling), Chuẩn Tăng Cân Y Khoa IOM 2009 & Thực Đơn Cho Bố Bầu.
- [x] **v0.8.3+29**: Phân Hệ Sao Lưu & Khôi Phục Dữ Liệu Toàn Diện (Backup & Restore Service): Tệp container `.moona` mã hóa AES-256-CBC, nén GZIP, KDF UID + Salt, Checksum SHA-256, Cloud Sync (Firestore Private Vault `users/{uid}/backups/latest`), Local Export/Import (`share_plus` / `file_picker`), MoonaConfirmDialog chống ghi đè nhầm, Ma trận khôi phục 6 kịch bản (100% pass).

---

## 🚀 KẾ HOẠCH BƯỚC TIẾP THEO (v0.9.0 & v1.0.0)

1. **v0.9.0 - Bảo Mật Nâng Cao & Tối Ưu Mật Mã:**
   - Kế hoạch chuyển đổi (migration) khóa AES runtime sang lưu trữ an toàn trong **Android Keystore / iOS Keychain** qua `flutter_secure_storage`.
   - Báo cáo đối soát chu kỳ (Cycle Audit Report) xuất bảng tính nhanh (.csv) phục vụ khám phụ khoa.
2. **v1.0.0 - Phát Hành Chính Thức:**
   - Hoàn thiện toàn bộ hệ sinh thái FemTech: Widget màn hình chính Android/iOS, Trợ lý AI Coach, Cloud Functions tự động hóa.
