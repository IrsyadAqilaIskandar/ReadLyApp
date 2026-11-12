import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../config.dart';
import '../models.dart';

class OfficeException implements Exception {
  final String message;
  OfficeException(this.message);

  @override
  String toString() => message;
}

/// Membaca teks dari file Word (.docx) dan PowerPoint (.pptx).
/// Kedua format ini adalah arsip ZIP berisi XML, jadi teksnya bisa diambil langsung
/// tanpa OCR. Format lama (.doc / .ppt) belum didukung.
class OfficeService {
  static final RegExp _wp = RegExp(r'<w:p[ >].*?</w:p>', dotAll: true);
  static final RegExp _wRun = RegExp(
    r'<w:t(?:\s[^>]*)?>(.*?)</w:t>|<w:tab\s*/>|<w:br[^>]*/>',
    dotAll: true,
  );
  static final RegExp _wHeading = RegExp(
    r'<w:pStyle w:val="(?:Heading\d*|Title|Subtitle|Judul\d*)"',
    caseSensitive: false,
  );

  static final RegExp _slideName = RegExp(r'^ppt/slides/slide(\d+)\.xml$');
  static final RegExp _shape = RegExp(
    r'<p:sp[ >].*?</p:sp>|<p:graphicFrame[ >].*?</p:graphicFrame>',
    dotAll: true,
  );
  static final RegExp _aPara = RegExp(r'<a:p[ >].*?</a:p>', dotAll: true);
  static final RegExp _aRun = RegExp(
    r'<a:t(?:\s[^>]*)?>(.*?)</a:t>|<a:br[^>]*>',
    dotAll: true,
  );
  static final RegExp _titleShape = RegExp(r'<p:ph[^>]*type="(?:title|ctrTitle)"');

  Future<ReadDoc> read(Uint8List bytes, String fileName) async {
    if (bytes.length > AppConfig.maxPdfBytes) {
      throw OfficeException(
          'File terlalu besar untuk prototype (maks ${AppConfig.maxPdfBytes ~/ (1024 * 1024)} MB).');
    }
    final lower = fileName.toLowerCase();
    final isDocx = lower.endsWith('.docx');
    final isPptx = lower.endsWith('.pptx');
    if (!isDocx && !isPptx) {
      throw OfficeException('Format belum didukung. Gunakan file .docx atau .pptx.');
    }

    Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw OfficeException(
          'File tidak dapat dibuka. Pastikan file tidak rusak dan tidak diberi kata sandi.');
    }

    final title = _baseName(fileName);
    return isDocx ? _docx(archive, title) : _pptx(archive, title);
  }

  // ---------------- Word ----------------

  ReadDoc _docx(Archive a, String title) {
    final xml = _text(a, 'word/document.xml');
    if (xml == null) throw OfficeException('Isi dokumen Word tidak ditemukan.');

    final paras = <TextPara>[];
    for (final m in _wp.allMatches(xml)) {
      final p = m.group(0)!;
      final text = _runs(p, _wRun);
      if (text.isEmpty) continue;
      final heading = _wHeading.hasMatch(p) && text.length <= 200;
      paras.add(TextPara(text, heading ? ParaKind.heading : ParaKind.body));
    }

    // Bagi menjadi "bagian" berisi 30 paragraf agar mudah dilompati.
    final pages = <PageData>[];
    for (var i = 0, n = 1; i < paras.length; i += 30, n++) {
      pages.add(PageData(number: n, paras: paras.sublist(i, math.min(i + 30, paras.length))));
    }

    return ReadDoc(
      id: newDocId(),
      title: title,
      source: 'word',
      createdAt: DateTime.now(),
      pages: pages,
    );
  }

  // ---------------- PowerPoint ----------------

  ReadDoc _pptx(Archive a, String title) {
    final slides = a.files.where((f) => f.isFile && _slideName.hasMatch(f.name)).toList()
      ..sort((x, y) => _slideNo(x.name).compareTo(_slideNo(y.name)));
    if (slides.isEmpty) throw OfficeException('Slide tidak ditemukan di file ini.');

    final pages = <PageData>[];
    for (final f in slides) {
      final xml = utf8.decode(f.content as List<int>, allowMalformed: true);
      final paras = <TextPara>[];

      for (final s in _shape.allMatches(xml)) {
        final shape = s.group(0)!;
        final isTitle = _titleShape.hasMatch(shape);
        for (final pm in _aPara.allMatches(shape)) {
          final text = _runs(pm.group(0)!, _aRun);
          if (text.isEmpty) continue;
          paras.add(TextPara(text, isTitle ? ParaKind.heading : ParaKind.body));
        }
      }
      if (paras.isNotEmpty) {
        pages.add(PageData(number: _slideNo(f.name), paras: paras));
      }
    }

    return ReadDoc(
      id: newDocId(),
      title: title,
      source: 'slide',
      createdAt: DateTime.now(),
      pages: pages,
    );
  }

  // ---------------- Bantuan ----------------

  int _slideNo(String name) => int.parse(_slideName.firstMatch(name)!.group(1)!);

  String? _text(Archive a, String name) {
    final f = a.findFile(name);
    if (f == null) return null;
    return utf8.decode(f.content as List<int>, allowMalformed: true);
  }

  String _runs(String xml, RegExp tag) {
    final b = StringBuffer();
    for (final m in tag.allMatches(xml)) {
      final t = m.group(1);
      if (t == null) {
        b.write(' ');
      } else {
        b.write(_unescape(t));
      }
    }
    return b.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _unescape(String s) {
    return s
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAllMapped(
          RegExp(r'&#(\d+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!)),
        )
        .replaceAllMapped(
          RegExp(r'&#x([0-9a-fA-F]+);'),
          (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
        )
        .replaceAll('&amp;', '&');
  }

  String _baseName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot > 0 ? fileName.substring(0, dot) : fileName;
  }
}
