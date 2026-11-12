import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models.dart';
import '../reader_controller.dart';
import '../services/audio_export.dart';
import '../services/history_store.dart';
import '../settings.dart';
import '../widgets/premium_gate.dart';
import 'settings_screen.dart';

/// Layar baca: kartu teks dengan pemisah halaman dan highlight kalimat, tab Teks/Asli,
/// panel cepat (huruf, tebal, kontras, kecepatan), dan pemutar suara besar di bawah.
class ReaderScreen extends StatefulWidget {
  final ReadDoc doc;
  final int startAt;

  const ReaderScreen({super.key, required this.doc, this.startAt = 0});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final ReaderController ctrl = ReaderController();
  final ScrollController scroll = ScrollController();
  final PageController pageCtrl = PageController();
  late final AppSettings _settings;

  List<GlobalKey> paraKeys = [];
  final Map<int, GlobalKey> pageKeys = {};
  int mode = 0; // 0 = Teks, 1 = Asli
  int _lastSentence = -1;

  @override
  void initState() {
    super.initState();
    _settings = context.read<AppSettings>();
    ctrl.setDoc(widget.doc, startAt: widget.startAt);
    paraKeys = List.generate(ctrl.paras.length, (_) => GlobalKey());
    for (final p in ctrl.pagesWithText) {
      pageKeys[p] = GlobalKey();
    }
    ctrl.addListener(_follow);

    // Riwayat hanya disimpan bila Premium.
    if (_settings.isPremium) {
      widget.doc.position = ctrl.current < 0 ? 0 : ctrl.current;
      HistoryStore.save(widget.doc);
    }

    if (ctrl.current >= 0) {
      final i = ctrl.current;
      _lastSentence = i;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _scrollToSentence(i);
      });
    }
  }

  @override
  void dispose() {
    ctrl.removeListener(_follow);
    if (_settings.isPremium && ctrl.current >= 0) {
      HistoryStore.updatePosition(widget.doc.id, ctrl.current);
    }
    ctrl.dispose();
    scroll.dispose();
    pageCtrl.dispose();
    super.dispose();
  }

  // ---------------- Menggulir mengikuti kalimat ----------------

  void _follow() {
    if (mode != 0) return;
    final i = ctrl.current;
    if (i < 0) {
      _lastSentence = -1;
      return;
    }
    if (i == _lastSentence) return;
    _lastSentence = i;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scrollToSentence(i);
    });
  }

  /// Menggulir sampai kalimat [i] terlihat nyaman, bahkan di dalam paragraf yang panjang.
  void _scrollToSentence(int i) {
    if (i < 0 || i >= ctrl.sentences.length || !scroll.hasClients) return;
    final sent = ctrl.sentences[i];
    final ctx = paraKeys[sent.para].currentContext;
    if (ctx == null) return;

    final ro = ctx.findRenderObject();
    if (ro is RenderParagraph) {
      final start = ctrl.charOffsetInPara(i);
      final boxes = ro.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: start + sent.text.length),
      );
      final viewport = RenderAbstractViewport.maybeOf(ro);
      if (boxes.isNotEmpty && viewport != null) {
        final rect = Rect.fromLTRB(0, boxes.first.top, ro.size.width, boxes.first.bottom);
        final pos = scroll.position;
        final atTop = viewport.getOffsetToReveal(ro, 0.0, rect: rect).offset;
        final dist = (atTop - pos.pixels) / pos.viewportDimension;
        if (dist < 0.04 || dist > 0.6) {
          final target = viewport
              .getOffsetToReveal(ro, 0.2, rect: rect)
              .offset
              .clamp(pos.minScrollExtent, pos.maxScrollExtent)
              .toDouble();
          scroll.animateTo(
            target,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        }
        return;
      }
    }
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.15,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  // ---------------- Lompat halaman ----------------

  Future<void> _pickPage() async {
    final doc = widget.doc;
    final pages = ctrl.pagesWithText;
    final chosen = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lompat ke ${doc.pageWord.toLowerCase()}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final p in pages)
                        SizedBox(
                          width: 68,
                          height: 64,
                          child: FilledButton(
                            onPressed: () => Navigator.of(ctx).pop(p),
                            child: Text(
                              '${doc.pages[p].number}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (chosen != null) _goToPage(chosen);
  }

  void _goToPage(int pi) {
    HapticFeedback.selectionClick();
    if (mode == 1) {
      if (pageCtrl.hasClients) pageCtrl.jumpToPage(pi);
      return;
    }
    final ctx = pageKeys[pi]?.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
    if (ctrl.playing) ctrl.jumpTo(ctrl.firstSentenceOfPage(pi));
  }

  // ---------------- Ekspor audio (Premium) ----------------

  Future<void> _exportAudio() async {
    if (!_settings.isPremium) {
      openPremium(context);
      return;
    }
    if (ctrl.sentences.isEmpty) return;
    await ctrl.pause();
    if (!mounted) return;

    var cancelled = false;
    final progress = ValueNotifier<String>('Menyiapkan suara…');
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Membuat audio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LinearProgressIndicator(),
              const SizedBox(height: 14),
              ValueListenableBuilder<String>(
                valueListenable: progress,
                builder: (_, v, __) => Text(v, style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                cancelled = true;
                progress.value = 'Membatalkan…';
              },
              child: const Text('Batal', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );

    ExportResult? result;
    String? failure;
    try {
      result = await AudioExporter().exportWav(
        sentences: ctrl.sentences.map((e) => e.text).toList(),
        engineRate: ctrl.engineRate,
        language: AppConfig.ttsLanguage,
        onProgress: (done, total) => progress.value = 'Memproses bagian ${done + 1} dari $total…',
        isCancelled: () => cancelled,
      );
    } catch (e) {
      failure = e.toString();
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();

    if (failure != null) {
      _snack(failure);
      return;
    }
    if (result == null) {
      _snack('Ekspor dibatalkan.');
      return;
    }

    final safeTitle = widget.doc.title.replaceAll(RegExp(r'[^A-Za-z0-9_\- ]'), '').trim();
    String? saved;
    try {
      saved = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan audio',
        fileName: 'ReadLy_${safeTitle.isEmpty ? 'audio' : safeTitle}.wav',
        bytes: result.bytes,
      );
    } catch (e) {
      _snack('Tidak dapat menyimpan file: $e');
      return;
    }
    if (saved == null) {
      _snack('Penyimpanan dibatalkan.');
      return;
    }
    _snack(result.truncated
        ? 'Audio disimpan (${result.used} dari ${result.total} kalimat; dibatasi agar tidak terlalu besar).'
        : 'Audio disimpan.');
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  // ---------------- Tampilan ----------------

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final pal = s.palette;
    ctrl.setRate(s.rate);

    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: pal.screen,
          appBar: AppBar(
            backgroundColor: pal.screen,
            surfaceTintColor: Colors.transparent,
            foregroundColor: pal.text,
            elevation: 0,
            leading: IconButton(
              tooltip: 'Kembali',
              iconSize: 30,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            title: Text(
              widget.doc.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: pal.text, fontWeight: FontWeight.w700, fontSize: 18),
            ),
            actions: [
              if (ctrl.pagesWithText.length > 1)
                IconButton(
                  tooltip: 'Lompat ke ${widget.doc.pageWord.toLowerCase()}',
                  iconSize: 30,
                  onPressed: _pickPage,
                  icon: const Icon(Icons.format_list_numbered_rounded),
                ),
              IconButton(
                tooltip: 'Pengaturan tampilan',
                iconSize: 30,
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.tune_rounded),
              ),
              IconButton(
                tooltip: s.isPremium ? 'Ekspor audio' : 'Ekspor audio (Premium)',
                iconSize: 30,
                onPressed: _exportAudio,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.download_rounded, size: 30),
                    if (!s.isPremium) const Positioned(right: -6, top: -6, child: LockBadge(size: 18)),
                  ],
                ),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                if (ctrl.error != null) _errorBanner(),
                if (widget.doc.hasImages) _modeSwitch(pal),
                Expanded(
                  child: IndexedStack(
                    index: mode,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _textCard(pal, s)),
                          const SizedBox(width: 10),
                          _sidePanel(pal, s),
                        ],
                      ),
                      _originalView(pal),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _player(pal),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _modeSwitch(ReadPalette pal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          style: SegmentedButton.styleFrom(
            foregroundColor: pal.text,
            backgroundColor: pal.card,
            selectedForegroundColor: pal.onAccent,
            selectedBackgroundColor: pal.accent,
            minimumSize: const Size(0, 52),
          ),
          segments: const [
            ButtonSegment(
              value: 0,
              icon: Icon(Icons.article_outlined),
              label: Text('Teks', style: TextStyle(fontSize: 17)),
            ),
            ButtonSegment(
              value: 1,
              icon: Icon(Icons.image_outlined),
              label: Text('Asli', style: TextStyle(fontSize: 17)),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (v) {
            HapticFeedback.selectionClick();
            setState(() => mode = v.first);
          },
        ),
      ),
    );
  }

  Widget _errorBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8E8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFF8A1C1C)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              ctrl.error ?? '',
              style: const TextStyle(color: Color(0xFF8A1C1C), fontSize: 15),
            ),
          ),
          IconButton(
            tooltip: 'Tutup pesan',
            icon: const Icon(Icons.close_rounded, color: Color(0xFF8A1C1C)),
            onPressed: ctrl.clearError,
          ),
        ],
      ),
    );
  }

  Widget _pageHeader(int page, ReadPalette pal) {
    final doc = widget.doc;
    final label = '${doc.pageWord} ${doc.pages[page].number} dari ${doc.pages.last.number}';
    return Padding(
      key: pageKeys[page],
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Semantics(
        header: true,
        label: label,
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(child: Container(height: 2, color: pal.panel)),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: pal.panel,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                label,
                style: TextStyle(color: pal.panelIcon, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(child: Container(height: 2, color: pal.panel)),
          ],
        ),
      ),
    );
  }

  Widget _textCard(ReadPalette pal, AppSettings s) {
    final base = s.readingStyle(pal);
    final headStyle = s.readingStyle(pal, size: s.fontSize * 1.2, weight: FontWeight.w700);
    final multi = ctrl.pagesWithText.length > 1;

    final children = <Widget>[];
    for (var k = 0; k < ctrl.paras.length; k++) {
      final p = ctrl.paras[k];
      if (multi && p.firstOfPage) children.add(_pageHeader(p.page, pal));
      children.add(
        _ParaText(
          textKey: paraKeys[k],
          sentences: [for (final i in p.sentences) ctrl.sentences[i].text],
          firstIndex: p.sentences.first,
          active: ctrl.current,
          style: p.heading ? headStyle : base,
          hl: pal.highlight,
          hlText: pal.highlightText,
          align: p.heading ? TextAlign.left : s.effAlign,
          topGap: p.heading ? s.effParaSpacing * 0.6 : 0,
          bottomGap: s.effParaSpacing,
          onTap: ctrl.jumpTo,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SingleChildScrollView(
          controller: scroll,
          padding: EdgeInsets.fromLTRB(s.effMargin, 20, s.effMargin, 48),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ),
    );
  }

  Widget _originalView(ReadPalette pal) {
    final doc = widget.doc;
    return PageView.builder(
      controller: pageCtrl,
      itemCount: doc.pages.length,
      itemBuilder: (context, i) {
        final page = doc.pages[i];
        final path = page.imagePath;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '${doc.pageWord} ${page.number} dari ${doc.pages.last.number}  •  cubit untuk memperbesar',
                style: TextStyle(color: pal.text, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            Expanded(
              child: path == null
                  ? Center(
                      child: Text(
                        'Gambar asli tidak tersedia.',
                        style: TextStyle(color: pal.text, fontSize: 17),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        color: Colors.white,
                        child: InteractiveViewer(
                          minScale: 1,
                          maxScale: 6,
                          child: Center(
                            child: Image.file(
                              File(path),
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Padding(
                                padding: EdgeInsets.all(24),
                                child: Text(
                                  'Gambar asli tidak dapat dimuat.',
                                  style: TextStyle(fontSize: 17, color: Colors.black87),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _sidePanel(ReadPalette pal, AppSettings s) {
    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: pal.panel,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PanelButton(
              tooltip: 'Perbesar huruf',
              onTap: s.increaseFont,
              child: Text('A',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w600, color: pal.panelIcon)),
            ),
            _PanelButton(
              tooltip: 'Perkecil huruf',
              onTap: s.decreaseFont,
              child: Text('A',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: pal.panelIcon)),
            ),
            _PanelButton(
              tooltip: s.bold ? 'Matikan huruf tebal' : 'Nyalakan huruf tebal',
              onTap: s.toggleBold,
              selected: s.bold,
              selectedColor: pal.accent,
              child: Text('B',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: s.bold ? pal.onAccent : pal.panelIcon,
                  )),
            ),
            _PanelButton(
              tooltip: 'Ganti kontras',
              onTap: () {
                s.nextContrast();
                _snack('Kontras: ${s.contrastLabel}');
              },
              child: Icon(Icons.contrast, color: pal.panelIcon, size: 30),
            ),
            _PanelButton(
              tooltip: 'Kecepatan suara',
              onTap: s.nextRate,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.speed_rounded, color: pal.panelIcon, size: 24),
                  Text('${s.rate}x',
                      style: TextStyle(fontSize: 12, color: pal.panelIcon, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _player(ReadPalette pal) {
    final n = ctrl.sentences.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: pal.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 44,
                color: pal.accent,
                tooltip: 'Kalimat sebelumnya',
                onPressed: n == 0
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        ctrl.prev();
                      },
                icon: const Icon(Icons.skip_previous_rounded),
              ),
              const SizedBox(width: 14),
              Semantics(
                button: true,
                label: ctrl.playing ? 'Jeda' : 'Putar',
                excludeSemantics: true,
                child: SizedBox(
                  width: 76,
                  height: 76,
                  child: Material(
                    color: pal.accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: n == 0
                          ? null
                          : () {
                              HapticFeedback.mediumImpact();
                              ctrl.toggle();
                            },
                      child: Center(
                        child: ctrl.loading
                            ? SizedBox(
                                width: 30,
                                height: 30,
                                child: CircularProgressIndicator(strokeWidth: 3.5, color: pal.onAccent),
                              )
                            : Icon(
                                ctrl.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                size: 46,
                                color: pal.onAccent,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              IconButton(
                iconSize: 44,
                color: pal.accent,
                tooltip: 'Kalimat berikutnya',
                onPressed: n == 0
                    ? null
                    : () {
                        HapticFeedback.selectionClick();
                        ctrl.next();
                      },
                icon: const Icon(Icons.skip_next_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ctrl.progress,
              minHeight: 8,
              backgroundColor: pal.panel,
              color: pal.accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            ctrl.current < 0 ? '$n kalimat' : 'Kalimat ${ctrl.current + 1} dari $n',
            style: TextStyle(fontSize: 14.5, color: pal.text),
          ),
        ],
      ),
    );
  }
}

/// Satu paragraf dengan kalimat yang bisa diketuk dan di-highlight.
class _ParaText extends StatefulWidget {
  final GlobalKey textKey;
  final List<String> sentences;
  final int firstIndex;
  final int active;
  final TextStyle style;
  final Color hl;
  final Color hlText;
  final TextAlign align;
  final double topGap;
  final double bottomGap;
  final void Function(int) onTap;

  const _ParaText({
    required this.textKey,
    required this.sentences,
    required this.firstIndex,
    required this.active,
    required this.style,
    required this.hl,
    required this.hlText,
    required this.align,
    required this.topGap,
    required this.bottomGap,
    required this.onTap,
  });

  @override
  State<_ParaText> createState() => _ParaTextState();
}

class _ParaTextState extends State<_ParaText> {
  late final List<TapGestureRecognizer> _recs;

  @override
  void initState() {
    super.initState();
    _recs = [
      for (var i = 0; i < widget.sentences.length; i++)
        TapGestureRecognizer()..onTap = () => widget.onTap(widget.firstIndex + i),
    ];
  }

  @override
  void dispose() {
    for (final r in _recs) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < widget.sentences.length; i++) {
      final active = widget.firstIndex + i == widget.active;
      spans.add(
        TextSpan(
          text: '${widget.sentences[i]} ',
          recognizer: _recs[i],
          style: active
              ? TextStyle(backgroundColor: widget.hl, color: widget.hlText)
              : null,
        ),
      );
    }
    return Padding(
      padding: EdgeInsets.only(top: widget.topGap, bottom: widget.bottomGap),
      child: SizedBox(
        width: double.infinity,
        child: Text.rich(
          TextSpan(children: spans, style: widget.style),
          key: widget.textKey,
          textAlign: widget.align,
        ),
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final String tooltip;
  final VoidCallback onTap;
  final Widget child;
  final bool selected;
  final Color? selectedColor;

  const _PanelButton({
    required this.tooltip,
    required this.onTap,
    required this.child,
    this.selected = false,
    this.selectedColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Material(
          color: selected ? (selectedColor ?? Colors.transparent) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: SizedBox(width: 56, height: 58, child: Center(child: child)),
          ),
        ),
      ),
    );
  }
}
