import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

class AnimatedSkipIndicator extends StatelessWidget {
  const AnimatedSkipIndicator({
    super.key,
    required this.skipDirection,
    required this.skipSeconds,
  });

  final SkipDirection skipDirection;
  final int skipSeconds;

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colors.playPauseBackground.withAlpha(100),
          borderRadius: BorderRadius.circular(200),
        ),
        child: Icon(
          _getSkipIcon(skipDirection, skipSeconds, theme.icons),
          size: 36,
          color: theme.colors.playPauseIcon ?? theme.colors.icon,
        ),
      ),
    );
  }
}

enum SkipDirection { forward, backward }

IconData _getSkipIcon(
  SkipDirection direction,
  int seconds,
  VideoPlayerIconTheme icons,
) {
  if (direction == SkipDirection.forward) {
    switch (seconds) {
      case 5:
        return icons.forward5;
      case 10:
        return icons.forward10;
      default:
        return icons.forward30;
    }
  } else {
    switch (seconds) {
      case 5:
        return icons.replay5;
      case 10:
        return icons.replay10;
      default:
        return icons.replay30;
    }
  }
}
