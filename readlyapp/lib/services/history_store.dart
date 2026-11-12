import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models.dart';

/// Ringkasan satu dokumen di daftar riwayat.
class HistoryEntry {
  final String id;
  final String title;
  final String source;
  final String preview;
  final DateTime createdAt;
  final int pageCount;
  int position;

  HistoryEntry({
    required this.id,
    required this.title,
    required this.source,
    required this.preview,
    required this.createdAt,
    required this.pageCount,
    this.position = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'source': source,
        'preview': preview,
        'created': createdAt.toIso8601String(),
        'pages': pageCount,
        'position': position,
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> j) => HistoryEntry(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? 'Dokumen').toString(),
        source: (j['source'] ?? 'teks').toString(),
        preview: (j['preview'] ?? '').toString(),
        createdAt: DateTime.tryParse((j['created'] ?? '').toString()) ?? DateTime.now(),
        pageCount: (j['pages'] is num) ? (j['pages'] as num).toInt() : 1,
        position: (j['position'] is num) ? (j['position'] as num).toInt() : 0,
      );
}

/// Riwayat bacaan (fitur Premium) yang disimpan di HP:
/// folder `readly_history/` berisi `index.json` dan satu folder per dokumen
/// (teks `doc.json` + gambar halaman). Semua operasi aman dari error: bila gagal,
/// aplikasi tetap berjalan dan riwayat dianggap kosong.
class HistoryStore {
  static const int maxItems = 50;

  static Future<Directory> _root() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/readly_history');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File> _indexFile() async => File('${(await _root()).path}/index.json');

  static Future<List<HistoryEntry>> list() async {
    try {
      final f = await _indexFile();
      if (!await f.exists()) return [];
      final data = jsonDecode(await f.readAsString());
      if (data is! List) return [];
      return data
          .whereType<Map>()
          .map((m) => HistoryEntry.fromJson(Map<String, dynamic>.from(m)))
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _writeIndex(List<HistoryEntry> items) async {
    final f = await _indexFile();
    await f.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  /// Menyimpan (atau memperbarui) dokumen, termasuk menyalin gambar halamannya.
  static Future<void> save(ReadDoc doc) async {
    try {
      final root = await _root();
      final dir = Directory('${root.path}/${doc.id}');
      await dir.create(recursive: true);

      final pages = <PageData>[];
      for (final p in doc.pages) {
        String? path = p.imagePath;
        if (path != null && !path.startsWith(dir.path)) {
          final src = File(path);
          if (await src.exists()) {
            final dot = path.lastIndexOf('.');
            final ext = dot > path.lastIndexOf('/') ? path.substring(dot) : '.jpg';
            final dest = '${dir.path}/page_${p.number}$ext';
            await src.copy(dest);
            path = dest;
          } else {
            path = null;
          }
        }
        pages.add(PageData(number: p.number, paras: p.paras, imagePath: path));
      }

      final stored = ReadDoc(
        id: doc.id,
        title: doc.title,
        source: doc.source,
        createdAt: doc.createdAt,
        pages: pages,
        position: doc.position,
      );
      await File('${dir.path}/doc.json').writeAsString(jsonEncode(stored.toJson()));

      final items = await list();
      items.removeWhere((e) => e.id == doc.id);
      items.insert(
        0,
        HistoryEntry(
          id: doc.id,
          title: doc.title,
          source: doc.source,
          preview: doc.preview,
          createdAt: doc.createdAt,
          pageCount: doc.pages.length,
          position: doc.position,
        ),
      );
      while (items.length > maxItems) {
        final old = items.removeLast();
        await _deleteDir(old.id);
      }
      await _writeIndex(items);
    } catch (_) {
      // Riwayat bersifat tambahan; kegagalan tidak boleh mengganggu pembacaan.
    }
  }

  static Future<ReadDoc?> load(String id) async {
    try {
      final root = await _root();
      final f = File('${root.path}/$id/doc.json');
      if (!await f.exists()) return null;
      final data = jsonDecode(await f.readAsString());
      if (data is! Map) return null;
      final doc = ReadDoc.fromJson(Map<String, dynamic>.from(data));
      final items = await list();
      for (final e in items) {
        if (e.id == id) doc.position = e.position;
      }
      return doc;
    } catch (_) {
      return null;
    }
  }

  static Future<void> updatePosition(String id, int position) async {
    try {
      final items = await list();
      var changed = false;
      for (final e in items) {
        if (e.id == id) {
          e.position = position;
          changed = true;
        }
      }
      if (changed) await _writeIndex(items);
    } catch (_) {}
  }

  static Future<void> delete(String id) async {
    try {
      final items = await list();
      items.removeWhere((e) => e.id == id);
      await _writeIndex(items);
      await _deleteDir(id);
    } catch (_) {}
  }

  static Future<void> clear() async {
    try {
      final root = await _root();
      if (await root.exists()) await root.delete(recursive: true);
    } catch (_) {}
  }

  static Future<void> _deleteDir(String id) async {
    try {
      final root = await _root();
      final dir = Directory('${root.path}/$id');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
