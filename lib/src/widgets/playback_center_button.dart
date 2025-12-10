import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/widgets/controls/video_play_pause_button.dart';
import 'package:omni_video_player/src/utils/animated_fade_visibility.dart';

/// A play/pause button that fades in or out automatically based on playback state.
///
/// This widget provides a responsive play/pause button that:
/// - Fades out when the video is buffering or controls are hidden.
/// - Optionally shows a replay button when playback finishes.
/// - Automatically respects fullscreen and UI visibility options.
/// - Uses [AnimatedFadeVisibility] to transition smoothly between visible states.
///
/// Typical use case:
/// ```dart
/// AutoHidePlayPauseButton(
///   visible: controller.isControlsVisible,
///   controller: controller,
///   configuration: config,
///   callbacks: callbacks,
/// )
/// ```
class PlaybackCenterButton extends StatefulWidget {
  /// Whether the button should currently be visible.
  ///
  /// Visibility is further constrained by the playback state and configuration.
  final bool visible;

  /// Controller that manages playback actions and state.
  final OmniPlaybackController controller;

  /// Player behavior and appearance configuration.
  final VideoPlayerConfiguration configuration;

  /// Callback handlers for player events.
  final VideoPlayerCallbacks callbacks;

  const PlaybackCenterButton({
    super.key,
    required this.visible,
    required this.controller,
    required this.configuration,
    required this.callbacks,
  });

  @override
  State<PlaybackCenterButton> createState() => _PlaybackCenterButtonState();
}

class _PlaybackCenterButtonState extends State<PlaybackCenterButton> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_update);
  }

  void _update() {
    setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_update);
    super.dispose();
  }

  bool get _shouldShowButton {
    final uiOptions = widget.configuration.playerUIVisibilityOptions;
    return widget.visible &&
        !widget.controller.isSeeking &&
        (widget.controller.isFullScreen ||
            uiOptions.showPlayPauseReplayButton) &&
        !(widget.controller.isBuffering ||
            (widget.controller.isFinished && !uiOptions.showReplayButton));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedFadeVisibility(
      visible: _shouldShowButton,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: VideoPlayPauseButton(
        controller: widget.controller,
        showReplayButton:
            widget.configuration.playerUIVisibilityOptions.showReplayButton,
        autoMuteOnStart:
            widget.configuration.videoSourceConfiguration.autoMuteOnStart,
        onReplay: widget.callbacks.onReplay,
        onFinished: widget.callbacks.onFinished,
      ),
    );
  }
}
