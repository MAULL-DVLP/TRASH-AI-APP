# trash_ai_app

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

Panduan Setup Proyek untuk Pengguna

📋 Prerequisite
Flutter SDK (≥3.9.2): https://flutter.dev/docs/get-started/install
Git: https://git-scm.com/download
Android Studio / Xcode (untuk emulator atau build)
Emulator atau Physical Device (untuk testing)

Langkah Setup
1. Clone Repository
   git clone https://github.com/MAULL-DVLP/TRASH-AI-APP
cd trash_ai_app
2. Verifikasi Flutter Environment
   flutter doctor
Pastikan semua ✓ berwarna hijau (terutama Flutter SDK dan satu platform yang ingin digunakan).
3. Install Dependencies
   flutter pub get
4. Setup Emulator (Opsional) Jika menggunakan Android Emulator
   flutter emulators --launch <emulator_id>
   Atau buka Android Studio → AVD Manager → jalankan emulator
5. Jalankan Aplikasi
   flutter run
Atau untuk target spesifik:
Android: flutter run -d android
iOS: flutter run -d ios
Windows: flutter run -d windows

Dependencies Utama
image_picker - Memilih gambar dari gallery/kamera
tflite_flutter - Menjalankan model TensorFlow Lite (trash_model.tflite)
image - Pemrosesan gambar
camera - Akses kamera device

Catatan Penting
Model ML ada di trash_model.tflite - sudah included
Pastikan assets sudah ter-download dengan flutter pub get
Untuk iOS mungkin perlu tambah permission di Info.plist
Untuk Android sudah dikonfigurasi di build.gradle.kts


   
