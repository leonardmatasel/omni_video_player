import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/src/widgets/auto_hide_controls_manager.dart';
import 'package:omni_video_player/src/widgets/auto_hide_play_pause_button.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/gradient_bottom_control_bar.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/video_playback_control_bar.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';

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
///
/// Example usage:
/// ```dart
/// VideoOverlayControls(
///   controller: playbackController,
///   settings: videoPlayerOptions,
///   callbacks: videoPlayerCallbacks,
///   child: VideoPlayerDisplay(controller: playbackController),
/// )
/// ```
class VideoOverlayControls extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, __) {
        return AutoHideControlsManager(
          controlsPersistence:
              kIsWeb ? _hideControlsTimerWeb : _hideControlsTimerMobile,
          controller: controller,
          options: options,
          callbacks: callbacks,
          builder: (context, areControlsVisible, toggleVisibility) {
            bool areOverlayControlsVisible = (controller.isPlaying ||
                    controller.isSeeking) &&
                options.playerUIVisibilityOptions.showVideoBottomControlsBar &&
                areControlsVisible;

            bool isVisibleButton = areControlsVisible &&
                !controller.isBuffering &&
                !controller.isSeeking &&
                controller.isReady &&
                !(controller.isFinished &&
                    !options.playerUIVisibilityOptions.showReplayButton);

            callbacks.onCenterControlsVisibilityChanged?.call(isVisibleButton);
            callbacks.onOverlayControlsVisibilityChanged?.call(
              areOverlayControlsVisible,
            );

            return GestureDetector(
              onTap: toggleVisibility,
              behavior: HitTestBehavior.opaque,
              child: Stack(
                children: [
                  child,
                  // used because InAppWebView don't take the flutter tap event
                  Container(
                    color: Colors.transparent,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                  GradientBottomControlBar(
                    isVisible: areOverlayControlsVisible,
                    padding: playerBarPadding,
                    useSafeAreaForBottomControls: options
                        .playerUIVisibilityOptions.useSafeAreaForBottomControls,
                    showGradientBottomControl: options
                        .playerUIVisibilityOptions.showGradientBottomControl,
                    child: options.customPlayerWidgets.bottomControlsBar ??
                        VideoPlaybackControlBar(
                          controller: controller,
                          options: options,
                          callbacks: callbacks,
                        ),
                  ),
                  AutoHidePlayPauseButton(
                    isVisible: isVisibleButton,
                    controller: controller,
                    options: options,
                    callbacks: callbacks,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
