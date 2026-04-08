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
    return Scaffold(
      resizeToAvoidBottomInset: true, // Enabled to prevent overflow when keyboard appears
      body: Container(
        height: Get.height,
        decoration: const ShapeDecoration(
            shape: SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.vertical(
              top: SmoothRadius(cornerRadius: 0, cornerSmoothing: 1)),
        )),
        child: Stack(
          children: [
            const ThemeBlurBg(),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            text: LKey.signIn.tr.toUpperCase(),
                            style: TextStyleCustom.unboundedBlack900(
                              fontSize: 25,
                              color: whitePure(context),
                            ).copyWith(letterSpacing: -.2),
                            children: [
                              TextSpan(
                                  text: '\n${LKey.toContinue.tr}'
                                      .toUpperCase(),
                                  style:
                                      TextStyleCustom.unboundedBlack900(
                                          fontSize: 25,
                                          color: whitePure(context)
                                              .withValues(alpha: .5),
                                          opacity: .5))
                            ],
                          )),
                      const SizedBox(height: 75),
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
                            Get.bottomSheet(const ForgetPasswordSheet(),
                                    isScrollControlled: true)
                                .then((value) => controller
                                    .forgetEmailController
                                    .clear());
                          },
                          child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 14.0),
                              child: Text(LKey.forgetPassword.tr,
                                  style: TextStyleCustom.outFitRegular400(
                                      fontSize: 16,
                                      color: whitePure(context)))),
                        ),
                      ),
                      TextButtonCustom(
                          onTap: controller.onLogin,
                          title: LKey.logIn.tr,
                          btnHeight: 50,
                          horizontalMargin: 0),
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
                          margin: const EdgeInsets.symmetric(vertical: 25),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: whitePure(context).withValues(alpha: .2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            LKey.createAccountHere.tr,
                            style: TextStyleCustom.outFitRegular400(
                                color: whitePure(context), fontSize: 16),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: CustomDivider(
                              color: whitePure(context),
                              height: .5,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15.0),
                            child: Text(
                              LKey.continueWith.tr,
                              style: TextStyleCustom.outFitRegular400(
                                  fontSize: 16, color: whitePure(context)),
                            ),
                          ),
                          Expanded(
                            child: CustomDivider(
                              color: whitePure(context),
                              height: .5,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (Platform.isIOS)
                              SocialBtn(
                                onTap: controller.onAppleTap,
                                icon: AssetRes.icApple,
                              ),
                            if (Platform.isIOS) const SizedBox(width: 10),
                            SocialBtn(
                                onTap: controller.onGoogleTap,
                                icon: AssetRes.icGoogle),
                          ],
                        ),
                      ),
                      PrivacyPolicyText(
                        boldTextColor: whitePure(context),
                        regularTextColor:
                            whitePure(context).withValues(alpha: .8),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
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
    return Container(
      decoration: ShapeDecoration(
          shape: SmoothRectangleBorder(
            borderRadius:
                SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 1),
            side: BorderSide(color: whitePure(context).withValues(alpha: .4)),
            borderAlign: BorderAlign.inside,
          ),
          color: whitePure(context).withValues(alpha: .1)),
      child: TextField(
        controller: widget.controller,
        style: TextStyleCustom.outFitRegular400(
            color: whitePure(context), fontSize: 16),
        onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
        obscureText: widget.isPasswordField && isHide,
        keyboardType: widget.keyboardType ?? TextInputType.text,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          hintStyle: TextStyleCustom.outFitRegular400(
              color: whitePure(context), fontSize: 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          suffixIconConstraints: const BoxConstraints(),
          suffixIcon: widget.isPasswordField
              ? InkWell(
                  onTap: () {
                    isHide = !isHide;
                    setState(() {});
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Image.asset(
                          isHide ? AssetRes.icEye : AssetRes.icHideEye,
                          height: 24,
                          width: 24,
                          color: whitePure(context),
                          key: UniqueKey()),
                    ),
                  ),
                )
              : null,
        ),
        cursorColor: whitePure(context),
      ),
    );
  }
}

class SocialBtn extends StatelessWidget {
  final String icon;
  final VoidCallback onTap;

  const SocialBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 57,
        width: 57,
        decoration:
            BoxDecoration(shape: BoxShape.circle, color: whitePure(context)),
        alignment: Alignment.center,
        child: Image.asset(icon, height: 32, width: 32),
      ),
    );
  }
}
