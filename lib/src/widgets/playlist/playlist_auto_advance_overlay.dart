import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playlist_controller.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_item.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// "Up Next" countdown overlay shown when a video finishes and auto-advance is enabled.
///
/// Displays:
/// - Thumbnail + title of the next video
/// - Circular countdown timer
/// - "Play Now" button to skip the countdown
/// - "Cancel" button to stop auto-advancement
class PlaylistAutoAdvanceOverlay extends StatelessWidget {
  /// The playlist controller for state and actions.
  final OmniPlaylistController playlistController;

  /// The total auto-advance duration (for the progress indicator).
  final Duration totalDuration;

  const PlaylistAutoAdvanceOverlay({
    super.key,
    required this.playlistController,
    required this.totalDuration,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context);
    final nextItem = playlistController.nextItem;

    if (nextItem == null) return const SizedBox.shrink();

    return AnimatedOpacity(
      opacity: playlistController.isAutoAdvancing ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: playlistController.isAutoAdvancing
          ? _buildOverlayContent(context, theme, nextItem)
          : const SizedBox.shrink(),
    );
  }

  Widget _buildOverlayContent(
    BuildContext context,
    OmniVideoPlayerThemeData? theme,
    OmniPlaylistItem nextItem,
  ) {
    final activeColor = theme?.colors.active ?? Colors.redAccent;
    final textColor = theme?.colors.textDefault ?? Colors.white;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(140),
            Colors.black.withAlpha(180),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // "Up Next" label
              Text(
                'UP NEXT',
                style: TextStyle(
                  color: textColor.withAlpha(180),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Thumbnail + info row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Countdown timer
                  _CountdownIndicator(
                    countdown: playlistController.autoAdvanceCountdown,
                    totalSeconds: totalDuration.inSeconds,
                    activeColor: activeColor,
                    textColor: textColor,
                  ),
                  const SizedBox(width: 16),

                  // Thumbnail
                  if (nextItem.thumbnail != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image(
                        image: nextItem.thumbnail!,
                        width: 80,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, e, s) => Container(
                          width: 80,
                          height: 48,
                          color: Colors.grey.shade800,
                          child: const Icon(
                            Icons.video_library,
                            color: Colors.white54,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Title and subtitle
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (nextItem.title != null)
                          Text(
                            nextItem.title!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (nextItem.subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            nextItem.subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: textColor.withAlpha(150),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cancel button
                  _ActionButton(
                    label: 'Cancel',
                    textColor: textColor,
                    backgroundColor: Colors.white.withAlpha(25),
                    onPressed: () => playlistController.cancelAutoAdvance(),
                  ),
                  const SizedBox(width: 12),
                  // Play Now button
                  _ActionButton(
                    label: 'Play Now',
                    textColor: Colors.white,
                    backgroundColor: activeColor,
                    onPressed: () =>
                        playlistController.skipAutoAdvanceCountdown(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountdownIndicator extends StatelessWidget {
  final int countdown;
  final int totalSeconds;
  final Color activeColor;
  final Color textColor;

  const _CountdownIndicator({
    required this.countdown,
    required this.totalSeconds,
    required this.activeColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalSeconds > 0 ? countdown / totalSeconds : 0.0;

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white.withAlpha(50),
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
          Text(
            '$countdown',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
