/// Satu kalimat yang dibacakan dan di-highlight.
class Sentence {
  final String text;
  final int page; // indeks halaman (0-based)
  final int para; // indeks paragraf (global)
  final bool heading;
  const Sentence(this.text, this.page, this.para, this.heading);
}

/// Memecah teks mentah (hasil tempel) menjadi paragraf.
/// Baris kosong = pergantian paragraf; baris baru tunggal dianggap lanjutan kalimat.
List<String> splitParagraphs(String raw) {
  final cleaned = raw.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final out = <String>[];
  for (final p in cleaned.split(RegExp(r'\n\s*\n'))) {
    final flat = p
        .replaceAll(RegExp(r'\s*\n\s*'), ' ')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ')
        .trim();
    if (flat.isNotEmpty) out.add(flat);
  }
  return out;
}

/// Memecah satu paragraf menjadi kalimat. Potongan lebih panjang dari [maxLen]
/// dipecah di spasi (batas aman untuk mesin suara).
List<String> splitSentences(String text, {int maxLen = 280}) {
  final flat = text.trim();
  if (flat.isEmpty) return const [];

  final parts = flat.split(RegExp(r'(?<=[.!?…])\s+'));
  final out = <String>[];
  var carry = '';

  for (final raw in parts) {
    final part = (carry + raw).trim();
    carry = '';
    if (part.isEmpty) continue;
    // Potongan sangat pendek (mis. "1." atau "Dr.") digabung dengan kalimat berikutnya.
    if (part.length < 4) {
      carry = '$part ';
      continue;
    }
    out.addAll(_chunk(part, maxLen));
  }
  if (carry.trim().isNotEmpty) out.addAll(_chunk(carry.trim(), maxLen));
  return out;
}

/// Menggabungkan baris-baris hasil OCR dalam satu blok menjadi satu paragraf.
/// Baris yang diakhiri tanda hubung dan disambung huruf kecil digabung tanpa spasi
/// (tanda hubung dipertahankan agar kata ulang seperti "anak-anak" tidak rusak).
String joinOcrLines(List<String> lines) {
  final b = StringBuffer();
  var last = '';
  for (final raw in lines) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (last.isEmpty) {
      b.write(line);
    } else if (last.endsWith('-') && RegExp(r'^[a-z]').hasMatch(line)) {
      b.write(line);
    } else {
      b.write(' ');
      b.write(line);
    }
    last = line;
  }
  return b.toString();
}

Iterable<String> _chunk(String s, int maxLen) sync* {
  var rest = s;
  while (rest.length > maxLen) {
    var cut = rest.lastIndexOf(' ', maxLen);
    if (cut <= 0) cut = maxLen;
    yield rest.substring(0, cut).trim();
    rest = rest.substring(cut).trim();
  }
  if (rest.isNotEmpty) yield rest;
}
