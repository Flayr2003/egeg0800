import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flayr/common/manager/firebase_notification_manager.dart';
import 'package:flayr/common/controller/theme_controller.dart';
import 'package:flayr/common/manager/logger.dart';
import 'package:flayr/common/manager/session_manager.dart';
import 'package:flayr/common/service/auth/firebase_user_sync_service.dart';
import 'package:flayr/common/service/subscription/subscription_manager.dart';
import 'package:flayr/common/widget/restart_widget.dart';
import 'package:flayr/languages/dynamic_translations.dart';
import 'package:flayr/screen/splash_screen/splash_screen.dart';
import 'package:flayr/utilities/theme_res.dart';

import 'common/service/network_helper/network_helper.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Loggers.success("Handling a background message: ${message.data}");
  await Firebase.initializeApp();
  if (Platform.isIOS) {
    FirebaseNotificationManager.instance.showNotification(message);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force dark system UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp();

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await FirebaseNotificationManager.instance.init();

    await GetStorage.init('shortzz');

    FirebaseAuth.instance.authStateChanges().listen((_) {
      FirebaseUserSyncService.syncCurrentSessionUserFromFirebase();
    });

    await FirebaseUserSyncService.syncCurrentSessionUserFromFirebase();

    try {
      await SubscriptionManager.shared.initPlatformState();
    } catch (e, st) {
      Loggers.error('SubscriptionManager init error: $e\n$st');
    }

    (await AudioSession.instance)
        .configure(const AudioSessionConfiguration.speech());

    MobileAds.instance.initialize();

    try {
      await GoogleSignIn.instance.initialize(
        serverClientId:
            '28441059803-78ro06cusr82bc0d9ksf3eoo12rvhat1.apps.googleusercontent.com',
      );
      Loggers.info('GoogleSignIn initialized at startup');
    } catch (e) {
      Loggers.error('GoogleSignIn init error: $e');
    }

    NetworkHelper().initialize();

    Get.put(DynamicTranslations());
    Get.put(ThemeController(), permanent: true);

    runApp(const RestartWidget(child: MyApp()));
  } catch (e, st) {
    Loggers.error('Fatal crash during app startup $st');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Get.find<ThemeController>();

    return GetMaterialApp(
      builder: (context, child) =>
          ScrollConfiguration(behavior: MyBehavior(), child: child!),
      translations: Get.find<DynamicTranslations>(),
      locale: Locale(SessionManager.instance.getLang()),
      fallbackLocale: Locale(SessionManager.instance.getFallbackLang()),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      themeMode: ThemeMode.dark,
      darkTheme: ThemeRes.darkTheme(context),
      theme: ThemeRes.darkTheme(context),
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
