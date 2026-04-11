import 'package:flutter/material.dart';

class ThemeBlurBg extends StatelessWidget {
  const ThemeBlurBg({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: double.infinity,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [
                  Color(0xFF000000),
                  Color(0xFF101010),
                  Color(0xFF000000),
                ]
              : const [
                  Color(0xFFFFFFFF),
                  Color(0xFFF4F5F7),
                  Color(0xFFEDEFF3),
                ],
        ),
      ),
    );
  }
}
