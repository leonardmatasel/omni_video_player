import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A customizable icon button for video player controls, such as play, pause, mute, etc.
///
/// [VideoControlIconButton] is a reusable component that responds to user interaction
/// with an animated icon transition. It uses the theming defined in [OmniVideoPlayerTheme].
class VideoControlIconButton extends StatelessWidget {
  /// The icon to display inside the button.
  final IconData icon;

  /// The callback invoked when the button is tapped.
  final VoidCallback onPressed;

  /// Creates a new video control button.
  const VideoControlIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(100),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 100),
          child: Icon(icon, key: ValueKey(icon), color: theme.colors.icon),
        ),
      ),
    );
  }
}
