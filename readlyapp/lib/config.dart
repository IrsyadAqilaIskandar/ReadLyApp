/// Konfigurasi aplikasi (versi offline: tanpa API key, tanpa billing).
class AppConfig {
  /// Bahasa suara. Pastikan data suara Bahasa Indonesia terpasang di HP.
  static const String ttsLanguage = 'id-ID';

  /// Batas halaman PDF per dokumen. OCR di HP memakan waktu per halaman.
  static const int maxPdfPages = 30;

  /// Batas ukuran PDF (byte) karena PDF dimuat ke memori.
  static const int maxPdfBytes = 25 * 1024 * 1024;
}
