# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-10-27

### Changed
- 🔧 Refactored codebase untuk naming convention yang lebih profesional
- 📝 Rename semua file page dari suffix `_modern` dan `_simple` ke nama standar
- 🧹 Cleanup file-file yang tidak terpakai (versi lama)
- 🗂️ Reorganisasi struktur project untuk maintainability lebih baik

### Removed
- ❌ Hapus file-file duplikat (login_page.dart versi lama, dll)
- ❌ Hapus page yang tidak terpakai (dashboard_page_v2.dart, ui_showcase_page.dart)
- ❌ Hapus widget yang tidak terpakai (app_scaffold.dart, balance_hero_card.dart)

### Technical
- Renamed: `login_page_modern.dart` → `login_page.dart`
- Renamed: `add_transaction_simple.dart` → `add_transaction_page.dart`
- Renamed: `profile_page_modern.dart` → `profile_page.dart`
- Renamed: `categories_page_modern.dart` → `categories_page.dart`
- Renamed: `transactions_page_modern.dart` → `transactions_page.dart`
- Renamed: `budgets_page_modern.dart` → `budgets_page.dart`
- Renamed: `savings_page_modern.dart` → `savings_page.dart`
- Renamed: `statistics_page_modern.dart` → `statistics_page.dart`
- Updated all imports dan references
- No breaking changes - app berjalan normal

## [1.0.0] - 2025-10-27

### Added
- 📱 Aplikasi mobile Temanku pertama kali dirilis
- 🎨 UI/UX modern dengan Material Design 3
- 🔐 Sistem autentikasi (Email/Password & Google Sign-In)
- 📊 Dashboard interaktif dengan grafik keuangan
- 💰 Manajemen transaksi (pemasukan & pengeluaran)
- 🏷️ Manajemen kategori transaksi
- 🏦 Manajemen akun (Cash, Bank, E-Wallet)
- 💳 Fitur transfer antar akun
- 🎯 Manajemen budget per kategori
- 💎 Fitur tabungan dengan target
- 📈 Riwayat transaksi lengkap dengan filter
- 📤 Import/Export data CSV
- 🎭 Profile card dengan design debit card style
- 🚀 Splash screen custom dengan logo Temanku
- 📱 Launcher icon custom
- ✨ Success dialog dengan animasi
- 🎨 Segmented control modern untuk login/register

### Features Details

#### Dashboard
- Ringkasan saldo total
- Grafik pie chart pengeluaran per kategori
- Grafik bar chart pengeluaran 7 hari terakhir
- Quick actions (Tambah Transaksi, Lihat Riwayat, dll)
- Recent transactions

#### Transaksi
- Form input simple dan intuitif
- Support pemasukan dan pengeluaran
- Auto-reset form setelah submit
- Animated success dialog

#### Login/Register
- Modern segmented control untuk tab switching
- Smooth animations (200ms background, 150ms text)
- Google Sign-In integration
- Form validation
- Eye-catching logo dan tagline

#### Profile
- Debit card style profile display
- Auto-uppercase nama
- Font Courier New untuk aesthetic
- Info user lengkap
- Logout functionality

### Technical
- Framework: Flutter 3.9.2
- State Management: Provider
- Database: SQLite (sqflite)
- Chart Library: fl_chart
- Authentication: Google Sign-In
- Custom Icons: flutter_launcher_icons
- Splash Screen: flutter_native_splash

### Fixed
- Navigation issues setelah add transaction
- Login navigation ke home page
- Form overflow pada landscape mode
- Spacing dan layout inconsistencies

---

## Upcoming Features

### [1.1.0] - Planned
- [ ] Dark mode support
- [ ] Notification & reminders
- [ ] Recurring transactions
- [ ] Multi-currency support
- [ ] Cloud backup & sync
- [ ] Expense insights & analytics
- [ ] Export to PDF
- [ ] Widget support
- [ ] Biometric authentication
- [ ] Tutorial & onboarding

---

## Developer Notes

### Build Info
- Minimum SDK: Android 21 (Lollipop)
- Target SDK: Android 34
- iOS Deployment Target: 12.0

### Dependencies
See `pubspec.yaml` for full list of dependencies and versions.
