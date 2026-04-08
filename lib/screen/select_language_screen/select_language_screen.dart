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
            top: false,
            child: Column(
              children: [
                switch (languageNavigationType) {
                  LanguageNavigationType.fromStart => SafeArea(
                      child: Container(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 30),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              padding: const EdgeInsets.all(12),
                              decoration: ShapeDecoration(
                                  color:
                                      whitePure(context).withValues(alpha: .1),
                                  shape: SmoothRectangleBorder(
                                    borderRadius:
                                        SmoothBorderRadius(cornerRadius: 15),
                                  )),
                              child: Image.asset(AssetRes.icLanguage),
                            ),
                            const SizedBox(width: 18),
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
                                      color: whitePure(context),
                                      opacity: .5),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            )),
                          ],
                        ),
                      ),
                    ),
                  LanguageNavigationType.fromSetting => CustomAppBar(
                      title: LKey.languages.tr,
                      titleStyle: TextStyleCustom.unboundedSemiBold600(
                          fontSize: 15, color: whitePure(context)),
                      bgColor: Colors.transparent,
                      iconColor: whitePure(context)),
                },
                Expanded(
                  child: ListView.builder(
                      itemCount: controller.languages.length,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 15),
                      itemBuilder: (context, index) {
                        Language language = controller.languages[index];
                        return Obx(
                          () {
                            bool isSelected =
                                language == controller.selectedLanguage.value;
                            return GestureDetector(
                              onTap: () => controller.onLanguageChange(language),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: ShapeDecoration(
                                  shape: SmoothRectangleBorder(
                                    borderRadius: SmoothBorderRadius(cornerRadius: 10, cornerSmoothing: 1),
                                    side: isSelected
                                        ? BorderSide(color: whitePure(context))
                                        : const BorderSide(color: Colors.transparent),
                                  ),
                                  color: whitePure(context).withValues(alpha: isSelected ? .3 : .1),
                                ),
                                child: RadioListTile<Language?>(
                                    value: language,
                                    groupValue: controller.selectedLanguage.value,
                                    onChanged: controller.onLanguageChange,
                                    activeColor: whitePure(context),
                                    fillColor: WidgetStatePropertyAll(whitePure(context)),
                                    splashRadius: 0,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    dense: true,
                                    visualDensity: const VisualDensity(
                                      horizontal: VisualDensity.minimumDensity,
                                      vertical: VisualDensity.minimumDensity,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    title: Text(
                                      language.localizedTitle ?? '',
                                      style: TextStyleCustom.outFitLight300(fontSize: 14, color: whitePure(context)),
                                    ),
                                    subtitle: Text(
                                      language.title ?? '',
                                      style: TextStyleCustom.outFitMedium500(fontSize: 16, color: whitePure(context)),
                                    )),
                              ),
                            );
                          },
                        );
                      }),
                ),
                if (languageNavigationType == LanguageNavigationType.fromStart)
                  TextButtonCustom(
                    onTap: () {
                      SessionManager.instance.setBool(SessionKeys.isLanguageScreenSelect, true);
                      if ((controller.setting?.onBoarding ?? []).isEmpty) {
                        Get.off(() => const LoginScreen());
                      } else {
                        Get.off(() => const OnBoardingScreen());
                      }
                    },
                    title: LKey.continueText.tr,
                    margin: const EdgeInsets.all(15),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
