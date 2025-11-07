import 'package:flutter/material.dart';

/// A reusable widget that smoothly transitions its child's visibility using opacity.
///
/// When [visible] is `true`, the child fades in and remains interactive.
/// When [visible] is `false`, the child fades out and becomes non-interactive,
/// meaning it does not respond to gestures.
///
/// This widget is ideal for toggling UI layers such as playback controls,
/// toolbars, or overlay elements that should disappear smoothly.
///
/// Example:
/// ```dart
/// FadeVisibility(
///   visible: controller.isControlsVisible,
///   duration: const Duration(milliseconds: 300),
///   child: ControlsBar(),
/// )
/// ```
class AnimatedFadeVisibility extends StatelessWidget {
  /// Whether the [child] should be visible and interactive.
  final bool visible;

  /// The widget to fade in/out.
  final Widget child;

  /// The duration of the fade animation.
  ///
  /// Defaults to 300ms.
  final Duration duration;

  /// The animation curve used for the fade transition.
  ///
  /// Defaults to [Curves.easeInOut].
  final Curve curve;

  /// Optional parameter to control whether the widget should
  /// fade in immediately or wait for visibility changes.
  final bool animateOnInit;

  const AnimatedFadeVisibility({
    super.key,
    required this.visible,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.animateOnInit = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: visible ? 1.0 : 0.0,
      duration: animateOnInit && visible ? Duration.zero : duration,
      curve: curve,
      child: IgnorePointer(ignoring: !visible, child: child),
    );
  }
}
