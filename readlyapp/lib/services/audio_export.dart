import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class AudioExportException implements Exception {
  final String message;
  AudioExportException(this.message);

  @override
  String toString() => message;
}

class ExportResult {
  final Uint8List bytes; // file WAV lengkap
  final int used; // jumlah kalimat yang masuk
  final int total; // jumlah kalimat dokumen
  const ExportResult(this.bytes, this.used, this.total);
  bool get truncated => used < total;
}

class _Wav {
  final int channels;
  final int rate;
  final int bits;
  final int dataStart;
  final int dataEnd;
  const _Wav(this.channels, this.rate, this.bits, this.dataStart, this.dataEnd);
}

/// Ekspor audio (Premium): mesin suara Android menyintesis teks ke file WAV per potongan,
/// lalu potongan-potongan itu digabung menjadi satu file WAV.
/// Dibatasi [maxChars] karakter supaya memori tidak habis di HP.
class AudioExporter {
  static const int maxChars = 8000;
  static const int chunkChars = 3000;

  Future<ExportResult?> exportWav({
    required List<String> sentences,
    required double engineRate,
    required String language,
    void Function(int done, int total)? onProgress,
    bool Function()? isCancelled,
  }) async {
    // 1. Pilih kalimat sampai batas karakter.
    final chosen = <String>[];
    var chars = 0;
    for (final s in sentences) {
      if (chars + s.length > maxChars && chosen.isNotEmpty) break;
      chosen.add(s);
      chars += s.length + 1;
    }
    if (chosen.isEmpty) throw AudioExportException('Tidak ada teks untuk diekspor.');

    // 2. Kelompokkan menjadi potongan.
    final chunks = <String>[];
    var buf = StringBuffer();
    for (final s in chosen) {
      if (buf.length > 0 && buf.length + s.length + 1 > chunkChars) {
        chunks.add(buf.toString().trim());
        buf = StringBuffer();
      }
      buf.write(s);
      buf.write(' ');
    }
    if (buf.toString().trim().isNotEmpty) chunks.add(buf.toString().trim());

    // 3. Sintesis tiap potongan ke file WAV.
    final dir = await getExternalStorageDirectory();
    if (dir == null) throw AudioExportException('Penyimpanan HP tidak tersedia.');

    final tts = FlutterTts();
    await tts.awaitSynthCompletion(true);
    await tts.setLanguage(language);
    await tts.setSpeechRate(engineRate);

    final parts = <Uint8List>[];
    for (var i = 0; i < chunks.length; i++) {
      if (isCancelled?.call() ?? false) return null;
      onProgress?.call(i, chunks.length);

      final name = 'readly_export_$i.wav';
      final res = await tts.synthesizeToFile(chunks[i], name);
      final file = File('${dir.path}/$name');
      final ok = (res == 1 || res == true) && await file.exists();
      if (!ok) {
        throw AudioExportException(
            'Mesin suara gagal membuat file audio. Pastikan data suara Bahasa Indonesia terpasang.');
      }
      parts.add(await file.readAsBytes());
      try {
        await file.delete();
      } catch (_) {}
    }
    onProgress?.call(chunks.length, chunks.length);

    final merged = _merge(parts);
    if (merged == null) {
      throw AudioExportException('Format audio dari mesin suara tidak dikenali.');
    }
    return ExportResult(merged, chosen.length, sentences.length);
  }

  /// Menggabungkan data PCM dari beberapa file WAV (formatnya sama karena satu mesin).
  Uint8List? _merge(List<Uint8List> parts) {
    int? channels;
    int? rate;
    int? bits;
    final pcm = BytesBuilder();

    for (final w in parts) {
      final info = _parse(w);
      if (info == null) continue;
      channels ??= info.channels;
      rate ??= info.rate;
      bits ??= info.bits;
      pcm.add(Uint8List.sublistView(w, info.dataStart, info.dataEnd));
    }
    if (channels == null || rate == null || bits == null || pcm.length == 0) return null;

    final data = pcm.toBytes();
    final byteRate = rate * channels * bits ~/ 8;
    final blockAlign = channels * bits ~/ 8;

    final h = ByteData(44);
    void tag(int offset, String t) {
      for (var i = 0; i < 4; i++) {
        h.setUint8(offset + i, t.codeUnitAt(i));
      }
    }

    tag(0, 'RIFF');
    h.setUint32(4, 36 + data.length, Endian.little);
    tag(8, 'WAVE');
    tag(12, 'fmt ');
    h.setUint32(16, 16, Endian.little);
    h.setUint16(20, 1, Endian.little); // PCM
    h.setUint16(22, channels, Endian.little);
    h.setUint32(24, rate, Endian.little);
    h.setUint32(28, byteRate, Endian.little);
    h.setUint16(32, blockAlign, Endian.little);
    h.setUint16(34, bits, Endian.little);
    tag(36, 'data');
    h.setUint32(40, data.length, Endian.little);

    final out = Uint8List(44 + data.length);
    out.setRange(0, 44, h.buffer.asUint8List());
    out.setRange(44, out.length, data);
    return out;
  }

  _Wav? _parse(Uint8List b) {
    if (b.length < 44) return null;
    final bd = ByteData.sublistView(b);
    if (String.fromCharCodes(b.sublist(0, 4)) != 'RIFF' ||
        String.fromCharCodes(b.sublist(8, 12)) != 'WAVE') {
      return null;
    }

    int? channels;
    int? rate;
    int? bits;
    var pos = 12;
    while (pos + 8 <= b.length) {
      final id = String.fromCharCodes(b.sublist(pos, pos + 4));
      final size = bd.getUint32(pos + 4, Endian.little);
      final body = pos + 8;

      if (id == 'fmt ' && body + 16 <= b.length) {
        channels = bd.getUint16(body + 2, Endian.little);
        rate = bd.getUint32(body + 4, Endian.little);
        bits = bd.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        var end = body + size;
        // Ukuran 0 atau melebihi file = header streaming; pakai sisa file.
        if (size == 0 || end > b.length) end = b.length;
        if (channels == null || rate == null || bits == null) return null;
        return _Wav(channels, rate, bits, body, end);
      }
      pos = body + size + (size.isOdd ? 1 : 0);
    }
    return null;
  }
}
