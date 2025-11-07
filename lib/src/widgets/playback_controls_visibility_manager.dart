import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/navigation/route_aware_listener.dart';

/// Manages automatic visibility of video playback controls based on user interaction
/// and playback state.
///
/// When a video is playing, the controls auto-hide after a configurable duration.
/// They reappear when playback is paused, finished, or when the user interacts
/// with the video area (e.g., tap or hover on web).
///
/// The [builder] function receives:
/// - [isVisible]: whether controls are currently shown.
/// - [onToggleVisibility]: callback to manually toggle control visibility.
/// - [pauseAutoHideTimer]: stops the auto-hide countdown (keeps controls visible).
/// - [resumeAutoHideTimer]: restarts the countdown to hide controls after inactivity.
///
/// Example:
/// ```dart
/// PlaybackControlsVisibilityManager(
///   controller: playbackController,
///   configuration: videoConfig,
///   callbacks: playerCallbacks,
///   builder: (context, isVisible, toggle, pauseTimer, resumeTimer) {
///     return Stack(
///       children: [
///         videoLayer,
///         if (isVisible) controlBar,
///       ],
///     );
///   },
/// );
/// ```
class PlaybackControlsVisibilityManager extends StatefulWidget {
  final OmniPlaybackController controller;
  final VideoPlayerConfiguration configuration;
  final VideoPlayerCallbacks callbacks;

  /// Builder for UI layers based on control visibility.
  final Widget Function(
    BuildContext context,
    bool isVisible,
    VoidCallback onToggleVisibility,
    VoidCallback pauseAutoHideTimer,
    VoidCallback resumeAutoHideTimer,
  )
  builder;

  const PlaybackControlsVisibilityManager({
    super.key,
    required this.controller,
    required this.configuration,
    required this.callbacks,
    required this.builder,
  });

  @override
  State<PlaybackControlsVisibilityManager> createState() =>
      _PlaybackControlsVisibilityManagerState();
}

class _PlaybackControlsVisibilityManagerState
    extends State<PlaybackControlsVisibilityManager>
    with TickerProviderStateMixin {
  /// Whether controls are currently visible.
  bool _areControlsVisible = true;

  /// Whether the player is currently in a playing state.
  bool _isCurrentlyPlaying = false;

  /// Timer used to auto-hide controls after inactivity.
  late final AnimationController _autoHideTimer;

  Duration get _persistenceDuration => widget
      .configuration
      .playerUIVisibilityOptions
      .controlsPersistenceDuration;

  OmniPlaybackController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();

    _autoHideTimer = AnimationController(
      vsync: this,
      duration: _persistenceDuration,
    );

    _isCurrentlyPlaying =
        _controller.isPlaying && !_controller.isSeeking && _controller.isReady;

    if (_isCurrentlyPlaying) {
      _restartAutoHideTimer();
    }
  }

  @override
  void didUpdateWidget(covariant PlaybackControlsVisibilityManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    _handlePlaybackStateChange(_controller.isPlaying && !_controller.isSeeking);
  }

  /// Toggles control visibility manually (e.g., on tap).
  void _toggleVisibility() {
    if (_controller.isFinished && _controller.isSeeking) return;

    final wasVisible = _areControlsVisible;
    _setControlsVisibility(!wasVisible);

    if (_areControlsVisible && _isCurrentlyPlaying) {
      _restartAutoHideTimer();
    } else {
      _autoHideTimer.stop();
    }
  }

  /// Updates the visibility flag and rebuilds.
  void _setControlsVisibility(bool isVisible) {
    if (isVisible == _areControlsVisible) return;
    setState(() => _areControlsVisible = isVisible);
  }

  /// Starts (or restarts) the persistence timer to auto-hide controls.
  void _restartAutoHideTimer() {
    _autoHideTimer
      ..stop()
      ..forward(from: 0).then((_) {
        if (mounted && _areControlsVisible) {
          _setControlsVisibility(false);
        }
      });
  }

  /// Reacts to playback state changes.
  void _handlePlaybackStateChange(bool isNowPlaying) {
    if (_isCurrentlyPlaying == isNowPlaying) return;

    if (!isNowPlaying && _isCurrentlyPlaying) {
      _setControlsVisibility(true);
    }

    setState(() => _isCurrentlyPlaying = isNowPlaying);

    if (isNowPlaying && _areControlsVisible) {
      _restartAutoHideTimer();
    } else {
      _autoHideTimer.stop();
    }
  }

  /// 🧩 Public methods exposed via builder

  /// Stops the auto-hide timer and keeps controls visible indefinitely.
  void _pauseAutoHideTimer() {
    _autoHideTimer.stop();
    if (!_areControlsVisible) {
      _setControlsVisibility(true);
    }
  }

  /// Restarts the auto-hide timer from zero, re-enabling auto-hide behavior.
  void _resumeAutoHideTimer() {
    if (_isCurrentlyPlaying) {
      _restartAutoHideTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareListener(
      onPopNext: (_) {
        _setControlsVisibility(true);
        if (_isCurrentlyPlaying) _restartAutoHideTimer();
      },
      child: widget.builder(
        context,
        _areControlsVisible,
        _toggleVisibility,
        _pauseAutoHideTimer,
        _resumeAutoHideTimer,
      ),
    );
  }

  @override
  void dispose() {
    _autoHideTimer.dispose();
    super.dispose();
  }
}
