import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A small visual indicator used to signal that a live video stream is currently playing.
///
/// The [LiveStatusIndicator] consists of a circular red dot and a customizable label
/// (e.g., "LIVE") styled according to the active [OmniVideoPlayerTheme].
///
/// Typically displayed in the top control bar of a video player during live streams.
class LiveStatusIndicator extends StatelessWidget {
  /// Creates a live indicator widget.
  ///
  /// The [label] is shown next to the red dot to indicate live playback.
  const LiveStatusIndicator({super.key, required this.label});

  /// The label to display next to the live indicator, such as "LIVE".
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10.0,
            height: 10.0,
            decoration: BoxDecoration(
              color: theme.colors.liveIndicator,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: theme.colors.liveIndicator),
          ),
        ],
      ),
    );
  }
}
