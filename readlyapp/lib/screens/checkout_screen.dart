import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../settings.dart';
import '../theme.dart';
import 'premium_screen.dart';

/// Halaman pembayaran SIMULASI. Tidak ada transaksi nyata; tombol bayar langsung
/// mengaktifkan Premium setelah jeda singkat.
class CheckoutScreen extends StatefulWidget {
  final PremiumPlan plan;
  const CheckoutScreen({super.key, required this.plan});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  static const _methods = [
    (Icons.account_balance_wallet_rounded, 'Dompet digital'),
    (Icons.account_balance_rounded, 'Transfer bank'),
    (Icons.qr_code_2_rounded, 'QRIS'),
    (Icons.credit_card_rounded, 'Kartu debit / kredit'),
  ];

  int _method = 0;
  bool _paying = false;

  Future<void> _pay() async {
    if (_paying) return;
    HapticFeedback.mediumImpact();
    setState(() => _paying = true);

    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    context.read<AppSettings>().setPremium(true, plan: widget.plan.name);
    setState(() => _paying = false);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E9E4F), size: 56),
        title: const Text('Pembayaran berhasil (simulasi)'),
        content: const Text(
          'ReadLy Premium sudah aktif. Tidak ada uang yang dipindahkan karena ini hanya prototype.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Selesai', style: TextStyle(fontSize: 17)),
            ),
          ),
        ],
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    return Scaffold(
      appBar: AppBar(
        title: Text('Pembayaran', style: heading(20)),
        backgroundColor: RC.lightBg,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Kembali',
          iconSize: 30,
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _paying ? null : () => Navigator.of(context).pop(false),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3CD),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF7A5B00)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'SIMULASI: tidak ada pembayaran sungguhan.',
                    style: GoogleFonts.lato(fontSize: 15.5, fontWeight: FontWeight.w700, color: const Color(0xFF5C4400)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Ringkasan pesanan', style: heading(19)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: RC.gold, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ReadLy Premium, ${p.name}',
                          style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w700)),
                      Text(p.period, style: GoogleFonts.lato(fontSize: 15, color: Colors.black54)),
                    ],
                  ),
                ),
                Text(p.price, style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Metode pembayaran', style: heading(19)),
          const SizedBox(height: 10),
          for (var i = 0; i < _methods.length; i++) _methodTile(i),
          const SizedBox(height: 22),
          SizedBox(
            height: 62,
            child: FilledButton(
              onPressed: _paying ? null : _pay,
              style: FilledButton.styleFrom(
                backgroundColor: RC.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              child: _paying
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : Text('Bayar ${p.price} (simulasi)',
                      style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _methodTile(int i) {
    final m = _methods[i];
    final selected = _method == i;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Semantics(
        button: true,
        selected: selected,
        label: 'Metode ${m.$2}${selected ? ', dipilih' : ''}',
        excludeSemantics: true,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _paying
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  setState(() => _method = i);
                },
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFE8F0FF) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? RC.blue : Colors.black26, width: selected ? 3 : 1.5),
            ),
            child: Row(
              children: [
                Icon(m.$1, size: 30, color: RC.navy),
                const SizedBox(width: 14),
                Expanded(child: Text(m.$2, style: GoogleFonts.lato(fontSize: 17, fontWeight: FontWeight.w600))),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? RC.blue : Colors.black45,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
