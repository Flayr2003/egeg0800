import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flayr/common/controller/base_controller.dart';
import 'package:flayr/common/functions/debounce_action.dart';
import 'package:flayr/common/manager/firebase_notification_manager.dart';
import 'package:flayr/common/manager/logger.dart';
import 'package:flayr/common/manager/session_manager.dart';
import 'package:flayr/common/service/api/common_service.dart';
import 'package:flayr/common/service/api/notification_service.dart';
import 'package:flayr/common/service/api/user_service.dart';
import 'package:flayr/common/service/subscription/subscription_manager.dart';
import 'package:flayr/languages/dynamic_translations.dart';
import 'package:flayr/languages/languages_keys.dart';
import 'package:flayr/model/general/settings_model.dart';
import 'package:flayr/model/user_model/user_model.dart' as user;
import 'package:flayr/screen/dashboard_screen/dashboard_screen.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Web Client ID (type 3) from google-services.json
const String _googleWebClientId =
    '28441059803-78ro06cusr82bc0d9ksf3eoo12rvhat1.apps.googleusercontent.com';

class AuthScreenController extends BaseController {
  TextEditingController fullNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController forgetEmailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPassController = TextEditingController();

  @override
  void onInit() {
    CommonService.instance.fetchGlobalSettings();
    FirebaseNotificationManager.instance;
    super.onInit();
  }

  Future<void> onLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty) {
      return showSnackBar(LKey.enterEmail.tr);
    }
    if (password.isEmpty) {
      return showSnackBar(LKey.enterAPassword.tr);
    }

    showLoader();

    try {
      // Real Login using Firebase
      UserCredential? credential = await signInWithEmailAndPassword();
      if (credential != null) {
        final user.User? data = await _registration(
            identity: email, 
            loginMethod: LoginMethod.email, 
            loginVia: LoginVia.loginInUser, 
            password: password
        );
        stopLoader();

        if (data != null) {
          _navigateScreen(data);
        }
      } else {
        stopLoader();
      }
    } catch (e) {
      Loggers.error('Unexpected error in onLogin: $e');
      stopLoader();
      showSnackBar('Login failed. Please check your credentials.');
    }
  }

  Future<void> onCreateAccount() async {
    if (fullNameController.text.trim().isEmpty) {
      return showSnackBar(LKey.fullNameEmpty.tr);
    }
    if (emailController.text.trim().isEmpty) {
      return showSnackBar(LKey.enterEmail.tr);
    }
    if (passwordController.text.trim().isEmpty) {
      return showSnackBar(LKey.enterAPassword.tr);
    }
    if (confirmPassController.text.trim().isEmpty) {
      return showSnackBar(LKey.confirmPasswordEmpty.tr);
    }
    if (!GetUtils.isEmail(emailController.text.trim())) {
      return showSnackBar(LKey.invalidEmail.tr);
    }
    if (passwordController.text.trim() != confirmPassController.text.trim()) {
      return showSnackBar(LKey.passwordMismatch.tr);
    }
    showLoader();
    UserCredential? credential = await createUserWithEmailAndPassword();
    if (credential != null) {
      await _registration(
          identity: emailController.text.trim(),
          loginMethod: LoginMethod.email,
          fullname: fullNameController.text.trim(),
          loginVia: LoginVia.loginInUser);
      if (credential.user != null) {
        credential.user!.updateDisplayName(fullNameController.text.trim());
        credential.user!.sendEmailVerification();
      }
      Get.back();
      Get.back();
      showSnackBar(LKey.verificationLinkSent.tr);
    }
  }

  void onGoogleTap() async {
    showLoader();
    UserCredential? credential;
    try {
      credential = await signInWithGoogle();
    } catch (e) {
      Loggers.error(e);
      stopLoader();
      return;
    }
    if (credential == null || credential.user == null) {
      stopLoader();
      return;
    }
    user.User? data = await _registration(
        identity: credential.user?.email ?? '',
        loginMethod: LoginMethod.google,
        fullname: credential.user?.displayName ?? credential.user?.email?.split('@')[0],
        loginVia: LoginVia.loginInUser);
    stopLoader();
    if (data != null) {
      _navigateScreen(data);
    }
  }

  void onAppleTap() async {
    showLoader();
    UserCredential? credential;
    try {
      credential = await signInWithApple();
    } catch (e) {
      Loggers.error(e);
      stopLoader();
      return;
    }
    if (credential == null || credential.user == null) {
      stopLoader();
      return;
    }
    user.User? data = await _registration(
        identity: credential.user?.email ?? '',
        loginMethod: LoginMethod.apple,
        fullname: credential.user?.displayName ?? credential.user?.email?.split('@')[0],
        loginVia: LoginVia.loginInUser);
    stopLoader();
    if (data != null) {
      _navigateScreen(data);
    }
  }

  Future<user.User?> _registration(
      {required String identity,
      required LoginMethod loginMethod,
      String? fullname,
      required LoginVia loginVia,
      String? password}) async {
    Loggers.info('Fetching device token for registration...');
    String? deviceToken = '';
    try {
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        deviceToken = await FirebaseNotificationManager.instance.getNotificationToken().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            Loggers.warning('FCM Token fetch timed out, using empty token');
            return '';
          },
        );
      }
    } catch (e) {
      Loggers.error('Error fetching device token: $e');
    }
    deviceToken ??= '';

    user.User? userData;
    try {
      switch (loginVia) {
        case LoginVia.loginInUser:
          userData = await UserService.instance
              .logInUser(identity: identity, loginMethod: loginMethod, deviceToken: deviceToken, fullName: fullname);
          break;
        case LoginVia.logInFakeUser:
          userData = await UserService.instance
              .logInFakeUser(identity: identity, loginMethod: loginMethod, deviceToken: deviceToken, password: password);
          break;
      }
    } catch (e) {
      Loggers.error('API Call Exception in _registration: $e');
      rethrow;
    }

    Setting? setting = SessionManager.instance.getSettings();
    if (userData?.isDummy == 0 && userData?.newRegister == true && setting?.registrationBonusStatus == 1) {
      final translations = Get.find<DynamicTranslations>();
      final languageData = translations.keys[userData?.appLanguage] ?? {};

      NotificationService.instance.pushNotification(
          title: languageData[LKey.registrationBonusTitle] ?? LKey.registrationBonusTitle.tr,
          body: languageData[LKey.registrationBonusDescription] ?? LKey.registrationBonusDescription.tr,
          type: NotificationType.other,
          deviceType: userData?.device,
          token: userData?.deviceToken,
          authorizationToken: userData?.token?.authToken);
    }
    SubscriptionManager.shared.login('${userData?.id}');
    if (userData != null) {
      return userData;
    }
    return null;
  }

  Future<UserCredential?> createUserWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());
      SessionManager.instance.setPassword(passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      stopLoader();
      Loggers.error(e.message);
      if (e.code == 'weak-password') {
        showSnackBar(LKey.weakPassword.tr);
      } else if (e.code == 'email-already-in-use') {
        showSnackBar(LKey.accountExists.tr);
      } else {
        showSnackBar(e.message);
      }
      return null;
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword() async {
    try {
      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailController.text.trim(), password: passwordController.text.trim());
      return credential;
    } on FirebaseAuthException catch (e) {
      stopLoader();
      if (e.code == 'user-not-found') {
        showSnackBar(LKey.noUserFound.tr);
      } else if (e.code == 'wrong-password') {
        showSnackBar(LKey.incorrectPassword.tr);
      } else if (e.code == 'invalid-credential') {
        showSnackBar(LKey.incorrectPassword.tr);
      } else {
        showSnackBar(e.message ?? 'Login failed. Please try again.');
      }
      return null;
    } catch (e) {
      stopLoader();
      Loggers.error('Unexpected login error: $e');
      return null;
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: _googleWebClientId,
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) throw 'Google Sign-In cancelled';

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScope.email,
        AppleIDAuthorizationScope.fullName,
      ],
    );

    final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
    final AuthCredential credential = oAuthProvider.credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  void _navigateScreen(user.User data) {
    SessionManager.instance.setUser(data);
    SessionManager.instance.setAuthToken(data.token);
    Get.offAll(() => DashboardScreen(myUser: data));
  }

  void forgetPassword() async {
    if (forgetEmailController.text.trim().isEmpty) {
      return showSnackBar(LKey.enterEmail.tr);
    }
    showLoader();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: forgetEmailController.text.trim());
      stopLoader();
      Get.back();
      showSnackBar(LKey.verificationLinkSent.tr);
    } on FirebaseAuthException catch (e) {
      stopLoader();
      showSnackBar(e.message);
    }
  }
}

enum LoginVia { loginInUser, logInFakeUser }
