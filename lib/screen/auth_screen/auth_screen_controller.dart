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
    // Initialize Google Sign-In once when the controller is created
    _initGoogleSignIn();
    super.onInit();
  }

  /// Initialize Google Sign-In with serverClientId (required for v7+)
  Future<void> _initGoogleSignIn() async {
    try {
      await GoogleSignIn.instance.initialize(serverClientId: _googleWebClientId);
      Loggers.info('GoogleSignIn initialized successfully');
    } catch (e) {
      Loggers.error('GoogleSignIn initialization error: $e');
    }
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
      // Authenticate with Firebase first
      UserCredential? credential = await signInWithEmailAndPassword();
      if (credential != null && credential.user != null) {
        Loggers.info('Firebase login successful for: ${credential.user?.email}');
        
        // Register/Login with backend using Firebase UID or Email
        final user.User? data = await _registration(
            identity: credential.user?.email ?? email, 
            loginMethod: LoginMethod.email, 
            loginVia: LoginVia.loginInUser,
            fullname: credential.user?.displayName
        );
        stopLoader();

        if (data != null) {
          Loggers.success('Backend login successful');
          _navigateScreen(data);
        } else {
          Loggers.error('Backend returned null for login');
          showSnackBar('Server error. Please try again later.');
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
      credential.user?.updateDisplayName(fullNameController.text.trim());
      credential.user?.sendEmailVerification();
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
      Loggers.info(
          'GOOGLE EMAIL : ${credential.user?.email} FULLNAME : ${credential.user?.displayName}');
    } catch (e) {
      Loggers.error('Google Sign-In Error: $e');
      stopLoader();
      showSnackBar('Google Sign-In failed: ${e.toString()}');
      return;
    }

    if (credential.user == null) {
      stopLoader();
      return;
    }

    // Register/Login with backend using REAL Google data
    user.User? data = await _registration(
        identity: credential.user?.email ?? '',
        loginMethod: LoginMethod.google,
        fullname: credential.user?.displayName ?? credential.user?.email?.split('@')[0],
        loginVia: LoginVia.loginInUser);
    
    stopLoader();
    if (data != null) {
      Loggers.success('Google login successful with real data');
      _navigateScreen(data);
    } else {
      showSnackBar('Failed to sync with server. Please try again.');
    }
  }

  void onAppleTap() async {
    showLoader();
    UserCredential? credential;
    try {
      credential = await signInWithApple();
      Loggers.info(
          'EMAIL : ${credential.user?.email} FULLNAME : ${credential.user?.displayName ?? credential.user?.email?.split('@')[0]}');
    } catch (e) {
      Loggers.error(e);
      stopLoader();
      return;
    }
    if (credential?.user == null) {
      stopLoader();
      return;
    }
    user.User? data = await _registration(
        identity: credential?.user?.email ?? '',
        loginMethod: LoginMethod.apple,
        fullname: credential?.user?.displayName ?? credential?.user?.email?.split('@')[0],
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
      // Check if we are on a real device/emulator that supports FCM
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        deviceToken = await FirebaseNotificationManager.instance.getNotificationToken().timeout(
          const Duration(seconds: 3), // Reduced timeout for better UX
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
    Loggers.info('Device Token: ${deviceToken.isEmpty ? "EMPTY" : "RECEIVED"}');

    user.User? userData;
    try {
      switch (loginVia) {
        case LoginVia.loginInUser:
          Loggers.info('Calling logInUser API for $identity');
          userData = await UserService.instance
              .logInUser(identity: identity, loginMethod: loginMethod, deviceToken: deviceToken, fullName: fullname);
          break;
        case LoginVia.logInFakeUser:
          Loggers.info('Calling logInFakeUser API for $identity');
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
      // Subscribe My Following Ids For Live streaming notification
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
        Loggers.info(LKey.noUserFound.tr);
      } else if (e.code == 'wrong-password') {
        showSnackBar(LKey.incorrectPassword.tr);
        Loggers.info(LKey.incorrectPassword.tr);
      } else if (e.code == 'invalid-credential') {
        showSnackBar(LKey.incorrectPassword.tr);
        Loggers.error('Invalid credential: ${e.message}');
      } else {
        showSnackBar(e.message ?? 'Login failed. Please try again.');
        Loggers.error('FirebaseAuthException: ${e.code} - ${e.message}');
      }
      return null;
    } catch (e) {
      stopLoader();
      Loggers.error('Unexpected login error: $e');
      return null;
    }
  }

  /// Google Sign-In using google_sign_in v7+ API
  Future<UserCredential> signInWithGoogle() async {
    // Step 1: Authenticate (triggers account picker / Credential Manager)
    final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled by user');
    }

    // Step 2: Get authentication details (MUST use await)
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Step 3: Get idToken from authentication
    final String? idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('Google Sign-In failed: idToken is null');
    }

    // Step 4: Create Firebase credential with idToken only
    final credential = GoogleAuthProvider.credential(idToken: idToken);

    // Step 5: Sign in to Firebase
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential> signInWithApple() async {
    // Request credential for the currently signed in Apple account.
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );

    // Create an `OAuthCredential` from the credential returned by Apple.
    final oauthCredential = OAuthProvider("apple.com")
        .credential(idToken: appleCredential.identityToken, accessToken: appleCredential.authorizationCode);

    return await FirebaseAuth.instance.signInWithCredential(oauthCredential);
  }

  void forgetPassword() async {
    final email = forgetEmailController.text.trim();
    if (email.isEmpty) {
      showSnackBar(LKey.enterEmail.tr);
      return;
    }
    showLoader();
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      stopLoader();
      Get.back(); // Close the BottomSheet
      showSnackBar(LKey.resetPasswordLinkSent.tr);
    } on FirebaseAuthException catch (e) {
      stopLoader();
      showSnackBar(e.message ?? "An error occurred. Please try again.");
    }
  }

  void _navigateScreen(user.User? data) {
    if (data == null) {
      Loggers.error('Cannot navigate: User data is null');
      return;
    }

    Loggers.info('Saving user session and token...');
    
    // 1. Save Login Status
    SessionManager.instance.setLogin(true);
    
    // 2. Save User Data
    SessionManager.instance.setUser(data);
    
    // 3. Save Auth Token (CRITICAL)
    if (data.token != null) {
      SessionManager.instance.setAuthToken(data.token);
      Loggers.success('Auth Token saved successfully: ${data.token?.authToken}');
    } else {
      Loggers.warning('User data received but Token is NULL - API might not be returning token correctly');
    }

    // 4. Navigate to Dashboard
    Get.offAll(() => DashboardScreen(myUser: data));
  }
}

enum LoginVia { loginInUser, logInFakeUser }
