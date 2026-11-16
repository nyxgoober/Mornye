import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// Reports a two-finger tap, the touch stand-in for a right-click.
///
/// It joins the gesture arena, unlike a plain pointer [Listener]. The moment
/// the second finger lands it claims both pointers, so the row or button under
/// the fingers loses its own tap and nothing is activated besides the menu.
/// A single finger never resolves in its favor: it rejects itself on lift, so
/// ordinary taps, scrolls and drags work as before.
///
/// [onTwoFingerTap] gets the midpoint of the two touches, in the same
/// coordinate space as `details.globalPosition`, once both fingers have
/// lifted without wandering or overstaying a normal tap.
class TwoFingerTapListener extends StatelessWidget {
  const TwoFingerTapListener({
    super.key,
    required this.onTwoFingerTap,
    required this.child,
  });

  final ValueChanged<Offset> onTwoFingerTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        _TwoFingerTapRecognizer:
            GestureRecognizerFactoryWithHandlers<_TwoFingerTapRecognizer>(
              _TwoFingerTapRecognizer.new,
              (recognizer) => recognizer.onTwoFingerTap = onTwoFingerTap,
            ),
      },
      child: child,
    );
  }
}

class _TwoFingerTapRecognizer extends OneSequenceGestureRecognizer {
  _TwoFingerTapRecognizer({super.debugOwner});

  ValueChanged<Offset>? onTwoFingerTap;

  // Generous enough for two fingers landing a beat apart, tight enough that
  // it never reads as a long press or an unrelated later tap.
  static const _maxTapDuration = Duration(milliseconds: 350);

  // A tap, not a pan or a pinch: each finger may drift a little.
  static const _maxTapTravel = 18.0;

  final Map<int, Offset> _downPositions = <int, Offset>{};
  DateTime? _firstDownAt;
  Offset? _origin;
  int _liftedCount = 0;
  bool _claimed = false;
  bool _failed = false;

  bool get _expired {
    final firstDownAt = _firstDownAt;
    return firstDownAt == null ||
        DateTime.now().difference(firstDownAt) > _maxTapDuration;
  }

  @override
  bool isPointerAllowed(PointerDownEvent event) =>
      event.kind == PointerDeviceKind.touch && super.isPointerAllowed(event);

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer, event.transform);
    if (_downPositions.isEmpty) {
      _firstDownAt = DateTime.now();
      _liftedCount = 0;
      _claimed = false;
      _failed = false;
      _origin = null;
    }
    // A third finger means this was never a clean two-finger tap.
    if (_downPositions.length >= 2) {
      _failed = true;
      return;
    }
    _downPositions[event.pointer] = event.position;
    if (_downPositions.length == 2) {
      if (_expired) {
        _failed = true;
        return;
      }
      final positions = _downPositions.values.toList(growable: false);
      _origin = Offset(
        (positions[0].dx + positions[1].dx) / 2,
        (positions[0].dy + positions[1].dy) / 2,
      );
      // Win both pointers' arenas now, so the widgets under the fingers
      // get their taps rejected instead of firing when a finger lifts.
      _claimed = true;
      for (final pointer in _downPositions.keys) {
        resolvePointer(pointer, GestureDisposition.accepted);
      }
    }
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent) {
      final start = _downPositions[event.pointer];
      if (start != null && (event.position - start).distance > _maxTapTravel) {
        _failed = true;
      }
    } else if (event is PointerUpEvent) {
      if (!_claimed) {
        // One finger on its own: step aside for the normal tap or scroll.
        resolvePointer(event.pointer, GestureDisposition.rejected);
      }
      if (_downPositions.containsKey(event.pointer)) _liftedCount++;
      if (_claimed && _liftedCount == 2) {
        final origin = _origin;
        if (!_failed && !_expired && origin != null) {
          invokeCallback<void>(
            'onTwoFingerTap',
            () => onTwoFingerTap?.call(origin),
          );
        }
      }
      stopTrackingPointer(event.pointer);
    } else if (event is PointerCancelEvent) {
      _failed = true;
      stopTrackingPointer(event.pointer);
    }
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _downPositions.clear();
    _firstDownAt = null;
    _origin = null;
    _liftedCount = 0;
    _claimed = false;
    _failed = false;
  }

  @override
  void acceptGesture(int pointer) {}

  @override
  void rejectGesture(int pointer) {
    if (_claimed) return;
    _failed = true;
  }

  @override
  String get debugDescription => 'two-finger tap';
}
