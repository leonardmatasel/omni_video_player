import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';

/// A configuration class that provides callback hooks for responding to video player events.
///
/// [VideoPlayerCallbacks] allows developers to attach custom logic
/// to lifecycle events, UI changes, and error handling during playback.
///
/// These callbacks are completely optional and non-intrusive.
///
/// Example usage:
/// ```dart
/// VideoPlayerCallbacks(
///   onControllerCreated: (controller) {
///     controller.play();
///   },
///   onFullScreenToggled: (isFullScreen) {
///     print('Fullscreen toggled: $isFullScreen');
///   },
/// )
/// ```
@immutable
class VideoPlayerCallbacks {
  /// Creates a new set of callback hooks for [OmniVideoPlayer] and related widgets.
  const VideoPlayerCallbacks({
    this.onControllerCreated,
    this.onFullScreenToggled,
    this.onOverlayControlsVisibilityChanged,
    this.onCenterControlsVisibilityChanged,
    this.onMuteToggled,
    this.onSeekStart,
    this.onSeekEnd,
    this.onFinished,
    this.onReplay,
  });

  /// Called once when the internal [OmniPlaybackController] is created and ready.
  ///
  /// This is the ideal place to auto-start playback or set up listeners.
  final void Function(OmniPlaybackController controller)? onControllerCreated;

  /// Called when the player enters or exits fullscreen mode.
  ///
  /// [isGoingFullScreen] is `true` if entering fullscreen, `false` if exiting.
  final void Function(bool isGoingFullScreen)? onFullScreenToggled;

  /// Called when overlay controls (e.g., seek bar, volume/mute, fullscreen) are shown or hidden.
  ///
  /// [areVisible] is `true` when controls are visible, `false` otherwise.
  final void Function(bool areVisible)? onOverlayControlsVisibilityChanged;

  /// Called when central controls (e.g., play/pause icon in the center) are shown or hidden.
  ///
  /// [areVisible] is `true` when controls are visible, `false` otherwise.
  final void Function(bool areVisible)? onCenterControlsVisibilityChanged;

  /// Called when the mute state is toggled.
  ///
  /// [isMute] is `true` if the video is now muted, `false` if unmuted.
  final void Function(bool isMute)? onMuteToggled;

  /// Called when the user starts seeking.
  ///
  /// [currentPosition] is the playback position where the seek started.
  final void Function(Duration currentPosition)? onSeekStart;

  /// Called when the user ends a seek operation.
  ///
  /// [currentPosition] is the final playback position after seeking.
  final void Function(Duration currentPosition)? onSeekEnd;

  /// Called when the video reaches the end of playback.
  ///
  /// This callback is triggered **once per video finish**.
  final VoidCallback? onFinished;

  /// Called when the user presses the replay button after the video has finished.
  final VoidCallback? onReplay;

  /// Returns a new [VideoPlayerCallbacks] instance with specified callbacks overridden.
  ///
  /// Useful to update specific callback handlers without redefining all.
  ///
  /// Parameters:
  ///
  /// - [onControllerCreated]: Callback when the controller is created.
  ///
  /// - [onFullScreenToggled]: Callback on fullscreen toggle.
  ///
  /// - [onOverlayControlsVisibilityChanged]: Callback when overlay controls visibility changes.
  ///
  /// - [onCenterControlsVisibilityChanged]: Callback when center controls visibility changes.
  ///
  /// - [onMuteToggled]: Callback when mute state toggles.
  ///
  /// - [onSeekStart]: Callback when seeking starts.
  ///
  /// - [onSeekEnd]: Callback when seeking ends.
  VideoPlayerCallbacks copyWith({
    void Function(OmniPlaybackController controller)? onControllerCreated,
    void Function(bool isGoingFullScreen)? onFullScreenToggled,
    void Function(bool areVisible)? onOverlayControlsVisibilityChanged,
    void Function(bool areVisible)? onCenterControlsVisibilityChanged,
    void Function(bool isMute)? onMuteToggled,
    void Function(Duration currentPosition)? onSeekStart,
    void Function(Duration currentPosition)? onSeekEnd,
    VoidCallback? onFinished,
    VoidCallback? onReplay,
  }) {
    return VideoPlayerCallbacks(
      onControllerCreated: onControllerCreated ?? this.onControllerCreated,
      onFullScreenToggled: onFullScreenToggled ?? this.onFullScreenToggled,
      onOverlayControlsVisibilityChanged: onOverlayControlsVisibilityChanged ??
          this.onOverlayControlsVisibilityChanged,
      onCenterControlsVisibilityChanged: onCenterControlsVisibilityChanged ??
          this.onCenterControlsVisibilityChanged,
      onMuteToggled: onMuteToggled ?? this.onMuteToggled,
      onSeekStart: onSeekStart ?? this.onSeekStart,
      onSeekEnd: onSeekEnd ?? this.onSeekEnd,
      onFinished: onFinished ?? this.onFinished,
      onReplay: onReplay ?? this.onReplay,
    );
  }
}
