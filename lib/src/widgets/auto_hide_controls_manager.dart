import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/src/navigation/route_aware_listener.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';

/// A widget that manages automatic show/hide behavior of video playback controls.
///
/// This widget controls the visibility of video player controls based on
/// the playback state and user interaction. Controls are automatically hidden
/// after a configurable duration ([controlsPersistence]) when the video is playing,
/// and shown again when the video is paused, finished, or when the user interacts
/// with the video area.
///
/// The visibility state is exposed via the [builder], which receives the current
/// visibility status and a toggle callback for user interaction.
///
/// The widget listens to playback events through the provided [controller],
/// notifies visibility changes via [callbacks], and supports additional
/// configuration through [options].
///
/// Example usage:
/// ```dart
/// AutoHideControlsManager(
///   controller: mediaController,
///   settings: videoSettings,
///   callbacks: videoCallbacks,
///   controlsPersistence: Duration(seconds: 3),
///   builder: (context, areVisible, toggleVisibility) {
///     return Stack(
///       children: [
///         videoWidget,
///         if (areVisible) controlsWidget,
///       ],
///     );
///   },
/// )
/// ```
class AutoHideControlsManager extends StatefulWidget {
  /// Builder that builds UI based on controls visibility state.
  ///
  /// Provides:
  /// - [areVisible]: whether the controls are currently visible.
  /// - [toggleVisibilityTap]: callback to toggle visibility on user tap.
  final Widget Function(
    BuildContext context,
    bool areVisible,
    VoidCallback toggleVisibilityTap,
  ) builder;

  /// Controller managing video playback state.
  final OmniPlaybackController controller;

  /// Video player options used to customize behavior.
  final VideoPlayerConfiguration options;

  /// Callback hooks for video player events.
  final VideoPlayerCallbacks callbacks;

  /// Duration controls remain visible after interaction while video is playing.
  final Duration controlsPersistence;

  const AutoHideControlsManager({
    super.key,
    required this.builder,
    required this.controller,
    required this.options,
    required this.callbacks,
    required this.controlsPersistence,
  });

  @override
  State<AutoHideControlsManager> createState() =>
      _AutoHideControlsManagerState();
}

class _AutoHideControlsManagerState extends State<AutoHideControlsManager>
    with SingleTickerProviderStateMixin {
  bool isShowing = true;
  bool isPlaying = false;

  late AnimationController _hideTimer;

  @override
  void initState() {
    super.initState();
    _hideTimer = AnimationController(
      vsync: this,
      duration: widget.controlsPersistence,
      value: 0,
    );

    isPlaying = widget.controller.isPlaying &&
        !widget.controller.isSeeking &&
        widget.controller.isReady;
    if (isPlaying) {
      _startHideTimer();
    }
  }

  @override
  void didUpdateWidget(covariant AutoHideControlsManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handlePlayingStateChange(
      widget.controller.isPlaying && !widget.controller.isSeeking,
    );
  }

  void _setIsShowing(bool value) {
    if (value != isShowing) {
      setState(() => isShowing = value);
      WidgetsBinding.instance.addPostFrameCallback((_) {});
    }
  }

  void _toggleIsShowing() {
    if (widget.controller.isFinished && widget.controller.isSeeking) return;

    bool previous = isShowing;
    _setIsShowing(!isShowing);
    _manageTimer(
      prevIsPlaying: isPlaying,
      currentIsPlaying: isPlaying,
      prevShowControls: previous,
      currentShowControls: isShowing,
    );
  }

  void _startHideTimer() {
    _hideTimer.forward(from: 0).then((_) {
      if (mounted && isShowing) {
        _setIsShowing(false);
      }
    });
  }

  void _handlePlayingStateChange(bool newIsPlaying) {
    if (isPlaying != newIsPlaying) {
      if (!newIsPlaying && isPlaying) {
        _setIsShowing(true);
      }
      setState(() => isPlaying = newIsPlaying);

      _manageTimer(
        prevIsPlaying: !newIsPlaying,
        currentIsPlaying: newIsPlaying,
        prevShowControls: isShowing,
        currentShowControls: isShowing,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareListener(
      onPopNext: (_) {
        _setIsShowing(true);
        if (isPlaying) _startHideTimer();
      },
      child: Listener(
        onPointerHover: (event) {
          if (kIsWeb) {
            _setIsShowing(true);
            if (isPlaying) _startHideTimer();
          }
        },
        child: widget.builder(context, isShowing, _toggleIsShowing),
      ),
    );
  }

  void _manageTimer({
    required bool prevIsPlaying,
    required bool currentIsPlaying,
    required bool prevShowControls,
    required bool currentShowControls,
  }) {
    if (currentIsPlaying && !prevShowControls && currentShowControls) {
      _startHideTimer();
      return;
    }
    if (currentShowControls && !prevIsPlaying && currentIsPlaying) {
      _startHideTimer();
      return;
    }
    _hideTimer.stop();
  }

  @override
  void dispose() {
    _hideTimer.dispose();
    super.dispose();
  }
}
