import 'dart:math';

import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/player_ui_visibility_options.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/widgets/playback_controls_visibility_manager.dart';
import 'package:omni_video_player/src/widgets/playback_center_button.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/gradient_bottom_control_bar.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/video_playback_control_bar.dart';
import '../../widgets/indicators/animated_skip_indicator.dart';
import '../../widgets/indicators/loader_indicator.dart';

/// Overlay widget managing playback controls, gestures, and skip indicators.
///
/// Features:
/// - Auto-hiding and showing of controls.
/// - Double-tap to skip forward/backward.
/// - Gradient bottom bar with playback controls.
/// - Optional custom overlay layers.
class OmniVideoPlayerControlsOverlay extends StatefulWidget {
  const OmniVideoPlayerControlsOverlay({
    super.key,
    required this.child,
    required this.controller,
    required this.configuration,
    required this.callbacks,
    this.playerBarPadding = const EdgeInsets.only(right: 8, left: 8, top: 16),
  });

  final OmniPlaybackController controller;
  final Widget child;
  final VideoPlayerConfiguration configuration;
  final VideoPlayerCallbacks callbacks;
  final EdgeInsets playerBarPadding;

  @override
  State<OmniVideoPlayerControlsOverlay> createState() =>
      _OmniVideoPlayerControlsOverlayState();
}

class _OmniVideoPlayerControlsOverlayState
    extends State<OmniVideoPlayerControlsOverlay>
    with SingleTickerProviderStateMixin {
  SkipDirection? _skipDirection;
  int _skipSeconds = 0;
  late final AnimationController _animationController;
  late final FocusNode _focusKeyboard = FocusNode();
  _TapInteractionState _tapState = _TapInteractionState.idle;

  static const _skipDurations = [5, 10, 30];
  static const _skipFadeDuration = Duration(milliseconds: 500);
  static const _skipAnimationDuration = Duration(milliseconds: 2500);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _skipAnimationDuration,
    );
    _focusKeyboard.requestFocus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 🌀 TAP HANDLERS ------------------------------------------------------------

  /// Handles a double tap gesture in the given [direction].
  void _onDoubleTap(SkipDirection direction) {
    final isBackward = direction == SkipDirection.backward;
    final opts = widget.configuration.playerUIVisibilityOptions;
    final ctrl = widget.controller;

    if ((isBackward && !opts.enableBackwardGesture) ||
        (!isBackward && !opts.enableForwardGesture) ||
        ctrl.isFinished ||
        !ctrl.hasStarted) {
      return;
    }

    int nextSkip = _calculateNextSkip(direction);

    final newPosition = isBackward
        ? ctrl.currentPosition - Duration(seconds: nextSkip)
        : ctrl.currentPosition + Duration(seconds: nextSkip);

    // Prevent seeking beyond video limits.
    if (newPosition < Duration.zero || newPosition > ctrl.duration) return;

    if (!ctrl.isSeeking) ctrl.wasPlayingBeforeSeek = ctrl.isPlaying;
    if (ctrl.isReady) ctrl.isSeeking = true;

    // Manually clamp Duration between 0 and controller.duration
    final clampedPosition = newPosition < Duration.zero
        ? Duration.zero
        : (newPosition > ctrl.duration ? ctrl.duration : newPosition);

    ctrl.seekTo(clampedPosition);
    _showSkip(direction, nextSkip);
  }

  /// Calculates next skip amount (progressive: 5 → 10 → 30 seconds).
  int _calculateNextSkip(SkipDirection direction) {
    if (_skipDirection == direction &&
        (_tapState ==
            (direction == SkipDirection.backward
                ? _TapInteractionState.doubleTapBackward
                : _TapInteractionState.doubleTapForward))) {
      final nextIndex = _skipDurations.indexOf(_skipSeconds) + 1;
      return _skipDurations[min(nextIndex, _skipDurations.length - 1)];
    }
    return _skipDurations.first;
  }

  /// Triggers skip animation and updates internal state.
  void _showSkip(SkipDirection direction, int skipSeconds) {
    setState(() {
      _skipDirection = direction;
      _skipSeconds = skipSeconds;
      _tapState = direction == SkipDirection.forward
          ? _TapInteractionState.doubleTapForward
          : _TapInteractionState.doubleTapBackward;
    });

    _animationController
      ..reset()
      ..forward().then((_) {
        if (mounted) {
          setState(() {
            _skipDirection = null;
            _tapState = _TapInteractionState.idle;
          });
        }
      });
  }

  // 🧩 UI BUILD ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = OmniVideoPlayerTheme.of(context)!;

    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return PlaybackControlsVisibilityManager(
          controller: widget.controller,
          configuration: widget.configuration,
          callbacks: widget.callbacks,
          builder:
              (context, areControlsVisible, toggle, pauseTimer, resumeTimer) {
                final ctrl = widget.controller;
                final opts = widget.configuration.playerUIVisibilityOptions;

                final areOverlayVisible = _shouldShowOverlay(
                  areControlsVisible,
                  ctrl,
                  opts,
                );
                final isButtonVisible = _shouldShowCenterButton(
                  areControlsVisible,
                  ctrl,
                  opts,
                );

                widget.callbacks.onCenterControlsVisibilityChanged?.call(
                  isButtonVisible,
                );
                widget.callbacks.onOverlayControlsVisibilityChanged?.call(
                  areOverlayVisible,
                );

                final layers = _buildOverlayLayers(
                  theme: theme,
                  areOverlayVisible: areOverlayVisible,
                  isButtonVisible: isButtonVisible,
                  toggleVisibility: toggle,
                  onStartInteraction: pauseTimer,
                  onEndInteraction: resumeTimer,
                );

                return Semantics(
                  label: theme.accessibility.controlsVisibleLabel,
                  toggled: isButtonVisible,
                  container: true,
                  explicitChildNodes: false,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(
                        () => _tapState = _TapInteractionState.singleTap,
                      );
                      toggle();
                    },
                    onDoubleTap: () {
                      setState(() => _tapState = _TapInteractionState.idle);
                      toggle();
                    },
                    onVerticalDragUpdate: _handleVerticalDrag,
                    child: Stack(children: layers),
                  ),
                );
              },
        );
      },
    );
  }

  // 🧱 LAYER BUILDERS ----------------------------------------------------------

  List<Widget> _buildOverlayLayers({
    required OmniVideoPlayerThemeData theme,
    required bool areOverlayVisible,
    required bool isButtonVisible,
    required VoidCallback toggleVisibility,
    required VoidCallback onStartInteraction,
    required VoidCallback onEndInteraction,
  }) {
    final ctrl = widget.controller;

    final layers = <Widget>[
      Positioned.directional(
        textDirection: TextDirection.ltr,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(child: widget.child),
        ),
      ),

      _buildDoubleTapZones(),
      Positioned.fill(
        child: Align(alignment: Alignment.center, child: _buildSkipIndicator()),
      ),
      _buildBottomBar(
        areOverlayVisible,
        onStartInteraction: onStartInteraction,
        onEndInteraction: onEndInteraction,
      ),
      if (ctrl.isSeeking)
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: const LoaderIndicator(),
          ),
        ),
      Positioned.fill(child: _buildCenterButton(isButtonVisible)),
    ];

    // Add custom overlay layers from configuration
    for (final overlay
        in widget.configuration.customPlayerWidgets.customOverlayLayers) {
      if (overlay.ignoreOverlayControlsVisibility || areOverlayVisible) {
        final aspectRatio =
            widget
                .configuration
                .playerUIVisibilityOptions
                .customAspectRatioNormal ??
            (ctrl.size.width / ctrl.size.height);
        layers.insert(
          overlay.level,
          Positioned.fill(
            child: AspectRatio(
              aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
              child: overlay.widget,
            ),
          ),
        );
      }
    }

    return layers;
  }

  Widget _buildDoubleTapZones() => Positioned.fill(
    child: ExcludeSemantics(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () => _onDoubleTap(SkipDirection.backward),
              child: const SizedBox.expand(),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTap: () => _onDoubleTap(SkipDirection.forward),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSkipIndicator() => AnimatedSwitcher(
    duration: _skipFadeDuration,
    child:
        _skipDirection != null &&
            (_tapState == _TapInteractionState.doubleTapForward ||
                _tapState == _TapInteractionState.doubleTapBackward)
        ? AnimatedSkipIndicator(
            skipDirection: _skipDirection!,
            skipSeconds: _skipSeconds,
          )
        : const SizedBox.shrink(),
  );

  Widget _buildBottomBar(
    bool isVisible, {
    required VoidCallback onStartInteraction,
    required VoidCallback onEndInteraction,
  }) => GradientBottomControlBar(
    isVisible: isVisible,
    padding: widget.playerBarPadding,
    useSafeAreaForBottomControls: widget
        .configuration
        .playerUIVisibilityOptions
        .useSafeAreaForBottomControls,
    showGradientBottomControl: widget
        .configuration
        .playerUIVisibilityOptions
        .showGradientBottomControl,
    child:
        widget.configuration.customPlayerWidgets.bottomControlsBar ??
        VideoPlaybackControlBar(
          controller: widget.controller,
          options: widget.configuration,
          callbacks: widget.callbacks,
          onStartInteraction: onStartInteraction,
          onEndInteraction: onEndInteraction,
        ),
  );

  Widget _buildCenterButton(bool isVisible) => PlaybackCenterButton(
    visible: isVisible,
    controller: widget.controller,
    configuration: widget.configuration,
    callbacks: widget.callbacks,
  );

  // 🔄 STATE HELPERS -----------------------------------------------------------

  bool _shouldShowOverlay(
    bool areControlsVisible,
    OmniPlaybackController ctrl,
    PlayerUIVisibilityOptions opts,
  ) {
    return ((ctrl.isPlaying || ctrl.isSeeking) &&
            opts.showVideoBottomControlsBar &&
            areControlsVisible &&
            !_isInDoubleTapState) ||
        opts.alwaysShowBottomControlsBar ||
        (opts.showBottomControlsBarOnPause && !ctrl.isPlaying) ||
        (ctrl.isFullScreen &&
            ctrl.isFinished &&
            opts.showBottomControlsBarOnEndedFullscreen);
  }

  bool _shouldShowCenterButton(
    bool areControlsVisible,
    OmniPlaybackController ctrl,
    PlayerUIVisibilityOptions opts,
  ) {
    return ctrl.isFinished ||
        (areControlsVisible &&
            !ctrl.isBuffering &&
            !ctrl.isSeeking &&
            ctrl.isReady &&
            !(ctrl.isFinished && !opts.showReplayButton) &&
            !_isInDoubleTapState);
  }

  bool get _isInDoubleTapState =>
      _tapState == _TapInteractionState.doubleTapForward ||
      _tapState == _TapInteractionState.doubleTapBackward;

  void _handleVerticalDrag(DragUpdateDetails details) {
    final opts = widget.configuration.playerUIVisibilityOptions;
    if (!opts.enableExitFullscreenOnVerticalSwipe ||
        !widget.controller.isFullScreen) {
      return;
    }

    if (details.primaryDelta != null && details.primaryDelta!.abs() > 10) {
      widget.controller.switchFullScreenMode(
        context,
        pageBuilder: null,
        onToggle: widget.callbacks.onFullScreenToggled,
      );
    }
  }
}

// 📚 Interaction states for overlay tap gestures
enum _TapInteractionState {
  idle,
  singleTap,
  doubleTapForward,
  doubleTapBackward,
}
