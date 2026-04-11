import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flayr/common/controller/ads_controller.dart';
import 'package:flayr/common/controller/base_controller.dart';
import 'package:flayr/common/controller/firebase_firestore_controller.dart';
import 'package:flayr/common/manager/firebase_notification_manager.dart';
import 'package:flayr/common/manager/logger.dart';
import 'package:flayr/common/manager/session_manager.dart';
import 'package:flayr/common/service/api/user_service.dart';
import 'package:flayr/common/service/subscription/subscription_manager.dart';
import 'package:flayr/languages/languages_keys.dart';
import 'package:flayr/model/chat/chat_thread.dart';
import 'package:flayr/model/general/settings_model.dart';
import 'package:flayr/model/user_model/user_model.dart';
import 'package:flayr/screen/camera_screen/camera_screen.dart';
import 'package:flayr/screen/feed_screen/feed_screen_controller.dart';
import 'package:flayr/screen/gif_sheet/gif_sheet_controller.dart';
import 'package:flayr/utilities/firebase_const.dart';
import 'package:zego_express_engine/zego_express_engine.dart';

class DashboardScreenController extends BaseController with GetSingleTickerProviderStateMixin {
  final List<DashboardNavIcon> bottomIconList = const [
    DashboardNavIcon(outlined: Icons.home_outlined, filled: Icons.home_rounded),
    DashboardNavIcon(outlined: Icons.smart_display_outlined, filled: Icons.smart_display_rounded),
    DashboardNavIcon(outlined: Icons.live_tv_outlined, filled: Icons.live_tv_rounded),
    DashboardNavIcon(outlined: Icons.explore_outlined, filled: Icons.explore_rounded),
    DashboardNavIcon(outlined: Icons.chat_bubble_outline_rounded, filled: Icons.chat_rounded),
    DashboardNavIcon(outlined: Icons.person_outline_rounded, filled: Icons.person_rounded),
  ];
  RxInt selectedPageIndex = 0.obs;
  RxDouble scaleValue = 1.0.obs;
  Function(int index)? onBottomIndexChanged;
  Rx<PostUploadingProgress> postProgress = Rx(PostUploadingProgress());
  Function(PostUploadingProgress progress) onProgress = (_) {};

  late AnimationController animationController;

  FirebaseFirestore db = FirebaseFirestore.instance;
  RxInt unReadCount = 0.obs;
  RxInt requestUnReadCount = 0.obs;

  late StreamSubscription _unReadCountSubscription;
  late Animation<double> scaleAnimation;
  User? user = SessionManager.instance.getUser();

  @override
  void onInit() {
    super.onInit();
    if (selectedPageIndex.value == 1 || selectedPageIndex.value == 2) {
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark));
    } else {
      SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(statusBarBrightness: Brightness.light));
    }
    Get.put(GifSheetController());
    Get.put(FirebaseFirestoreController());
    Get.put(AdsController());
    animationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: animationController, curve: Curves.easeInOut),
    )..addListener(() {
        scaleValue.value = scaleAnimation.value; // Update reactive scale value
      });
    onProgress = (progress) {
      postProgress.value = progress;
    };
  }

  @override
  void onReady() async {
    super.onReady();
    SubscriptionManager.shared.subscriptionListener();

    // Run below in parallel
    _createZegoEngine();
    _fetchLanguageFromUser();
    _fetchUnReadCount();
    startCacheCleanupScheduler();
    _subscribeFollowUserIds();
    updateDummyUsers();
  }

  void startCacheCleanupScheduler() {
    UserService.instance.updateLastUsedAt();
    Timer.periodic(const Duration(minutes: 15), (_) {
      UserService.instance.updateLastUsedAt();
    });
  }

  @override
  void onClose() {
    animationController.dispose();
    _unReadCountSubscription.cancel();
    super.onClose();
  }

  onChanged(int index) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarBrightness: index == 1 || index == 2 ? Brightness.dark : Brightness.light));
    if (index == 0) {
      onFeedPostScrollDown(index);
    }
    if (selectedPageIndex.value == index) return;
    HapticFeedback.lightImpact();
    onBottomIndexChanged?.call(index);
    selectedPageIndex.value = index;
    animationController
      ..reset()
      ..forward();
  }

  onFeedPostScrollDown(int index) {
    if (selectedPageIndex.value != index) return;
    if (Get.isRegistered<FeedScreenController>()) {
      final controller = Get.find<FeedScreenController>();
      if (controller.posts.isNotEmpty && !controller.isLoading.value) {
        controller.postScrollController
            .animateTo(0.0, duration: const Duration(milliseconds: 150), curve: Curves.linear);
        controller.refreshKey.currentState?.show();
      }
    }
  }

  void _fetchUnReadCount() {
    _unReadCountSubscription = db
        .collection(FirebaseConst.users)
        .doc(user?.id.toString())
        .collection(FirebaseConst.usersList)
        .where(FirebaseConst.isDeleted, isEqualTo: false)
        .withConverter(
          fromFirestore: (snapshot, _) => ChatThread.fromJson(snapshot.data()!),
          toFirestore: (value, _) => value.toJson(),
        )
        .snapshots()
        .listen((event) {
      // Calculate unread counts once per snapshot (not per docChange)
      final docs = event.docs.map((e) => e.data()).toList();

      final totalUnread = docs.where((e) => (e.msgCount ?? 0) > 0).length;

      final requestUnread = docs.where((e) => (e.msgCount ?? 0) > 0 && e.chatType == ChatType.request).length;

      unReadCount.value = totalUnread;
      requestUnReadCount.value = requestUnread;
    });
  }

  Future<void> _createZegoEngine() async {
    Setting? appSetting = SessionManager.instance.getSettings();
    int appId = int.parse(appSetting?.zegoAppId ?? '0');
    if (appId == 0) {
      return Loggers.info('The Zego App ID is not configured.');
    }
    try {
      await ZegoExpressEngine.createEngineWithProfile(
          ZegoEngineProfile(appId, ZegoScenario.Default, appSign: appSetting?.zegoAppSign));
    } on MissingPluginException catch (e) {
      Loggers.error('Create Zego Engine : ${e.message}');
    }
  }

  Future<void> _fetchLanguageFromUser() async {
    final selectedLanguage = SessionManager.instance.getLang();
    if (selectedLanguage.isEmpty) return;

    if (Get.locale?.languageCode != selectedLanguage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.updateLocale(Locale(selectedLanguage));
      });
    }
  }

  void _subscribeFollowUserIds() async {
    Future.wait([addUserInFirebase()]);
    for (int id in (user?.followingIds ?? [])) {
      // Delay slightly to avoid overloading FCM
      await Future.delayed(const Duration(milliseconds: 100));
      Future.wait([FirebaseNotificationManager.instance.subscribeToTopic(topic: '$id')]);
    }
  }

  Future addUserInFirebase() async {
    if (Get.isRegistered<FirebaseFirestoreController>()) {
      Get.find<FirebaseFirestoreController>().addUser(user);
    } else {
      Get.put(FirebaseFirestoreController()).addUser(user);
    }
  }

  void updateDummyUsers() {
    List<DummyLive> dummyLives = SessionManager.instance.getSettings()?.dummyLives ?? [];
    if (dummyLives.isNotEmpty) {
      final controller = Get.find<FirebaseFirestoreController>();
      for (var element in dummyLives) {
        controller.updateUser(element.user);
      }
    }
  }
}

class DashboardNavIcon {
  final IconData outlined;
  final IconData filled;

  const DashboardNavIcon({required this.outlined, required this.filled});
}


class PostUploadingProgress {
  final CameraScreenType type;
  final UploadType uploadType;
  final double progress;

  PostUploadingProgress({this.type = CameraScreenType.post, this.progress = 0, this.uploadType = UploadType.none});
}

enum UploadType {
  none,
  finish,
  error,
  uploading;

  String title(CameraScreenType type) {
    switch (this) {
      case UploadType.none:
        return '';
      case UploadType.finish:
        return type == CameraScreenType.post ? LKey.postUploadSuccessfully.tr : LKey.storyUploadSuccess.tr;
      case UploadType.error:
        return LKey.uploadingFailed.tr;
      case UploadType.uploading:
        return type == CameraScreenType.post ? LKey.postIsBeginUploading.tr : LKey.storyIsBeginUploading.tr;
    }
  }
}
