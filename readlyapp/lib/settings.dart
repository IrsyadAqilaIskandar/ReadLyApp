import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'theme.dart';

enum ContrastMode { normal, tinggi, hitamKuning, gelap }

enum FontChoice { standar, atkinson, lexend, comicNeue, merriweather, openSans }

const Map<FontChoice, String> fontLabels = {
  FontChoice.standar: 'Standar (Lato)',
  FontChoice.atkinson: 'Atkinson Hyperlegible',
  FontChoice.lexend: 'Lexend',
  FontChoice.comicNeue: 'Comic Neue',
  FontChoice.merriweather: 'Merriweather',
  FontChoice.openSans: 'Open Sans',
};

class ReadPalette {
  final Color screen;
  final Color card;
  final Color text;
  final Color highlight;
  final Color highlightText;
  final Color panel;
  final Color panelIcon;
  final Color accent;
  final Color onAccent;

  const ReadPalette({
    required this.screen,
    required this.card,
    required this.text,
    required this.highlight,
    required this.highlightText,
    required this.panel,
    required this.panelIcon,
    required this.accent,
    required this.onAccent,
  });

  ReadPalette copyWith({
    Color? screen,
    Color? card,
    Color? text,
    Color? highlight,
    Color? highlightText,
    Color? panel,
    Color? panelIcon,
    Color? accent,
    Color? onAccent,
  }) =>
      ReadPalette(
        screen: screen ?? this.screen,
        card: card ?? this.card,
        text: text ?? this.text,
        highlight: highlight ?? this.highlight,
        highlightText: highlightText ?? this.highlightText,
        panel: panel ?? this.panel,
        panelIcon: panelIcon ?? this.panelIcon,
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
      );
}

/// Tema warna siap pakai (Premium).
class ColorTheme {
  final String name;
  final Color bg;
  final Color card;
  final Color text;
  final Color hl;
  const ColorTheme(this.name, this.bg, this.card, this.text, this.hl);
}

const List<ColorTheme> presetThemes = [
  ColorTheme('Krem', Color(0xFFF7EDD2), Color(0xFFFFF8E1), Color(0xFF3B2F1E), Color(0xFFFFD27A)),
  ColorTheme('Langit', Color(0xFFDCEEFB), Color(0xFFEAF5FD), Color(0xFF0B2A44), Color(0xFFFFE082)),
  ColorTheme('Mint', Color(0xFFDDF1E4), Color(0xFFEAF8EF), Color(0xFF0F3D26), Color(0xFFFFF176)),
  ColorTheme('Lavender', Color(0xFFE9E0F6), Color(0xFFF3EEFB), Color(0xFF2B1B4D), Color(0xFFFFE082)),
  ColorTheme('Sepia', Color(0xFFE6D3B0), Color(0xFFEFE0C4), Color(0xFF4A3520), Color(0xFFF4B860)),
];

/// Pilihan warna untuk tema kustom (Premium).
class Swatch {
  final String name;
  final Color color;
  const Swatch(this.name, this.color);
}

const List<Swatch> swatches = [
  Swatch('Hitam', Color(0xFF000000)),
  Swatch('Putih', Color(0xFFFFFFFF)),
  Swatch('Krem', Color(0xFFFFF8E1)),
  Swatch('Kuning', Color(0xFFFFEB3B)),
  Swatch('Biru tua', Color(0xFF0D2B66)),
  Swatch('Biru muda', Color(0xFFD6ECFF)),
  Swatch('Hijau tua', Color(0xFF0E4D2F)),
  Swatch('Hijau muda', Color(0xFFDDF5E5)),
  Swatch('Merah tua', Color(0xFF7A1010)),
  Swatch('Oranye', Color(0xFFFF9800)),
  Swatch('Ungu tua', Color(0xFF4A2A8A)),
  Swatch('Abu tua', Color(0xFF333333)),
];

class ProfileInfo {
  final String key;
  final String name;
  final String desc;
  const ProfileInfo(this.key, this.name, this.desc);
}

const List<ProfileInfo> readProfiles = [
  ProfileInfo('standar', 'Standar', 'Kembali ke pengaturan bawaan'),
  ProfileInfo('lowvision', 'Low vision', 'Huruf besar dan tebal, kontras hitam-kuning'),
  ProfileInfo('disleksia', 'Disleksia', 'Huruf Lexend, jarak lebar, latar krem'),
  ProfileInfo('malam', 'Malam', 'Mode gelap dengan jarak baris longgar'),
  ProfileInfo('fokus', 'Fokus', 'Margin lebar dan jarak antar paragraf besar'),
];

/// Rasio kontras WCAG antara dua warna (>= 4.5 dianggap nyaman dibaca).
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Color _onColor(Color c) =>
    ThemeData.estimateBrightnessForColor(c) == Brightness.dark ? Colors.white : Colors.black;

double _num(Object? v, double def, double lo, double hi) =>
    v is num ? v.toDouble().clamp(lo, hi).toDouble() : def;

int _int(Object? v, int def, int lo, int hi) =>
    v is num ? v.toInt().clamp(lo, hi).toInt() : def;

class AppSettings extends ChangeNotifier {
  static const double minFont = 14;
  static const double maxFont = 64;
  static const List<double> rates = [0.75, 1.0, 1.25, 1.5];
  static int get customThemeIdx => presetThemes.length + 1;

  // ---- Gratis (kebutuhan dasar low vision) ----
  double fontSize = 22;
  ContrastMode contrast = ContrastMode.normal;
  bool bold = false;
  double rate = 1.0;

  // ---- Premium (kecantikan dan personalisasi) ----
  FontChoice font = FontChoice.standar;
  int themeIdx = 0; // 0 = ikuti mode kontras, 1..n = preset, n+1 = kustom
  int customText = -1;
  int customBg = -1;
  int customHl = -1;
  double lineHeight = 1.65;
  double letterSpacing = 0;
  double wordSpacing = 0;
  double paraSpacing = 14;
  double margin = 20;
  bool justify = false;
  String profile = 'standar';

  // ---- Status Premium (sementara bisa diubah lewat Pengaturan) ----
  bool isPremium = false;
  String? plan;

  // ================= Penyimpanan =================

  Future<void> load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final raw = p.getString('settings_v2');
      if (raw == null) return;
      final m = jsonDecode(raw);
      if (m is! Map) return;
      fontSize = _num(m['fontSize'], 22, minFont, maxFont);
      contrast = ContrastMode.values[_int(m['contrast'], 0, 0, ContrastMode.values.length - 1)];
      bold = m['bold'] == true;
      rate = _num(m['rate'], 1.0, 0.5, 2.0);
      if (!rates.contains(rate)) rate = 1.0;
      font = FontChoice.values[_int(m['font'], 0, 0, FontChoice.values.length - 1)];
      themeIdx = _int(m['themeIdx'], 0, 0, customThemeIdx);
      customText = _int(m['customText'], -1, -1, swatches.length - 1);
      customBg = _int(m['customBg'], -1, -1, swatches.length - 1);
      customHl = _int(m['customHl'], -1, -1, swatches.length - 1);
      lineHeight = _num(m['lineHeight'], 1.65, 1.2, 2.6);
      letterSpacing = _num(m['letterSpacing'], 0, 0, 4);
      wordSpacing = _num(m['wordSpacing'], 0, 0, 12);
      paraSpacing = _num(m['paraSpacing'], 14, 6, 48);
      margin = _num(m['margin'], 20, 8, 48);
      justify = m['justify'] == true;
      profile = (m['profile'] ?? 'standar').toString();
      isPremium = m['isPremium'] == true;
      plan = m['plan']?.toString();
    } catch (_) {
      // Pakai nilai bawaan bila penyimpanan gagal.
    }
  }

  Future<void> _save() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        'settings_v2',
        jsonEncode({
          'fontSize': fontSize,
          'contrast': contrast.index,
          'bold': bold,
          'rate': rate,
          'font': font.index,
          'themeIdx': themeIdx,
          'customText': customText,
          'customBg': customBg,
          'customHl': customHl,
          'lineHeight': lineHeight,
          'letterSpacing': letterSpacing,
          'wordSpacing': wordSpacing,
          'paraSpacing': paraSpacing,
          'margin': margin,
          'justify': justify,
          'profile': profile,
          'isPremium': isPremium,
          'plan': plan,
        }),
      );
    } catch (_) {}
  }

  /// Ubah pengaturan lalu beritahu tampilan dan simpan.
  /// Untuk slider, panggil dengan save: false saat digeser, lalu sekali lagi saat selesai.
  void change(VoidCallback fn, {bool save = true}) {
    fn();
    notifyListeners();
    if (save) _save();
  }

  // ================= Aksi cepat =================

  void increaseFont() =>
      change(() => fontSize = (fontSize + (fontSize >= 32 ? 4 : 2)).clamp(minFont, maxFont).toDouble());

  void decreaseFont() =>
      change(() => fontSize = (fontSize - (fontSize > 32 ? 4 : 2)).clamp(minFont, maxFont).toDouble());

  void toggleBold() => change(() => bold = !bold);

  void nextContrast() =>
      change(() => contrast = ContrastMode.values[(contrast.index + 1) % ContrastMode.values.length]);

  void nextRate() {
    final i = rates.indexOf(rate);
    change(() => rate = rates[(i + 1) % rates.length]);
  }

  void setPremium(bool value, {String? plan}) {
    change(() {
      isPremium = value;
      this.plan = value ? (plan ?? 'Uji coba') : null;
    });
  }

  void resetAll() {
    change(() {
      fontSize = 22;
      contrast = ContrastMode.normal;
      bold = false;
      rate = 1.0;
      _resetPersonalization();
    });
  }

  void _resetPersonalization() {
    font = FontChoice.standar;
    themeIdx = 0;
    customText = -1;
    customBg = -1;
    customHl = -1;
    lineHeight = 1.65;
    letterSpacing = 0;
    wordSpacing = 0;
    paraSpacing = 14;
    margin = 20;
    justify = false;
    profile = 'standar';
  }

  /// Menerapkan profil siap pakai (Premium).
  void applyProfile(String key) {
    if (!isPremium) return;
    change(() {
      _resetPersonalization();
      fontSize = 22;
      contrast = ContrastMode.normal;
      bold = false;
      profile = key;
      switch (key) {
        case 'lowvision':
          font = FontChoice.atkinson;
          fontSize = 36;
          bold = true;
          contrast = ContrastMode.hitamKuning;
          lineHeight = 1.8;
          paraSpacing = 24;
          break;
        case 'disleksia':
          font = FontChoice.lexend;
          themeIdx = 1;
          fontSize = 24;
          letterSpacing = 1.2;
          wordSpacing = 5;
          lineHeight = 1.9;
          paraSpacing = 22;
          break;
        case 'malam':
          contrast = ContrastMode.gelap;
          font = FontChoice.openSans;
          fontSize = 24;
          lineHeight = 1.8;
          paraSpacing = 20;
          break;
        case 'fokus':
          font = FontChoice.merriweather;
          margin = 32;
          lineHeight = 2.0;
          paraSpacing = 28;
          break;
        default:
          break;
      }
    });
  }

  // ================= Nilai efektif (Premium dikunci) =================

  FontChoice get effFont => isPremium ? font : FontChoice.standar;
  double get effLineHeight => isPremium ? lineHeight : 1.65;
  double get effLetterSpacing => isPremium ? letterSpacing : 0;
  double get effWordSpacing => isPremium ? wordSpacing : 0;
  double get effParaSpacing => isPremium ? paraSpacing : 14;
  double get effMargin => isPremium ? margin : 20;
  TextAlign get effAlign => (isPremium && justify) ? TextAlign.justify : TextAlign.left;
  FontWeight get weight => bold ? FontWeight.w700 : FontWeight.w400;

  static String contrastNameOf(ContrastMode m) {
    switch (m) {
      case ContrastMode.normal:
        return 'Normal';
      case ContrastMode.tinggi:
        return 'Kontras tinggi';
      case ContrastMode.hitamKuning:
        return 'Hitam-kuning';
      case ContrastMode.gelap:
        return 'Mode gelap';
    }
  }

  String get contrastLabel => contrastNameOf(contrast);

  ReadPalette get basePalette {
    switch (contrast) {
      case ContrastMode.normal:
        return const ReadPalette(
          screen: RC.lightBg,
          card: Colors.white,
          text: Color(0xFF1E2A3A),
          highlight: RC.yellow,
          highlightText: Color(0xFF1E2A3A),
          panel: Color(0xFFE3ECFA),
          panelIcon: RC.navy,
          accent: RC.blue,
          onAccent: Colors.white,
        );
      case ContrastMode.tinggi:
        return const ReadPalette(
          screen: Colors.white,
          card: Colors.white,
          text: Colors.black,
          highlight: Color(0xFFFFD400),
          highlightText: Colors.black,
          panel: Color(0xFFEDEDED),
          panelIcon: Colors.black,
          accent: Colors.black,
          onAccent: Colors.white,
        );
      case ContrastMode.hitamKuning:
        return const ReadPalette(
          screen: Colors.black,
          card: Colors.black,
          text: Color(0xFFFFEB3B),
          highlight: Color(0xFFFFEB3B),
          highlightText: Colors.black,
          panel: Color(0xFF222222),
          panelIcon: Color(0xFFFFEB3B),
          accent: Color(0xFFFFEB3B),
          onAccent: Colors.black,
        );
      case ContrastMode.gelap:
        return const ReadPalette(
          screen: Color(0xFF0E1116),
          card: Color(0xFF1A1F29),
          text: Color(0xFFEDEDED),
          highlight: Color(0xFF3B6BFF),
          highlightText: Colors.white,
          panel: Color(0xFF262C38),
          panelIcon: Colors.white,
          accent: Color(0xFF6FA0FF),
          onAccent: Colors.black,
        );
    }
  }

  /// Palet akhir: mode kontras (gratis), lalu tema warna / warna kustom bila Premium.
  ReadPalette get palette {
    final base = basePalette;
    if (!isPremium || themeIdx == 0) return base;

    if (themeIdx >= 1 && themeIdx <= presetThemes.length) {
      final t = presetThemes[themeIdx - 1];
      return base.copyWith(
        screen: t.bg,
        card: t.card,
        text: t.text,
        highlight: t.hl,
        highlightText: t.text,
      );
    }

    Color? pick(int i) => (i >= 0 && i < swatches.length) ? swatches[i].color : null;
    final bg = pick(customBg);
    final tx = pick(customText);
    final hl = pick(customHl);
    return base.copyWith(
      screen: bg,
      card: bg,
      text: tx,
      highlight: hl,
      highlightText: hl == null ? null : _onColor(hl),
    );
  }

  /// Gaya teks bacaan sesuai pengaturan (huruf, ukuran, jarak, warna).
  TextStyle readingStyle(ReadPalette pal, {double? size, FontWeight? weight}) {
    final base = TextStyle(
      fontSize: size ?? fontSize,
      height: effLineHeight,
      letterSpacing: effLetterSpacing,
      wordSpacing: effWordSpacing,
      color: pal.text,
      fontWeight: weight ?? this.weight,
    );
    switch (effFont) {
      case FontChoice.standar:
        return GoogleFonts.lato(textStyle: base);
      case FontChoice.atkinson:
        return GoogleFonts.atkinsonHyperlegible(textStyle: base);
      case FontChoice.lexend:
        return GoogleFonts.lexend(textStyle: base);
      case FontChoice.comicNeue:
        return GoogleFonts.comicNeue(textStyle: base);
      case FontChoice.merriweather:
        return GoogleFonts.merriweather(textStyle: base);
      case FontChoice.openSans:
        return GoogleFonts.openSans(textStyle: base);
    }
  }
}
