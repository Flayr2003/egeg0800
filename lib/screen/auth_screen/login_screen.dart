import 'dart:io';

import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flayr/common/widget/custom_divider.dart';
import 'package:flayr/common/widget/privacy_policy_text.dart';
import 'package:flayr/common/widget/text_button_custom.dart';
import 'package:flayr/common/widget/theme_blur_bg.dart';
import 'package:flayr/languages/languages_keys.dart';
import 'package:flayr/screen/auth_screen/auth_screen_controller.dart';
import 'package:flayr/screen/auth_screen/forget_password_sheet.dart';
import 'package:flayr/screen/auth_screen/registration_screen.dart';
import 'package:flayr/utilities/asset_res.dart';
import 'package:flayr/utilities/text_style_custom.dart';
import 'package:flayr/utilities/theme_res.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AuthScreenController());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius: SmoothBorderRadius.vertical(
              top: SmoothRadius(cornerRadius: 0, cornerSmoothing: 1),
            ),
          ),
        ),
        child: Stack(
          children: [
            const ThemeBlurBg(),
            SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 20, end: 20, top: 30),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 30.0),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                text: LKey.signIn.tr.toUpperCase(),
                                style: TextStyleCustom.unboundedBlack900(
                                  fontSize: 25,
                                  color: primaryTextColor,
                                ).copyWith(letterSpacing: -.2),
                                children: [
                                  TextSpan(
                                    text: '\n${LKey.toContinue.tr}'.toUpperCase(),
                                    style: TextStyleCustom.unboundedBlack900(
                                      fontSize: 25,
                                      color: secondaryTextColor,
                                      opacity: .5,
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 56),
                          LoginSheetTextField(
                            hintText: LKey.enterYourEmail.tr,
                            controller: controller.emailController,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 14),
                          LoginSheetTextField(
                            isPasswordField: true,
                            hintText: LKey.enterPassword.tr,
                            controller: controller.passwordController,
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: InkWell(
                              onTap: () {
                                Get.bottomSheet(
                                  const ForgetPasswordSheet(),
                                  isScrollControlled: true,
                                ).then((_) =>
                                    controller.forgetEmailController.clear());
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14.0),
                                child: Text(
                                  LKey.forgetPassword.tr,
                                  style: TextStyleCustom.outFitRegular400(
                                    fontSize: 16,
                                    color: primaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Obx(
                            () => TextButtonCustom(
                              onTap: controller.isCredentialSubmitting.value
                                  ? () {}
                                  : controller.onLogin,
                              title: LKey.logIn.tr,
                              btnHeight: 50,
                              horizontalMargin: 0,
                              child: controller.isCredentialSubmitting.value
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Colors.white,
                                      ),
                                    )
                                  : null,
                            ),
                          )
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        controller.fullNameController.clear();
                        controller.emailController.clear();
                        controller.passwordController.clear();
                        controller.confirmPassController.clear();
                        Get.to(() => const RegistrationScreen());
                      },
                      child: Container(
                        height: 48,
                        margin: const EdgeInsets.symmetric(vertical: 24),
                        alignment: Alignment.center,
                        color: isDark
                            ? whitePure(context).withValues(alpha: .2)
                            : Colors.black.withValues(alpha: .06),
                        child: Text(
                          LKey.createAccountHere.tr,
                          style: TextStyleCustom.outFitRegular400(
                            color: secondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Expanded(
                            child: CustomDivider(
                              color: secondaryTextColor,
                              height: .5,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              LKey.continueWith.tr,
                              style: TextStyleCustom.outFitRegular400(
                                fontSize: 16,
                                color: secondaryTextColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: CustomDivider(
                              color: secondaryTextColor,
                              height: .5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (Platform.isIOS)
                            SocialBtn(
                              onTap: controller.onAppleTap,
                              icon: AssetRes.icApple,
                            ),
                          if (Platform.isIOS) const SizedBox(width: 10),
                          Obx(
                            () => SocialBtn(
                              onTap: controller.onGoogleTap,
                              isDisabled: controller.isGoogleSigningIn.value,
                              child: controller.isGoogleSigningIn.value
                                  ? SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: textDarkGrey(context),
                                      ),
                                    )
                                  : Image.asset(AssetRes.icGoogle,
                                      height: 32, width: 32),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PrivacyPolicyText(
                      boldTextColor: primaryTextColor,
                      regularTextColor: secondaryTextColor,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginSheetTextField extends StatefulWidget {
  final bool isPasswordField;
  final String hintText;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const LoginSheetTextField(
      {super.key,
      this.isPasswordField = false,
      required this.hintText,
      required this.controller,
      this.keyboardType});

  @override
  State<LoginSheetTextField> createState() => _LoginSheetTextFieldState();
}

class _LoginSheetTextFieldState extends State<LoginSheetTextField> {
  bool isHide = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fieldTextColor = isDark ? Colors.white : Colors.black87;
    final borderColor =
        isDark ? Colors.white.withValues(alpha: .4) : Colors.black.withValues(alpha: .18);
    final fieldBgColor =
        isDark ? Colors.white.withValues(alpha: .10) : Colors.white.withValues(alpha: .92);

    return Container(
      decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 1),
            side: BorderSide(color: borderColor),
            borderAlign: BorderAlign.inside,
          ),
          color: fieldBgColor),
      child: TextField(
        controller: widget.controller,
        style:
            TextStyleCustom.outFitRegular400(color: fieldTextColor, fontSize: 16),
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        obscureText: widget.isPasswordField && isHide,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: TextStyleCustom.outFitRegular400(
              color: isDark ? Colors.white70 : Colors.black45, fontSize: 16),
          contentPadding: EdgeInsetsDirectional.only(
              start: 10, end: 10, top: widget.isPasswordField ? 2 : 0),
          suffixIconConstraints: const BoxConstraints(),
          suffixIcon: widget.isPasswordField
              ? InkWell(
                  onTap: () {
                    isHide = !isHide;
                    setState(() {});
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Image.asset(
                        isHide ? AssetRes.icEye : AssetRes.icHideEye,
                        height: 24,
                        width: 35,
                        color: isDark ? whitePure(context) : Colors.black87,
                        key: UniqueKey()),
                  ),
                )
              : null,
        ),
        cursorColor: isDark ? whitePure(context) : Colors.black87,
      ),
    );
  }
}

class SocialBtn extends StatelessWidget {
  final String? icon;
  final Widget? child;
  final bool isDisabled;
  final VoidCallback onTap;

  const SocialBtn({
    super.key,
    this.icon,
    this.child,
    this.isDisabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isDisabled ? .7 : 1,
        child: Container(
          height: 57,
          width: 57,
          decoration:
              BoxDecoration(shape: BoxShape.circle, color: whitePure(context)),
          alignment: Alignment.center,
          child: child ?? Image.asset(icon!, height: 32, width: 32),
        ),
      ),
    );
  }
}
