# Flayr - Short Video App - PRD

## Original Problem Statement
User needs SHA-1 certificate fingerprint for Firebase Google Sign-In, build release APK, and push to GitHub.

## Architecture
- Flutter mobile app (Android/iOS)
- Firebase backend (Auth, Firestore, Messaging, Ads)
- Google Sign-In, Apple Sign-In
- CI/CD via GitHub Actions

## What's Been Implemented (April 15, 2026)

### Session 1 - SHA-1 & Release Setup
- Created release keystore: `android/app/flayr-release-key.jks`
- Created `android/key.properties` for Gradle signing config
- Updated `android/app/google-services.json` from Firebase
- SHA-1: `40:FB:94:73:AB:32:40:E3:1E:94:5B:3D:16:C0:21:41:B7:E6:50:20`

### Session 2 - GitHub Actions CI/CD
- Created `.github/workflows/build-release.yml`
- Auto builds release APK on push to main/master
- Extracts SHA-1 in build logs
- Uploads APK as downloadable artifact (30 day retention)

## Keystore Details
- Path: android/app/flayr-release-key.jks
- Alias: flayr-key
- Password: flayr2024release

## Backlog
- P0: Verify GitHub Actions build succeeds
- P1: Add Firebase App Distribution step
- P2: Add debug SHA-1 to Firebase
- P2: Add iOS build workflow
