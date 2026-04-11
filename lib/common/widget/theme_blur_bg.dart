import 'package:flutter/material.dart';
import 'package:flayr/utilities/color_res.dart';

class ThemeBlurBg extends StatelessWidget {
  const ThemeBlurBg({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF111216),
            Color(0xFF1A1D24),
            Color(0xFF0B0C10),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: ColorRes.blackPure.withValues(alpha: .18),
        ),
      ),
    );
  }
}
