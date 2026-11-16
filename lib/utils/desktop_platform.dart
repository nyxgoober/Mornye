import 'dart:io' show Platform;

/// Overrides [isDesktopPlatform] in tests.
bool? debugDesktopPlatformOverride;

/// User opt-in, from Settings > Appearance, to render the desktop shell
/// (sidebar, window-style chrome, desktop now-playing layout, hover/desktop
/// context menus) on a large-screen Android device. `null` means "follow the
/// platform default"; resolved at startup in main.dart from the persisted
/// setting and kept here so every `isDesktopPlatform` call site picks it up
/// without threading it through. Only ever set on Android: on other
/// platforms the host already decides this.
bool? forceDesktopUiOverride;

// `flutter test` runs on a desktop host; tests see a mobile app unless they
// opt in through [debugDesktopPlatformOverride].
final bool _hostIsDesktop =
    !Platform.environment.containsKey('FLUTTER_TEST') &&
    (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// True in Windows, Linux and macOS builds of the app, or on Android when
/// the user has turned on "Use desktop layout" for this device.
bool get isDesktopPlatform =>
    debugDesktopPlatformOverride ?? forceDesktopUiOverride ?? _hostIsDesktop;
