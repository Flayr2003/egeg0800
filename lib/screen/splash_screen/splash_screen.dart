import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flayr/common/widget/custom_shimmer_fill_text.dart';
import 'package:flayr/screen/splash_screen/splash_screen_controller.dart';
import 'package:flayr/utilities/app_res.dart';
import 'package:flayr/utilities/text_style_custom.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SplashScreenController());
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            color: const Color(0xFF000000),
          ),
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/icons/app_icon.png',
                  width: 160,
                  height: 160,
                ),
                const SizedBox(height: 24),
                CustomShimmerFillText(
                  text: AppRes.appName.toUpperCase(),
                  baseColor: Colors.white,
                  textStyle: TextStyleCustom.unboundedBlack900(
                      color: Colors.white, fontSize: 38),
                  finalColor: Colors.white,
                  shimmerColor: const Color(0xFF3E8BFF),
                ),
                const SizedBox(height: 40),
                // DIAGNOSTIC overlay - shows exactly where app is stuck
                Obx(() => Column(
                      children: [
                        Text(
                          '${controller.secondsElapsed.value}s',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            controller.debugStatus.value,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Developed by'.tr,
                    style: TextStyleCustom.outFitLight300(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFF3E8BFF), Color(0xFF7B5CFF)],
                    ).createShader(bounds),
                    child: Text(
                      'Abdullah Mabruok',
                      style: TextStyleCustom.unboundedSemiBold600(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
