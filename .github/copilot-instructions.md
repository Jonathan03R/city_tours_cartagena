# AI Coding Agent Instructions for City Tours Cartagena

Welcome to the City Tours Cartagena project! This document provides essential guidelines for AI coding agents to be productive in this codebase. Follow these instructions to understand the architecture, workflows, and conventions specific to this project.

## Project Overview
- **Framework**: This is a Flutter project designed for mobile applications.
- **Purpose**: The app provides city tours for Cartagena, integrating Firebase services for analytics, authentication, and notifications.
- **Key Directories**:
  - `lib/`: Contains the main application code.
  - `assets/`: Stores static resources like images and data files.
  - `functions-cititours/`: Backend Firebase functions.
  - `android/` and `ios/`: Platform-specific configurations.

## Architecture
- **Frontend**: Built with Flutter, the app follows a modular structure with directories like `auth/`, `core/`, and `screens/`.
- **Backend**: Firebase Functions handle server-side logic, located in `functions-cititours/`.
- **Data Flow**: Data is fetched from Firebase Firestore and processed in `lib/core/services/`.
- **State Management**: Ensure to follow the existing state management pattern (e.g., Provider, Riverpod, or Bloc).

## Developer Workflows
- **Building the App**:
  - Run `flutter pub get` to fetch dependencies.
  - Use `flutter run` to start the app on a connected device.
- **Testing**:
  - Tests are located in `test/`.
  - Run `flutter test` to execute unit tests.
- **Firebase Setup**:
  - Ensure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are correctly configured.

## Project-Specific Conventions
- **File Naming**: Use snake_case for file names (e.g., `metrics_service.dart`).
- **Service Layer**: Place reusable logic in `lib/core/services/`.
- **UI Components**: Keep widgets modular and reusable, stored in `lib/screens/`.
- **Assets**: Reference assets in `pubspec.yaml` under the `assets` section.

## Integration Points
- **Firebase**:
  - Authentication: `firebase_auth`.
  - Notifications: `firebase_messaging`.
  - Analytics: `firebase_analytics`.
- **External Packages**:
  - `flutter_local_notifications`: For local notifications.
  - `connectivity_plus`: For network status checks.

## Examples
- **Service Example**: `lib/core/services/metrics_service.dart` demonstrates how to structure a service.
- **Widget Example**: Check `lib/screens/` for reusable UI components.

## Notes for AI Agents
- Follow the existing patterns and conventions strictly.
- Avoid introducing new dependencies without approval.
- Ensure all changes are tested and do not break existing functionality.

For any unclear sections or additional guidance, consult the project maintainers.
