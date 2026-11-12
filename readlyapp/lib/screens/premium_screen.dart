import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../settings.dart';
import '../theme.dart';
import 'checkout_screen.dart';

class PremiumPlan {
  final String id;
  final String name;
  final String price;
  final String period;
  final String note;
  const PremiumPlan(this.id, this.name, this.price, this.period, this.note);
}

/// Contoh harga untuk prototype (belum ada penagihan sungguhan).
const List<PremiumPlan> premiumPlans = [
  PremiumPlan('bulanan', 'Bulanan', 'Rp 19.000', 'per bulan', ''),
  PremiumPlan('tahunan', 'Tahunan', 'Rp 149.000', 'per tahun', 'Hemat 35%'),
];

/// Halaman penawaran ReadLy Premium (prototype: pembayaran hanya simulasi).
class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _plan = 1;

  static const _benefits = [
    (Icons.history_rounded, 'Riwayat bacaan', 'Dokumen tersimpan dan bisa dilanjutkan dari kalimat terakhir.'),
    (Icons.description_rounded, 'Word dan PowerPoint', 'Baca file .docx dan .pptx, bukan hanya PDF dan foto.'),
    (Icons.download_rounded, 'Ekspor audio', 'Simpan hasil bacaan sebagai file suara.'),
    (Icons.palette_rounded, 'Huruf, tema, dan profil', 'Font ramah baca, warna kustom, pengaturan jarak, dan profil siap pakai.'),
  ];

  Future<void> _continue() async {
    HapticFeedback.selectionClick();
    final done = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CheckoutScreen(plan: premiumPlans[_plan])),
    );
    if (done == true && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppSettings>();
    final body = GoogleFonts.lato(fontSize: 16, height: 1.45, color: Colors.black87);

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 12, 24, 28),
              decoration: const BoxDecoration(
                color: RC.blue,
                borderRadius: BorderRadius.only(bottomRight: Radius.circular(48)),
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali',
                    iconSize: 30,
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.workspace_premium_rounded, color: RC.gold, size: 36),
                  const SizedBox(width: 10),
                  Expanded(child: Text('ReadLy Premium', style: heading(24, color: Colors.white))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (s.isPremium) ..._activeCard(s, body) else ..._offer(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _activeCard(AppSettings s, TextStyle body) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RC.gold, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: RC.gold, size: 32),
                const SizedBox(width: 10),
                Expanded(child: Text('Premium aktif', style: heading(20))),
              ],
            ),
            const SizedBox(height: 8),
            Text('Paket: ${s.plan ?? 'Uji coba'}', style: body),
            const SizedBox(height: 4),
            Text('Semua fitur Premium sudah terbuka.', style: body),
          ],
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        height: 56,
        child: OutlinedButton.icon(
          onPressed: () {
            s.setPremium(false);
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text('Langganan dihentikan (simulasi).')));
          },
          icon: const Icon(Icons.cancel_outlined),
          label: const Text('Berhenti berlangganan (simulasi)', style: TextStyle(fontSize: 16)),
        ),
      ),
    ];
  }

  List<Widget> _offer(TextStyle body) {
    return [
      Text('Yang Anda dapatkan', style: heading(21)),
      const SizedBox(height: 12),
      for (final b in _benefits)
        Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: RC.blue,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(b.$1, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.$2, style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(b.$3, style: body),
                  ],
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F6E5),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tetap gratis untuk semua orang', style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Membaca dari foto, PDF, dan teks tempel, suara, ukuran huruf, '
              '4 mode kontras, huruf tebal, dan kecepatan suara.',
              style: body,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      Text('Pilih paket', style: heading(21)),
      const SizedBox(height: 12),
      for (var i = 0; i < premiumPlans.length; i++) _planCard(i, body),
      const SizedBox(height: 6),
      Text(
        'Harga hanya contoh untuk prototype. Tidak ada pembayaran sungguhan.',
        style: GoogleFonts.lato(fontSize: 13.5, color: Colors.black54),
      ),
      const SizedBox(height: 18),
      SizedBox(
        width: double.infinity,
        height: 60,
        child: FilledButton(
          onPressed: _continue,
          style: FilledButton.styleFrom(
            backgroundColor: RC.blue,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          child: Text('Lanjut ke pembayaran', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
      ),
    ];
  }

  Widget _planCard(int i, TextStyle body) {
    final p = premiumPlans[i];
    final selected = _plan == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Paket ${p.name}, ${p.price} ${p.period}${p.note.isEmpty ? '' : ', ${p.note}'}',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _plan = i);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F0FF) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: selected ? RC.blue : Colors.black26, width: selected ? 3 : 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? RC.blue : Colors.black45,
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(p.name, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700)),
                          if (p.note.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: RC.gold,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(p.note, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('${p.price} ${p.period}', style: body),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
