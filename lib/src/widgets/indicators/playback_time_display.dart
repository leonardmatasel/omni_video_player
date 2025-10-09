import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A widget that displays the current playback time and/or total duration of a video.
///
/// The [PlaybackTimeDisplay] is typically shown in the video player's control bar and
/// adapts its content based on [showCurrentTime] and [showDurationTime] flags.
///
/// It uses [OmniPlaybackController] to access current playback position and duration.
class PlaybackTimeDisplay extends StatelessWidget {
  /// Creates a widget that shows formatted video time indicators.
  const PlaybackTimeDisplay({
    super.key,
    required this.controller,
    required this.showCurrentTime,
    required this.showDurationTime,
  });

  /// Controller that provides current playback position and video duration.
  final OmniPlaybackController controller;

  /// Whether to show the current playback position.
  final bool showCurrentTime;

  /// Whether to show the total video duration.
  final bool showDurationTime;

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: theme.colors.textDefault),
          children: [
            if (showCurrentTime)
              TextSpan(
                text: VideoTimeFormatter.format(
                  controller.currentPosition,
                  showHours: controller.duration.inHours > 0,
                ),
              ),
            if (showDurationTime) ...[
              TextSpan(
                text: showCurrentTime ? ' / ' : '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.colors.textDefault?.withValues(alpha: 0.7),
                ),
              ),
              TextSpan(
                text: VideoTimeFormatter.format(
                  controller.duration,
                  showHours: controller.duration.inHours > 0,
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: theme.colors.textDefault?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Utility class for formatting [Duration] into readable time strings.
abstract class VideoTimeFormatter {
  /// Formats a duration into `HH:MM:SS` or `MM:SS` depending on [showHours].
  static String format(Duration duration, {bool showHours = true}) {
    final seconds = duration.inSeconds % 60;
    final minutes = duration.inMinutes % 60;
    final hours = duration.inHours;

    final buffer = StringBuffer();
    if (showHours) buffer.write('${hours.toTwoDigits()}:');
    buffer.write('${minutes.toTwoDigits()}:${seconds.toTwoDigits()}');
    return buffer.toString();
  }
}

/// Extension to format numbers into two-digit strings.
extension TwoDigitFormatting on int {
  String toTwoDigits() => this > 9 ? toString() : '0$this';
}
