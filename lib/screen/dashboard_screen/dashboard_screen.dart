import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proste_indexed_stack/proste_indexed_stack.dart';
import 'package:flayr/common/widget/banner_ads_custom.dart';
import 'package:flayr/model/user_model/user_model.dart';
import 'package:flayr/screen/dashboard_screen/dashboard_screen_controller.dart';
import 'package:flayr/screen/explore_screen/explore_screen.dart';
import 'package:flayr/screen/feed_screen/feed_screen.dart';
import 'package:flayr/screen/home_screen/home_screen.dart';
import 'package:flayr/screen/live_stream/live_stream_search_screen/live_stream_search_screen.dart';
import 'package:flayr/screen/message_screen/message_screen.dart';
import 'package:flayr/screen/profile_screen/profile_screen.dart';
import 'package:flayr/utilities/style_res.dart';
import 'package:flayr/utilities/text_style_custom.dart';
import 'package:flayr/utilities/theme_res.dart';

class DashboardScreen extends StatelessWidget {
  final User? myUser;

  const DashboardScreen({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DashboardScreenController());
    return Scaffold(
      backgroundColor: scaffoldBackgroundColor(context),
      resizeToAvoidBottomInset: true,
      body: Obx(() {
        return Column(
          children: [
            Expanded(
              child: ProsteIndexedStack(
                index: controller.selectedPageIndex.value,
                children: [
                  IndexedStackChild(
                      child: MainHomeTab(myUser: myUser), preload: true),
                  IndexedStackChild(child: const VideoReelsTab(), preload: true),
                  IndexedStackChild(
                      child: const LiveStreamSearchScreen(), preload: true),
                  IndexedStackChild(child: const ExploreScreen(), preload: true),
                  IndexedStackChild(child: const MessageScreen(), preload: true),
                  IndexedStackChild(
                    child: ProfileScreen(
                      isDashBoard: false,
                      user: myUser,
                      isTopBarVisible: false,
                    ),
                    preload: true,
                  )
                ],
              ),
            ),
            if (controller.selectedPageIndex.value != 0) const BannerAdsCustom(),
          ],
        );
      }),
      bottomNavigationBar: _buildBottomNavigationBar(context, controller),
    );
  }

  Widget _buildBottomNavigationBar(
      BuildContext context, DashboardScreenController controller) {
    return Obx(() {
      final postUpload = controller.postProgress.value;
      final isPostUploading = postUpload.uploadType != UploadType.none;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: blackPure(context),
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavigationBarTheme(
              data: NavigationBarThemeData(
                height: 64,
                backgroundColor: blackPure(context),
                indicatorColor: whitePure(context).withValues(alpha: .12),
                labelTextStyle: WidgetStatePropertyAll(
                  TextStyleCustom.outFitRegular400(
                    fontSize: 10,
                    color: whitePure(context),
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: controller.selectedPageIndex.value,
                animationDuration: const Duration(milliseconds: 250),
                labelBehavior:
                    NavigationDestinationLabelBehavior.alwaysHide,
                onDestinationSelected: controller.onChanged,
                destinations: List.generate(
                  controller.bottomIconList.length,
                  (index) => NavigationDestination(
                    label: '',
                    icon: _buildDestinationIcon(
                      context: context,
                      controller: controller,
                      index: index,
                      isSelected: false,
                    ),
                    selectedIcon: _buildDestinationIcon(
                      context: context,
                      controller: controller,
                      index: index,
                      isSelected: true,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              bottom: isPostUploading,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                height: isPostUploading ? 30 : 0,
                margin: Platform.isAndroid || !isPostUploading
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 20, top: 5),
                color: Colors.white,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 30,
                      decoration:
                          BoxDecoration(gradient: StyleRes.themeGradient),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: LayoutBuilder(builder: (context, constraints) {
                        final progress =
                            (constraints.maxWidth * postUpload.progress) / 100;
                        return AnimatedContainer(
                          height: 30,
                          width: constraints.maxWidth - progress,
                          duration: const Duration(milliseconds: 250),
                          decoration:
                              BoxDecoration(color: textDarkGrey(context)),
                        );
                      }),
                    ),
                    Align(
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (postUpload.uploadType != UploadType.error)
                            Text(
                              '${postUpload.progress.toInt()}%',
                              style: TextStyleCustom.outFitMedium500(
                                color: whitePure(context),
                                fontSize: 16,
                              ),
                            ),
                          Text(
                            ' ${postUpload.uploadType.title(postUpload.type)}',
                            style: TextStyleCustom.outFitLight300(
                              color: whitePure(context),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    });
  }

  Widget _buildDestinationIcon({
    required BuildContext context,
    required DashboardScreenController controller,
    required int index,
    required bool isSelected,
  }) {
    final navIcon = controller.bottomIconList[index];
    final scaleValue = isSelected ? controller.scaleValue.value : 1.0;

    Widget icon = AnimatedScale(
      scale: scaleValue,
      duration: const Duration(milliseconds: 250),
      child: Icon(
        isSelected ? navIcon.filled : navIcon.outlined,
        size: 25,
        color: isSelected ? whitePure(context) : textLightGrey(context),
      ),
    );

    if (index == 4) {
      icon = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          icon,
          PositionedDirectional(
            top: -6,
            end: -8,
            child: _buildUnreadBadge(controller, context),
          )
        ],
      );
    }

    return icon;
  }

  Widget _buildUnreadBadge(
      DashboardScreenController controller, BuildContext context) {
    final count = controller.unReadCount.value;
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      constraints: const BoxConstraints(minWidth: 16),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: TextStyleCustom.outFitMedium500(
          color: whitePure(context),
          fontSize: 10,
        ),
      ),
    );
  }
}

/// Primary tab shown first in bottom navigation.
class MainHomeTab extends StatelessWidget {
  final User? myUser;

  const MainHomeTab({super.key, this.myUser});

  @override
  Widget build(BuildContext context) {
    return FeedScreen(myUser: myUser);
  }
}

/// Secondary tab for short-video/reels experience.
class VideoReelsTab extends StatelessWidget {
  const VideoReelsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}

