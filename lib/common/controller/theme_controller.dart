import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flayr/common/manager/session_manager.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  String localizedTitle(String languageCode) {
    final isArabic = languageCode == 'ar';
    switch (this) {
      case AppThemePreference.system:
        return isArabic ? 'تلقائي' : 'System';
      case AppThemePreference.light:
        return isArabic ? 'نهاري' : 'Light';
      case AppThemePreference.dark:
        return isArabic ? 'ليلي' : 'Dark';
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemePreference.system:
        return ThemeMode.system;
      case AppThemePreference.light:
        return ThemeMode.light;
      case AppThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  static AppThemePreference fromValue(String? value) {
    switch (value) {
      case 'light':
        return AppThemePreference.light;
      case 'dark':
        return AppThemePreference.dark;
      default:
        return AppThemePreference.system;
    }
  }

  String get value {
    switch (this) {
      case AppThemePreference.system:
        return 'system';
      case AppThemePreference.light:
        return 'light';
      case AppThemePreference.dark:
        return 'dark';
    }
  }
}

class ThemeController extends GetxController {
  final Rx<AppThemePreference> selectedPreference =
      AppThemePreference.system.obs;

  Rx<ThemeMode> themeMode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    final preference =
        AppThemePreference.fromValue(SessionManager.instance.getThemeMode());
    _apply(preference, persist: false);
  }

  void updatePreference(AppThemePreference preference) {
    _apply(preference, persist: true);
  }

  void _apply(AppThemePreference preference, {required bool persist}) {
    selectedPreference.value = preference;
    themeMode.value = preference.themeMode;
    if (persist) {
      SessionManager.instance.setThemeMode(preference.value);
    }
  }
}
