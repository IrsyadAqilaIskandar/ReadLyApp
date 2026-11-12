import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Warna ReadLy, diambil dari dokumen PDF.
class RC {
  static const blue = Color(0xFF4F80FF); // header biru
  static const sky = Color(0xFF3DBDEB); // lingkaran cover
  static const paleBlue = Color(0xFFB0D4EC); // blob dekoratif
  static const lightBg = Color(0xFFF5FBFF);
  static const navy = Color(0xFF1B3A6B);
  static const bookBlue = Color(0xFF1A73C0); // ikon buku di logo
  static const green = Color(0xFF8DC63F);
  static const yellow = Color(0xFFFFE97A); // highlight
  static const gold = Color(0xFFF5B301); // penanda Premium
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: RC.blue, primary: RC.blue),
    scaffoldBackgroundColor: RC.lightBg,
  );
  return base.copyWith(textTheme: GoogleFonts.latoTextTheme(base.textTheme));
}

/// Gaya judul (slab serif seperti judul di PDF).
TextStyle heading(double size, {Color color = Colors.black}) =>
    GoogleFonts.arvo(fontSize: size, fontWeight: FontWeight.bold, color: color);
