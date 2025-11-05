import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/navigation/route_aware_listener.dart';

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
  /// - [pauseAutoHide]: pause auto-hide while modal overlays are open.
  /// - [resumeAutoHide]: resume auto-hide when modal overlays close.
  final Widget Function(
    BuildContext context,
    bool areVisible,
    VoidCallback toggleVisibilityTap,
    VoidCallback pauseAutoHide,
    VoidCallback resumeAutoHide,
  )
  builder;

  /// Controller managing video playback state.
  final OmniPlaybackController controller;

  /// Video player options used to customize behavior.
  final VideoPlayerConfiguration options;

  /// Callback hooks for video player events.
  final VideoPlayerCallbacks callbacks;

  const AutoHideControlsManager({
    super.key,
    required this.builder,
    required this.controller,
    required this.options,
    required this.callbacks,
  });

  @override
  State<AutoHideControlsManager> createState() =>
      _AutoHideControlsManagerState();
}

class _AutoHideControlsManagerState extends State<AutoHideControlsManager>
    with TickerProviderStateMixin {
  bool isShowing = true;
  bool isPlaying = false;

  late AnimationController _persistenceTimer;
  bool _paused = false;

  @override
  void initState() {
    super.initState();

    _persistenceTimer = AnimationController(
      vsync: this,
      duration:
          widget.options.playerUIVisibilityOptions.controlsPersistenceDuration,
    );

    isPlaying =
        widget.controller.isPlaying &&
        !widget.controller.isSeeking &&
        widget.controller.isReady;
    if (isPlaying) {
      _startPersistenceTimer();
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

    // Mostro o nascondo subito i controlli
    _setIsShowing(!isShowing);

    // Avvio reaction timer solo se sto mostrando i controlli (fade-in delay)
    if (!isShowing) {
      _persistenceTimer.stop();
    }

    _manageTimers(
      prevIsPlaying: isPlaying,
      currentIsPlaying: isPlaying,
      prevShowControls: previous,
      currentShowControls: isShowing,
    );
  }

  void _startPersistenceTimer() {
    _persistenceTimer.forward(from: 0).then((_) {
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

      _manageTimers(
        prevIsPlaying: !newIsPlaying,
        currentIsPlaying: newIsPlaying,
        prevShowControls: isShowing,
        currentShowControls: isShowing,
      );
    }
  }

  void _manageTimers({
    required bool prevIsPlaying,
    required bool currentIsPlaying,
    required bool prevShowControls,
    required bool currentShowControls,
  }) {
    if (currentIsPlaying && !prevShowControls && currentShowControls) {
      _startPersistenceTimer();
      return;
    }
    if (currentShowControls && !prevIsPlaying && currentIsPlaying) {
      _startPersistenceTimer();
      return;
    }
    _persistenceTimer.stop();
  }

  // Called when user interacts with the controls area (touch, tap, move).
  // Shows controls and restarts the persistence timer so sub-menus/dialogs
  // remain visible for the full configured duration after interaction.
  void _onInteraction([PointerEvent? _]) {
    if (_paused) return;
    // Ensure controls are visible on interaction
    _setIsShowing(true);
    // Restart persistence timer if playing
    if (isPlaying) {
      // stop any running animation and restart from 0
      _persistenceTimer.stop();
      _startPersistenceTimer();
    }
  }

  /// Pause auto-hide behavior. While paused, interactions won't restart the timer
  /// and the manager will not hide controls automatically.
  void pauseAutoHide() {
    _paused = true;
    _persistenceTimer.stop();
  }

  /// Resume auto-hide behavior and restart the persistence timer when appropriate.
  void resumeAutoHide() {
    if (!_paused) return;
    _paused = false;
    if (isPlaying && isShowing) {
      _persistenceTimer.stop();
      _startPersistenceTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return RouteAwareListener(
      onPopNext: (_) {
        _setIsShowing(true);
        if (isPlaying) _startPersistenceTimer();
      },
      child: Listener(
        onPointerMove: _onInteraction,
        onPointerHover: (event) {
          if (kIsWeb) {
            _onInteraction(event);
          }
        },
        child: widget.builder(
          context,
          isShowing,
          _toggleIsShowing,
          pauseAutoHide,
          resumeAutoHide,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _persistenceTimer.dispose();
    super.dispose();
  }
}
