import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/utils/orientation_locker.dart';
import 'package:omni_video_player/src/widgets/adaptive_video_player_display.dart';
import 'package:omni_video_player/src/widgets/video_overlay_controls.dart';

/// A full-screen video player widget that manages system UI, device orientation,
/// and overlays interactive video controls.
///
/// This widget locks the device orientation based on the video's rotation and aspect ratio,
/// enters immersive full-screen mode, and restores system UI overlays when dismissed.
///
/// It integrates with a [OmniPlaybackController] for video playback control,
/// uses [VideoPlayerConfiguration] for configuration, and reports events through [VideoPlayerCallbacks].
class FullscreenVideoPlayer extends StatefulWidget {
  /// The controller managing media playback state and logic.
  final OmniPlaybackController controller;

  /// Configuration options for the video player appearance and behavior.
  final VideoPlayerConfiguration options;

  /// Callbacks to respond to video player events and user interactions.
  final VideoPlayerCallbacks callbacks;

  const FullscreenVideoPlayer({
    super.key,
    required this.controller,
    required this.options,
    required this.callbacks,
  });

  @override
  State<FullscreenVideoPlayer> createState() => _FullscreenVideoPlayerState();
}

class _FullscreenVideoPlayerState extends State<FullscreenVideoPlayer> {
  late final double _aspectRatio;
  @override
  void initState() {
    super.initState();
    // Enter immersive full-screen mode hiding system UI overlays.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    final rotation = widget.controller.rotationCorrection;
    final size = widget.controller.size;

    _aspectRatio =
        widget.options.playerUIVisibilityOptions.customAspectRatioFullScreen ??
        ((rotation == 90 || rotation == 270)
            ? size.height / size.width
            : size.width / size.height);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final basePlayer = OrientationLocker(
      enableOrientationLock:
          widget.options.playerUIVisibilityOptions.enableOrientationLock,
      orientation:
          widget.options.playerUIVisibilityOptions.fullscreenOrientation ??
          (widget.controller.size.height / widget.controller.size.width > 1
              ? Orientation.portrait
              : Orientation.landscape),
      child: Material(
        color: Colors.black,
        child: Column(
          children: [
            Expanded(
              child: VideoOverlayControls(
                playerBarPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 16,
                ),
                controller: widget.controller,
                options: widget.options,
                callbacks: widget.callbacks,
                child: AdaptiveVideoPlayerDisplay(
                  controller: widget.controller,
                  isFullScreenDisplay: true,
                  aspectRatio: _aspectRatio,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    final wrapper = widget.options.customPlayerWidgets.fullscreenWrapper;

    return wrapper != null ? wrapper(context, basePlayer) : basePlayer;
  }
}
