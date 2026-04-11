import 'package:figma_squircle_updated/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flayr/common/manager/session_manager.dart';
import 'package:flayr/common/widget/custom_app_bar.dart';
import 'package:flayr/common/widget/text_button_custom.dart';
import 'package:flayr/common/widget/theme_blur_bg.dart';
import 'package:flayr/languages/languages_keys.dart';
import 'package:flayr/model/general/settings_model.dart';
import 'package:flayr/screen/auth_screen/login_screen.dart';
import 'package:flayr/screen/on_boarding_screen/on_boarding_screen.dart';
import 'package:flayr/screen/select_language_screen/select_language_screen_controller.dart';
import 'package:flayr/utilities/asset_res.dart';
import 'package:flayr/utilities/text_style_custom.dart';
import 'package:flayr/utilities/theme_res.dart';

enum LanguageNavigationType { fromStart, fromSetting }

class SelectLanguageScreen extends StatelessWidget {
  final LanguageNavigationType languageNavigationType;

  const SelectLanguageScreen({super.key, required this.languageNavigationType});

  @override
  Widget build(BuildContext context) {
    final controller =
        Get.put(SelectLanguageScreenController(languageNavigationType));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          const ThemeBlurBg(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: ShapeDecoration(
                        color: isDark ? const Color(0xFF121212) : Colors.white,
                        shape: SmoothRectangleBorder(
                          borderRadius:
                              SmoothBorderRadius(cornerRadius: 20, cornerSmoothing: 1),
                        ),
                      ),
                      child: Obx(
                        () => ListView.separated(
                          itemCount: controller.languages.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final language = controller.languages[index];
                            final isSelected =
                                language == controller.selectedLanguage.value;

                            return Material(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF000000) : const Color(0xFFECECEC))
                                  : (isDark ? const Color(0xFF1B1B1B) : const Color(0xFFF7F7F7)),
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => controller.onLanguageChange(language),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isDark
                                            ? (isSelected ? Colors.white : Colors.white70)
                                            : (isSelected ? Colors.black : Colors.black54),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              language.localizedTitle ?? '',
                                              style:
                                                  TextStyleCustom.outFitMedium500(
                                                fontSize: 15,
                                                color: isDark ? Colors.white : Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              language.title ?? '',
                                              style:
                                                  TextStyleCustom.outFitRegular400(
                                                fontSize: 13,
                                                color: isDark ? Colors.white70 : Colors.black54,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                if (languageNavigationType == LanguageNavigationType.fromStart)
                  SafeArea(
                    top: false,
                    child: TextButtonCustom(
                      onTap: () {
                        SessionManager.instance
                            .setBool(SessionKeys.isLanguageScreenSelect, true);
                        if ((controller.setting?.onBoarding ?? []).isEmpty) {
                          Get.off(() => const LoginScreen());
                        } else {
                          Get.off(() => const OnBoardingScreen());
                        }
                      },
                      title: LKey.continueText.tr,
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      backgroundColor: const Color(0xFF2B2E34),
                      titleColor: Colors.white,
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    switch (languageNavigationType) {
      case LanguageNavigationType.fromStart:
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 6),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: isDark
                      ? whitePure(context).withValues(alpha: .18)
                      : Colors.black.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(AssetRes.icLanguage),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LKey.select.tr.toUpperCase(),
                      style: TextStyleCustom.unboundedBlack900(
                          fontSize: 18,
                          color: isDark ? whitePure(context) : Colors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LKey.language.tr.toUpperCase(),
                      style: TextStyleCustom.unboundedBlack900(
                        fontSize: 18,
                        color: isDark ? whitePure(context) : Colors.black,
                        opacity: .65,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case LanguageNavigationType.fromSetting:
        return CustomAppBar(
          title: LKey.languages.tr,
          titleStyle: TextStyleCustom.unboundedSemiBold600(
              fontSize: 15, color: isDark ? whitePure(context) : Colors.black),
          bgColor: Colors.transparent,
          iconColor: isDark ? whitePure(context) : Colors.black,
        );
    }
  }
}
