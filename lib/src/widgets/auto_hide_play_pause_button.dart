import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/widgets/controls/video_play_pause_button.dart';
import 'package:omni_video_player/src/widgets/fade_visibility.dart';

/// A play/pause button widget that automatically hides itself based on playback state.
///
/// This widget displays the video play/pause button with optional replay functionality,
/// and manages its visibility with a fade animation. It automatically hides when
/// the video is buffering or finished (depending on settings).
///
/// The button’s visibility is controlled by the [isVisible] flag, but it will also
/// be hidden automatically while the video is buffering or when the video is finished
/// and replay button is disabled (for non-live videos).
///
/// It forwards playback control and replay callbacks to the internal [VideoPlayPauseButton].
class AutoHidePlayPauseButton extends StatelessWidget {
  /// Whether the button should be visible (subject to additional internal conditions).
  final bool isVisible;

  /// Controller managing media playback state and actions.
  final OmniPlaybackController controller;

  /// Callbacks for player events such as replay.
  final VideoPlayerCallbacks callbacks;

  /// Configuration options for player behavior and appearance.
  final VideoPlayerConfiguration options;

  /// Creates an auto-hiding play/pause button with optional replay support.
  const AutoHidePlayPauseButton({
    super.key,
    required this.isVisible,
    required this.controller,
    required this.options,
    required this.callbacks,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        return FadeVisibility(
          isVisible: isVisible,
          child: VideoPlayPauseButton(
            controller: controller,
            showReplayButton:
                options.playerUIVisibilityOptions.showReplayButton,
            autoMuteOnStart: options.videoSourceConfiguration.autoMuteOnStart,
          ),
        );
      },
    );
  }
}
