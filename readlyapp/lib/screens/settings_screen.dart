import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../settings.dart';
import '../theme.dart';
import '../widgets/premium_gate.dart';
import 'about_screen.dart';
import 'premium_screen.dart';

/// Pengaturan: bagian dasar (gratis, penting untuk low vision) dan personalisasi (Premium),
/// ditambah saklar uji coba Premium untuk prototype.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengaturan', style: heading(20)),
        backgroundColor: RC.lightBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Kembali',
          iconSize: 30,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          _Preview(s: s),
          const SizedBox(height: 22),
          const _Title('Dasar', note: 'Gratis untuk semua pengguna'),
          _basicCard(context, s),
          const SizedBox(height: 22),
          const _Title('Personalisasi', premium: true),
          PremiumGate(feature: 'Personalisasi tampilan', child: _premiumCard(s)),
          const SizedBox(height: 22),
          const _Title('Akun'),
          _accountCard(context, s),
          const SizedBox(height: 22),
          _testCard(s),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                s.resetAll();
              },
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Atur ulang tampilan', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('Tentang ReadLy', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Dasar (gratis) ----------------

  Widget _basicCard(BuildContext context, AppSettings s) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Ukuran huruf: ${s.fontSize.round()}'),
          Row(
            children: [
              _RoundButton(icon: Icons.remove_rounded, tooltip: 'Perkecil huruf', onTap: s.decreaseFont),
              Expanded(
                child: Slider(
                  value: s.fontSize,
                  min: AppSettings.minFont,
                  max: AppSettings.maxFont,
                  divisions: 25,
                  label: '${s.fontSize.round()}',
                  onChanged: (v) => s.change(() => s.fontSize = v, save: false),
                  onChangeEnd: (_) => s.change(() {}),
                ),
              ),
              _RoundButton(icon: Icons.add_rounded, tooltip: 'Perbesar huruf', onTap: s.increaseFont),
            ],
          ),
          const SizedBox(height: 10),
          const _Label('Kontras'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final m in ContrastMode.values)
                ChoiceChip(
                  label: Text(AppSettings.contrastNameOf(m), style: const TextStyle(fontSize: 16)),
                  selected: s.contrast == m,
                  onSelected: (_) => s.change(() => s.contrast = m),
                ),
            ],
          ),
          const SizedBox(height: 6),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Huruf tebal', style: TextStyle(fontSize: 17)),
            value: s.bold,
            onChanged: (v) => s.change(() => s.bold = v),
          ),
          const _Label('Kecepatan suara'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final r in AppSettings.rates)
                ChoiceChip(
                  label: Text('${r}x', style: const TextStyle(fontSize: 16)),
                  selected: s.rate == r,
                  onSelected: (_) => s.change(() => s.rate = r),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- Personalisasi (Premium) ----------------

  Widget _premiumCard(AppSettings s) {
    final custom = s.themeIdx == AppSettings.customThemeIdx;
    ProfileInfo? info;
    for (final p in readProfiles) {
      if (p.key == s.profile) info = p;
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Profil siap pakai'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final p in readProfiles)
                ChoiceChip(
                  label: Text(p.name, style: const TextStyle(fontSize: 16)),
                  selected: s.profile == p.key,
                  onSelected: (_) => s.applyProfile(p.key),
                ),
            ],
          ),
          if (info != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(info.desc, style: GoogleFonts.lato(fontSize: 14.5, color: Colors.black54)),
            ),
          const SizedBox(height: 16),
          const _Label('Jenis huruf'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final f in FontChoice.values)
                ChoiceChip(
                  label: Text(fontLabels[f]!, style: const TextStyle(fontSize: 16)),
                  selected: s.font == f,
                  onSelected: (_) => s.change(() => s.font = f),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Huruf diunduh sekali saat pertama dipakai (butuh internet). Tanpa internet, huruf bawaan dipakai.',
            style: GoogleFonts.lato(fontSize: 13.5, color: Colors.black54),
          ),
          const SizedBox(height: 16),
          const _Label('Tema warna'),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ChoiceChip(
                label: const Text('Ikuti kontras', style: TextStyle(fontSize: 16)),
                selected: s.themeIdx == 0,
                onSelected: (_) => s.change(() => s.themeIdx = 0),
              ),
              for (var i = 0; i < presetThemes.length; i++)
                ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: presetThemes[i].card, radius: 10),
                  label: Text(presetThemes[i].name, style: const TextStyle(fontSize: 16)),
                  selected: s.themeIdx == i + 1,
                  onSelected: (_) => s.change(() => s.themeIdx = i + 1),
                ),
              ChoiceChip(
                avatar: const Icon(Icons.palette_rounded, size: 20),
                label: const Text('Kustom', style: TextStyle(fontSize: 16)),
                selected: custom,
                onSelected: (_) => s.change(() => s.themeIdx = AppSettings.customThemeIdx),
              ),
            ],
          ),
          if (custom) ...[
            const SizedBox(height: 12),
            _SwatchRow(
              title: 'Warna huruf',
              selected: s.customText,
              onPick: (i) => s.change(() => s.customText = i),
            ),
            const SizedBox(height: 10),
            _SwatchRow(
              title: 'Warna latar',
              selected: s.customBg,
              onPick: (i) => s.change(() => s.customBg = i),
            ),
            const SizedBox(height: 10),
            _SwatchRow(
              title: 'Warna sorotan kalimat',
              selected: s.customHl,
              onPick: (i) => s.change(() => s.customHl = i),
            ),
          ],
          const SizedBox(height: 16),
          _SliderRow(
            label: 'Jarak baris',
            value: s.lineHeight,
            min: 1.2,
            max: 2.6,
            divisions: 14,
            text: s.lineHeight.toStringAsFixed(1),
            onChanged: (v) => s.change(() => s.lineHeight = v, save: false),
            onEnd: () => s.change(() {}),
          ),
          _SliderRow(
            label: 'Jarak huruf',
            value: s.letterSpacing,
            min: 0,
            max: 4,
            divisions: 16,
            text: s.letterSpacing.toStringAsFixed(1),
            onChanged: (v) => s.change(() => s.letterSpacing = v, save: false),
            onEnd: () => s.change(() {}),
          ),
          _SliderRow(
            label: 'Jarak kata',
            value: s.wordSpacing,
            min: 0,
            max: 12,
            divisions: 12,
            text: s.wordSpacing.round().toString(),
            onChanged: (v) => s.change(() => s.wordSpacing = v, save: false),
            onEnd: () => s.change(() {}),
          ),
          _SliderRow(
            label: 'Jarak antar paragraf',
            value: s.paraSpacing,
            min: 6,
            max: 48,
            divisions: 21,
            text: s.paraSpacing.round().toString(),
            onChanged: (v) => s.change(() => s.paraSpacing = v, save: false),
            onEnd: () => s.change(() {}),
          ),
          _SliderRow(
            label: 'Margin kiri-kanan',
            value: s.margin,
            min: 8,
            max: 48,
            divisions: 20,
            text: s.margin.round().toString(),
            onChanged: (v) => s.change(() => s.margin = v, save: false),
            onEnd: () => s.change(() {}),
          ),
          const SizedBox(height: 6),
          const _Label('Perataan teks'),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Rata kiri')),
                ButtonSegment(value: true, label: Text('Kiri-kanan')),
              ],
              selected: {s.justify},
              onSelectionChanged: (v) => s.change(() => s.justify = v.first),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Akun dan uji coba ----------------

  Widget _accountCard(BuildContext context, AppSettings s) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                s.isPremium ? Icons.verified_rounded : Icons.workspace_premium_rounded,
                color: RC.gold,
                size: 34,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.isPremium ? 'Premium aktif (${s.plan ?? 'Uji coba'})' : 'Paket Gratis',
                  style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PremiumScreen()),
              ),
              style: FilledButton.styleFrom(backgroundColor: RC.blue),
              child: Text(
                s.isPremium ? 'Kelola langganan' : 'Lihat ReadLy Premium',
                style: const TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _testCard(AppSettings s) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3CD),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text(
          'Mode uji: anggap sudah Premium',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        subtitle: const Text(
          'Hanya untuk pengujian prototype. Akan dihapus pada versi final.',
          style: TextStyle(fontSize: 14),
        ),
        value: s.isPremium,
        onChanged: (v) => s.setPremium(v, plan: v ? 'Uji coba' : null),
      ),
    );
  }
}

// ======================= Komponen kecil =======================

class _Title extends StatelessWidget {
  final String text;
  final String? note;
  final bool premium;
  const _Title(this.text, {this.note, this.premium = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(text, style: heading(20)),
          if (premium) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: RC.gold, borderRadius: BorderRadius.circular(12)),
              child: const Text('PREMIUM', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
            ),
          ],
          if (note != null) ...[
            const SizedBox(width: 10),
            Flexible(
              child: Text(note!, style: GoogleFonts.lato(fontSize: 13.5, color: Colors.black54)),
            ),
          ],
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: GoogleFonts.lato(fontSize: 16.5, fontWeight: FontWeight.w700)),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _RoundButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: RC.blue,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(width: 52, height: 52, child: Icon(icon, color: Colors.white, size: 30)),
        ),
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String text;
  final ValueChanged<double> onChanged;
  final VoidCallback onEnd;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.text,
    required this.onChanged,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('$label: $text'),
        Slider(
          value: value.clamp(min, max).toDouble(),
          min: min,
          max: max,
          divisions: divisions,
          label: text,
          onChanged: onChanged,
          onChangeEnd: (_) => onEnd(),
        ),
      ],
    );
  }
}

class _SwatchRow extends StatelessWidget {
  final String title;
  final int selected;
  final ValueChanged<int> onPick;
  const _SwatchRow({required this.title, required this.selected, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _Label(title)),
            TextButton(
              onPressed: () => onPick(-1),
              child: const Text('Bawaan', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < swatches.length; i++)
              Semantics(
                button: true,
                selected: selected == i,
                label: '${swatches[i].name}${selected == i ? ', dipilih' : ''}',
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onPick(i);
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: swatches[i].color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected == i ? RC.blue : Colors.black38,
                        width: selected == i ? 4 : 1.5,
                      ),
                    ),
                    child: selected == i
                        ? Icon(
                            Icons.check_rounded,
                            color: swatches[i].color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                          )
                        : null,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Pratinjau langsung teks bacaan sesuai pengaturan, dengan peringatan kontras rendah.
class _Preview extends StatelessWidget {
  final AppSettings s;
  const _Preview({required this.s});

  @override
  Widget build(BuildContext context) {
    final pal = s.palette;
    final style = s.readingStyle(pal);
    final m = s.effMargin.clamp(8.0, 32.0).toDouble();
    final ratio = contrastRatio(pal.text, pal.card);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: 'Pratinjau teks bacaan',
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: m, vertical: 18),
            decoration: BoxDecoration(
              color: pal.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: pal.panel, width: 2),
            ),
            child: Text.rich(
              TextSpan(
                style: style,
                children: [
                  const TextSpan(text: 'Contoh teks bacaan. '),
                  TextSpan(
                    text: 'Kalimat ini sedang dibacakan. ',
                    style: TextStyle(backgroundColor: pal.highlight, color: pal.highlightText),
                  ),
                  const TextSpan(text: 'ReadLy membantu Anda membaca dengan nyaman.'),
                ],
              ),
              textAlign: s.effAlign,
            ),
          ),
        ),
        if (ratio < 4.5)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Color(0xFFB26A00)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Kontras warna rendah, teks bisa sulit dibaca. Coba warna huruf dan latar yang lebih berbeda.',
                    style: GoogleFonts.lato(fontSize: 14.5, color: const Color(0xFF8A5300)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
