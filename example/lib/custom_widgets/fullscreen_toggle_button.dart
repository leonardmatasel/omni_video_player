import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

import 'video_control_icon_button.dart';

/// A toggle button to enter or exit full-screen mode in a video player.
///
/// The [FullscreenToggleButton] uses a [OmniPlaybackController] to manage
/// full-screen transitions. It dynamically updates its icon to reflect the
/// current full-screen state. When pressed, it either navigates to a custom
/// full-screen page or exits full-screen mode, depending on the current state.
///
/// The [fullscreenPageBuilder] is called to build the full-screen view when
/// entering full-screen mode. The [onFullscreenToggled] callback can be used
/// to listen for changes in the full-screen state.
///
/// {@tool snippet}
/// Example usage:
/// ```dart
/// FullscreenToggleButton(
///   controller: myPlaybackController,
///   fullscreenPageBuilder: (context) => FullscreenVideoPage(),
///   onFullscreenToggled: (isFullscreen) {
///     print('Is fullscreen: $isFullscreen');
///   },
/// )
/// ```
/// {@end-tool}
class FullscreenToggleButton extends StatelessWidget {
  /// Creates a [FullscreenToggleButton].
  ///
  /// Requires a [controller] to manage the full-screen state,
  /// a [fullscreenPageBuilder] to build the full-screen UI,
  /// and an optional [onFullscreenToggled] callback.
  const FullscreenToggleButton({
    super.key,
    required this.controller,
    required this.fullscreenPageBuilder,
    required this.onFullscreenToggled,
  });

  /// The controller that manages the full-screen state and transitions.
  final OmniPlaybackController controller;

  /// Callback invoked when the full-screen state changes.
  ///
  /// Receives `true` when entering full-screen mode,
  /// and `false` when exiting.
  final void Function(bool isEnteringFullscreen)? onFullscreenToggled;

  /// Builder function that returns the widget to show in full-screen mode.
  final Widget Function(BuildContext context) fullscreenPageBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return VideoControlIconButton(
      icon:
          controller.isFullScreen
              ? theme.icons.exitFullScreen
              : theme.icons.fullScreen,
      onPressed:
          () => controller.switchFullScreenMode(
            context,
            pageBuilder: fullscreenPageBuilder,
            onToggle: onFullscreenToggled,
          ),
    );
  }
}
