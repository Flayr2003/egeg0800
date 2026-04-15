# Flayr - Short Video App - PRD

## Original Problem Statement
User needs:
1. SHA-1 certificate fingerprint from APK signing certificate for Firebase Google Sign-In
2. Build release APK with proper signing
3. Push changes to GitHub

## Architecture
- Flutter mobile app (Android/iOS)
- Firebase backend (Auth, Firestore, Messaging, Ads)
- Google Sign-In, Apple Sign-In
- Google Maps, Google ML Kit, DeepAR
- RevenueCat for purchases

## What's Been Implemented (April 15, 2026)

### Session 1 - SHA-1 & Release Setup
- Created release keystore: `android/app/flayr-release-key.jks`
  - Alias: flayr-key
  - Password: flayr2024release
  - Validity: 10,000 days
- Created `android/key.properties` for Gradle signing config
- Updated `android/app/google-services.json` from Firebase
- Extracted SHA-1: `40:FB:94:73:AB:32:40:E3:1E:94:5B:3D:16:C0:21:41:B7:E6:50:20`
- Extracted SHA-256: `91:6F:03:2B:E8:89:F4:3D:58:0A:49:93:13:3B:82:5C:F0:59:A7:6A:56:06:8C:7F:0C:51:A6:13:6B:3D:34:2F`
- APK build attempted but failed due to cloud environment memory limit (2GB)

## Prioritized Backlog
- P0: Build release APK locally & test Google Sign-In
- P1: Add debug SHA-1 to Firebase for dev testing
- P1: Set up GitHub Actions for CI/CD APK builds
- P2: Test Firebase Messaging end-to-end
- P2: Test all native plugins (DeepAR, video_compress, etc.)

## Next Tasks
- User to Save to GitHub, pull locally, and build APK
- Test Google Sign-In after APK build
- Consider adding GitHub Actions workflow for automated builds
