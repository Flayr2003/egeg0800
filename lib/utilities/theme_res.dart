import 'package:flutter/material.dart';
import 'package:flayr/utilities/color_res.dart';
import 'package:flayr/utilities/font_res.dart';

class ThemeRes {
  static ThemeData lightTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ColorRes.whitePure,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: ColorRes.whitePure,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: ColorRes.bgLightGrey),
      fontFamily: FontRes.outFitRegular400,
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: ColorRes.whitePure),
      sliderTheme: const SliderThemeData(
        trackHeight: 2.5,
        trackShape: RectangularSliderTrackShape(),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
        overlayColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: ColorRes.whitePure),
        titleMedium: TextStyle(color: ColorRes.textDarkGrey),
        titleSmall: TextStyle(color: ColorRes.textLightGrey),
        labelSmall: TextStyle(color: ColorRes.blackPure),
        labelLarge: TextStyle(color: ColorRes.disabledGrey),
      ),
      textSelectionTheme:
          const TextSelectionThemeData(selectionColor: ColorRes.disabledGrey),
      cardTheme: const CardThemeData(color: ColorRes.blueFollow),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      primaryColor: ColorRes.themeAccentSolid,
      dividerColor: ColorRes.bgGrey,
      cardColor: ColorRes.bgMediumGrey,
      primaryColorDark: ColorRes.blackPure,
      canvasColor: ColorRes.whitePure,
    );
  }

  static ThemeData darkTheme(BuildContext context) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: ColorRes.themeColor,
      appBarTheme: const AppBarTheme(backgroundColor: ColorRes.blackPure),
      fontFamily: FontRes.outFitRegular400,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: ColorRes.blackPure,
      ),
      bottomSheetTheme:
          const BottomSheetThemeData(backgroundColor: Color(0xFF1B1C20)),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: ColorRes.whitePure),
        titleMedium: TextStyle(color: ColorRes.whitePure),
        titleSmall: TextStyle(color: Color(0xFFC8CCD1)),
        labelSmall: TextStyle(color: ColorRes.whitePure),
        labelLarge: TextStyle(color: Color(0xFFB5BAC3)),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        selectionColor: Color(0xFF3A3A3A),
      ),
      cardTheme: const CardThemeData(color: Color(0xFF24262B)),
      primaryColor: ColorRes.themeAccentSolid,
      dividerColor: const Color(0xFF2B2D33),
      cardColor: const Color(0xFF1F2126),
      primaryColorDark: ColorRes.blackPure,
      canvasColor: ColorRes.themeColor,
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
  return Theme.of(context).textTheme.labelSmall?.color ??
      ColorRes.themeAccentSolid;
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
  return Theme.of(context).appBarTheme.backgroundColor ?? ColorRes.bgLightGrey;
}

Color themeColor(BuildContext context) {
  return Theme.of(context).canvasColor;
}
