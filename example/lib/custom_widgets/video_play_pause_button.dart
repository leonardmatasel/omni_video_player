import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

/// A play/pause toggle button with animated transitions and optional replay support.
///
/// The [VideoPlayPauseButton] displays an animated play/pause icon that reflects the
/// current playback state managed by the given [OmniPlaybackController].
///
/// When playback is finished and the content is not a live stream, a replay icon can
/// be shown if [showReplayButton] is `true`. Tapping the replay icon restarts playback.
/// The button also supports automatically muting the video when starting for the first time
/// via [autoMuteOnStart].
///
/// The appearance of icons and background is themed using [OmniVideoPlayerTheme].
///
/// {@tool snippet}
/// Example usage:
/// ```dart
/// VideoPlayPauseButton(
///   controller: myPlaybackController,
///   autoMuteOnStart: true,
///   showReplayButton: true,
/// )
/// ```
/// {@end-tool}
class VideoPlayPauseButton extends StatefulWidget {
  /// Creates a [VideoPlayPauseButton].
  ///
  /// Requires a [controller] to manage playback state,
  /// [autoMuteOnStart] to indicate if the video should auto-mute on first play,
  /// and [showReplayButton] to show a replay icon when the video ends.
  const VideoPlayPauseButton({
    super.key,
    required this.controller,
    required this.autoMuteOnStart,
    required this.showReplayButton,
  });

  /// The playback controller that provides current state and actions.
  final OmniPlaybackController controller;

  /// If `true`, the video will be muted when started for the first time.
  final bool autoMuteOnStart;

  /// If `true`, a replay button is shown when the video is finished.
  final bool showReplayButton;

  @override
  State<VideoPlayPauseButton> createState() => _VideoPlayPauseButtonState();
}

class _VideoPlayPauseButtonState extends State<VideoPlayPauseButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconAnimationController;

  OmniPlaybackController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _iconAnimationController = AnimationController(
      vsync: this,
      value: controller.isPlaying ? 1 : 0,
      duration: const Duration(milliseconds: 400),
    );
    controller.addListener(_updateIconAnimation);
  }

  /// Updates the animated icon based on playback state.
  void _updateIconAnimation() {
    if (!mounted) return;

    setState(() {
      if (controller.isPlaying) {
        _iconAnimationController.forward();
      } else {
        _iconAnimationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    controller.removeListener(_updateIconAnimation);
    _iconAnimationController.dispose();
    super.dispose();
  }

  /// Handles tap interaction and determines playback behavior:
  /// - Starts playback and mutes if it's the first play and [autoMuteOnStart] is `true`.
  /// - Replays the video if it has finished and [showReplayButton] is `true`.
  /// - Otherwise, toggles between play and pause.
  void _handleTap() {
    if (!controller.hasStarted && widget.autoMuteOnStart) {
      controller.mute();
      controller.play();
    } else if (controller.isFinished) {
      if (!widget.showReplayButton) return;
      controller.replay();
    } else {
      controller.isPlaying ? controller.pause() : controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return Center(
      child: InkWell(
        onTap: _handleTap,
        borderRadius: BorderRadius.circular(200),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colors.playPauseBackground.withAlpha(100),
            borderRadius: BorderRadius.circular(200),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.fastOutSlowIn,
            transitionBuilder:
                (child, animation) =>
                    FadeTransition(opacity: animation, child: child),
            child:
                controller.isFinished
                    ? widget.showReplayButton
                        ? Icon(
                          theme.icons.replay,
                          key: const ValueKey('replay'),
                          color:
                              theme.colors.playPauseIcon ?? theme.colors.icon,
                          size: 32,
                        )
                        : null
                    : AnimatedIcon(
                      key: const ValueKey('play_pause'),
                      icon: theme.icons.playPause,
                      progress: _iconAnimationController,
                      color: theme.colors.playPauseIcon ?? theme.colors.icon,
                      size: 32,
                    ),
          ),
        ),
      ),
    );
  }
}
