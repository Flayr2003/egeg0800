import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flayr/common/widget/custom_back_button.dart';
import 'package:flayr/common/widget/gradient_text.dart';
import 'package:flayr/common/widget/privacy_policy_text.dart';
import 'package:flayr/common/widget/text_button_custom.dart';
import 'package:flayr/common/widget/text_field_custom.dart';
import 'package:flayr/languages/languages_keys.dart';
import 'package:flayr/screen/auth_screen/auth_screen_controller.dart';
import 'package:flayr/utilities/style_res.dart';
import 'package:flayr/utilities/text_style_custom.dart';
import 'package:flayr/utilities/theme_res.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AuthScreenController>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              dragStartBehavior: DragStartBehavior.down,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    const CustomBackButton(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(
                          start: 20.0, end: 20, top: 30, bottom: 26),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            LKey.signUp.tr.toUpperCase(),
                            style: TextStyleCustom.unboundedBlack900(
                              fontSize: 24,
                              color: textDarkGrey(context),
                            ).copyWith(letterSpacing: -.2),
                          ),
                          const SizedBox(height: 4),
                          GradientText(
                            LKey.startJourney.tr.toUpperCase(),
                            gradient: StyleRes.themeGradient,
                            style: TextStyleCustom.unboundedBlack900(
                              fontSize: 24,
                              color: textDarkGrey(context),
                            ).copyWith(letterSpacing: -.2),
                          ),
                        ],
                      ),
                    ),
                    TextFieldCustom(
                      controller: controller.fullNameController,
                      title: LKey.fullName.tr,
                    ),
                    TextFieldCustom(
                      controller: controller.emailController,
                      title: LKey.email.tr,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    TextFieldCustom(
                      controller: controller.passwordController,
                      title: LKey.password.tr,
                      isPasswordField: true,
                    ),
                    TextFieldCustom(
                      controller: controller.confirmPassController,
                      title: LKey.reTypePassword.tr,
                      isPasswordField: true,
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => TextButtonCustom(
                        onTap: controller.isCredentialSubmitting.value
                            ? () {}
                            : controller.onCreateAccount,
                        title: LKey.createAccount.tr,
                        backgroundColor: const Color(0xFF2B2E34),
                        horizontalMargin: 20,
                        titleColor: whitePure(context),
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
                    ),
                    const SizedBox(height: 16),
                    const SafeArea(
                      top: false,
                      maintainBottomViewPadding: true,
                      child: PrivacyPolicyText(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
