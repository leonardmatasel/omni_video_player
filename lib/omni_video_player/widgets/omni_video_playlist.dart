import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playlist_controller.dart';
import 'package:omni_video_player/omni_video_player/models/custom_overlay_layer.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_item.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/omni_video_player/widgets/omni_video_player.dart';
import 'package:omni_video_player/src/widgets/playlist/playlist_auto_advance_overlay.dart';
import 'package:omni_video_player/src/widgets/playlist/playlist_navigation_overlay.dart';
import 'package:omni_video_player/src/widgets/playlist/playlist_panel.dart';
import 'package:omni_video_player/src/widgets/playlist/playlist_up_next_preview.dart';

/// A video playlist widget that plays a queue of videos with autoplay,
/// next/previous navigation, and YouTube-style auto-advance.
///
/// Supports YouTube, Vimeo, Network, Asset, and File sources in any combination.
///
/// ### Basic Usage
/// ```dart
/// OmniVideoPlaylist(
///   playlistConfiguration: PlaylistConfiguration(
///     items: [
///       OmniPlaylistItem(
///         sourceConfiguration: VideoSourceConfiguration.youtube(
///           videoUrl: Uri.parse('https://youtube.com/watch?v=...'),
///         ),
///         title: 'Video 1',
///       ),
///       OmniPlaylistItem(
///         sourceConfiguration: VideoSourceConfiguration.network(
///           videoUrl: Uri.parse('https://example.com/video.mp4'),
///         ),
///         title: 'Video 2',
///       ),
///     ],
///     autoAdvance: true,
///   ),
///   playerConfiguration: VideoPlayerConfiguration(
///     videoSourceConfiguration: VideoSourceConfiguration.youtube(
///       videoUrl: Uri.parse('https://youtube.com/watch?v=...'),
///     ),
///   ),
///   callbacks: VideoPlayerCallbacks(),
/// )
/// ```
///
/// ### Landscape/Fullscreen
/// In landscape or fullscreen mode, the playlist panel is shown alongside the
/// video (YouTube-style), displaying the current and upcoming videos.
class OmniVideoPlaylist extends StatefulWidget {
  /// Configuration for the playlist behavior (items, autoplay, shuffle, etc.).
  final PlaylistConfiguration playlistConfiguration;

  /// Base configuration for the video player (theme, UI options, etc.).
  ///
  /// The [videoSourceConfiguration] inside this will be overridden by the
  /// current playlist item's source configuration.
  final VideoPlayerConfiguration playerConfiguration;

  /// Callback handlers for per-video player lifecycle events.
  final VideoPlayerCallbacks callbacks;

  /// Callback handlers for playlist-level events.
  final PlaylistCallbacks? playlistCallbacks;

  /// Called when the internal [OmniPlaylistController] is created.
  ///
  /// Use this to get a reference to the controller for external navigation.
  final void Function(OmniPlaylistController controller)?
      onPlaylistControllerCreated;

  /// Whether to show the playlist panel in landscape/fullscreen mode.
  ///
  /// Defaults to `true`.
  final bool showPlaylistPanelInFullscreen;

  /// Whether to show the next/previous navigation overlay buttons.
  ///
  /// Defaults to `true`.
  final bool showNavigationOverlay;

  const OmniVideoPlaylist({
    super.key,
    required this.playlistConfiguration,
    required this.playerConfiguration,
    required this.callbacks,
    this.playlistCallbacks,
    this.onPlaylistControllerCreated,
    this.showPlaylistPanelInFullscreen = true,
    this.showNavigationOverlay = true,
  });

  @override
  State<OmniVideoPlaylist> createState() => _OmniVideoPlaylistState();
}

class _OmniVideoPlaylistState extends State<OmniVideoPlaylist> {
  late OmniPlaylistController _playlistController;
  bool _showPlaylistPanel = false;

  late VideoPlayerConfiguration _currentPlayerConfig;

  @override
  void initState() {
    super.initState();
    _playlistController = OmniPlaylistController(
      configuration: widget.playlistConfiguration,
      callbacks: widget.playlistCallbacks,
    );
    _playlistController.addListener(_onPlaylistStateChanged);
    _playlistController.onSourceChangeRequested = _onSourceChange;

    // Build initial player config
    _currentPlayerConfig = _buildPlayerConfig(
      widget.playlistConfiguration.initialIndex.clamp(
        0,
        widget.playlistConfiguration.items.length - 1,
      ),
    );

    widget.onPlaylistControllerCreated?.call(_playlistController);
  }

  @override
  void didUpdateWidget(covariant OmniVideoPlaylist oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update callbacks if they changed
    if (widget.playlistCallbacks != oldWidget.playlistCallbacks) {
      _playlistController.callbacks = widget.playlistCallbacks;
    }
  }

  VideoPlayerConfiguration _buildPlayerConfig(int index) {
    final item = _playlistController.items[index];
    var sourceConfig = item.sourceConfiguration;

    // Apply start position if specified
    if (item.startPosition != null) {
      sourceConfig = sourceConfig.copyWith(
        initialPosition: item.startPosition,
      );
    }

    // Apply autoPlay from playlist configuration
    sourceConfig = sourceConfig.copyWith(
      autoPlay: true,
    );

    // Merge or copy existing overlay layers
    final customOverlays = List<CustomOverlayLayer>.from(
      widget.playerConfiguration.customPlayerWidgets.customOverlayLayers,
    );

    // 1. Navigation Overlay
    if (widget.showNavigationOverlay && _playlistController.itemCount > 1) {
      customOverlays.add(
        CustomOverlayLayer(
          level: 10,
          ignoreOverlayControlsVisibility: false,
          widget: ListenableBuilder(
            listenable: _playlistController,
            builder: (context, _) {
              return PlaylistNavigationOverlay(
                playlistController: _playlistController,
                isVisible: !_playlistController.isAutoAdvancing,
              );
            },
          ),
        ),
      );
    }

    // 2. Auto-Advance Overlay
    customOverlays.add(
      CustomOverlayLayer(
        level: 11,
        ignoreOverlayControlsVisibility: true,
        widget: ListenableBuilder(
          listenable: _playlistController,
          builder: (context, _) {
            if (!_playlistController.isAutoAdvancing) return const SizedBox.shrink();
            return PlaylistAutoAdvanceOverlay(
              playlistController: _playlistController,
              totalDuration: _playlistController.advanceDelay,
            );
          },
        ),
      ),
    );

    // 3. Top Info & Toggle Bar Overlay
    customOverlays.add(
      CustomOverlayLayer(
        level: 12,
        ignoreOverlayControlsVisibility: false,
        widget: ListenableBuilder(
          listenable: _playlistController,
          builder: (context, _) {
            return Stack(
              children: [
                if (_playlistController.currentItem.title != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 50,
                    child: _NowPlayingBar(
                      item: _playlistController.currentItem,
                      index: _playlistController.currentIndex,
                      total: _playlistController.itemCount,
                    ),
                  ),
                if (widget.showPlaylistPanelInFullscreen)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return _PlaylistToggleButton(
                          isActive: _showPlaylistPanel,
                          onPressed: () {
                            this.setState(() {
                              _showPlaylistPanel = !_showPlaylistPanel;
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );

    // 4. Fullscreen Queue Panel Overlay (rendered on the right side over video)
    if (widget.showPlaylistPanelInFullscreen) {
      customOverlays.add(
        CustomOverlayLayer(
          level: 13,
          ignoreOverlayControlsVisibility: true,
          widget: ListenableBuilder(
            listenable: _playlistController,
            builder: (context, _) {
              final isFullScreen = _playlistController.playbackController?.isFullScreen ?? false;
              if (!_showPlaylistPanel || !isFullScreen) return const SizedBox.shrink();
              return Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: 0.35,
                  heightFactor: 1.0,
                  child: PlaylistPanel(
                    playlistController: _playlistController,
                    isVisible: true,
                    onClose: () {
                      setState(() {
                        _showPlaylistPanel = false;
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    // 5. "Up Next" preview card shown on the thumbnail when video finishes
    //    (only when auto-advance countdown is NOT active)
    if (_playlistController.itemCount > 1) {
      customOverlays.add(
        CustomOverlayLayer(
          level: 14,
          ignoreOverlayControlsVisibility: true,
          widget: ListenableBuilder(
            listenable: _playlistController,
            builder: (context, _) {
              final controller = _playlistController.playbackController;
              final isFinished = controller?.isFinished ?? false;
              final isAutoAdvancing = _playlistController.isAutoAdvancing;

              return PlaylistUpNextPreview(
                playlistController: _playlistController,
                isVisible: isFinished && !isAutoAdvancing,
              );
            },
          ),
        ),
      );
    }

    return widget.playerConfiguration.copyWith(
      videoSourceConfiguration: sourceConfig,
      customPlayerWidgets: widget.playerConfiguration.customPlayerWidgets.copyWith(
        customOverlayLayers: customOverlays,
        // Use the playlist item's thumbnail if provided, otherwise fall back
        // to the base player config thumbnail (auto-fetched by the initializer).
        thumbnail: item.thumbnail ??
            widget.playerConfiguration.customPlayerWidgets.thumbnail,
      ),
    );
  }

  void _onPlaylistStateChanged() {
    if (mounted) setState(() {});
  }

  void _onSourceChange(int newIndex) {
    setState(() {
      _currentPlayerConfig = _buildPlayerConfig(newIndex);
    });
  }

  VideoPlayerCallbacks _buildCallbacks() {
    return widget.callbacks.copyWith(
      onControllerCreated: (controller) {
        _playlistController.bindPlaybackController(controller);
        widget.callbacks.onControllerCreated?.call(controller);
        widget.playlistCallbacks?.onVideoStarted?.call(
          _playlistController.currentIndex,
        );
      },
      onFinished: () {
        widget.callbacks.onFinished?.call();
        Future.delayed(Duration.zero, () {
          if (!mounted) return;
          _playlistController.onVideoFinished();
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _playlistController,
      builder: (context, _) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;
            final isFullScreen = _playlistController.playbackController?.isFullScreen ?? false;
            final showPanel = isLandscape &&
                widget.showPlaylistPanelInFullscreen &&
                _showPlaylistPanel &&
                !isFullScreen;

            return Row(
              children: [
                // Video player with overlays
                Expanded(
                  child: _buildPlayerWithOverlays(),
                ),
                // Playlist panel (landscape only)
                if (showPanel)
                  PlaylistPanel(
                    playlistController: _playlistController,
                    isVisible: true,
                    onClose: () {
                      setState(() => _showPlaylistPanel = false);
                    },
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPlayerWithOverlays() {
    return OmniVideoPlayer(
      key: ValueKey(
        '${_playlistController.currentIndex}_'
        '${_currentPlayerConfig.videoSourceConfiguration.videoSourceType}_'
        '${_currentPlayerConfig.videoSourceConfiguration.videoUrl ?? ''}_'
        '${_currentPlayerConfig.videoSourceConfiguration.videoId ?? ''}',
      ),
      configuration: _currentPlayerConfig,
      callbacks: _buildCallbacks(),
    );
  }

  @override
  void dispose() {
    _playlistController.removeListener(_onPlaylistStateChanged);
    _playlistController.dispose();
    super.dispose();
  }
}

/// Small toggle button to show/hide the playlist panel in landscape mode.
class _PlaylistToggleButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const _PlaylistToggleButton({
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context);
    final iconColor = theme?.colors.icon ?? Colors.white;

    return Material(
      color: isActive ? Colors.white.withAlpha(25) : Colors.black38,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.playlist_play_rounded,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// A compact "now playing" bar displayed at the top of the player.
class _NowPlayingBar extends StatelessWidget {
  final OmniPlaylistItem item;
  final int index;
  final int total;

  const _NowPlayingBar({
    required this.item,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context);
    final textColor = theme?.colors.textDefault ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withAlpha(150),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          // Index indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(25),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${index + 1}/$total',
              style: TextStyle(
                color: textColor.withAlpha(180),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Title
          Expanded(
            child: Text(
              item.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
