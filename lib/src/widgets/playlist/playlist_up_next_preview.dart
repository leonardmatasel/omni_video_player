import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playlist_controller.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_item.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A compact "Up Next" preview card that appears at the bottom of the player
/// when a video finishes in playlist mode.
///
/// This is shown when auto-advance is NOT active (i.e. the user cancelled it
/// or `autoAdvance` is `false`), giving the user a clear way to manually
/// proceed to the next video.
class PlaylistUpNextPreview extends StatelessWidget {
  /// The playlist controller for state and navigation.
  final OmniPlaylistController playlistController;

  /// Whether this preview should be visible.
  final bool isVisible;

  const PlaylistUpNextPreview({
    super.key,
    required this.playlistController,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context);
    final nextItem = playlistController.nextItem;

    if (!isVisible || nextItem == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned(
          bottom: 60,
          left: 16,
          right: 16,
          child: AnimatedOpacity(
            opacity: isVisible ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: _UpNextCard(
              nextItem: nextItem,
              theme: theme,
              onPlayNext: () => playlistController.next(),
            ),
          ),
        ),
      ],
    );
  }
}

class _UpNextCard extends StatelessWidget {
  final OmniPlaylistItem nextItem;
  final OmniVideoPlayerThemeData? theme;
  final VoidCallback onPlayNext;

  const _UpNextCard({
    required this.nextItem,
    required this.theme,
    required this.onPlayNext,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = theme?.colors.textDefault ?? Colors.white;
    final activeColor = theme?.colors.active ?? Colors.redAccent;

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(200),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withAlpha(25),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // "UP NEXT" label + thumbnail
            if (nextItem.thumbnail != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image(
                  image: nextItem.thumbnail!,
                  width: 72,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, e, s) => Container(
                    width: 72,
                    height: 44,
                    color: Colors.grey.shade800,
                    child: const Icon(
                      Icons.video_library,
                      color: Colors.white54,
                      size: 20,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 72,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            const SizedBox(width: 12),

            // Title and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'UP NEXT',
                    style: TextStyle(
                      color: textColor.withAlpha(140),
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  if (nextItem.title != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      nextItem.title!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (nextItem.subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      nextItem.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor.withAlpha(130),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Play Next button
            Material(
              color: activeColor,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onPlayNext,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.skip_next_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
