import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flayr/common/controller/base_controller.dart';
import 'package:flayr/common/manager/firebase_notification_manager.dart';
import 'package:flayr/common/manager/logger.dart';
import 'package:flayr/common/manager/session_manager.dart';
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
    showLoader();
    try {
      final userCredential = await _googleSignInProcess();
      if (userCredential != null && userCredential.user != null) {
        final userData = await UserService.instance.logInUser(
          fullName: userCredential.user!.displayName ?? '',
          identity: userCredential.user!.uid,
          loginMethod: LoginMethod.google,
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
      Loggers.error('Google Sign-In Error: $e');
      showSnackBar(e.toString());
    }
  }

  Future<UserCredential?> _googleSignInProcess() async {
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
