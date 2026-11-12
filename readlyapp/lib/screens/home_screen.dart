import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../services/ocr_service.dart';
import '../services/office_service.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/logo.dart';
import '../widgets/phone_preview.dart';
import '../widgets/premium_gate.dart';
import 'history_screen.dart';
import 'reader_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  void _openReader(ReadDoc doc) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ReaderScreen(doc: doc)),
    );
  }

  String _stripExt(String name) {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  /// Menjalankan pekerjaan baca dokumen dengan dialog loading, lalu membuka layar baca.
  Future<void> _run(
    String label,
    Future<ReadDoc> Function(ValueNotifier<String> status) job,
  ) async {
    final status = ValueNotifier<String>(label);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3.5),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: status,
                  builder: (_, v, __) => Text(v, style: const TextStyle(fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final doc = await job(status);
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (doc.isEmpty) {
        _snack('Tidak ada teks yang terbaca. Coba foto yang lebih jelas dan terang.');
        return;
      }
      _openReader(doc);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _snack(e.toString());
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2600,
      );
    } catch (e) {
      _snack('Tidak dapat membuka ${source == ImageSource.camera ? 'kamera' : 'galeri'}.');
      return;
    }
    if (file == null) return;
    final String path = file.path;
    await _run(
      'Membaca teks dari gambar…',
      (status) => OcrService().readImageFile(path),
    );
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );
    } catch (e) {
      _snack('Tidak dapat membuka pemilih file.');
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      _snack('File tidak dapat dibaca.');
      return;
    }
    await _run(
      'Membaca PDF…',
      (status) => OcrService().readPdf(
        bytes,
        title: _stripExt(picked.name),
        onProgress: (page, total) => status.value = 'Membaca PDF… halaman $page dari $total',
      ),
    );
  }

  Future<void> _pickOffice() async {
    final premium = context.read<AppSettings>().isPremium;
    if (!premium) {
      openPremium(context);
      return;
    }
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['docx', 'pptx'],
        withData: true,
      );
    } catch (e) {
      _snack('Tidak dapat membuka pemilih file.');
      return;
    }
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null) {
      _snack('File tidak dapat dibaca.');
      return;
    }
    await _run(
      'Membaca dokumen…',
      (status) => OfficeService().read(bytes, picked.name),
    );
  }

  Future<void> _pasteText() async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tempel teks', style: heading(20)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              minLines: 4,
              maxLines: 8,
              style: const TextStyle(fontSize: 18),
              decoration: InputDecoration(
                hintText: 'Tempel atau ketik teks di sini…',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton.icon(
                onPressed: () => Navigator.pop(ctx, controller.text),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text('Bacakan', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (text == null || text.trim().isEmpty || !mounted) return;
    _openReader(ReadDoc.fromPlainText(text));
  }

  void _openHistory() {
    final premium = context.read<AppSettings>().isPremium;
    if (!premium) {
      openPremium(context);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  void _openSettings() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<AppSettings>().isPremium;

    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: -70, right: -50, child: _blob(200, RC.paleBlue)),
          Positioned(top: -90, left: 140, child: _blob(160, const Color(0xFFDCE8F8))),
          Positioned(bottom: 120, left: -90, child: _blob(180, RC.paleBlue)),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: ReadLyLogo(size: 36, showRays: true),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _TopButton(
                        icon: Icons.workspace_premium_rounded,
                        label: premium ? 'Premium aktif' : 'ReadLy Premium',
                        color: premium ? RC.gold : RC.navy,
                        onTap: () => openPremium(context),
                      ),
                      const SizedBox(width: 8),
                      _TopButton(
                        icon: Icons.settings_rounded,
                        label: 'Pengaturan',
                        color: RC.navy,
                        onTap: _openSettings,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'APLIKASI ASSISTIVE READING UNTUK PENGGUNA LOW VISION, '
                    'DISLEKSIA, DAN KESULITAN MEMBACA',
                    style: GoogleFonts.poppins(fontSize: 12.5, height: 1.4, color: Colors.black87),
                  ),
                  const SizedBox(height: 20),
                  Center(child: _hero()),
                  const SizedBox(height: 24),
                  Text('Mulai membaca', style: heading(24)),
                  const SizedBox(height: 4),
                  Text(
                    'Pilih sumber bacaan Anda. ReadLy mengubahnya menjadi teks yang bisa dibaca dan didengarkan.',
                    style: GoogleFonts.lato(fontSize: 16, height: 1.4, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 1.0,
                    children: [
                      _Tile(
                        icon: Icons.photo_camera_rounded,
                        title: 'FOTO KAMERA',
                        subtitle: 'Foto → Teks',
                        onTap: () => _pickImage(ImageSource.camera),
                      ),
                      _Tile(
                        icon: Icons.photo_library_rounded,
                        title: 'GALERI FOTO',
                        subtitle: 'Foto → Teks',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),
                      _Tile(
                        icon: Icons.picture_as_pdf_rounded,
                        title: 'FILE PDF',
                        subtitle: 'PDF → Teks',
                        onTap: _pickPdf,
                      ),
                      _Tile(
                        icon: Icons.content_paste_rounded,
                        title: 'TEMPEL TEKS',
                        subtitle: 'Teks → Suara',
                        onTap: _pasteText,
                      ),
                      _Tile(
                        icon: Icons.description_rounded,
                        title: 'WORD / PPT',
                        subtitle: 'Dokumen → Teks',
                        locked: !premium,
                        onTap: _pickOffice,
                      ),
                      _Tile(
                        icon: Icons.history_rounded,
                        title: 'RIWAYAT',
                        subtitle: 'Lanjut membaca',
                        locked: !premium,
                        onTap: _openHistory,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                      'One application • Multiple reading needs\nAccessible • Personalized • Independent',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.arvo(fontSize: 12.5, height: 1.5, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hero() {
    return LayoutBuilder(
      builder: (context, box) {
        final d = box.maxWidth < 312 ? box.maxWidth : 312.0;
        return Container(
          width: d,
          height: d,
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: RC.sky, shape: BoxShape.circle),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF7FBFF), Color(0xFFE6F0FA)],
              ),
            ),
            child: const Center(
              child: FittedBox(fit: BoxFit.scaleDown, child: PhonePreview()),
            ),
          ),
        );
      },
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

/// Tombol bulat di bagian atas (Premium dan Pengaturan), 52 dp agar mudah diketuk.
class _TopButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _TopButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(width: 52, height: 52, child: Icon(icon, color: color, size: 30)),
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool locked;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.locked = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$title. $subtitle.${locked ? ' Fitur Premium, terkunci.' : ''}',
      child: Material(
        color: RC.blue,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: Colors.white, size: 42),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.arvo(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(color: Colors.white, fontSize: 14.5),
                      ),
                    ],
                  ),
                ),
              ),
              if (locked) const Positioned(top: 10, right: 10, child: LockBadge(size: 28)),
            ],
          ),
        ),
      ),
    );
  }
}
