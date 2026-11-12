import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

/// Halaman "Tentang ReadLy": ringkasan, visi, misi, masalah, dan solusi (isi dari PDF).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _misi = [
    'Menyediakan teknologi OCR dan text-to-speech yang akurat dan mendukung Bahasa Indonesia secara optimal.',
    'Menghadirkan pengalaman membaca yang dapat dipersonalisasi (ukuran teks, kontras, highlight) sesuai kebutuhan masing-masing pengguna.',
    'Memastikan aplikasi mudah diakses dan terjangkau bagi seluruh kalangan, termasuk penyandang low vision dan disleksia.',
    'Mengurangi ketergantungan pengguna pada bantuan orang lain dalam mengakses dokumen tertulis.',
  ];

  static const _masalah = [
    'Teks berukuran kecil dan kontras yang rendah membuat mata cepat lelah.',
    'Kesulitan membaca teks yang panjang atau kompleks.',
    'PDF hasil scan atau foto sulit untuk dibaca.',
    'Masih bergantung pada orang lain untuk membacakan dokumen, sehingga membutuhkan waktu yang lebih lama untuk membaca.',
    'Dukungan Bahasa Indonesia pada aplikasi membaca saat ini masih terbatas.',
  ];

  static const _solusi = [
    ('INTEGRATED', 'ReadLy menggabungkan OCR, Text-to-Speech, penyesuaian teks, dan penyorotan teks dalam satu aplikasi.'),
    ('PERSONALIZED', 'Pengguna dapat menyesuaikan ukuran dan kontras teks sesuai dengan kebutuhan membaca masing-masing.'),
    ('INDEPENDENT', 'ReadLy membantu pengguna mengakses informasi tertulis dengan lebih sedikit bergantung pada orang lain.'),
    ('BAHASA INDONESIA', 'ReadLy bertujuan mendukung pengalaman membaca yang lebih mudah diakses dalam Bahasa Indonesia.'),
  ];

  @override
  Widget build(BuildContext context) {
    final body = GoogleFonts.lato(fontSize: 15.5, height: 1.5, color: Colors.black87);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Band(title: 'Ringkasan Eksklusif'),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ReadLy adalah aplikasi assistive reading yang dirancang untuk membantu pengguna '
                    'dengan low vision, disleksia, dan kesulitan membaca umum agar dapat mengakses '
                    'dokumen dan bacaan secara mandiri. Pengguna cukup mengunggah dokumen dalam bentuk '
                    'PDF atau foto, kemudian ReadLy akan mengubah konten tersebut menjadi teks yang dapat '
                    'dibaca (melalui OCR atau optical character recognition) dan didengarkan melalui '
                    'fitur text-to-speech.',
                    style: body,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Dilengkapi dengan pengaturan ukuran teks, kontras, dan highlight saat dibacakan, '
                    'ReadLy hadir sebagai solusi yang terjangkau dan mudah digunakan bagi siapa saja '
                    'yang selama ini bergantung pada orang lain untuk membacakan dokumen.',
                    style: body,
                  ),
                  const SizedBox(height: 28),
                  Text('Visi', style: heading(24)),
                  const SizedBox(height: 8),
                  Text(
                    'Membuat aplikasi assistive reading yang memberdayakan setiap individu dengan '
                    'keterbatasan membaca untuk mengakses informasi secara mandiri, setara, dan percaya diri.',
                    style: body,
                  ),
                  const SizedBox(height: 24),
                  Text('Misi', style: heading(24)),
                  const SizedBox(height: 8),
                  for (final m in _misi)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•  ', style: body),
                          Expanded(child: Text(m, style: body)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 18),
                  Text('Latar Belakang & Masalah', style: heading(22)),
                  const SizedBox(height: 8),
                  Text(
                    'Pengguna memiliki kebutuhan (Jobs To Be Done) untuk memahami isi dokumen/bacaan, '
                    'menyelesaikan bacaan tepat waktu, dan mengakses informasi tertulis secara mandiri. '
                    'Namun, dalam prosesnya pengguna menghadapi berbagai hambatan (Pains):',
                    style: body,
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < _masalah.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(width: 28, child: Text('${i + 1}.', style: body)),
                          Expanded(child: Text(_masalah[i], style: body)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 22),
                  Text('Solusi dan Inovasi', style: heading(22)),
                  const SizedBox(height: 12),
                  for (final s in _solusi)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: RC.blue,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.$1, style: heading(15, color: Colors.white)),
                          const SizedBox(height: 6),
                          Text(
                            s.$2,
                            style: GoogleFonts.lato(fontSize: 15, height: 1.4, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    '“Inovasinya bukan hanya pada masing-masing teknologi, tetapi pada bagaimana '
                    'teknologi tersebut diintegrasikan dalam satu aplikasi untuk memberikan pengalaman '
                    'membaca yang lebih personal dan mandiri.”',
                    style: GoogleFonts.arvo(fontSize: 14.5, height: 1.5, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Versi prototype (offline): mendukung PDF, foto, dan teks tempel.',
                    style: GoogleFonts.lato(fontSize: 13, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Band extends StatelessWidget {
  final String title;
  const _Band({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 12, 24, 30),
      decoration: const BoxDecoration(
        color: RC.blue,
        borderRadius: BorderRadius.only(bottomRight: Radius.circular(48)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(child: Text(title, style: heading(26, color: Colors.white))),
        ],
      ),
    );
  }
}
