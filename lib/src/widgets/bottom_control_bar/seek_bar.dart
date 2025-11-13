import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/progress_bar_with_preview.dart';
import 'package:omni_video_player/src/widgets/indicators/playback_time_display.dart';
import 'package:omni_video_player/src/widgets/indicators/remaining_playback_time.dart';

/// A customizable seek bar widget for video playback control using a custom progress bar.
///
/// Displays a progress bar representing the current playback position within the total duration of the media,
/// with optional display of current time, duration, and remaining playback time.
///
/// Features:
/// - Shows playback progress visually with a custom progress bar and thumb.
/// - Allows seeking interaction if enabled, with callbacks for drag start, update, and drag end events.
/// - Uses the app's theme color for the active portion and thumb.
/// - Optionally displays current playback time and total duration.
/// - Optionally shows remaining playback time below the progress bar.
/// - Supports injecting custom widgets for duration and remaining time displays.
/// - Integrates with [OmniPlaybackController] to reflect current playback state.
///
/// Usage example:
/// ```dart
/// SeekBar(
///   duration: videoDuration,
///   position: currentPosition,
///   bufferedPosition: bufferedPosition,
///   onChanged: (pos) => controller.seekTo(pos),
///   onChangeStart: (pos) => // handle drag start,
///   onChangeEnd: (pos) => // handle drag end,
///   showCurrentTime: true,
///   showDurationTime: true,
///   showRemainingTime: false,
///   allowSeeking: true,
///   controller: playbackController,
/// )
/// ```
class SeekBar extends StatelessWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeStart;
  final ValueChanged<Duration>? onChangeEnd;
  final bool showRemainingTime;
  final bool showCurrentTime;
  final bool showDurationTime;
  final bool allowSeeking;
  final bool showScrubbingThumbnailPreview;
  final Widget? customDurationDisplay;
  final Widget? customRemainingTimeDisplay;
  final Widget? customTimeDisplay;
  final OmniPlaybackController controller;

  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.showRemainingTime,
    required this.showCurrentTime,
    required this.showDurationTime,
    required this.customTimeDisplay,
    required this.controller,
    required this.allowSeeking,
    required this.showScrubbingThumbnailPreview,
    required this.customDurationDisplay,
    required this.customRemainingTimeDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          showCurrentTime || showDurationTime
              ? Align(
                  alignment: Alignment.topLeft,
                  child:
                      customDurationDisplay ??
                      PlaybackTimeDisplay(
                        controller: controller,
                        showCurrentTime: showCurrentTime,
                        showDurationTime: showDurationTime,
                      ),
                )
              : const SizedBox(height: 18),

          // Custom Progress Bar with thumb and active color
          ProgressBarWithPreview(
            activeColor: theme.colors.active,
            thumbColor: theme.colors.thumb ?? theme.colors.active,
            inactiveColor: theme.colors.inactive,
            controller: controller,
            onChanged: onChanged,
            onChangeStart: onChangeStart,
            onChangeEnd: onChangeEnd,
            allowSeeking: allowSeeking,
            showScrubbingThumbnailPreview: showScrubbingThumbnailPreview,
          ),

          // Optional remaining playback time below the bar
          showRemainingTime
              ? customRemainingTimeDisplay ??
                    Align(
                      alignment: Alignment.bottomRight,
                      child: RemainingPlaybackTime(duration: _remaining),
                    )
              : const SizedBox(height: 18),
        ],
      ),
    );
  }

  Duration get _remaining => duration - position;
}
