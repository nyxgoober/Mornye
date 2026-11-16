import 'dart:io' show Platform;

/// Overrides [isDesktopPlatform] in tests.
bool? debugDesktopPlatformOverride;

/// User opt-in, from Settings > Appearance, to render the desktop shell
/// (sidebar, window-style chrome, desktop now-playing layout, hover/desktop
/// context menus) on a large-screen Android device. `null` means "follow the
/// platform default"; resolved at startup in main.dart from the persisted
/// setting and kept here so every `isDesktopUi` call site picks it up
/// without threading it through. Only ever set on Android: on other
/// platforms the host already decides this.
bool? forceDesktopUiOverride;

// `flutter test` runs on a desktop host; tests see a mobile app unless they
// opt in through [debugDesktopPlatformOverride].
final bool _hostIsDesktop =
    !Platform.environment.containsKey('FLUTTER_TEST') &&
    (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

/// True only when the app runs on a Windows, Linux or macOS host.
///
/// Gates everything tied to the real platform: the Rust FFI backend, the FFI
/// sqlite factory, the desktop playback engine, window and drop-target
/// channels, ffmpeg runner, link host role and so on. Never affected by
/// [forceDesktopUiOverride].
bool get isDesktopPlatform => debugDesktopPlatformOverride ?? _hostIsDesktop;

/// True when the desktop layout should be drawn: on a desktop host, or on
/// Android when the user turned on "Use desktop layout". Use this only for
/// layout and styling; behaviour that needs a desktop host uses
/// [isDesktopPlatform].
bool get isDesktopUi =>
    debugDesktopPlatformOverride ?? forceDesktopUiOverride ?? _hostIsDesktop;
