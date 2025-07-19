import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  static const _hideControlsTimerWeb = Duration(milliseconds: 2000);
  static const _hideControlsTimerMobile = Duration(milliseconds: 2000);

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

  Timer? _tapDebounceTimer;
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
          controlsPersistence: kIsWeb
              ? VideoOverlayControls._hideControlsTimerWeb
              : VideoOverlayControls._hideControlsTimerMobile,
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

            bool isVisibleButton = areControlsVisible &&
                !widget.controller.isBuffering &&
                !widget.controller.isSeeking &&
                widget.controller.isReady &&
                !(widget.controller.isFinished &&
                    !widget
                        .options.playerUIVisibilityOptions.showReplayButton) &&
                _tapState != _TapInteractionState.doubleTapForward &&
                _tapState != _TapInteractionState.doubleTapBackward;

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
                child: Row(
                  children: [
                    // Left side double-tap to rewind.
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () {
                          if (!widget.options.playerUIVisibilityOptions
                              .enableBackwardGesture) {
                            return;
                          }
                          int skipSeconds = 5;

                          if (_skipDirection == SkipDirection.backward &&
                              _tapState ==
                                  _TapInteractionState.doubleTapBackward) {
                            switch (_skipSeconds) {
                              case 5:
                                skipSeconds = 10;
                                break;
                              default:
                                skipSeconds = 30;
                            }
                          }

                          final currentPosition =
                              widget.controller.currentPosition;
                          final targetPosition =
                              currentPosition - Duration(seconds: skipSeconds);
                          widget.controller.seekTo(
                            targetPosition > Duration.zero
                                ? targetPosition
                                : Duration.zero,
                          );
                          _showSkip(SkipDirection.backward, skipSeconds);
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),

                    // Right side double-tap to fast-forward.
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onDoubleTap: () {
                          if (!widget.options.playerUIVisibilityOptions
                              .enableForwardGesture) {
                            return;
                          }
                          int skipSeconds = 5;

                          if (_skipDirection == SkipDirection.forward &&
                              _tapState ==
                                  _TapInteractionState.doubleTapForward) {
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

                          final currentPosition =
                              widget.controller.currentPosition;
                          final targetPosition =
                              currentPosition + Duration(seconds: skipSeconds);
                          widget.controller.seekTo(targetPosition);
                          _showSkip(SkipDirection.forward, skipSeconds);
                        },
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
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
                isVisible: areOverlayControlsVisible,
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

            if (widget.options.customPlayerWidgets.customOverlayLayer != null &&
                areOverlayControlsVisible) {
              final customOverlay =
                  widget.options.customPlayerWidgets.customOverlayLayer!;
              final rotation = widget.controller.rotationCorrection;
              final size = widget.controller.size;

              final aspectRatio = (rotation == 90 || rotation == 270)
                  ? size.height / size.width
                  : size.width / size.height;

              layers.insert(
                customOverlay.level,
                Center(
                  child: AspectRatio(
                    aspectRatio: aspectRatio,
                    child: customOverlay.widget,
                  ),
                ),
              );
            }

            return GestureDetector(
              onTap: () {
                if (!widget.controller.isPlaying &&
                    (_tapState == _TapInteractionState.doubleTapBackward ||
                        _tapState == _TapInteractionState.doubleTapForward)) {
                  setState(() => _tapState = _TapInteractionState.singleTap);
                  return;
                }

                // Wait to determine whether it's a single or double tap.
                _tapDebounceTimer?.cancel();
                _tapDebounceTimer =
                    Timer(const Duration(milliseconds: 300), () {
                  if ((_tapState != _TapInteractionState.doubleTapBackward &&
                      _tapState != _TapInteractionState.doubleTapForward)) {
                    setState(() => _tapState = _TapInteractionState.singleTap);
                    toggleVisibility();
                  }
                });
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
