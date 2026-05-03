# Aduane Intelligence — Frontend

## Table of Contents

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Installation](#installation)
  - [Firebase Setup (Mobile)](#firebase-setup-mobile)
  - [Environment Variables](#environment-variables)
  - [Running Locally](#running-locally)
  - [Building for Production](#building-for-production)
- [Project Structure](#project-structure)
- [Available Scripts](#available-scripts)
- [API Integration](#api-integration)
- [Troubleshooting](#troubleshooting)

---

## Project Overview

Aduane Intelligence (Capstone Frontend) is a cross-platform mobile application designed to seamlessly track daily health goals, log meals, and monitor weekly progress.

The application offers a robust suite of features including:

- **Authentication & Onboarding**: Secure login, registration, OTP verification, and profile setup.
- **Health Tracking**: Interfaces for logging meals, adding workouts, and viewing daily goal completions.
- **Analytics**: Weekly insights and dynamic progress cards.
- **Interactive Chat**: A built-in chat screen interface for real-time interaction.

**Live Demo:** `[Insert TestFlight / Google Play Testing Link Here]`

---

## Tech Stack

| Layer                         | Technology                                                                      |
| ----------------------------- | ------------------------------------------------------------------------------- |
| Core Framework                | Flutter                                                                         |
| Language                      | Dart                                                                            |
| Styling                       | Flutter Material UI / Custom Themes (`app_colors.dart`)                         |
| State Management              | Custom App State (`app_state.dart`)                                             |
| Routing Library               | Flutter Navigator 2.0                                                           |
| HTTP Client                   | Custom API Service & Network Helper (`api_service.dart`, `network_helper.dart`) |
| Build Tool                    | Flutter CLI                                                                     |
| Testing Framework             | `flutter_test` for unit/widget testing                                          |
| Linting/Formatting            | Flutter Lints (`analysis_options.yaml`)                                         |
| Package Manager               | Pub (`pubspec.yaml`)                                                            |
| Notable Third-Party Libraries | Firebase (`firebase.json`, `firebase_options.dart`)                             |

---

## Prerequisites

Ensure your development environment meets the following requirements before proceeding:

- **Flutter SDK**: `^3.10.0` or higher
- **Dart SDK**: `^3.0.0` or higher
- **Package manager**: `pub` (bundled with Flutter)
- **IDEs**: VS Code (with Flutter extension) or Android Studio
- **System Requirements**: Xcode (for iOS builds) and Android Studio (for Android builds)

---

## Getting Started

### Installation

Clone the repository and install the required dependencies:

```bash
# Clone the repository
git clone https://github.com/alappiah/Aduane_Intelligence.git

# Navigate into the directory
cd aduane_intelligence

# Install dependencies
flutter pub get
```

### Firebase Setup (Mobile)

1. In Firebase Console, add an **Android app** using your package name
2. Download `google-services.json` and place it in `android/app/`
3. Add an **iOS app**, download `GoogleService-Info.plist`, and link it in Xcode under the Runner target

### Environment Variables

To connect to the backend and third-party services, you need to configure your environment. Create a `.env` file in the root directory and add the following:

```env
# API Configuration
API_BASE_URL=https://api.aduane-intelligence.com/v1

# General Firebase Config
FIREBASE_PROJECT_ID=aduane-intelligence
FIREBASE_SENDER_ID=your_sender_id_here

# Web Config
FIREBASE_WEB_API_KEY=your_web_api_key_here
FIREBASE_WEB_APP_ID=your_web_app_id_here
FIREBASE_WEB_MEASUREMENT_ID=your_web_measurement_id_here

# Android Config
FIREBASE_ANDROID_API_KEY=your_android_api_key_here
FIREBASE_ANDROID_APP_ID=your_android_app_id_here

# iOS / macOS Config
FIREBASE_IOS_API_KEY=your_ios_api_key_here
FIREBASE_IOS_APP_ID=your_ios_app_id_here
FIREBASE_IOS_BUNDLE_ID=your_ios_bundle_id_here

# Windows Config (Uses Web API Key by default)
FIREBASE_WINDOWS_APP_ID=your_windows_app_id_here
FIREBASE_WINDOWS_MEASUREMENT_ID=your_windows_measurement_id_here
```

### Running Locally

To start the application on an emulator or connected device:

```bash
# Run on the default connected device
flutter run
```

The local development environment will hot-reload automatically upon saving changes.

### Building for Production

To generate release builds for app stores, the output binaries will be placed in `build/app/outputs/`:

```bash
# Build Android App Bundle (AAB) for Google Play
flutter build appbundle --release

# Build iOS Archive (IPA) for App Store
flutter build ipa --release
```

---

## Project Structure

```
lib/
├── main.dart                  # Application entry point
├── firebase_options.dart      # Auto-generated Firebase configuration
├── models/                    # Data models (e.g., weekly_stats.dart)
├── screens/                   # Core application views (Dashboard, Chat, Auth)
├── services/                  # Business logic, API calls, and Notifications
├── state/                     # Global state management
├── theme/                     # Global styles and colors
└── widgets/                   # Reusable UI components (Cards, Sheets, Buttons)
```

---

## Available Scripts

Run these commands using the Flutter CLI:

| Command             | Description                                                     |
| ------------------- | --------------------------------------------------------------- |
| `flutter pub get`   | Installs all dependencies listed in `pubspec.yaml`.             |
| `flutter run`       | Starts the app in debug mode with Hot Reload enabled.           |
| `flutter clean`     | Clears the build cache and deletes the `build/` directory.      |
| `flutter analyze`   | Runs the linter using rules defined in `analysis_options.yaml`. |
| `flutter test`      | Executes the testing suite.                                     |
| `flutter build apk` | Generates a standalone Android APK for manual testing.          |

---

## API Integration

- **Base URL configuration**: Managed via `NetworkHelper` and environment variables.
- **Connection mechanism**: The frontend connects to the backend REST API via the custom `ApiService` (`lib/services/api_service.dart`).
- **Backend Repository**: https://github.com/alappiah/Aduane_Intelligence_Backend.git

---

## Troubleshooting

**Gradle Build Fails on Android**

> Solution: Run `flutter clean`, then navigate to the `android/` directory and run `./gradlew clean`. Return to the root and run `flutter run`.

**Firebase Initialization Error**

> Solution: Ensure `google-services.json` is placed correctly in `android/app/` and `GoogleService-Info.plist` is properly linked in Xcode.

**Dependencies not resolving**

> Solution: Delete the `pubspec.lock` file and run `flutter pub get` to force a fresh resolution of packages.

**Hot Reload is not working**

> Solution: Ensure you haven't drastically changed the app's `main()` initialization or state structure. Perform a full restart (`Shift + R`) instead of a hot reload.

---
