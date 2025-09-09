import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omni_video_player/src/widgets/auto_hide_controls_manager.dart';
import 'package:omni_video_player/src/widgets/auto_hide_play_pause_button.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/gradient_bottom_control_bar.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/video_playback_control_bar.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';

import 'indicators/animated_skip_indicator.dart';
import 'indicators/loader_indicator.dart';

/// A widget that overlays video playback controls on top of a video display.
///
/// This widget manages the visibility of playback controls including a play/pause button
/// and a bottom control bar with playback progress and other controls. It supports
/// auto-hiding controls after a configurable timeout period, which differs between
/// web and mobile platforms for optimized user experience.
///
/// Key features:
/// - Wraps the video content [child] and overlays playback controls.
/// - Toggles control visibility on user tap gestures.
/// - Auto-hides controls after a timeout (2 seconds by default).
/// - Shows a customizable bottom control bar or defaults to a standard control bar.
/// - Displays an auto-hide play/pause button.
/// - Supports playback state and interaction through [OmniPlaybackController].
///
/// The auto-hide timers are set separately for web and mobile platforms to
/// accommodate typical user interaction patterns.
class VideoOverlayControls extends StatefulWidget {
  const VideoOverlayControls({
    super.key,
    required this.child,
    required this.controller,
    this.playerBarPadding = const EdgeInsets.only(right: 8, left: 8, top: 16),
    required this.options,
    required this.callbacks,
  });

  final OmniPlaybackController controller;
  final Widget child;
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final EdgeInsets playerBarPadding;

  @override
  State<VideoOverlayControls> createState() => _VideoOverlayControlsState();
}

class _VideoOverlayControlsState extends State<VideoOverlayControls>
    with SingleTickerProviderStateMixin {
  /// Indicates the direction of the skip (forward or backward). Null means no skip indicator.
  SkipDirection? _skipDirection;

  /// Number of seconds to skip.
  int _skipSeconds = 0;

  late final AnimationController _animationController;

  _TapInteractionState _tapState = _TapInteractionState.idle;

  @override
  void initState() {
    super.initState();
    // Initializes the animation controller for the skip indicator (fade-out effect).
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2, milliseconds: 500),
    );
  }

  /// Triggers the skip indicator with the given direction and duration.
  void _showSkip(SkipDirection direction, int skipSeconds) {
    setState(() {
      _skipDirection = direction;
      _skipSeconds = skipSeconds;
      _tapState = direction == SkipDirection.forward
          ? _TapInteractionState.doubleTapForward
          : _TapInteractionState.doubleTapBackward;
    });
    _animationController.reset();
    _animationController.forward().then((_) {
      setState(() {
        _skipDirection = null;
        _tapState = _TapInteractionState.idle;
      });
    });
  }

  void handleDoubleTap(SkipDirection direction) {
    final isBackward = direction == SkipDirection.backward;

    // Controlli iniziali
    if ((isBackward &&
            !widget.options.playerUIVisibilityOptions.enableBackwardGesture) ||
        (!isBackward &&
            !widget.options.playerUIVisibilityOptions.enableForwardGesture) ||
        widget.controller.isFinished ||
        !widget.controller.hasStarted) {
      return;
    }

    int skipSeconds = 5;

    // Incremento progressivo
    if (_skipDirection == direction &&
        (_tapState ==
            (isBackward
                ? _TapInteractionState.doubleTapBackward
                : _TapInteractionState.doubleTapForward))) {
      switch (_skipSeconds) {
        case 5:
          skipSeconds = 10;
          break;
        case 10:
          skipSeconds = 30;
          break;
        default:
          skipSeconds = 30;
      }
    }

    final currentPosition = widget.controller.currentPosition;
    final targetPosition = isBackward
        ? currentPosition - Duration(seconds: skipSeconds)
        : currentPosition + Duration(seconds: skipSeconds);

    // Limiti
    if ((isBackward && targetPosition < Duration.zero) ||
        (!isBackward && targetPosition > widget.controller.duration)) {
      return;
    }

    widget.controller.seekTo(
      targetPosition < Duration.zero
          ? Duration.zero
          : (targetPosition > widget.controller.duration
              ? widget.controller.duration
              : targetPosition),
    );

    _showSkip(direction, skipSeconds);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, __) {
        return AutoHideControlsManager(
          controller: widget.controller,
          options: widget.options,
          callbacks: widget.callbacks,
          builder: (context, areControlsVisible, toggleVisibility) {
            bool areOverlayControlsVisible =
                (widget.controller.isPlaying || widget.controller.isSeeking) &&
                    widget.options.playerUIVisibilityOptions
                        .showVideoBottomControlsBar &&
                    areControlsVisible &&
                    _tapState != _TapInteractionState.doubleTapForward &&
                    _tapState != _TapInteractionState.doubleTapBackward;

            bool isVisibleButton = widget.controller.isFinished ||
                (areControlsVisible &&
                    !widget.controller.isBuffering &&
                    !widget.controller.isSeeking &&
                    widget.controller.isReady &&
                    !(widget.controller.isFinished &&
                        !widget.options.playerUIVisibilityOptions
                            .showReplayButton) &&
                    _tapState != _TapInteractionState.doubleTapForward &&
                    _tapState != _TapInteractionState.doubleTapBackward);

            widget.callbacks.onCenterControlsVisibilityChanged
                ?.call(isVisibleButton);
            widget.callbacks.onOverlayControlsVisibilityChanged?.call(
              areOverlayControlsVisible,
            );

            List<Widget> layers = [
              widget.child,

              // Transparent layer to ensure tap detection on web (e.g., InAppWebView).
              Container(
                color: Colors.transparent,
                width: double.infinity,
                height: double.infinity,
              ),

              // Tap area for double tap (left = backward, right = forward).
              Positioned.fill(
                child: KeyboardListener(
                  focusNode: FocusNode()..requestFocus(),
                  onKeyEvent: (KeyEvent event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                        // Skip forward
                        handleDoubleTap(SkipDirection.forward);
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowLeft) {
                        // Skip backward
                        handleDoubleTap(SkipDirection.backward);
                      }
                    }
                  },
                  child: Row(
                    children: [
                      // Left side double-tap to rewind.
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onDoubleTap: () {
                            handleDoubleTap(SkipDirection.backward);
                          },
                          child: const SizedBox.expand(),
                        ),
                      ),

                      // Right side double-tap to fast-forward.
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onDoubleTap: () {
                            handleDoubleTap(SkipDirection.forward);
                          },
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Skip indicator shown in the center with fade out animation.
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: _skipDirection != null &&
                        (_tapState == _TapInteractionState.doubleTapForward ||
                            _tapState == _TapInteractionState.doubleTapBackward)
                    ? AnimatedSkipIndicator(
                        skipDirection: _skipDirection!,
                        skipSeconds: _skipSeconds,
                      )
                    : const SizedBox.shrink(),
              ),

              // Gradient bottom bar with playback controls.
              GradientBottomControlBar(
                isVisible: (areOverlayControlsVisible && !kIsWeb) ||
                    (kIsWeb && widget.controller.isPlaying),
                padding: widget.playerBarPadding,
                useSafeAreaForBottomControls: widget.options
                    .playerUIVisibilityOptions.useSafeAreaForBottomControls,
                showGradientBottomControl: widget.options
                    .playerUIVisibilityOptions.showGradientBottomControl,
                child: widget.options.customPlayerWidgets.bottomControlsBar ??
                    VideoPlaybackControlBar(
                      controller: widget.controller,
                      options: widget.options,
                      callbacks: widget.callbacks,
                    ),
              ),

              if (widget.controller.isSeeking) LoaderIndicator(),
              // Central play/pause button with auto-hide logic.
              AutoHidePlayPauseButton(
                isVisible: isVisibleButton,
                controller: widget.controller,
                options: widget.options,
                callbacks: widget.callbacks,
              ),
            ];

            for (final customOverlay
                in widget.options.customPlayerWidgets.customOverlayLayers) {
              if (customOverlay.ignoreOverlayControlsVisibility ||
                  areOverlayControlsVisible) {
                final size = widget.controller.size;

                final aspectRatio = widget.options.playerUIVisibilityOptions
                        .customAspectRatioNormal ??
                    size.width / size.height;

                layers.insert(
                  customOverlay.level,
                  Center(
                    child: AspectRatio(
                      aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
                      child: customOverlay.widget,
                    ),
                  ),
                );
              }
            }

            return GestureDetector(
              onTap: () {
                setState(() => _tapState = _TapInteractionState.singleTap);
                toggleVisibility();
              },
              onDoubleTap: () {
                setState(() => _tapState = _TapInteractionState.idle);
                toggleVisibility();
              },
              onVerticalDragUpdate: (details) {
                if (!widget.options.playerUIVisibilityOptions
                    .enableExitFullscreenOnVerticalSwipe) {
                  return;
                }
                // Exit fullscreen if the user drags downwards significantly.
                if (details.primaryDelta != null &&
                    details.primaryDelta! > 10) {
                  if (widget.controller.isFullScreen) {
                    widget.controller.switchFullScreenMode(
                      context,
                      pageBuilder: null,
                      onToggle: widget.callbacks.onFullScreenToggled,
                    );
                  }
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: layers,
              ),
            );
          },
        );
      },
    );
  }
}

/// Represents the type of user interaction detected via tap.
enum _TapInteractionState {
  idle,
  singleTap,
  doubleTapForward,
  doubleTapBackward,
}
