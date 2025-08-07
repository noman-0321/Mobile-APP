# Flutter Mobile App

This is the client app for the health monitoring system.

## Requirements

- Flutter SDK: https://flutter.dev/docs/get-started/install
- Android Studio or VS Code with Flutter plugins
- Firebase project (for auth/database)

## Setup

1. Clone repo or download zip
2. Fetch packages:
    flutter pub get
3. Connect device or start emulator
4. Run app:
    flutter run

## Firebase Integration

1. Add `google-services.json` to `android/app/`
2. Add `GoogleService-Info.plist` to `ios/Runner/` (if building for iOS)
3. Ensure `Firebase.initializeApp()` is called in `main.dart`

## Building APK / AAB

- Build APK:
    flutter build apk --release

- Build App Bundle:
    flutter build appbundle --release

## Notes

- App connects to backend WebSocket at `/ws/predict`
- Displays real-time predictions and health status
