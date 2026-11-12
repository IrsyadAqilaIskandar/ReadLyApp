# ReadLy (prototype Android, versi offline) - pembaruan Premium

Aplikasi assistive reading untuk pengguna low vision, disleksia, dan kesulitan membaca.
Berjalan tanpa Google Cloud, tanpa API key, tanpa billing.

## Fitur

**Gratis (kebutuhan dasar low vision)**
- Baca dari foto, PDF (teks maupun scan), dan teks tempel; suara Bahasa Indonesia bawaan Android
- Ukuran huruf (14-64), 4 mode kontras, huruf tebal, kecepatan suara
- Tampilan baca rapi: pemisah halaman, judul terdeteksi, lompat ke halaman, tab **Teks | Asli**
  (gambar halaman asli, bisa dicubit untuk memperbesar), highlight kalimat yang menggulir otomatis
- Tombol besar, posisi tetap, label TalkBack, getar singkat saat tombol ditekan

**Premium (kecantikan dan personalisasi)**
- Riwayat bacaan + lanjut dari kalimat terakhir
- Word (.docx) dan PowerPoint (.pptx)
- Ekspor audio (WAV, maksimal sekitar 8.000 karakter per ekspor)
- Jenis huruf (Lexend, Atkinson Hyperlegible, Comic Neue, Merriweather, Open Sans), tema warna,
  warna kustom, jarak baris/huruf/kata/paragraf, margin, perataan, dan 5 profil siap pakai

**Uji coba Premium:** buka **Pengaturan** (ikon gerigi) > kartu kuning
"Mode uji: anggap sudah Premium". Halaman Premium dan pembayaran hanya **simulasi**;
tidak ada transaksi sungguhan.

## Letak file

Salin ke proyek Flutter Anda (timpa yang lama), sesuai folder:

| File | Folder tujuan | Status |
|---|---|---|
| pubspec.yaml | (root proyek) | diubah (tambah `archive`) |
| theme.dart, settings.dart, text_utils.dart, reader_controller.dart | lib/ | diubah |
| models.dart | lib/ | **baru** |
| ocr_service.dart | lib/services/ | diubah |
| office_service.dart, history_store.dart, audio_export.dart | lib/services/ | **baru** |
| home_screen.dart, reader_screen.dart | lib/screens/ | diubah |
| settings_screen.dart, premium_screen.dart, checkout_screen.dart, history_screen.dart | lib/screens/ | **baru** |
| premium_gate.dart | lib/widgets/ | **baru** |

Tidak berubah: `main.dart`, `config.dart`, `about_screen.dart`, `logo.dart`, `phone_preview.dart`.

Setelah menyalin:

```powershell
flutter pub get
flutter analyze
flutter run
```

Kalau `flutter pub get` mengeluh soal versi `archive`, jalankan `flutter pub add archive`.

## Catatan

- **Huruf Premium** diunduh sekali saat pertama dipakai (butuh internet); tanpa internet dipakai huruf bawaan.
- **Ekspor audio** memakai mesin suara HP, jadi hasilnya WAV dan kualitasnya mengikuti mesin itu.
  Penyimpanan lewat jendela "Simpan" sistem Android.
- **Riwayat** hanya menyimpan dokumen selama Premium aktif. Gambar asli ikut tersimpan di HP.
- AndroidManifest tidak perlu diubah lagi dari sebelumnya (INTERNET dan `<queries>` TTS).
