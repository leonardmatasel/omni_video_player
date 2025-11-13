import 'package:flutter/material.dart';

/// Configuration options to control the visibility of various UI components
/// in the video player interface.
///
/// Use these options to customize which parts of the player UI are shown or hidden,
/// enabling a tailored user experience.
@immutable
class PlayerUIVisibilityOptions {
  /// Whether to display the seek bar.
  final bool showSeekBar;

  /// Whether to show the current playback time.
  final bool showCurrentTime;

  /// Whether to show the total video duration.
  final bool showDurationTime;

  /// Whether to show the remaining playback time.
  final bool showRemainingTime;

  /// Whether to show a live indicator when the video is a livestream.
  final bool showLiveIndicator;

  /// Whether to show the loading widget during buffering.
  final bool showLoadingWidget;

  /// Whether to display an error placeholder widget if playback fails.
  final bool showErrorPlaceholder;

  /// Whether to show the replay button after the video ends.
  final bool showReplayButton;

  /// Whether to show the thumbnail image before playback starts.
  final bool showThumbnailAtStart;

  /// Whether to display the bottom control bar.
  final bool showVideoBottomControlsBar;

  /// Whether to display the bottom control bar in fullscreen **after the video has ended**.
  final bool showBottomControlsBarOnEndedFullscreen;

  /// Whether to show the fullscreen toggle button.
  final bool showFullScreenButton;

  /// Whether to show the quality switch button.
  final bool showSwitchVideoQuality;

  /// Whether to show the switch quality button when only 'Auto' is available.
  ///
  /// - If `true`: the button is shown even when [availableVideoQualities] is empty,
  ///   and pressing it will open the dialog containing only the "auto" option.
  /// - If `false`: the button is hidden when [availableVideoQualities] is empty,
  ///   so the user cannot open a dialog that only contains "auto".
  final bool showSwitchWhenOnlyAuto;

  /// Whether to show the playback speed button in the UI.
  ///
  /// **Not applicable for live videos.**
  /// Default is `false`.
  final bool showPlaybackSpeedButton;

  /// Whether to show the mute/unmute toggle button.
  final bool showMuteUnMuteButton;

  /// Whether to wrap the bottom control bar inside a [SafeArea] widget
  /// to avoid overlaps with system UI elements like gesture bars or notches.
  final bool useSafeAreaForBottomControls;

  /// Whether to display a gradient overlay behind the bottom control bar.
  final bool showGradientBottomControl;

  /// Whether to show the main play/pause/replay button overlay
  /// (typically centered on the video).
  /// This only applies when the video is **not in full screen**.
  final bool showPlayPauseReplayButton;

  /// Whether to allow gesture-based fast-forward.
  final bool enableForwardGesture;

  /// Whether to allow gesture-based rewind.
  final bool enableBackwardGesture;

  /// Whether to allow exiting fullscreen via a vertical swipe down.
  final bool enableExitFullscreenOnVerticalSwipe;

  /// Whether to lock device orientation to the video orientation in fullscreen.
  ///
  /// If `true`, locks orientation to match the video while fullscreen.
  /// If `false`, does not lock orientation and uses system defaults.
  ///
  /// Defaults to `true`.
  final bool enableOrientationLock;

  /// Duration the controls remain visible after interaction while video is playing.
  ///
  /// After this duration without interaction, controls are hidden automatically.
  ///
  /// Defaults to 3 seconds.
  final Duration controlsPersistenceDuration;

  /// Optional custom aspect ratio for normal (non-fullscreen) mode.
  ///
  /// If `null`, the aspect ratio from the video controller is used.
  final double? customAspectRatioNormal;

  /// Optional custom aspect ratio for fullscreen mode.
  ///
  /// If `null`, the aspect ratio from the video controller is used.
  final double? customAspectRatioFullScreen;

  /// Optional orientation to use in fullscreen mode.
  ///
  /// If `null`, the orientation is inferred from the video size:
  /// portrait if height > width, otherwise landscape.
  final Orientation? fullscreenOrientation;

  /// Whether to always show the bottom control bar,
  /// even when the video is paused or hasn't started yet.
  final bool alwaysShowBottomControlsBar;

  /// Whether to display the bottom control bar when the video is paused.
  ///
  /// If `true`, the bottom bar remains visible when the player is paused.
  /// If `false`, it will follow the standard visibility behavior.
  final bool showBottomControlsBarOnPause;

  /// Whether to show the scrubbing thumbnail preview when dragging the seek bar.
  final bool showScrubbingThumbnailPreview;

  /// Creates a new instance of [PlayerUIVisibilityOptions].
  ///
  /// All options default to `true` except:
  /// - [useSafeAreaForBottomControls] defaults to `false`.
  /// - [showRefreshButtonInErrorPlaceholder] defaults to `true`.
  const PlayerUIVisibilityOptions({
    this.showSeekBar = true,
    this.showCurrentTime = true,
    this.showDurationTime = true,
    this.showRemainingTime = true,
    this.showLiveIndicator = true,
    this.showLoadingWidget = true,
    this.showErrorPlaceholder = true,
    this.showReplayButton = true,
    this.showThumbnailAtStart = true,
    this.showVideoBottomControlsBar = true,
    this.showBottomControlsBarOnEndedFullscreen = true,
    this.alwaysShowBottomControlsBar = false,
    this.showBottomControlsBarOnPause = false,
    this.showFullScreenButton = true,
    this.showMuteUnMuteButton = true,
    this.showPlayPauseReplayButton = true,
    this.useSafeAreaForBottomControls = false,
    this.showGradientBottomControl = true,
    this.enableForwardGesture = true,
    this.enableBackwardGesture = true,
    this.enableExitFullscreenOnVerticalSwipe = true,
    this.showSwitchVideoQuality = true,
    this.showSwitchWhenOnlyAuto = true,
    this.showPlaybackSpeedButton = false,
    this.enableOrientationLock = true,
    this.controlsPersistenceDuration = const Duration(seconds: 3),
    this.customAspectRatioNormal,
    this.customAspectRatioFullScreen,
    this.fullscreenOrientation,
    this.showScrubbingThumbnailPreview = true,
  });

  /// Returns a copy of this [PlayerUIVisibilityOptions] with
  /// the given fields replaced by the new values.
  PlayerUIVisibilityOptions copyWith({
    bool? showSeekBar,
    bool? showCurrentTime,
    bool? showDurationTime,
    bool? showRemainingTime,
    bool? showLiveIndicator,
    bool? showLoadingWidget,
    bool? showErrorPlaceholder,
    bool? showReplayButton,
    bool? showThumbnailAtStart,
    bool? showVideoBottomControlsBar,
    bool? showBottomControlsBarOnEndedFullscreen,
    bool? alwaysShowBottomControlsBar,
    bool? showBottomControlsBarOnPause,
    bool? showFullScreenButton,
    bool? showMuteUnMuteButton,
    bool? showPlayPauseReplayButton,
    bool? useSafeAreaForBottomControls,
    bool? showGradientBottomControl,
    bool? enableForwardGesture,
    bool? enableBackwardGesture,
    bool? enableExitFullscreenOnVerticalSwipe,
    bool? showSwitchVideoQuality,
    bool? showSwitchWhenOnlyAuto,
    bool? showPlaybackSpeedButton,
    bool? enableOrientationLock,
    Duration? controlsPersistenceDuration,
    double? customAspectRatioNormal,
    double? customAspectRatioFullScreen,
    Orientation? fullscreenOrientation,
    bool? showScrubbingThumbnailPreview,
  }) {
    return PlayerUIVisibilityOptions(
      showSeekBar: showSeekBar ?? this.showSeekBar,
      showCurrentTime: showCurrentTime ?? this.showCurrentTime,
      showDurationTime: showDurationTime ?? this.showDurationTime,
      showRemainingTime: showRemainingTime ?? this.showRemainingTime,
      showLiveIndicator: showLiveIndicator ?? this.showLiveIndicator,
      showLoadingWidget: showLoadingWidget ?? this.showLoadingWidget,
      showErrorPlaceholder: showErrorPlaceholder ?? this.showErrorPlaceholder,
      showReplayButton: showReplayButton ?? this.showReplayButton,
      showThumbnailAtStart: showThumbnailAtStart ?? this.showThumbnailAtStart,
      showVideoBottomControlsBar:
          showVideoBottomControlsBar ?? this.showVideoBottomControlsBar,
      showFullScreenButton: showFullScreenButton ?? this.showFullScreenButton,
      showMuteUnMuteButton: showMuteUnMuteButton ?? this.showMuteUnMuteButton,
      useSafeAreaForBottomControls:
          useSafeAreaForBottomControls ?? this.useSafeAreaForBottomControls,
      showGradientBottomControl:
          showGradientBottomControl ?? this.showGradientBottomControl,
      enableForwardGesture: enableForwardGesture ?? this.enableForwardGesture,
      enableBackwardGesture:
          enableBackwardGesture ?? this.enableBackwardGesture,
      enableExitFullscreenOnVerticalSwipe:
          enableExitFullscreenOnVerticalSwipe ??
          this.enableExitFullscreenOnVerticalSwipe,
      showSwitchVideoQuality:
          showSwitchVideoQuality ?? this.showSwitchVideoQuality,
      showSwitchWhenOnlyAuto:
          showSwitchWhenOnlyAuto ?? this.showSwitchWhenOnlyAuto,
      showPlaybackSpeedButton:
          showPlaybackSpeedButton ?? this.showPlaybackSpeedButton,
      enableOrientationLock:
          enableOrientationLock ?? this.enableOrientationLock,
      controlsPersistenceDuration:
          controlsPersistenceDuration ?? this.controlsPersistenceDuration,
      customAspectRatioNormal:
          customAspectRatioNormal ?? this.customAspectRatioNormal,
      customAspectRatioFullScreen:
          customAspectRatioFullScreen ?? this.customAspectRatioFullScreen,
      fullscreenOrientation:
          fullscreenOrientation ?? this.fullscreenOrientation,
      showPlayPauseReplayButton:
          showPlayPauseReplayButton ?? this.showPlayPauseReplayButton,
      showBottomControlsBarOnEndedFullscreen:
          showBottomControlsBarOnEndedFullscreen ??
          this.showBottomControlsBarOnEndedFullscreen,
      alwaysShowBottomControlsBar:
          alwaysShowBottomControlsBar ?? this.alwaysShowBottomControlsBar,
      showBottomControlsBarOnPause:
          showBottomControlsBarOnPause ?? this.showBottomControlsBarOnPause,
      showScrubbingThumbnailPreview:
          showScrubbingThumbnailPreview ?? this.showScrubbingThumbnailPreview,
    );
  }
}
