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

  /// Whether to show the fullscreen toggle button.
  final bool showFullScreenButton;

  /// Whether to show the quality switch button.
  final bool showSwitchVideoQuality;

  /// Whether to show the mute/unmute toggle button.
  final bool showMuteUnMuteButton;

  /// Whether to show a refresh button inside the error placeholder.
  final bool showRefreshButtonInErrorPlaceholder;

  /// Whether to wrap the bottom control bar inside a [SafeArea] widget
  /// to avoid overlaps with system UI elements like gesture bars or notches.
  final bool useSafeAreaForBottomControls;

  /// Whether to display a gradient overlay behind the bottom control bar.
  final bool showGradientBottomControl;

  /// Whether to allow gesture-based fast-forward.
  final bool enableForwardGesture;

  /// Whether to allow gesture-based rewind.
  final bool enableBackwardGesture;

  /// Whether to allow exiting fullscreen via a vertical swipe down.
  final bool enableExitFullscreenOnVerticalSwipe;

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
    this.showFullScreenButton = true,
    this.showMuteUnMuteButton = true,
    this.useSafeAreaForBottomControls = false,
    this.showGradientBottomControl = true,
    this.showRefreshButtonInErrorPlaceholder = true,
    this.enableForwardGesture = true,
    this.enableBackwardGesture = true,
    this.enableExitFullscreenOnVerticalSwipe = true,
    this.showSwitchVideoQuality = true,
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
    bool? showFullScreenButton,
    bool? showMuteUnMuteButton,
    bool? useSafeAreaForBottomControls,
    bool? showGradientBottomControl,
    bool? showRefreshButtonInErrorPlaceholder,
    bool? enableForwardGesture,
    bool? enableBackwardGesture,
    bool? enableExitFullscreenOnVerticalSwipe,
    bool? showSwitchVideoQuality,
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
      showRefreshButtonInErrorPlaceholder:
          showRefreshButtonInErrorPlaceholder ??
              this.showRefreshButtonInErrorPlaceholder,
      enableForwardGesture: enableForwardGesture ?? this.enableForwardGesture,
      enableBackwardGesture:
          enableBackwardGesture ?? this.enableBackwardGesture,
      enableExitFullscreenOnVerticalSwipe:
          enableExitFullscreenOnVerticalSwipe ??
              this.enableExitFullscreenOnVerticalSwipe,
      showSwitchVideoQuality:
          showSwitchVideoQuality ?? this.showSwitchVideoQuality,
    );
  }
}
