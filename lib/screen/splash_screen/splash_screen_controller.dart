import 'dart:async';
import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:flayr/common/controller/base_controller.dart';
import 'package:flayr/common/extensions/string_extension.dart';
import 'package:flayr/common/manager/logger.dart';
import 'package:flayr/common/manager/session_manager.dart';
import 'package:flayr/common/service/api/common_service.dart';
import 'package:flayr/common/service/auth/firebase_user_sync_service.dart';
import 'package:flayr/common/service/api/user_service.dart';
import 'package:flayr/common/service/network_helper/network_helper.dart';
import 'package:flayr/common/widget/no_internet_sheet.dart';
import 'package:flayr/languages/dynamic_translations.dart';
import 'package:flayr/model/general/settings_model.dart';
import 'package:flayr/screen/auth_screen/login_screen.dart';
import 'package:flayr/screen/dashboard_screen/dashboard_screen.dart';
import 'package:flayr/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:flayr/screen/select_language_screen/select_language_screen.dart';

class SplashScreenController extends BaseController {
  StreamSubscription<bool>? _subscription;
  bool isOnline = true;
  bool _navigated = false;

  // DIAGNOSTIC: Show on UI so user can see where app is stuck
  final RxString debugStatus = 'Starting...'.obs;
  final RxInt secondsElapsed = 0.obs;

  // HARD SAFETY NET: 20 seconds max on splash
  static const Duration _hardMaxSplashTime = Duration(seconds: 20);

  @override
  void onReady() {
    super.onReady();
    _updateStatus('onReady() fired');

    // Tick counter so user knows app is alive
    Timer.periodic(const Duration(seconds: 1), (t) {
      if (_navigated) {
        t.cancel();
        return;
      }
      secondsElapsed.value++;
    });

    // Start main flow
    fetchSettings();

    // Watchdog: force-navigate after hard timeout
    Future.delayed(_hardMaxSplashTime, () {
      if (!_navigated) {
        _updateStatus('Watchdog fired - forcing navigation');
        Loggers.warning('Splash watchdog fired');
        _navigateToNext();
      }
    });

    try {
      _subscription = NetworkHelper().onConnectionChange.listen((status) {
        isOnline = status;
        if (isOnline) {
          if (Get.currentRoute == '/NoInternetSheet') {
            Get.back();
          }
        } else {
          if (_navigated) {
            Get.to(() => const NoInternetSheet(),
                transition: Transition.downToUp);
          }
        }
      });
    } catch (e) {
      Loggers.error('Network listener error: $e');
    }
  }

  @override
  void onClose() {
    super.onClose();
    _subscription?.cancel();
  }

  void _updateStatus(String msg) {
    debugStatus.value = msg;
    Loggers.info('[SPLASH] $msg');
  }

  Future<void> fetchSettings() async {
    _updateStatus('Waiting 2s branding...');
    await Future.delayed(const Duration(milliseconds: 2000));

    _updateStatus('Calling fetchGlobalSettings...');
    try {
      bool success = await CommonService.instance
          .fetchGlobalSettings()
          .timeout(const Duration(seconds: 8), onTimeout: () {
        _updateStatus('fetchGlobalSettings TIMEOUT');
        return false;
      });

      _updateStatus('Settings success=$success');

      if (success) {
        final translations = Get.find<DynamicTranslations>();
        var setting = SessionManager.instance.getSettings();
        var languages = setting?.languages ?? [];

        List<Language> downloadLanguages =
            languages.where((element) => element.status == 1).toList();

        if (downloadLanguages.isNotEmpty) {
          _updateStatus('Downloading ${downloadLanguages.length} languages...');
          try {
            var downloadedFiles = await downloadAndParseLanguages(downloadLanguages)
                .timeout(const Duration(seconds: 5), onTimeout: () {
              _updateStatus('Language download TIMEOUT');
              return {};
            });
            if (downloadedFiles.isNotEmpty) {
              translations.addTranslations(downloadedFiles);
            }
            _updateStatus('Languages loaded: ${downloadedFiles.keys.join(",")}');
          } catch (e) {
            _updateStatus('Language error: $e');
            Loggers.error('Language download failed: $e');
          }
        }

        var defaultLang = languages
            .firstWhereOrNull((element) => element.isDefault == 1);
        if (defaultLang != null) {
          SessionManager.instance.setFallbackLang(defaultLang.code ?? 'en');
        }
      }
    } catch (e) {
      _updateStatus('Settings error: ${e.toString().substring(0, 50)}');
      Loggers.error('Settings fetch error: $e');
    }

    _updateStatus('Navigating to next screen...');
    _navigateToNext();
  }

  void _navigateToNext() {
    if (_navigated) return;
    _navigated = true;

    try {
      var setting = SessionManager.instance.getSettings();

      if (SessionManager.instance.isLogin()) {
        _updateStatus('User logged in, fetching details...');
        UserService.instance
            .fetchUserDetails(userId: SessionManager.instance.getUserID())
            .timeout(const Duration(seconds: 8), onTimeout: () => null)
            .then((value) async {
          try {
            if (value != null) {
              final syncedUser =
                  FirebaseUserSyncService.enrichUserWithFirebaseData(
                appUser: value,
                persistInSession: true,
              );
              Get.off(() => DashboardScreen(myUser: syncedUser ?? value));
            } else {
              Get.off(() => const LoginScreen());
            }
          } catch (e) {
            Loggers.error('Navigation after user fetch failed: $e');
            Get.off(() => const LoginScreen());
          }
        }).catchError((e) {
          Loggers.error('User fetch error: $e');
          Get.off(() => const LoginScreen());
        });
      } else {
        bool isLanguageSelect = SessionManager.instance
            .getBool(SessionKeys.isLanguageScreenSelect);
        bool onBoardingShow = SessionManager.instance
            .getBool(SessionKeys.isOnBoardingScreenSelect);

        _updateStatus('langSelect=$isLanguageSelect onBoard=$onBoardingShow');

        if (isLanguageSelect == false) {
          Get.off(() => const SelectLanguageScreen(
              languageNavigationType: LanguageNavigationType.fromStart));
        } else if (onBoardingShow == false &&
            (setting?.onBoarding ?? []).isNotEmpty) {
          Get.off(() => const OnBoardingScreen());
        } else {
          Get.off(() => const LoginScreen());
        }
      }
    } catch (e, st) {
      _updateStatus('Nav fatal: $e');
      Loggers.error('_navigateToNext fatal: $e\n$st');
      try {
        Get.off(() => const LoginScreen());
      } catch (_) {}
    }
  }

  Future<Map<String, Map<String, String>>> downloadAndParseLanguages(
      List<Language> languages) async {
    final languageData = <String, Map<String, String>>{};

    for (final language in languages) {
      if ((language.code ?? '').isEmpty ||
          (language.csvFile ?? '').isEmpty) {
        continue;
      }
      await downloadAndProcessLanguage(language, languageData);
    }

    return languageData;
  }

  Future<void> downloadAndProcessLanguage(
      Language language, Map<String, Map<String, String>> languageData) async {
    try {
      final response = await http
          .get(Uri.parse(language.csvFile?.addBaseURL() ?? ''))
          .timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final csvContent = utf8.decode(response.bodyBytes);
        final parsedMap = _parseCsvToMap(csvContent);
        languageData[language.code!] = parsedMap;
        Loggers.info('Downloaded and parsed: ${language.code}');
      }
    } catch (e) {
      Loggers.error('Error downloading ${language.code}: $e');
    }
  }

  Map<String, String> _parseCsvToMap(String csvContent) {
    try {
      final rows = const CsvToListConverter().convert(csvContent);
      final map = <String, String>{};

      for (final row in rows) {
        if (row.length < 2) continue;
        final key = row[0].toString().trim();
        final value = row[1].toString().trim();
        if (key.isEmpty || value.isEmpty) continue;
        if (key.toLowerCase() == 'key' && value.toLowerCase() == 'value') {
          continue;
        }
        map[key] = value;
      }
      return map;
    } catch (e) {
      Loggers.error('CSV parse error: $e');
      return <String, String>{};
    }
  }
}
