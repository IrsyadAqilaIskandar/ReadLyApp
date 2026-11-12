import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/history_store.dart';
import '../theme.dart';
import 'reader_screen.dart';

/// Daftar dokumen yang pernah dibaca (fitur Premium).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<HistoryEntry>? _items;

  static const _bulan = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final list = await HistoryStore.list();
    if (!mounted) return;
    setState(() => _items = list);
  }

  String _sourceLabel(String s) {
    switch (s) {
      case 'foto':
        return 'Foto';
      case 'pdf':
        return 'PDF';
      case 'word':
        return 'Word';
      case 'slide':
        return 'PowerPoint';
      default:
        return 'Teks';
    }
  }

  IconData _sourceIcon(String s) {
    switch (s) {
      case 'foto':
        return Icons.photo_camera_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'word':
        return Icons.description_rounded;
      case 'slide':
        return Icons.slideshow_rounded;
      default:
        return Icons.content_paste_rounded;
    }
  }

  String _date(DateTime d) => '${d.day} ${_bulan[d.month - 1]} ${d.year}';

  Future<void> _open(HistoryEntry e) async {
    HapticFeedback.selectionClick();
    final doc = await HistoryStore.load(e.id);
    if (!mounted) return;
    if (doc == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Dokumen ini tidak dapat dibuka lagi.')));
      await HistoryStore.delete(e.id);
      _reload();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReaderScreen(doc: doc, startAt: doc.position)),
    );
    _reload();
  }

  Future<bool> _confirm(String title, String message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message, style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal', style: TextStyle(fontSize: 16)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _delete(HistoryEntry e) async {
    if (!await _confirm('Hapus dokumen?', '"${e.title}" akan dihapus dari riwayat.')) return;
    await HistoryStore.delete(e.id);
    _reload();
  }

  Future<void> _clearAll() async {
    if (!await _confirm('Hapus semua riwayat?', 'Semua dokumen di riwayat akan dihapus.')) return;
    await HistoryStore.clear();
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat bacaan', style: heading(20)),
        backgroundColor: RC.lightBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Kembali',
          iconSize: 30,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          if (items != null && items.isNotEmpty)
            IconButton(
              tooltip: 'Hapus semua riwayat',
              iconSize: 28,
              icon: const Icon(Icons.delete_sweep_rounded),
              onPressed: _clearAll,
            ),
        ],
      ),
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? _empty()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _card(items[i]),
                ),
    );
  }

  Widget _empty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 72, color: RC.paleBlue),
            const SizedBox(height: 14),
            Text('Belum ada riwayat', style: heading(20)),
            const SizedBox(height: 8),
            Text(
              'Dokumen yang Anda baca akan tersimpan di sini selama Premium aktif.',
              textAlign: TextAlign.center,
              style: GoogleFonts.lato(fontSize: 16, height: 1.4, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(HistoryEntry e) {
    final pages = e.pageCount > 1 ? ' • ${e.pageCount} bagian' : '';
    final resume = e.position > 0 ? ' • lanjut dari kalimat ${e.position + 1}' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        label: '${e.title}. ${_sourceLabel(e.source)}, ${_date(e.createdAt)}. Ketuk untuk membuka.',
        excludeSemantics: true,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _open(e),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: RC.blue,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_sourceIcon(e.source), color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_sourceLabel(e.source)} • ${_date(e.createdAt)}$pages$resume',
                          style: GoogleFonts.lato(fontSize: 14, color: Colors.black54),
                        ),
                        if (e.preview.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            e.preview,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lato(fontSize: 15, height: 1.35),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus ${e.title}',
                    iconSize: 28,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: () => _delete(e),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
