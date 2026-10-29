import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/player_ui_visibility_options.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/_core/utils/open_fullscreen.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_viewport.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';

/// A full-screen video player widget that:
/// - Once grown, locks the orientation to the video and hides the system bars.
/// - Gives both back before shrinking.
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
  late Size _size;
  var _systemTaken = false;

  PlayerUIVisibilityOptions get _options =>
      widget.configuration.playerUIVisibilityOptions;

  @override
  void initState() {
    super.initState();
    onFullscreenSettled(context, enter: _takeSystem, exit: _giveSystemBack);
    _size = widget.controller.size;
    widget.controller.addListener(_onControllerUpdated);
  }

  // The controller notifies on every position tick: rebuild only when the
  // size changes, e.g. the real one arriving after fullscreen opened.
  void _onControllerUpdated() {
    if (widget.controller.size == _size) return;
    setState(() => _size = widget.controller.size);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerUpdated);
    // An app's forced pop skips the exit phases.
    _giveSystemBack();
    super.dispose();
  }

  /// Hides the system bars and locks the orientation; returns the one asked.
  Orientation? _takeSystem() {
    _systemTaken = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!_options.enableOrientationLock) return null;
    final orientation =
        _options.fullscreenOrientation ?? _getOrientationFromVideoSize();
    SystemChrome.setPreferredOrientations(
      orientation == Orientation.portrait
          ? [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]
          : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
    return orientation;
  }

  /// Gives the system bars and orientations back, once; returns the
  /// orientation they force, if one.
  Orientation? _giveSystemBack() {
    if (!_systemTaken) return null;
    _systemTaken = false;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    // Restored even without the lock. Flutter can't read the orientations the
    // app had before fullscreen: all of them unless the app says which (#75).
    final restore =
        _options.restoreOrientationsAfterFullscreen ?? DeviceOrientation.values;
    SystemChrome.setPreferredOrientations(restore);
    bool portrait(DeviceOrientation o) =>
        o == DeviceOrientation.portraitUp ||
        o == DeviceOrientation.portraitDown;
    if (restore.isEmpty) return null;
    if (restore.every(portrait)) return Orientation.portrait;
    if (!restore.any(portrait)) return Orientation.landscape;
    return null;
  }

  /// Computes the video aspect ratio considering rotation or user override.
  double _computeAspectRatio() {
    final rotation = widget.controller.rotationCorrection;
    final size = widget.controller.size;

    // User override takes priority.
    final customRatio = _options.customAspectRatioFullScreen;
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
    return Material(
      color: Colors.black,
      child: OmniVideoPlayerControlsOverlay(
        isFullScreenDisplay: true,
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
            aspectRatio: _computeAspectRatio(),
            videoFit: _options.videoFit,
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
