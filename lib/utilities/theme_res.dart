import 'package:flutter/material.dart';
import 'package:flayr/utilities/color_res.dart';
import 'package:flayr/utilities/font_res.dart';

class ThemeRes {
  static ThemeData lightTheme(BuildContext context) {
    // Light theme redirects to dark for all-black experience
    return darkTheme(context);
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: ColorRes.blackPure,
      appBarTheme: const AppBarTheme(backgroundColor: ColorRes.blackPure),
      fontFamily: FontRes.outFitRegular400,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: ColorRes.blackPure,
      ),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Color(0xFF0D0D0D)),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: ColorRes.whitePure),
        titleMedium: TextStyle(color: ColorRes.whitePure),
        titleSmall: TextStyle(color: Color(0xFFC8CCD1)),
        labelSmall: TextStyle(color: ColorRes.whitePure),
        labelLarge: TextStyle(color: Color(0xFFB5BAC3)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: Color(0xFF2A2A2A),
      ),
      cardTheme: const CardThemeData(color: Color(0xFF141414)),
      primaryColor: ColorRes.blackPure,
      dividerColor: const Color(0xFF1A1A1A),
      cardColor: const Color(0xFF0A0A0A),
      primaryColorDark: ColorRes.blackPure,
      canvasColor: ColorRes.blackPure,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
    );
  }
}

Color whitePure(BuildContext context) {
  return Theme.of(context).textTheme.titleLarge?.color ?? ColorRes.whitePure;
}

Color textDarkGrey(BuildContext context) {
  return Theme.of(context).textTheme.titleMedium?.color ??
      ColorRes.textDarkGrey;
}

Color textLightGrey(BuildContext context) {
  return Theme.of(context).textTheme.titleSmall?.color ??
      ColorRes.textLightGrey;
}

Color bgGrey(BuildContext context) {
  return Theme.of(context).dividerColor;
}

Color themeAccentSolid(BuildContext context) {
  return ColorRes.blueFollow;
}

Color disableGrey(BuildContext context) {
  return Theme.of(context).textTheme.labelLarge?.color ?? ColorRes.disabledGrey;
}

Color scaffoldBackgroundColor(BuildContext context) {
  return Theme.of(context).scaffoldBackgroundColor;
}

Color blueFollow(BuildContext context) {
  return Theme.of(context).cardTheme.color ?? ColorRes.blueFollow;
}

Color bgMediumGrey(BuildContext context) {
  return Theme.of(context).cardColor;
}

Color blackPure(BuildContext context) {
  return Theme.of(context).primaryColorDark;
}

Color bgLightGrey(BuildContext context) {
  return const Color(0xFF141414);
}

Color themeColor(BuildContext context) {
  return Theme.of(context).canvasColor;
}
