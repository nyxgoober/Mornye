import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mornye/providers/settings_provider.dart';

/// Hides what an upcoming queue row shows, so the next songs stay a surprise.
/// Active only while Settings > Playback > Hide upcoming songs is on and
/// [hidden] is true; otherwise it returns [child] untouched.
///
/// [grayscale] also drains the color, for artwork, where a blurred cover can
/// still give the album away by its palette.
class QueueSpoilerShield extends ConsumerWidget {
  const QueueSpoilerShield({
    super.key,
    required this.child,
    this.hidden = true,
    this.grayscale = false,
    this.sigma = 10,
  });

  final Widget child;
  final bool hidden;
  final bool grayscale;
  final double sigma;

  // Rec. 709 luma, no alpha change.
  static const _gray = ColorFilter.matrix(<double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      settingsProvider.select((s) => s.hideQueueSpoilers),
    );
    if (!enabled || !hidden) return child;
    Widget shielded = ImageFiltered(
      imageFilter: ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.decal,
      ),
      child: child,
    );
    if (grayscale) {
      shielded = ColorFiltered(colorFilter: _gray, child: shielded);
    }
    // Screen readers must not read out what the blur hides.
    return ExcludeSemantics(child: ClipRect(child: shielded));
  }
}
