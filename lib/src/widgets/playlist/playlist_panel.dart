import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playlist_controller.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_item.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';

/// A scrollable list panel displaying all playlist items.
///
/// Shown in fullscreen/landscape mode (YouTube-style "now playing" list).
/// Features:
/// - Highlights the currently playing item
/// - Tap to jump to any item
/// - Shows thumbnail, title, subtitle, and index for each item
class PlaylistPanel extends StatelessWidget {
  /// The playlist controller managing state.
  final OmniPlaylistController playlistController;

  /// Whether the panel is currently visible.
  final bool isVisible;

  /// Optional callback when the panel requests to close.
  final VoidCallback? onClose;

  const PlaylistPanel({
    super.key,
    required this.playlistController,
    required this.isVisible,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = OmniVideoPlayerTheme.of(context);
    final activeColor = theme?.colors.playlistItemActive ?? Colors.redAccent;
    final textColor = theme?.colors.textDefault ?? Colors.white;

    return AnimatedSlide(
      offset: isVisible ? Offset.zero : const Offset(1, 0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: Container(
        width: 320,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          border: Border(
            left: BorderSide(
              color: Colors.white.withAlpha(20),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(textColor, activeColor),
            // Divider
            Divider(color: Colors.white.withAlpha(25), height: 1),
            // Item list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: playlistController.itemCount,
                itemBuilder: (context, index) {
                  final item = playlistController.items[index];
                  final isCurrent = index == playlistController.currentIndex;
                  return _PlaylistItemTile(
                    item: item,
                    index: index,
                    isCurrent: isCurrent,
                    activeColor: activeColor,
                    textColor: textColor,
                    onTap: () => playlistController.jumpTo(index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color textColor, Color activeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.playlist_play_rounded, color: activeColor, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playlist',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${playlistController.currentIndex + 1}/${playlistController.itemCount}',
                  style: TextStyle(
                    color: textColor.withAlpha(120),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              icon: Icon(Icons.close, color: textColor.withAlpha(150), size: 20),
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }
}

class _PlaylistItemTile extends StatelessWidget {
  final OmniPlaylistItem item;
  final int index;
  final bool isCurrent;
  final Color activeColor;
  final Color textColor;
  final VoidCallback onTap;

  const _PlaylistItemTile({
    required this.item,
    required this.index,
    required this.isCurrent,
    required this.activeColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isCurrent
          ? activeColor.withAlpha(30)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              // Index or playing indicator
              SizedBox(
                width: 28,
                child: Center(
                  child: isCurrent
                      ? Icon(
                          Icons.play_arrow_rounded,
                          color: activeColor,
                          size: 18,
                        )
                      : Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: textColor.withAlpha(100),
                            fontSize: 12,
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 8),

              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 64,
                  height: 36,
                  child: item.thumbnail != null
                      ? Image(
                          image: item.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, e, s) => _placeholderThumb(),
                        )
                      : _placeholderThumb(),
                ),
              ),

              const SizedBox(width: 10),

              // Title and subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.title ?? 'Video ${index + 1}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrent ? activeColor : textColor,
                        fontSize: 12,
                        fontWeight:
                            isCurrent ? FontWeight.w600 : FontWeight.w400,
                        height: 1.3,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: textColor.withAlpha(100),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderThumb() {
    return Container(
      color: Colors.grey.shade800,
      child: const Center(
        child: Icon(
          Icons.video_library_outlined,
          color: Colors.white38,
          size: 16,
        ),
      ),
    );
  }
}
