import 'package:flutter/material.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/progress_bar.dart';
import 'package:omni_video_player/src/widgets/indicators/playback_time_display.dart';
import 'package:omni_video_player/src/widgets/indicators/remaining_playback_time.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

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
class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final Duration? bufferedPosition;
  final ValueChanged<Duration>? onChanged;
  final ValueChanged<Duration>? onChangeStart;
  final ValueChanged<Duration>? onChangeEnd;
  final bool showRemainingTime;
  final bool showCurrentTime;
  final bool showDurationTime;
  final bool allowSeeking;
  final Widget? customDurationDisplay;
  final Widget? customRemainingTimeDisplay;
  final Widget? customTimeDisplay;
  final OmniPlaybackController controller;

  const SeekBar({
    super.key,
    required this.duration,
    required this.position,
    required this.bufferedPosition,
    required this.onChanged,
    required this.onChangeStart,
    required this.onChangeEnd,
    required this.showRemainingTime,
    required this.showCurrentTime,
    required this.showDurationTime,
    required this.customTimeDisplay,
    required this.controller,
    required this.allowSeeking,
    required this.customDurationDisplay,
    required this.customRemainingTimeDisplay,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    final positionValue =
        _dragValue ?? widget.position.inMilliseconds.toDouble();
    final durationValue = widget.duration.inMilliseconds.toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          widget.showCurrentTime || widget.showDurationTime
              ? Align(
                  alignment: Alignment.topLeft,
                  child: widget.customDurationDisplay ??
                      PlaybackTimeDisplay(
                        controller: widget.controller,
                        showCurrentTime: widget.showCurrentTime,
                        showDurationTime: widget.showDurationTime,
                      ),
                )
              : const SizedBox(height: 18),

          // Custom Progress Bar with thumb and active color
          ProgressBar(
            value: positionValue.toDouble(),
            max: durationValue,
            allowSeeking: widget.allowSeeking,
            activeColor: theme.colors.active,
            thumbColor: theme.colors.thumb ?? theme.colors.active,
            inactiveColor: theme.colors.inactive,
            onChanged: (val) {
              setState(() {
                _dragValue = val;
              });
              widget.onChanged?.call(Duration(milliseconds: val.round()));
            },
            onChangeStart: (value) {
              widget.onChangeStart?.call(Duration(milliseconds: value.round()));
            },
            onChangeEnd: (value) {
              setState(() {
                _dragValue = null;
              });
              widget.onChangeEnd?.call(Duration(milliseconds: value.round()));
            },
          ),

          // Optional remaining playback time below the bar
          widget.showRemainingTime
              ? widget.customRemainingTimeDisplay ??
                  Align(
                    alignment: Alignment.bottomRight,
                    child: RemainingPlaybackTime(duration: _remaining),
                  )
              : const SizedBox(height: 18),
        ],
      ),
    );
  }

  Duration get _remaining => widget.duration - widget.position;
}
