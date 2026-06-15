import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playlist_controller.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/utils/animated_fade_visibility.dart';

/// Overlay buttons for next/previous playlist navigation.
///
/// Displayed on top of the video player when in playlist mode.
/// Buttons are hidden when at the start/end of playlist (unless looping).
class PlaylistNavigationOverlay extends StatelessWidget {
  /// The playlist controller managing navigation state.
  final OmniPlaylistController playlistController;

  /// Whether the overlay controls are currently visible.
  final bool isVisible;

  const PlaylistNavigationOverlay({
    super.key,
    required this.playlistController,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context);
    final iconColor = theme?.colors.icon ?? Colors.white;

    return AnimatedFadeVisibility(
      visible: isVisible,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Previous button
            _NavigationButton(
              icon: theme?.icons.skipPrevious ?? Icons.skip_previous_rounded,
              isEnabled: playlistController.hasPrevious,
              iconColor: iconColor,
              semanticLabel:
                  theme?.accessibility.previousTrackLabel ?? 'Previous video',
              onPressed: () => playlistController.previous(),
            ),
            const Spacer(),
            // Next button
            _NavigationButton(
              icon: theme?.icons.skipNext ?? Icons.skip_next_rounded,
              isEnabled: playlistController.hasNext,
              iconColor: iconColor,
              semanticLabel:
                  theme?.accessibility.nextTrackLabel ?? 'Next video',
              onPressed: () => playlistController.next(),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final bool isEnabled;
  final Color iconColor;
  final String semanticLabel;
  final VoidCallback onPressed;

  const _NavigationButton({
    required this.icon,
    required this.isEnabled,
    required this.iconColor,
    required this.semanticLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.3,
      duration: const Duration(milliseconds: 200),
      child: Semantics(
        label: semanticLabel,
        button: true,
        enabled: isEnabled,
        child: Material(
          color: Colors.black38,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                icon,
                color: iconColor,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
