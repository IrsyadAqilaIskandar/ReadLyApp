import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'config.dart';
import 'models.dart';
import 'text_utils.dart';

/// Satu paragraf (atau judul) di layar baca beserta kalimat-kalimatnya.
class ParaView {
  final int page; // indeks halaman (0-based)
  final bool heading;
  final List<int> sentences; // indeks kalimat global
  final bool firstOfPage;

  const ParaView({
    required this.page,
    required this.heading,
    required this.sentences,
    required this.firstOfPage,
  });
}

/// Mengatur pembacaan memakai mesin text-to-speech bawaan Android (offline):
/// membacakan kalimat demi kalimat dan menyimpan kalimat yang sedang dibacakan (untuk highlight).
class ReaderController extends ChangeNotifier {
  final FlutterTts _tts = FlutterTts();

  ReadDoc? doc;
  List<Sentence> sentences = const [];
  List<ParaView> paras = const [];

  /// Indeks halaman (0-based) yang punya teks, berurutan.
  List<int> pagesWithText = const [];

  int current = -1;
  bool playing = false;
  bool loading = false;
  String? error;

  // flutter_tts di Android: 0.5 = kecepatan normal.
  double _engineRate = 0.5;
  int _run = 0;
  bool _disposed = false;
  bool _initDone = false;
  bool _voiceWarned = false;
  String? _voiceWarning;

  double get engineRate => _engineRate;

  double get progress =>
      (sentences.isEmpty || current < 0) ? 0 : (current + 1) / sentences.length;

  /// Memasang dokumen; [startAt] = kalimat tempat melanjutkan membaca.
  void setDoc(ReadDoc d, {int startAt = 0}) {
    _run++;
    _tts.stop();
    doc = d;

    final s = <Sentence>[];
    final ps = <ParaView>[];
    final pages = <int>[];

    for (var pi = 0; pi < d.pages.length; pi++) {
      var first = true;
      for (final para in d.pages[pi].paras) {
        final texts = splitSentences(para.text);
        if (texts.isEmpty) continue;
        final isHeading = para.kind == ParaKind.heading;
        final idx = <int>[];
        for (final t in texts) {
          idx.add(s.length);
          s.add(Sentence(t, pi, ps.length, isHeading));
        }
        ps.add(ParaView(
          page: pi,
          heading: isHeading,
          sentences: idx,
          firstOfPage: first,
        ));
        if (first) pages.add(pi);
        first = false;
      }
    }

    sentences = s;
    paras = ps;
    pagesWithText = pages;
    current = (startAt > 0 && startAt < s.length) ? startAt : -1;
    playing = false;
    loading = false;
    error = null;
    _notify();
  }

  int firstSentenceOfPage(int page) {
    for (var i = 0; i < sentences.length; i++) {
      if (sentences[i].page == page) return i;
    }
    return 0;
  }

  /// Posisi karakter awal kalimat [i] di dalam teks paragrafnya
  /// (tiap kalimat diikuti satu spasi di tampilan).
  int charOffsetInPara(int i) {
    final para = paras[sentences[i].para];
    var off = 0;
    for (final k in para.sentences) {
      if (k == i) break;
      off += sentences[k].text.length + 1;
    }
    return off;
  }

  /// [r] adalah pengali kecepatan: 0.75x, 1.0x, 1.25x, 1.5x.
  void setRate(double r) {
    final v = (r * 0.5).clamp(0.1, 1.0).toDouble();
    if (v == _engineRate) return;
    _engineRate = v;
  }

  void clearError() {
    error = null;
    _notify();
  }

  Future<void> toggle() => playing ? pause() : play();

  Future<void> pause() async {
    _run++;
    playing = false;
    loading = false;
    _notify();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= sentences.length) return;
    await play(from: index);
  }

  Future<void> next() async {
    if (sentences.isEmpty) return;
    final target = current < 0 ? 0 : current + 1;
    if (target >= sentences.length) return;
    await play(from: target);
  }

  Future<void> prev() async {
    if (sentences.isEmpty) return;
    final target = current <= 0 ? 0 : current - 1;
    await play(from: target);
  }

  Future<void> _ensureInit() async {
    if (_initDone) return;
    loading = true;
    _notify();

    await _tts.awaitSpeakCompletion(true);

    final res = await _tts.setLanguage(AppConfig.ttsLanguage);
    final ok = res == 1 || res == true;
    if (!ok) {
      _voiceWarning =
          'Suara Bahasa Indonesia sepertinya belum terpasang di HP ini. Buka Pengaturan > '
          'Sistem > Bahasa > Output text-to-speech > Mesin Google > Instal data suara > '
          'Indonesia, lalu coba lagi. Sementara ini suara bawaan dipakai.';
    }
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _initDone = true;
    loading = false;
  }

  Future<void> play({int? from}) async {
    if (sentences.isEmpty) return;
    final run = ++_run;
    var i = from ?? ((current < 0 || current >= sentences.length) ? 0 : current);
    playing = true;
    error = null;
    _notify();

    try {
      await _ensureInit();
      if (run != _run) return;

      if (_voiceWarning != null && !_voiceWarned) {
        _voiceWarned = true;
        error = _voiceWarning; // peringatan satu kali; pembacaan tetap lanjut
        _notify();
      }

      // Hentikan ucapan sebelumnya supaya kalimat baru langsung dimulai.
      await _tts.stop();
      if (run != _run) return;

      while (i < sentences.length && run == _run) {
        current = i;
        _notify();

        await _tts.setSpeechRate(_engineRate);
        final res = await _tts.speak(sentences[i].text); // selesai saat kalimat habis
        if (run != _run) return;

        if (!(res == 1 || res == true)) {
          throw Exception('Mesin suara tidak dapat membacakan kalimat ini. '
              'Pastikan mesin text-to-speech aktif di pengaturan HP.');
        }
        i++;
      }

      if (run == _run) {
        playing = false;
        loading = false;
        current = -1;
        _notify();
      }
    } catch (e) {
      if (run == _run) {
        playing = false;
        loading = false;
        error = e.toString().replaceFirst('Exception: ', '');
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _run++;
    try {
      _tts.stop();
    } catch (_) {}
    super.dispose();
  }
}
