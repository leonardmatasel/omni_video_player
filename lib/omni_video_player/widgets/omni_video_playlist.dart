import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playlist_controller.dart';
import 'package:omni_video_player/omni_video_player/models/custom_overlay_layer.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/widgets/omni_video_player.dart';
import 'package:omni_video_player/src/widgets/playlist/playlist_navigation_overlay.dart';

/// A minimal video playlist: plays an ordered queue of videos with on-video
/// previous/next buttons.
///
/// The buttons fade in and out together with the center play/pause button:
/// hidden during uninterrupted playback, shown when the controls are revealed,
/// and shown next to the replay button when the video finishes. Each button
/// dims/disables at the queue ends unless [PlaylistConfiguration.loop] is set.
///
/// Set [PlaylistConfiguration.autoAdvance] to move on automatically when a
/// video ends, and [PlaylistConfiguration.loop] to wrap around the ends.
class OmniVideoPlaylist extends StatefulWidget {
  /// Playlist behaviour (items, initial index, autoAdvance, loop).
  final PlaylistConfiguration playlistConfiguration;

  /// Base player configuration; the per-item source is merged onto it.
  final VideoPlayerConfiguration playerConfiguration;

  /// Per-video player callbacks (forwarded to the inner player).
  final VideoPlayerCallbacks callbacks;

  /// Optional playlist-level callbacks.
  final PlaylistCallbacks? playlistCallbacks;

  /// Called once with the created [OmniPlaylistController] for external control.
  final void Function(OmniPlaylistController controller)?
  onPlaylistControllerCreated;

  const OmniVideoPlaylist({
    super.key,
    required this.playlistConfiguration,
    required this.playerConfiguration,
    required this.callbacks,
    this.playlistCallbacks,
    this.onPlaylistControllerCreated,
  });

  @override
  State<OmniVideoPlaylist> createState() => _OmniVideoPlaylistState();
}

class _OmniVideoPlaylistState extends State<OmniVideoPlaylist> {
  late final OmniPlaylistController _controller;

  /// Mirrors the inner player's center play/pause button visibility, fed by
  /// [VideoPlayerCallbacks.onCenterControlsVisibilityChanged]. Owned by this
  /// State so the nav overlay can fade in sync with that button (it is already
  /// `true` when the video is finished, so the buttons also show next to the
  /// replay button). Updated after the frame because the source callback fires
  /// during the inner player's build.
  final ValueNotifier<bool> _centerControlsVisible = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _controller = OmniPlaylistController(
      configuration: widget.playlistConfiguration,
      callbacks: widget.playlistCallbacks,
    );
    _controller.onSourceChangeRequested = (_) {
      if (mounted) setState(() {});
    };
    widget.onPlaylistControllerCreated?.call(_controller);
  }

  @override
  void dispose() {
    _centerControlsVisible.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Builds the prev/next buttons. Listens to the playlist controller (enabled
  /// state at the queue ends) and [_centerControlsVisible] (fade in/out) — both
  /// owned by this State, so always alive. The overlay layer is always mounted
  /// (see [_buildConfig]); visibility is animated, never unmounted, so the
  /// buttons dissolve like the play/pause button instead of popping.
  Widget _navButtons() {
    return ListenableBuilder(
      listenable: Listenable.merge([_controller, _centerControlsVisible]),
      builder: (context, _) {
        return PlaylistNavigationOverlay(
          playlistController: _controller,
          isVisible: _centerControlsVisible.value,
        );
      },
    );
  }

  VideoPlayerConfiguration _buildConfig() {
    final base = widget.playerConfiguration;
    return base.copyWith(
      // Force autoplay so navigating to a new item starts it.
      videoSourceConfiguration: _controller.currentSource.copyWith(
        autoPlay: true,
      ),
      customPlayerWidgets: base.customPlayerWidgets.copyWith(
        customOverlayLayers: [
          ...base.customPlayerWidgets.customOverlayLayers,
          // Always rendered (ignoreOverlayControlsVisibility: true) so the
          // buttons can fade rather than being added/removed from the tree.
          // Visibility tracks the center play/pause button via
          // [_centerControlsVisible], so prev/next fade in/out together with it
          // and stay visible next to the replay button when finished.
          CustomOverlayLayer(
            level: 5,
            ignoreOverlayControlsVisibility: true,
            widget: _navButtons(),
          ),
        ],
      ),
    );
  }

  VideoPlayerCallbacks _buildCallbacks() {
    return widget.callbacks.copyWith(
      onCenterControlsVisibilityChanged: (visible) {
        widget.callbacks.onCenterControlsVisibilityChanged?.call(visible);
        // This callback fires during the inner player's build; defer the
        // notifier update to after the frame to avoid mutating the widget tree
        // mid-build. The 250ms fade hides the one-frame offset.
        if (_centerControlsVisible.value == visible) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _centerControlsVisible.value = visible;
        });
      },
      onFinished: () {
        widget.callbacks.onFinished?.call();
        _controller.handleVideoFinished();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final source = _controller.currentSource;
    return OmniVideoPlayer(
      key: ValueKey(
        '${_controller.currentIndex}_'
        '${source.videoSourceType}_'
        '${source.videoUrl ?? ''}_${source.videoId ?? ''}',
      ),
      configuration: _buildConfig(),
      callbacks: _buildCallbacks(),
    );
  }
}
