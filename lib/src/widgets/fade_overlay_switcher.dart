import 'package:flutter/material.dart';

/// A widget that smoothly fades between its child widgets by
/// overlaying the new child on top of the previous one.
///
/// This is an [AnimatedSwitcher] variant that uses a custom curve
/// to make the outgoing child fade out abruptly (rounded up),
/// creating a fade-over effect rather than a cross-fade.
///
/// Useful for UI elements where you want the new content to
/// appear immediately while the old content fades out.
class FadeOverlaySwitcher extends StatelessWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The duration of the fade animation.
  final Duration duration;

  /// How to size the stack that holds the children.
  final StackFit fit;

  /// Creates a [FadeOverlaySwitcher] that animates fading over
  /// between children with a fade-over effect.
  const FadeOverlaySwitcher({
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
      layoutBuilder:
          (currentChild, previousChildren) => Stack(
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
