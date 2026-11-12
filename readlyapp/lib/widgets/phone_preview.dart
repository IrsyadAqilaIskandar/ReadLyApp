import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme.dart';

/// Ilustrasi ponsel ReadLy (mirip gambar di cover PDF), digambar dengan widget Flutter.
class PhonePreview extends StatelessWidget {
  const PhonePreview({super.key});

  static const _shadow = [
    BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 4)),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      height: 270,
      child: Stack(
        children: [
          Positioned(left: 60, top: 0, child: _phone()),
          Positioned(
            left: 10,
            top: 36,
            child: _bubble(const Icon(Icons.image_rounded, color: RC.blue, size: 22)),
          ),
          Positioned(
            left: 14,
            top: 112,
            child: _bubble(const Icon(Icons.visibility_rounded, color: Color(0xFF2E5AAC), size: 22)),
          ),
          Positioned(
            left: 22,
            top: 184,
            child: _bubble(
              const Icon(Icons.psychology_rounded, color: Color(0xFF8E5BD9), size: 22),
              tint: const Color(0xFFEDE3FB),
            ),
          ),
          Positioned(
            right: 8,
            top: 16,
            child: _bubble(
              const Icon(Icons.volume_up_rounded, color: Colors.white, size: 20),
              tint: RC.blue,
            ),
          ),
          Positioned(right: 0, top: 118, child: _textBubble()),
        ],
      ),
    );
  }

  Widget _phone() {
    return Container(
      width: 130,
      height: 262,
      padding: const EdgeInsets.fromLTRB(7, 14, 7, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FD),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF263042), width: 5),
        boxShadow: _shadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 11, color: RC.bookBlue),
              const SizedBox(width: 3),
              Text(
                'ReadLy',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: RC.navy,
                ),
              ),
              const Spacer(),
              const Icon(Icons.menu, size: 11, color: RC.navy),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _line(1),
                        _line(.8),
                        _line(1),
                        _line(.9, hl: true),
                        _line(1),
                        _line(.7),
                        _line(1),
                        _line(.85),
                        _line(.6),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  width: 20,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3ECFA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    children: [
                      Text('A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RC.navy)),
                      SizedBox(height: 6),
                      Text('A', style: TextStyle(fontSize: 8, color: RC.navy)),
                      SizedBox(height: 6),
                      Icon(Icons.contrast, size: 10, color: RC.navy),
                      SizedBox(height: 6),
                      Icon(Icons.wb_sunny_outlined, size: 10, color: RC.navy),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_left, size: 16, color: RC.blue),
                const SizedBox(width: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: RC.navy, shape: BoxShape.circle),
                  child: const Icon(Icons.pause, size: 12, color: Colors.white),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_right, size: 16, color: RC.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(double factor, {bool hl = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: FractionallySizedBox(
        widthFactor: factor,
        alignment: Alignment.centerLeft,
        child: Container(
          height: 4,
          decoration: BoxDecoration(
            color: hl ? RC.yellow : const Color(0xFFC9D6E8),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Widget _bubble(Widget icon, {Color tint = Colors.white}) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _shadow,
      ),
      child: Center(child: icon),
    );
  }

  Widget _textBubble() {
    return Container(
      width: 64,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _shadow,
      ),
      child: Column(
        children: [
          _line(1),
          _line(.7, hl: true),
          _line(1),
          _line(.8),
        ],
      ),
    );
  }
}
