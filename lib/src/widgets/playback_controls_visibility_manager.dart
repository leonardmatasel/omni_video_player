import 'dart:async';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/navigation/route_aware_listener.dart';

class PlaybackControlsVisibilityManager extends StatefulWidget {
  final OmniPlaybackController controller;
  final VideoPlayerConfiguration configuration;
  final VideoPlayerCallbacks callbacks;

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
    extends State<PlaybackControlsVisibilityManager> {
  bool _areControlsVisible = true;
  bool _isCurrentlyPlaying = false;

  Timer? _autoHideTimer;

  Duration get _persistenceDuration => widget
      .configuration
      .playerUIVisibilityOptions
      .controlsPersistenceDuration;

  OmniPlaybackController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();

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

  void _toggleVisibility() {
    if (_controller.isFinished && _controller.isSeeking) return;

    final wasVisible = _areControlsVisible;
    _setControlsVisibility(!wasVisible);

    if (_areControlsVisible && _isCurrentlyPlaying) {
      _restartAutoHideTimer();
    } else {
      _autoHideTimer?.cancel();
    }
  }

  void _setControlsVisibility(bool isVisible) {
    if (isVisible == _areControlsVisible) return;
    setState(() => _areControlsVisible = isVisible);
  }

  void _restartAutoHideTimer() {
    _autoHideTimer?.cancel();

    _autoHideTimer = Timer(_persistenceDuration, () {
      if (mounted && _areControlsVisible) {
        _setControlsVisibility(false);
      }
    });
  }

  void _handlePlaybackStateChange(bool isNowPlaying) {
    if (isNowPlaying == _isCurrentlyPlaying) return;

    if (!isNowPlaying && _isCurrentlyPlaying) {
      _setControlsVisibility(true);
    }

    setState(() => _isCurrentlyPlaying = isNowPlaying);

    if (isNowPlaying && _areControlsVisible) {
      _restartAutoHideTimer();
    } else {
      _autoHideTimer?.cancel();
    }
  }

  void _pauseAutoHideTimer() {
    _autoHideTimer?.cancel();
    if (!_areControlsVisible) {
      _setControlsVisibility(true);
    }
  }

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
    _autoHideTimer?.cancel();
    super.dispose();
  }
}
