import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

/// A reusable icon button for video player controls, such as play, pause, mute, and fullscreen.
///
/// The [VideoControlIconButton] provides a consistent, theme-aware control element
/// for video player interfaces. It integrates with [OmniVideoPlayerTheme] to apply
/// custom icon styles, and supports animated transitions between icons via [AnimatedSwitcher].
///
/// Typically used in conjunction with playback or UI control widgets.
///
/// {@tool snippet}
/// Example usage:
/// ```dart
/// VideoControlIconButton(
///   icon: Icons.play_arrow,
///   onPressed: () {
///     // Handle play button press
///   },
/// )
/// ```
/// {@end-tool}
class VideoControlIconButton extends StatelessWidget {
  /// Creates a [VideoControlIconButton].
  ///
  /// The [icon] is displayed as the button's visual representation.
  /// The [onPressed] callback is triggered when the user taps the button.
  const VideoControlIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  /// The icon to display inside the control button.
  final IconData icon;

  /// Callback invoked when the button is tapped.
  final VoidCallback onPressed;

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
