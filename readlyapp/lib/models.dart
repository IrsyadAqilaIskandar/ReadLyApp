import 'text_utils.dart';

enum ParaKind { body, heading }

String newDocId() => DateTime.now().microsecondsSinceEpoch.toString();

/// Satu paragraf (atau judul) hasil OCR / dokumen.
class TextPara {
  final String text;
  final ParaKind kind;
  const TextPara(this.text, [this.kind = ParaKind.body]);

  Map<String, dynamic> toJson() => {
        't': text,
        'k': kind == ParaKind.heading ? 1 : 0,
      };

  factory TextPara.fromJson(Map<String, dynamic> j) => TextPara(
        (j['t'] ?? '').toString(),
        j['k'] == 1 ? ParaKind.heading : ParaKind.body,
      );
}

/// Satu halaman / slide / bagian dokumen.
class PageData {
  final int number; // mulai dari 1
  final List<TextPara> paras;
  final String? imagePath; // gambar asli halaman (jika ada)

  const PageData({required this.number, required this.paras, this.imagePath});

  Map<String, dynamic> toJson() => {
        'n': number,
        'i': imagePath,
        'p': paras.map((e) => e.toJson()).toList(),
      };

  factory PageData.fromJson(Map<String, dynamic> j) {
    final raw = j['p'];
    final list = <TextPara>[];
    if (raw is List) {
      for (final m in raw) {
        if (m is Map) list.add(TextPara.fromJson(Map<String, dynamic>.from(m)));
      }
    }
    return PageData(
      number: (j['n'] is num) ? (j['n'] as num).toInt() : 1,
      paras: list,
      imagePath: j['i']?.toString(),
    );
  }
}

/// Dokumen yang dibaca: kumpulan halaman berisi paragraf.
class ReadDoc {
  final String id;
  final String title;

  /// 'foto', 'pdf', 'teks', 'word', atau 'slide'.
  final String source;
  final DateTime createdAt;
  final List<PageData> pages;

  /// Indeks kalimat terakhir yang dibaca (untuk "lanjutkan membaca").
  int position;

  ReadDoc({
    required this.id,
    required this.title,
    required this.source,
    required this.createdAt,
    required this.pages,
    this.position = 0,
  });

  factory ReadDoc.fromPlainText(String raw, {String title = 'Teks'}) {
    final paras = splitParagraphs(raw).map((t) => TextPara(t)).toList();
    return ReadDoc(
      id: newDocId(),
      title: title,
      source: 'teks',
      createdAt: DateTime.now(),
      pages: [PageData(number: 1, paras: paras)],
    );
  }

  bool get isEmpty => pages.every((p) => p.paras.isEmpty);
  bool get hasImages => pages.any((p) => p.imagePath != null);

  /// Kata yang dipakai untuk penanda halaman.
  String get pageWord {
    switch (source) {
      case 'slide':
        return 'Slide';
      case 'word':
        return 'Bagian';
      default:
        return 'Halaman';
    }
  }

  String get preview {
    for (final p in pages) {
      for (final para in p.paras) {
        if (para.text.trim().isEmpty) continue;
        final t = para.text.trim();
        return t.length > 120 ? '${t.substring(0, 120)}…' : t;
      }
    }
    return '';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'source': source,
        'created': createdAt.toIso8601String(),
        'position': position,
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory ReadDoc.fromJson(Map<String, dynamic> j) {
    final pages = <PageData>[];
    final raw = j['pages'];
    if (raw is List) {
      for (final m in raw) {
        if (m is Map) pages.add(PageData.fromJson(Map<String, dynamic>.from(m)));
      }
    }
    return ReadDoc(
      id: (j['id'] ?? newDocId()).toString(),
      title: (j['title'] ?? 'Dokumen').toString(),
      source: (j['source'] ?? 'teks').toString(),
      createdAt: DateTime.tryParse((j['created'] ?? '').toString()) ?? DateTime.now(),
      pages: pages,
      position: (j['position'] is num) ? (j['position'] as num).toInt() : 0,
    );
  }
}
