import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/seek_bar.dart';
import 'package:omni_video_player/src/widgets/indicators/live_status_indicator.dart';

/// A widget that displays the seek bar and playback timing information
/// for a video, with support for both live and non-live streams.
///
/// [VideoSeekBar] automatically switches between a seekable progress bar
/// and a live status indicator depending on the stream type and player state.
class VideoSeekBar extends StatelessWidget {
  /// Creates a video progress bar.
  const VideoSeekBar({
    super.key,
    required this.controller,
    required this.liveLabel,
    required this.showCurrentTime,
    required this.showDurationTime,
    required this.showRemainingTime,
    required this.showLiveIndicator,
    required this.showSeekBar,
    required this.allowSeeking,
    required this.customTimeDisplay,
    required this.customSeekBar,
    required this.customDurationDisplay,
    required this.customRemainingTimeDisplay,
    required this.onSeekStart,
  });

  /// Controls the playback and provides timing information.
  final OmniPlaybackController controller;

  /// Label to show when the video is live.
  final String liveLabel;

  /// Whether to show the current playback time.
  final bool showCurrentTime;

  /// Whether to show the total duration of the video.
  final bool showDurationTime;

  /// Whether to show the remaining time until the end.
  final bool showRemainingTime;

  /// Whether to show the live status indicator (only applies to live streams).
  final bool showLiveIndicator;

  /// Whether to show the seek bar (only applies to non-live streams).
  final bool showSeekBar;

  /// Whether the user is allowed to seek manually.
  final bool allowSeeking;

  /// A custom widget to override the default time indicator (e.g. current time / total duration).
  final Widget? customTimeDisplay;

  /// A custom seek bar widget to override the default slider behavior.
  final Widget? customSeekBar;

  final Widget? customDurationDisplay;

  final Widget? customRemainingTimeDisplay;

  final void Function(Duration)? onSeekStart;

  @override
  Widget build(BuildContext context) {
    return controller.isLive
        ? (showLiveIndicator ? _buildLiveIndicator() : const SizedBox.shrink())
        : (showSeekBar
            ? AnimatedBuilder(
                animation: controller,
                builder: (BuildContext context, Widget? child) {
                  return _buildSeekBar();
                })
            : const SizedBox.shrink());
  }

  /// Builds the UI for live stream playback indicator.
  Widget _buildLiveIndicator() => Align(
        alignment: Alignment.centerLeft,
        child: LiveStatusIndicator(label: liveLabel),
      );

  /// Builds the UI for the interactive seek bar.
  Widget _buildSeekBar() =>
      customSeekBar ??
      SeekBar(
        position: controller.currentPosition,
        duration: controller.duration,
        bufferedPosition: _findClosestBufferedEnd(),
        showRemainingTime: showRemainingTime,
        onChangeStart: (_) {
          if (!controller.isSeeking) {
            controller.wasPlayingBeforeSeek = controller.isPlaying;
          }
          if (controller.isReady) controller.isSeeking = true;
          onSeekStart?.call(controller.currentPosition);
        },
        onChangeEnd: (value) {
          controller.seekTo(value);
        },
        onChanged: (_) {
          if (controller.isReady) controller.isSeeking = true;
        },
        showCurrentTime: showCurrentTime,
        showDurationTime: showDurationTime,
        customTimeDisplay: customTimeDisplay,
        controller: controller,
        allowSeeking: allowSeeking,
        customDurationDisplay: customDurationDisplay,
        customRemainingTimeDisplay: customRemainingTimeDisplay,
      );

  /// Returns the end of the buffered range closest to the current position.
  Duration? _findClosestBufferedEnd() {
    if (controller.buffered.isEmpty) return null;
    return controller.buffered
        .reduce(
          (a, b) => _timeDifference(a.start) < _timeDifference(b.start) ? a : b,
        )
        .end;
  }

  /// Calculates the absolute difference from the current position.
  int _timeDifference(Duration start) =>
      (start.inMilliseconds - controller.currentPosition.inMilliseconds).abs();
}
