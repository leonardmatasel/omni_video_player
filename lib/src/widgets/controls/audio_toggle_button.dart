import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/widgets/controls/video_control_icon_button.dart';

/// A button that toggles between mute and unmute states in a video player.
///
/// [AudioToggleButton] listens to the current volume from [OmniPlaybackController]
/// and updates the icon accordingly. When pressed, it toggles mute/unmute and
/// optionally triggers [onAudioToggled] callback with the new mute state.
class AudioToggleButton extends StatelessWidget {
  /// Creates a mute/unmute toggle button.
  const AudioToggleButton({
    super.key,
    required this.controller,
    required this.onAudioToggled,
  });

  /// The media playback controller that manages volume and mute state.
  final OmniPlaybackController controller;

  /// Optional callback called with `true` if muted, `false` otherwise.
  final void Function(bool isMuted)? onAudioToggled;

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return VideoControlIconButton(
      onPressed: () {
        controller.toggleMute();
        onAudioToggled?.call(controller.volume == 0);
      },
      icon: controller.volume > 0 ? theme.icons.mute : theme.icons.unMute,
    );
  }
}
