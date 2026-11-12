import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

/// Logo "ReadLy": ikon buku biru + tulisan tebal hitam.
class ReadLyLogo extends StatelessWidget {
  final double size;
  final Color color;
  final bool showRays;

  const ReadLyLogo({
    super.key,
    this.size = 44,
    this.color = Colors.black,
    this.showRays = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.menu_book_rounded, color: RC.bookBlue, size: size * 1.15),
        SizedBox(width: size * 0.18),
        Text(
          'ReadLy',
          style: GoogleFonts.poppins(
            fontSize: size,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1.1,
          ),
        ),
      ],
    );

    if (!showRays) return row;

    // Garis-garis kuning kecil di pojok kanan atas, seperti di cover PDF.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(padding: EdgeInsets.only(right: size * 0.5, top: size * 0.3), child: row),
        Positioned(
          right: 0,
          top: 0,
          child: CustomPaint(
            size: Size(size * 0.8, size * 0.8),
            painter: _RaysPainter(),
          ),
        ),
      ],
    );
  }
}

class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD84D)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final origin = Offset(size.width * 0.15, size.height * 0.95);
    final angles = [-80.0, -55.0, -30.0, -5.0];
    for (final deg in angles) {
      final a = deg * math.pi / 180;
      final from = origin + Offset(math.cos(a), math.sin(a)) * (size.width * 0.35);
      final to = origin + Offset(math.cos(a), math.sin(a)) * (size.width * 0.8);
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
