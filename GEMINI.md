# ZShield Project Context

## Project Overview
ZShield is a cross-platform Flutter application acting as a VPN client. It uses V2Ray/Xray protocols under the hood and features a modern, dark-themed, glassmorphic user interface.

## Tech Stack
*   **Framework:** Flutter
*   **Language:** Dart
*   **State Management:** Riverpod (`flutter_riverpod` using v2 `Notifier` syntax)
*   **Routing:** GoRouter (`go_router`)
*   **Local Storage:** SharedPreferences (`shared_preferences`)
*   **VPN Core:** V2Ray Plus (`flutter_v2ray_plus`)
*   **Icons & Fonts:** Cupertino Icons, Material Symbols Icons, Google Fonts

## Architecture & Directory Structure
The `lib/` directory is structured logically by feature/concern:
*   **`lib/core/`**: Contains core application configuration, including routing (`router.dart`), theming (`theme/app_theme.dart`), and low-level system integrations like `XrayService`.
*   **`lib/providers/`**: Holds Riverpod state management logic (e.g., `vpn_provider.dart`, `config_provider.dart`).
*   **`lib/screens/`**: Contains the main route destinations (`dashboard_screen.dart`, `settings_screen.dart`, `routing_screen.dart`) and the app's structural shell (`layout.dart`).
*   **`lib/widgets/`**: Reusable visual components, specifically focusing on the app's aesthetic (e.g., `glass_button.dart`, `glass_panel.dart`).

## Development Conventions
*   **State Management:** Use Riverpod 2.x syntax. State controllers should extend `Notifier<T>` (or `AsyncNotifier`), and be exposed via `NotifierProvider`. Avoid legacy `StateNotifier`.
*   **Dependency Injection:** Synchronous initialization of async dependencies (like `SharedPreferences`) occurs in `main.dart` before `runApp`, and is injected by overriding values in the root `ProviderScope`.
*   **Routing:** All navigation must use `GoRouter`. The app utilizes a `ShellRoute` (via `AppLayout`) to provide a persistent UI skeleton around nested screens. Screen transitions default to a custom `FadeTransition`.
*   **UI/UX:** The primary design language involves a Dark Theme with Glassmorphism effects. Utilize the existing `GlassPanel` and `GlassButton` widgets for consistency.
*   **Immutable State:** State classes in providers (e.g., `VpnState`) should be immutable and utilize a `copyWith` method for updates.

## Building and Running
Standard Flutter CLI commands apply.

*   **Run app:** `flutter run`
*   **Clean project:** `flutter clean`
*   **Fetch dependencies:** `flutter pub get`
*   **Run tests:** `flutter test`

*Note: Since this app uses platform-specific VPN tunneling logic via `flutter_v2ray_plus`, ensure the target platform (Android, iOS, Windows, macOS, Linux) is properly configured for network extensions/VPN permissions as required by the OS.*