import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:mornye/utils/android_tv.dart';
import 'package:mornye/utils/desktop_platform.dart';

/// The system bar and cutout insets the desktop layout must keep clear of.
///
/// A desktop window has no system bars, so desktop layers are written to
/// fill their bounds. On Android the same layers draw edge to edge under the
/// status and navigation bars, so each layer pads its content by this while
/// its background keeps filling the screen. Zero on real desktops and on TV,
/// which has its own SafeArea.
EdgeInsets desktopSystemInsets(BuildContext context) =>
    Platform.isAndroid && isDesktopUi && !isAndroidTv
    ? MediaQuery.paddingOf(context)
    : EdgeInsets.zero;

/// Pads [child] by [desktopSystemInsets], and zeroes the insets below it so a
/// nested SafeArea does not pad a second time. The fill behind the padding is
/// [background], so the strip under the system bars matches the layer.
class DesktopInsetLayer extends StatelessWidget {
  const DesktopInsetLayer({
    super.key,
    required this.background,
    required this.child,
  });

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final insets = desktopSystemInsets(context);
    if (insets == EdgeInsets.zero) return child;
    final mediaQuery = MediaQuery.of(context);
    return ColoredBox(
      color: background,
      child: Padding(
        padding: insets,
        child: MediaQuery(
          data: mediaQuery.copyWith(
            padding: EdgeInsets.zero,
            viewPadding: EdgeInsets.zero,
          ),
          child: child,
        ),
      ),
    );
  }
}
