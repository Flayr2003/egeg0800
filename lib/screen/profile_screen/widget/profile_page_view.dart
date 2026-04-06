import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flayr/common/manager/session_manager.dart';
import 'package:flayr/common/widget/no_data_widget.dart';
import 'package:flayr/common/widget/post_list.dart';
import 'package:flayr/common/widget/reel_list.dart';
import 'package:flayr/languages/languages_keys.dart';
import 'package:flayr/model/user_model/user_model.dart';
import 'package:flayr/screen/profile_screen/profile_screen_controller.dart';
import 'package:flayr/utilities/text_style_custom.dart';
import 'package:flayr/utilities/theme_res.dart';

class ProfilePageView extends StatelessWidget {
  final ProfileScreenController controller;

  const ProfilePageView({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Obx(() {
      User? user = controller.userData.value;
      bool isMe = user?.id == SessionManager.instance.getUserID();
      bool isUserNotFound = controller.isUserNotFound.value;
      bool isModerator = SessionManager.instance.isModerator.value == 1;
      return isUserNotFound
          ? NoDataView(
              title: LKey.noUserPostsTitle.tr,
              description: LKey.noUserPostsDescription.tr)
          : user?.isBlock == true
              ? const BlockUserView()
              : user?.isFreez == 1
                  ? const FreezeUser()
                  : PageView(
                      controller: controller.pageController,
                      onPageChanged: controller.onTabChanged,
                      children: [
                        ReelList(
                            reels: controller.reels,
                            isLoading: controller.isReelLoading,
                            onFetchMoreData: controller.fetchReel,
                            menus: isMe
                                ? [
                                    ContextMenuElement(
                                        title: '',
                                        onTap: controller.onPinUnpinReel),
                                    ContextMenuElement(
                                        title: LKey.delete.tr,
                                        onTap: (post) =>
                                            controller.onDeleteReel(post,
                                                isModerator: false))
                                  ]
                                : [
                                    if (isModerator)
                                      ContextMenuElement(
                                          title: LKey.delete.tr,
                                          onTap: (post) =>
                                              controller.onDeleteReel(post,
                                                  isModerator: true))
                                  ],
                            isPinShow: true),
                        PostList(
                          posts: controller.posts,
                          onFetchMoreData: controller.fetchPost,
                          isLoading: controller.isPostLoading,
                          shouldShowPinOption: true,
                          isMe: isMe,
                        )
                      ],
                    );
    }));
  }
}

class BlockUserView extends StatelessWidget {
  const BlockUserView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        LKey.youAreBlockThisUser.tr,
        style: TextStyleCustom.outFitRegular400(
            color: textLightGrey(context), fontSize: 17),
      ),
    );
  }
}

class FreezeUser extends StatelessWidget {
  const FreezeUser({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        LKey.thisUserIsFreeze.tr,
        style: TextStyleCustom.outFitRegular400(
            color: textLightGrey(context), fontSize: 17),
      ),
    );
  }
}
