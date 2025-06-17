import 'package:flutter/material.dart';

/// A widget that smoothly fades its child in and out based on a visibility flag.
///
/// When [isVisible] is true, the child is fully visible and interactive.
/// When false, the child fades out and becomes non-interactive (ignores pointer events).
///
/// This widget is useful for toggling UI elements with a fade animation
/// while preventing interaction when invisible.
class FadeVisibility extends StatelessWidget {
  /// Whether the child should be visible.
  final bool isVisible;

  /// The widget to show or hide.
  final Widget child;

  const FadeVisibility({
    super.key,
    required this.isVisible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1 : 0,
      curve: Curves.ease,
      duration: const Duration(milliseconds: 300),
      child: IgnorePointer(ignoring: !isVisible, child: child),
    );
  }
}
