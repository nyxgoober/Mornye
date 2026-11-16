import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Observes a two-finger tap without competing in Flutter's gesture arena.
///
/// This is the touch equivalent of a right-click or Ctrl+click: the gesture
/// a touch-only device (an Android tablet running the desktop shell) uses to
/// open a context menu. A plain [GestureDetector] has no built-in two-finger
/// tap recognizer, and anything built on [GestureDetector.onScaleStart]
/// would also catch an ordinary one-finger pan and could win against a
/// surrounding scrollable's drag recognizer. Raw pointer observation, like
/// [TwoFingerPinchListener], keeps one-finger scrolling and taps untouched
/// and only reports a tap once exactly two touch pointers landed together
/// and lifted again without wandering or overstaying a normal tap.
///
/// [onTwoFingerTap] fires with the midpoint of the two touches at the moment
/// the second finger went down, in the same coordinate space
/// `details.globalPosition` would use, so callers that already open a
/// context menu from a pointer position (right-click, Ctrl+click) can feed
/// it the same way.
class TwoFingerTapListener extends StatefulWidget {
  const TwoFingerTapListener({
    super.key,
    required this.onTwoFingerTap,
    required this.child,
  });

  final ValueChanged<Offset> onTwoFingerTap;
  final Widget child;

  @override
  State<TwoFingerTapListener> createState() => _TwoFingerTapListenerState();
}

class _TwoFingerTapListenerState extends State<TwoFingerTapListener> {
  // Generous enough for two fingers landing a beat apart, tight enough that
  // it never reads as a long press or an unrelated later tap.
  static const _maxTapDuration = Duration(milliseconds: 350);

  // A tap, not a pan or a pinch: each pointer may drift a little without
  // cancelling the gesture, but not scroll- or pinch-sized distances.
  static const _maxTapTravel = 18.0;

  final Map<int, Offset> _downPositions = <int, Offset>{};
  DateTime? _firstDownAt;
  Offset? _tapOrigin;
  bool _everHadTwo = false;
  bool _cancelled = false;

  bool get _expired {
    final firstDownAt = _firstDownAt;
    return firstDownAt == null ||
        DateTime.now().difference(firstDownAt) > _maxTapDuration;
  }

  void _reset() {
    _downPositions.clear();
    _firstDownAt = null;
    _tapOrigin = null;
    _everHadTwo = false;
    _cancelled = false;
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (event.kind != PointerDeviceKind.touch) return;

    // A third finger means this was never a clean two-finger tap.
    if (_downPositions.length >= 2) {
      _cancelled = true;
      return;
    }

    if (_downPositions.isEmpty) {
      _firstDownAt = DateTime.now();
      _cancelled = false;
      _everHadTwo = false;
    } else if (_expired) {
      _cancelled = true;
    }

    _downPositions[event.pointer] = event.position;

    if (_downPositions.length == 2) {
      _everHadTwo = true;
      final positions = _downPositions.values.toList(growable: false);
      _tapOrigin = Offset(
        (positions[0].dx + positions[1].dx) / 2,
        (positions[0].dy + positions[1].dy) / 2,
      );
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final start = _downPositions[event.pointer];
    if (start == null) return;
    if ((event.position - start).distance > _maxTapTravel) {
      _cancelled = true;
    }
  }

  void _handlePointerUp(PointerEvent event) {
    final wasTracked = _downPositions.remove(event.pointer) != null;
    if (!wasTracked) return;

    if (_downPositions.isEmpty) {
      final origin = _tapOrigin;
      if (_everHadTwo && !_cancelled && !_expired && origin != null) {
        widget.onTwoFingerTap(origin);
      }
      _reset();
    }
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (_downPositions.remove(event.pointer) == null) return;
    if (_downPositions.isEmpty) {
      _reset();
    } else {
      _cancelled = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: widget.child,
    );
  }
}
