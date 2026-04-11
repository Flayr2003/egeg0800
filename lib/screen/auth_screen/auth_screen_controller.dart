import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flayr/common/controller/base_controller.dart';
import 'package:flayr/common/manager/firebase_notification_manager.dart';
import 'package:flayr/common/manager/logger.dart';
import 'package:flayr/common/manager/session_manager.dart';
import 'package:flayr/common/service/auth/firebase_user_sync_service.dart';
import 'package:flayr/common/service/api/user_service.dart';
import 'package:flayr/languages/languages_keys.dart';
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
  RxBool isGoogleSigningIn = false.obs;

  @override
  void onInit() {
    super.onInit();
  }

  Future<void> onLogin() async {
    if (emailController.text.trim().isEmpty) {
      showSnackBar(LKey.enterEmail.tr);
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      showSnackBar(LKey.enterPassword.tr);
      return;
    }

    showLoader();
    try {
      final userData = await UserService.instance.logInFakeUser(
        identity: emailController.text.trim(),
        password: passwordController.text.trim(),
        deviceToken: await FirebaseNotificationManager.instance.getNotificationToken() ?? '',
        loginMethod: LoginMethod.email,
      );

      stopLoader();
      if (userData != null) {
        _navigateScreen(userData);
      }
    } catch (e) {
      stopLoader();
      Loggers.error('Login Error: $e');
      showSnackBar(e.toString());
    }
  }

  Future<void> onCreateAccount() async {
    if (fullNameController.text.trim().isEmpty) {
      showSnackBar(LKey.enterFullName.tr);
      return;
    }
    if (emailController.text.trim().isEmpty) {
      showSnackBar(LKey.enterEmail.tr);
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      showSnackBar(LKey.enterAPassword.tr);
      return;
    }
    if (passwordController.text.trim() != confirmPassController.text.trim()) {
      showSnackBar(LKey.passwordMismatch.tr);
      return;
    }

    showLoader();
    try {
      final userData = await UserService.instance.logInUser(
        fullName: fullNameController.text.trim(),
        identity: emailController.text.trim(),
        deviceToken: await FirebaseNotificationManager.instance.getNotificationToken() ?? '',
        loginMethod: LoginMethod.email,
      );

      stopLoader();
      if (userData != null) {
        _navigateScreen(userData);
      }
    } catch (e) {
      stopLoader();
      Loggers.error('Register Error: $e');
      showSnackBar(e.toString());
    }
  }

  Future<void> onGoogleTap() async {
    if (isGoogleSigningIn.value) return;
    isGoogleSigningIn.value = true;
    showLoader();
    try {
      final userCredential = await _googleSignInProcess();
      final firebaseUser = userCredential?.user;

      if (firebaseUser == null) {
        showSnackBar(_localizedSignInMessage(
          ar: 'تعذّر تسجيل الدخول عبر Google. حاول مرة أخرى.',
          en: 'Unable to sign in with Google. Please try again.',
        ));
        return;
      }

      final userData = await UserService.instance.logInUser(
        fullName: firebaseUser.displayName ?? '',
        identity: firebaseUser.uid,
        loginMethod: LoginMethod.google,
        deviceToken:
            await FirebaseNotificationManager.instance.getNotificationToken() ??
                '',
      );

      if (userData != null) {
        final mergedUser = FirebaseUserSyncService.enrichUserWithFirebaseData(
          appUser: userData,
          firebaseUser: firebaseUser,
          persistInSession: true,
        );
        _navigateScreen(mergedUser ?? userData);
      }
    } on GoogleSignInException catch (e) {
      Loggers.error('Google Sign-In Error: ${e.code} - ${e.description}');
      showSnackBar(_mapGoogleSignInException(e));
    } catch (e) {
      Loggers.error('Google Sign-In Error: $e');
      showSnackBar(_localizedSignInMessage(
        ar: 'فشل تسجيل الدخول عبر Google. تأكد من SHA-1 وإعدادات Firebase ثم حاول مرة أخرى.',
        en: 'Google Sign-In failed. Verify SHA-1 and Firebase setup, then try again.',
      ));
    } finally {
      stopLoader();
      isGoogleSigningIn.value = false;
    }
  }

  Future<UserCredential?> _googleSignInProcess() async {
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    try {
      return await _authenticateWithGoogle(googleSignIn);
    } on GoogleSignInException catch (e) {
      if (_isRecoverableGoogleError(e)) {
        await _resetGoogleSession(googleSignIn);
        return await _authenticateWithGoogle(googleSignIn);
      }
      rethrow;
    }
  }

  Future<UserCredential?> _authenticateWithGoogle(
      GoogleSignIn googleSignIn) async {
    final GoogleSignInAccount googleUser = await googleSignIn.authenticate();
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    String? accessToken;
    try {
      const googleScopes = <String>['email', 'profile', 'openid'];
      final GoogleSignInClientAuthorization? authorization = await googleUser
              .authorizationClient
              .authorizationForScopes(googleScopes) ??
          await googleUser.authorizationClient.authorizeScopes(googleScopes);
      accessToken = authorization?.accessToken;
    } catch (e) {
      Loggers.error('Google authorization scope error: $e');
    }

    if ((googleAuth.idToken?.isEmpty ?? true) &&
        (accessToken?.isEmpty ?? true)) {
      throw Exception('Google token is missing.');
    }

    final AuthCredential credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: accessToken,
    );

    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  bool _isRecoverableGoogleError(GoogleSignInException exception) {
    final errorText =
        '${exception.code} ${exception.description ?? ''}'.toLowerCase();
    return errorText.contains('reauth') ||
        errorText.contains('[16]') ||
        errorText.contains('account reauth failed');
  }

  Future<void> _resetGoogleSession(GoogleSignIn googleSignIn) async {
    try {
      await googleSignIn.signOut();
    } catch (_) {}
    try {
      await googleSignIn.disconnect();
    } catch (_) {}
  }

  String _mapGoogleSignInException(GoogleSignInException exception) {
    final errorText =
        '${exception.code} ${exception.description ?? ''}'.toLowerCase();

    if (_isRecoverableGoogleError(exception)) {
      return _localizedSignInMessage(
        ar: 'حدثت مشكلة في إعادة توثيق حساب Google. أعدنا المحاولة تلقائيًا، وإذا استمر الخطأ راجع SHA-1 في Firebase.',
        en: 'Google account re-auth failed. We retried automatically. If it continues, verify SHA-1 in Firebase.',
      );
    }

    if (errorText.contains('canceled')) {

    return _localizedSignInMessage(
      ar: 'فشل تسجيل الدخول عبر Google. حاول مرة أخرى.',
      en: 'Google Sign-In failed. Please try again.',
    );
  }

  String _localizedSignInMessage({required String ar, required String en}) {
    return Get.locale?.languageCode == 'ar' ? ar : en;
  }

  Future<void> onAppleTap() async {
    showLoader();
    try {
      final userCredential = await signInWithApple();
      if (userCredential != null && userCredential.user != null) {
        final userData = await UserService.instance.logInUser(
          fullName: userCredential.user!.displayName ?? '',
          identity: userCredential.user!.uid,
          loginMethod: LoginMethod.apple,
          deviceToken: await FirebaseNotificationManager.instance.getNotificationToken() ?? '',
        );

        stopLoader();
        if (userData != null) {
          _navigateScreen(userData);
        }
      } else {
        stopLoader();
      }
    } catch (e) {
      stopLoader();
      Loggers.error('Apple Sign-In Error: $e');
      showSnackBar(e.toString());
    }
  }

  Future<UserCredential?> signInWithApple() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
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
    SessionManager.instance.setLogin(true);
    Get.offAll(() => DashboardScreen(myUser: data));
  }

  void forgetPassword() async {
    if (forgetEmailController.text.trim().isEmpty) {
      showSnackBar(LKey.enterEmail.tr);
      return;
    }

    showLoader();
    try {
      stopLoader();
      showSnackBar(LKey.resetPasswordLinkSent.tr);
      Get.back();
    } catch (e) {
      stopLoader();
      Loggers.error('Forget Password Error: $e');
      showSnackBar(e.toString());
    }
  }
}
