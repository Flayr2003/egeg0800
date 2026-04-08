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
    
    return Scaffold(
      body: Stack(
        children: [
          const ThemeBlurBg(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: Obx(
                    () => ListView.builder(
                        itemCount: controller.languages.length,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        physics: const BouncingScrollPhysics(),
                        itemBuilder: (context, index) {
                          Language language = controller.languages[index];
                          bool isSelected =
                              language == controller.selectedLanguage.value;
                          
                          return GestureDetector(
                            onTap: () => controller.onLanguageChange(language),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                              decoration: ShapeDecoration(
                                shape: SmoothRectangleBorder(
                                  borderRadius: SmoothBorderRadius(cornerRadius: 15, cornerSmoothing: 1),
                                  side: BorderSide(
                                    color: isSelected
                                        ? whitePure(context)
                                        : whitePure(context).withValues(alpha: .2),
                                      width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                color: whitePure(context).withValues(alpha: isSelected ? .25 : .05),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          language.localizedTitle ?? '',
                                          style: TextStyleCustom.outFitMedium500(
                                              fontSize: 18, color: whitePure(context)),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          language.title ?? '',
                                          style: TextStyleCustom.outFitLight300(
                                              fontSize: 14, color: whitePure(context).withValues(alpha: .7)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, color: whitePure(context), size: 24)
                                  else
                                    Icon(Icons.radio_button_unchecked, 
                                        color: whitePure(context).withValues(alpha: .4), size: 24),
                                ],
                              ),
                            ),
                          );
                        }),
                  ),
                ),
                if (languageNavigationType == LanguageNavigationType.fromStart)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: TextButtonCustom(
                      onTap: () {
                        SessionManager.instance.setBool(SessionKeys.isLanguageScreenSelect, true);
                        if ((controller.setting?.onBoarding ?? []).isEmpty) {
                          Get.off(() => const LoginScreen());
                        } else {
                          Get.off(() => const OnBoardingScreen());
                        }
                      },
                      title: LKey.continueText.tr,
                      margin: EdgeInsets.zero,
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (languageNavigationType == LanguageNavigationType.fromSetting) {
      return CustomAppBar(
        title: LKey.languages.tr,
        titleStyle: TextStyleCustom.unboundedSemiBold600(
            fontSize: 18, color: whitePure(context)),
        bgColor: Colors.transparent,
        iconColor: whitePure(context),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(15),
            decoration: ShapeDecoration(
                color: whitePure(context).withValues(alpha: .1),
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(cornerRadius: 15),
                )),
            child: Image.asset(
              AssetRes.icLanguage, 
              color: whitePure(context),
              errorBuilder: (context, error, stackTrace) => Icon(Icons.language, color: whitePure(context), size: 30),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LKey.select.tr.toUpperCase(),
                  style: TextStyleCustom.unboundedBlack900(
                      fontSize: 22, color: whitePure(context)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  LKey.language.tr.toUpperCase(),
                  style: TextStyleCustom.unboundedBlack900(
                      fontSize: 22,
                      color: whitePure(context).withValues(alpha: .5)),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
