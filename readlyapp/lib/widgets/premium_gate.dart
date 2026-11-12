import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../screens/premium_screen.dart';
import '../settings.dart';
import '../theme.dart';

/// Membuka halaman ReadLy Premium.
void openPremium(BuildContext context) {
  HapticFeedback.mediumImpact();
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PremiumScreen()),
  );
}

/// Lencana gembok emas untuk fitur Premium yang terkunci.
class LockBadge extends StatelessWidget {
  final double size;
  const LockBadge({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(color: RC.gold, shape: BoxShape.circle),
      child: Icon(Icons.lock_rounded, size: size * 0.6, color: Colors.black87),
    );
  }
}

/// Membungkus fitur Premium: bila belum Premium, isinya diredupkan, tidak bisa diubah,
/// dan mengetuknya membuka halaman Premium.
class PremiumGate extends StatelessWidget {
  final Widget child;
  final String feature;

  const PremiumGate({super.key, required this.child, required this.feature});

  @override
  Widget build(BuildContext context) {
    final premium = context.watch<AppSettings>().isPremium;
    if (premium) return child;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$feature. Fitur Premium, terkunci. Ketuk untuk membuka halaman Premium.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => openPremium(context),
        child: Stack(
          children: [
            Opacity(opacity: 0.5, child: IgnorePointer(child: child)),
            const Positioned(top: 8, right: 8, child: LockBadge(size: 28)),
          ],
        ),
      ),
    );
  }
}
