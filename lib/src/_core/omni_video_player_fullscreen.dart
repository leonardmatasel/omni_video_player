import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/utils/orientation_locker.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_viewport.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';

/// A full-screen video player widget that:
/// - Locks the screen orientation based on video ratio/rotation.
/// - Enters immersive full-screen mode (hiding system overlays).
/// - Restores UI overlays when closed.
/// - Displays video content with interactive controls.
///
/// Works with [OmniPlaybackController] to control playback,
/// [VideoPlayerConfiguration] for settings, and
/// [VideoPlayerCallbacks] to handle playback events.
class OmniVideoPlayerFullscreen extends StatefulWidget {
  final OmniPlaybackController controller;
  final VideoPlayerConfiguration configuration;
  final VideoPlayerCallbacks callbacks;

  const OmniVideoPlayerFullscreen({
    super.key,
    required this.controller,
    required this.configuration,
    required this.callbacks,
  });

  @override
  State<OmniVideoPlayerFullscreen> createState() =>
      _OmniVideoPlayerFullscreenState();
}

class _OmniVideoPlayerFullscreenState extends State<OmniVideoPlayerFullscreen> {
  late final double _effectiveAspectRatio;

  @override
  void initState() {
    super.initState();
    _enterFullscreenMode();
    _effectiveAspectRatio = _computeAspectRatio();
  }

  @override
  void dispose() {
    _exitFullscreenMode();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  /// Hides system UI overlays (status bar, navigation bar)
  /// to provide an immersive viewing experience.
  void _enterFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  /// Restores the normal system UI mode.
  void _exitFullscreenMode() {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
  }

  /// Computes the video aspect ratio considering rotation or user override.
  double _computeAspectRatio() {
    final rotation = widget.controller.rotationCorrection;
    final size = widget.controller.size;

    // User override takes priority.
    final customRatio = widget
        .configuration
        .playerUIVisibilityOptions
        .customAspectRatioFullScreen;
    if (customRatio != null) return customRatio;

    // Handle 90° / 270° rotation cases.
    final isRotated = rotation == 90 || rotation == 270;
    return isRotated ? size.height / size.width : size.width / size.height;
  }

  @override
  Widget build(BuildContext context) {
    final playerContent = _buildFullscreenPlayer(context);
    final customWrapper =
        widget.configuration.customPlayerWidgets.fullscreenWrapper;

    // Allow wrapping in a custom builder (e.g., for transitions or effects)
    return customWrapper != null
        ? customWrapper(context, playerContent)
        : playerContent;
  }

  Widget _buildFullscreenPlayer(BuildContext context) {
    final shouldLockOrientation =
        widget.configuration.playerUIVisibilityOptions.enableOrientationLock;

    final preferredOrientation =
        widget.configuration.playerUIVisibilityOptions.fullscreenOrientation ??
        _getOrientationFromVideoSize();

    return OrientationLocker(
      enableOrientationLock: shouldLockOrientation,
      orientation: preferredOrientation,
      child: Material(
        color: Colors.black,
        child: OmniVideoPlayerControlsOverlay(
          playerBarPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 16,
          ),
          controller: widget.controller,
          configuration: widget.configuration,
          callbacks: widget.callbacks,
          child: Align(
            alignment: Alignment.center,
            child: OmniVideoPlayerViewport(
              controller: widget.controller,
              isFullScreenDisplay: true,
              aspectRatio: _effectiveAspectRatio,
            ),
          ),
        ),
      ),
    );
  }

  /// Determines orientation preference (portrait/landscape)
  /// based on the video dimensions when not explicitly provided.
  Orientation _getOrientationFromVideoSize() {
    final size = widget.controller.size;
    return size.height > size.width
        ? Orientation.portrait
        : Orientation.landscape;
  }
}
