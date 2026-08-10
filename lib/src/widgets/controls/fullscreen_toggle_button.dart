import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/widgets/controls/video_control_icon_button.dart';

/// A button to toggle full-screen mode for a video player.
///
/// [FullscreenToggleButton] switches between full-screen and normal modes
/// using a [OmniPlaybackController]. It updates the icon based on the current state
/// and navigates to the provided [fullscreenPageBuilder] when entering full-screen.
///
/// The [onFullscreenToggled] callback is called with `true` when entering full-screen
/// and `false` when exiting.
class FullscreenToggleButton extends StatelessWidget {
  /// Creates a fullscreen toggle button.
  const FullscreenToggleButton({
    super.key,
    required this.controller,
    required this.fullscreenPageBuilder,
    required this.onFullscreenToggled,
  });

  /// The media playback controller that manages fullscreen state.
  final OmniPlaybackController controller;

  /// A callback to notify when fullscreen mode is toggled.
  final void Function(bool isEnteringFullscreen)? onFullscreenToggled;

  /// A builder for the fullscreen player page.
  final Widget Function(BuildContext context) fullscreenPageBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    final String semanticLabel = controller.isFullScreen
        ? theme.accessibility.exitFullscreenButtonLabel
        : theme.accessibility.fullscreenButtonLabel;

    return VideoControlIconButton(
      semanticLabel: semanticLabel,
      icon: controller.isFullScreen
          ? theme.icons.exitFullScreen
          : theme.icons.fullScreen,
      onPressed: () => controller.switchFullScreenMode(
        context,
        pageBuilder: fullscreenPageBuilder,
        onToggle: onFullscreenToggled,
      ),
    );
  }
}
