import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

import '../config.dart';
import '../models.dart';
import '../text_utils.dart';

class OcrException implements Exception {
  final String message;
  OcrException(this.message);

  @override
  String toString() => message;
}

/// OCR offline memakai Google ML Kit (berjalan di HP, gratis, tanpa internet).
/// Hasilnya berstruktur: halaman -> paragraf (dengan deteksi judul sederhana),
/// dan gambar asli tiap halaman disimpan untuk tab "Asli".
class OcrService {
  /// OCR untuk satu file gambar (foto dari kamera/galeri).
  Future<ReadDoc> readImageFile(String path, {String title = 'Foto'}) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(path));
      return ReadDoc(
        id: newDocId(),
        title: title,
        source: 'foto',
        createdAt: DateTime.now(),
        pages: [PageData(number: 1, paras: _paras(result), imagePath: path)],
      );
    } catch (e) {
      throw OcrException('Gagal membaca teks dari gambar: $e');
    } finally {
      await recognizer.close();
    }
  }

  /// OCR untuk PDF, halaman demi halaman. Tiap halaman dirender menjadi gambar JPEG.
  Future<ReadDoc> readPdf(
    Uint8List bytes, {
    String title = 'PDF',
    void Function(int page, int total)? onProgress,
  }) async {
    if (bytes.length > AppConfig.maxPdfBytes) {
      throw OcrException(
          'PDF terlalu besar untuk prototype (maks ${AppConfig.maxPdfBytes ~/ (1024 * 1024)} MB).');
    }

    PdfDocument pdf;
    try {
      pdf = await PdfDocument.openData(bytes);
    } catch (e) {
      throw OcrException(
          'PDF tidak dapat dibuka. Pastikan file tidak rusak dan tidak diproteksi sandi.');
    }

    final id = newDocId();
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final tmp = await getTemporaryDirectory();
    final dir = Directory('${tmp.path}/readly_$id');
    await dir.create(recursive: true);

    final total = math.min(pdf.pagesCount, AppConfig.maxPdfPages);
    final pages = <PageData>[];

    try {
      for (var n = 1; n <= total; n++) {
        onProgress?.call(n, total);

        final page = await pdf.getPage(n);
        PdfPageImage? img;
        try {
          // Lebar sekitar 1800 px agar OCR cukup tajam.
          final scale = (1800 / page.width).clamp(1.0, 4.0).toDouble();
          img = await page.render(
            width: page.width * scale,
            height: page.height * scale,
            format: PdfPageImageFormat.jpeg,
            backgroundColor: '#FFFFFF',
            quality: 85,
          );
        } finally {
          await page.close();
        }
        if (img == null) continue;

        final file = File('${dir.path}/page_$n.jpg');
        await file.writeAsBytes(img.bytes, flush: true);

        final result = await recognizer.processImage(InputImage.fromFilePath(file.path));
        pages.add(PageData(number: n, paras: _paras(result), imagePath: file.path));
      }
    } catch (e) {
      if (e is OcrException) rethrow;
      throw OcrException('Gagal membaca PDF: $e');
    } finally {
      await recognizer.close();
      await pdf.close();
    }

    return ReadDoc(
      id: id,
      title: title,
      source: 'pdf',
      createdAt: DateTime.now(),
      pages: pages,
    );
  }

  /// Mengubah blok-blok hasil OCR menjadi paragraf, dengan menandai judul:
  /// blok yang tinggi barisnya jelas lebih besar dari rata-rata, atau satu baris pendek
  /// tanpa tanda baca akhir yang berupa HURUF KAPITAL / blok pertama di halaman.
  List<TextPara> _paras(RecognizedText result) {
    final blocks = result.blocks.where((b) => b.lines.isNotEmpty).toList();
    if (blocks.isEmpty) return const [];

    final heights = blocks.map((b) => b.boundingBox.height / b.lines.length).toList();
    final sorted = [...heights]..sort();
    final median = sorted[sorted.length ~/ 2];

    final out = <TextPara>[];
    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
      final text = joinOcrLines(b.lines.map((l) => l.text).toList());
      if (text.isEmpty) continue;

      final hasLetter = RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(text);
      final endsSentence = RegExp(r'[.!?,;:]$').hasMatch(text);
      final bigger = median > 0 && heights[i] >= median * 1.3;
      final shortTitle = b.lines.length == 1 &&
          text.length <= 60 &&
          text.length >= 3 &&
          !endsSentence &&
          (i == 0 || text == text.toUpperCase());

      final heading = hasLetter &&
          ((bigger && b.lines.length <= 3 && text.length <= 120) || shortTitle);
      out.add(TextPara(text, heading ? ParaKind.heading : ParaKind.body));
    }
    return out;
  }
}
