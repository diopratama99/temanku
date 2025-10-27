# Temanku Mobile 📱

Teman kecil yang bantu jagain keuanganmu

## 📖 Deskripsi

Temanku adalah aplikasi manajemen keuangan pribadi yang membantu Anda melacak pengeluaran, pemasukan, dan mengelola budget dengan mudah dan intuitif.

## ✨ Fitur

- 📊 **Dashboard Interaktif** - Visualisasi keuangan dengan grafik dan chart
- 💰 **Transaksi** - Catat pemasukan dan pengeluaran dengan mudah
- 🏷️ **Kategori** - Kelola kategori transaksi sesuai kebutuhan
- 🏦 **Akun** - Kelola berbagai akun seperti cash, bank, e-wallet
- 💳 **Transfer Antar Akun** - Transfer dana antar akun dengan mudah
- 🎯 **Budget** - Atur budget per kategori
- 💎 **Tabungan** - Catat dan monitor target tabungan
- 📈 **Riwayat** - Lihat riwayat transaksi lengkap dengan filter
- 📤 **Import/Export** - Import dan export data dalam format CSV
- 🔐 **Autentikasi** - Login dengan email/password atau Google Sign-In
- 🌙 **Dark Mode** - Support mode gelap (coming soon)

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.9.2 atau lebih tinggi)
- Dart SDK (3.9.2 atau lebih tinggi)
- Android Studio / VS Code
- Android SDK (untuk build Android)
- Xcode (untuk build iOS - Mac only)

### Installation

1. Clone repository ini:
```bash
git clone https://github.com/diopratama99/temanku-webapp.git
cd temanku-webapp/temanku_mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate launcher icons:
```bash
dart run flutter_launcher_icons
```

4. Generate splash screen:
```bash
dart run flutter_native_splash:create
```

5. Run aplikasi:
```bash
flutter run
```

## 🏗️ Build

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 📦 Tech Stack

- **Framework**: Flutter
- **State Management**: Provider
- **Database**: SQLite (sqflite)
- **Charts**: fl_chart
- **Authentication**: Google Sign-In
- **Icons**: flutter_launcher_icons
- **Splash Screen**: flutter_native_splash
- **Fonts**: Google Fonts

## 📱 Screenshots

_Coming soon_

## 🗂️ Struktur Project

```
lib/
├── main.dart                 # Entry point aplikasi
├── data/
│   └── app_database.dart    # Database helper & models
├── pages/
│   ├── home_page.dart       # Dashboard
│   ├── login_page_modern.dart
│   ├── add_transaction_simple.dart
│   ├── transactions_page.dart
│   ├── categories_page.dart
│   ├── accounts_page.dart
│   ├── budgets_page.dart
│   ├── savings_page.dart
│   └── profile_page_modern.dart
├── services/
│   └── auth_service.dart    # Authentication service
├── theme/
│   └── app_theme.dart       # Theme configuration
├── utils/
│   └── snackbar_utils.dart  # Helper utilities
└── widgets/
    └── app_bottom_navigation.dart
```

## 🔧 Configuration

### Google Sign-In

Untuk menggunakan fitur Google Sign-In, Anda perlu:

1. Setup project di [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Google Sign-In API
3. Konfigurasi OAuth 2.0 credentials
4. Update `android/app/google-services.json` (Android)
5. Update `ios/Runner/GoogleService-Info.plist` (iOS)

### Database

Aplikasi menggunakan SQLite untuk penyimpanan lokal. Database akan otomatis dibuat saat pertama kali aplikasi dijalankan.

## 👨‍💻 Development

### Run in Debug Mode
```bash
flutter run
```

### Run Tests
```bash
flutter test
```

### Analyze Code
```bash
flutter analyze
```

### Format Code
```bash
flutter format .
```

## 📝 License

Copyright © 2025 Temanku. All rights reserved.

## 👤 Author

**Dio Pratama**
- GitHub: [@diopratama99](https://github.com/diopratama99)

## 🤝 Contributing

Contributions, issues and feature requests are welcome!

## ⭐ Show your support

Give a ⭐️ if this project helped you!

---

Made with ❤️ using Flutter
