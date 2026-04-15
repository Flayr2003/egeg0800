# Flayr - Short Video App - PRD

## Original Problem Statement
1. SHA-1 for Firebase Google Sign-In
2. Build release APK via GitHub Actions
3. Fix chat messages not delivering/delayed
4. Fix push notifications not working

## What's Been Implemented (April 15, 2026)

### Session 1 - SHA-1 & Release Setup
- Created release keystore + SHA-1 extraction

### Session 2 - GitHub Actions Fix
- Fixed key.properties path, consolidated workflows

### Session 3 - Chat & Notifications Fix
**Chat fixes:**
- Fixed `pushNotificationToUser` - was sending null data, now has fallback
- Made `_fetchOtherUser` awaited - user data ready before sending messages
- Added retry logic for Firestore message writes

**Notification fixes:**
- Added FCM token refresh listener (`onTokenRefresh`)
- Added `deviceToken` parameter to `updateUserDetails` API
- Fixed notification channel ID mismatch (AndroidManifest vs code)
- Updated channel to `flayr_chat` with `showBadge: true`
- Improved Android 13+ permission handling with status logging
- Added early return validation for empty FCM tokens
- Added response status logging for notification API calls

### Modified Files
- `lib/common/manager/firebase_notification_manager.dart` - FCM token refresh, permissions, channel fix
- `lib/common/service/api/notification_service.dart` - Better error handling, token validation
- `lib/screen/chat_screen/chat_screen_controller.dart` - Await otherUser, retry logic, notification data fix
- `lib/common/service/api/user_service.dart` - Added deviceToken parameter
- `android/app/src/main/AndroidManifest.xml` - Channel ID fix

## Backlog
- P0: Test chat + notifications on real devices
- P1: Add read receipts
- P2: Add typing indicator
- P2: Add Firebase App Distribution for beta testing
