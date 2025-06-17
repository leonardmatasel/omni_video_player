import 'package:flutter/material.dart';
import 'package:omni_video_player/src/widgets/fade_visibility.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A bottom-positioned control bar with a vertical gradient background
/// that smoothly appears and disappears based on visibility.
///
/// This widget is designed to overlay content near the bottom of the screen,
/// providing a dark gradient fade that helps controls stand out against
/// the video or other background content.
///
/// The gradient fades from semi-transparent black at the bottom
/// to fully transparent at the top, enhancing readability without
/// obscuring the content behind.
///
/// The [padding] parameter allows customizing the internal spacing
/// around the [child] controls.
class GradientBottomControlBar extends StatelessWidget {
  /// Whether the control bar is visible.
  final bool isVisible;

  /// The content of the control bar, usually video playback controls.
  final Widget child;

  /// Padding inside the control bar around the child.
  final EdgeInsets padding;

  final bool useSafeAreaForBottomControls;

  final bool showGradientBottomControl;

  /// Creates a gradient bottom control bar with animated visibility.
  const GradientBottomControlBar({
    super.key,
    required this.isVisible,
    required this.child,
    required this.useSafeAreaForBottomControls,
    required this.showGradientBottomControl,
    this.padding = const EdgeInsets.only(right: 8, left: 8, top: 16),
  });

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: FadeVisibility(
        isVisible: isVisible,
        child: Container(
          decoration: showGradientBottomControl
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    theme.shapes.borderRadius,
                  ),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                )
              : null,
          child: SafeArea(
            top: false,
            right: false,
            left: false,
            bottom: useSafeAreaForBottomControls,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
