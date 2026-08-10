import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

import 'video_control_icon_button.dart';

/// A toggle button to mute or unmute the audio in a video player.
///
/// The [AudioToggleButton] reflects the current volume state managed by a
/// [OmniPlaybackController]. When tapped, it toggles the mute state:
/// if the audio is currently on, it will be muted; if muted, it will be unmuted.
/// The button icon updates dynamically to indicate the current state.
///
/// Optionally, a [onAudioToggled] callback can be provided to receive updates
/// when the mute state changes.
///
/// {@tool snippet}
/// Example usage:
/// ```dart
/// AudioToggleButton(
///   controller: myPlaybackController,
///   onAudioToggled: (isMuted) {
///     print('Audio is muted: $isMuted');
///   },
/// )
/// ```
/// {@end-tool}
class AudioToggleButton extends StatelessWidget {
  /// Creates an [AudioToggleButton].
  ///
  /// The [controller] must not be null and is used to read and change the
  /// current volume state.
  ///
  /// The [onAudioToggled] callback is optional and will be invoked with the
  /// new mute state: `true` if muted, `false` otherwise.
  const AudioToggleButton({
    super.key,
    required this.controller,
    required this.onAudioToggled,
  });

  /// Controller that manages audio playback and mute state.
  final OmniPlaybackController controller;

  /// Callback triggered when the audio mute state is toggled.
  ///
  /// Receives `true` if the audio is now muted, or `false` if unmuted.
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
