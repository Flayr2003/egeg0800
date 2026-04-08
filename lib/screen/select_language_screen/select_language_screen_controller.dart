import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flayr/common/controller/base_controller.dart';
import 'package:flayr/common/manager/ads_manager.dart';
import 'package:flayr/common/manager/logger.dart';
import 'package:flayr/common/manager/session_manager.dart';
import 'package:flayr/common/widget/eula_sheet.dart';
import 'package:flayr/common/widget/restart_widget.dart';
import 'package:flayr/model/general/settings_model.dart';
import 'package:flayr/screen/select_language_screen/select_language_screen.dart';

class SelectLanguageScreenController extends BaseController {
  Rx<Language?> selectedLanguage = Rx(null);
  RxList<Language> languages = <Language>[].obs;
  LanguageNavigationType languageNavigationType;

  Setting? get setting => SessionManager.instance.getSettings();
  SelectLanguageScreenController(this.languageNavigationType);

  @override
  void onInit() {
    super.onInit();
    initLanguage();
  }

  @override
  void onReady() {
    super.onReady();
    if (languageNavigationType == LanguageNavigationType.fromStart) {
      openEULASheet();
    }
    AdsManager.instance.requestConsentInfoUpdate();
  }

  Future<void> openEULASheet() async {
    if (Platform.isIOS) {
      bool shouldOpen = SessionManager.instance.shouldOpenEULASheet;

      await Future.delayed(const Duration(milliseconds: 250));
      Loggers.info('message  $shouldOpen');
      if (shouldOpen) {
        Get.bottomSheet(const EulaSheet(),
            isScrollControlled: true, enableDrag: false);
      }
    }
  }

  void initLanguage() {
    List<Language> items =
        SessionManager.instance.getSettings()?.languages ?? [];
    
    // Sort languages to keep order consistent
    items.sort((a, b) => (a.title ?? '').compareTo(b.title ?? ''));
    
    languages.clear();
    for (Language element in items) {
      if (element.status == 1) {
        languages.add(element);
      }
    }
    
    // Safely find selected language
    String currentLang = SessionManager.instance.getLang();
    selectedLanguage.value = languages.firstWhereOrNull((element) {
      return element.code == currentLang;
    });
  }

  void onLanguageChange(Language? value) {
    if (value == null) return;
    
    selectedLanguage.value = value;
    String langCode = value.code ?? 'en';
    
    // 1. Save language to local storage
    SessionManager.instance.setLang(langCode);
    
    // 2. Update GetX Locale immediately to prevent mixed language UI
    Get.updateLocale(Locale(langCode));
    
    Loggers.info('Language changed to: $langCode');

    // 3. Restart app to ensure all controllers and translations are reloaded from CSV
    // We use a small delay to allow the storage to persist properly
    Future.delayed(const Duration(milliseconds: 100), () {
      RestartWidget.restartApp(Get.context!);
    });
  }
}
