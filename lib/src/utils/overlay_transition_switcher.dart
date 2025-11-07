import 'package:flutter/material.dart';

/// A widget that smoothly transitions between child widgets using a fade overlay effect.
///
/// Unlike a standard [AnimatedSwitcher], this version layers the new child
/// *on top* of the old one, fading out the previous widget while the new one
/// appears immediately. This creates a "fade-over" effect instead of a crossfade.
///
/// It is particularly useful for:
/// - Overlay UI transitions (e.g., player controls, tooltips)
/// - Replacing widgets where the new content should appear instantly
///   while the old content disappears smoothly
///
/// Example:
/// ```dart
/// FadeOverlaySwitcher(
///   duration: Duration(milliseconds: 400),
///   child: isPlaying
///       ? Icon(Icons.pause, key: ValueKey('pause'), color: Colors.white)
///       : Icon(Icons.play_arrow, key: ValueKey('play'), color: Colors.white),
/// )
/// ```
class OverlayTransitionSwitcher extends StatelessWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The duration of the fade animation.
  final Duration duration;

  /// How to size the stack that holds the children.
  final StackFit fit;

  /// Creates a [FadeOverlaySwitcher] that animates fading over
  /// between children with a fade-over effect.
  const OverlayTransitionSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.fit = StackFit.loose,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      switchOutCurve: CeilCurve(),
      switchInCurve: Curves.ease,
      reverseDuration: duration,
      duration: duration,
      child: child,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.center,
        fit: fit,
        children: <Widget>[
          ...previousChildren,
          if (currentChild != null) currentChild,
        ],
      ),
    );
  }
}

/// A curve that rounds up every value to 1 once t > 0.
///
/// This creates a step function effect where the animation
/// value instantly jumps to 1, causing an immediate opacity drop
/// instead of a gradual fade.
class CeilCurve extends Curve {
  @override
  double transformInternal(double t) {
    return t.ceil().toDouble();
  }
}
