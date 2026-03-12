import 'package:flutter/material.dart';

/// An inherited widget that provides consistent theming for
/// [OmniVideoPlayer] instances within its widget subtree.
///
/// Wrap the parts of your widget tree that should share the same
/// [OmniVideoPlayerThemeData] with this widget.
///
/// Example usage:
/// ```dart
/// OmniVideoPlayerTheme(
///   data: OmniVideoPlayerThemeData(
///     colors: VideoPlayerColorScheme(active: Colors.blueAccent),
///   ),
///   child: OmniVideoPlayer(),
/// )
/// ```
class OmniVideoPlayerTheme extends InheritedTheme {
  /// The theme data that defines the visual appearance of the video player.
  final OmniVideoPlayerThemeData data;

  const OmniVideoPlayerTheme({
    super.key,
    required super.child,
    required this.data,
  });

  @override
  bool updateShouldNotify(covariant OmniVideoPlayerTheme oldWidget) {
    return oldWidget.data != data;
  }

  @override
  Widget wrap(BuildContext context, Widget child) {
    return OmniVideoPlayerTheme(data: data, child: child);
  }

  /// Retrieves the nearest [OmniVideoPlayerThemeData] from
  /// the widget tree that encloses the given [context].
  ///
  /// Returns null if no [OmniVideoPlayerTheme] ancestor is found.
  static OmniVideoPlayerThemeData? of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<OmniVideoPlayerTheme>()
        ?.data;
  }
}

/// A container for all theme-related data used by
/// [OmniVideoPlayer], divided into modular sub-themes.
class OmniVideoPlayerThemeData {
  /// Color scheme for all colors used in the video player.
  final VideoPlayerColorScheme colors;

  /// Label theme data, including default strings and messages.
  final VideoPlayerLabelTheme labels;

  /// Icon data theme used for player controls and status indicators.
  final VideoPlayerIconTheme icons;

  /// Shape-related styling such as border radius.
  final VideoPlayerShapeTheme shapes;

  /// Theme data for overlays like background shading.
  final VideoPlayerBackdropTheme backdrop;

  /// Accessibility labels for screen readers and assistive technologies.
  final VideoPlayerAccessibilityTheme accessibility;

  /// Theme data for popup menus and floating UI components
  /// (e.g., quality menu, speed menu, volume slider).
  final VideoPlayerMenuTheme menus;

  const OmniVideoPlayerThemeData({
    this.colors = const VideoPlayerColorScheme(),
    this.labels = const VideoPlayerLabelTheme(),
    this.icons = const VideoPlayerIconTheme(),
    this.shapes = const VideoPlayerShapeTheme(),
    this.backdrop = const VideoPlayerBackdropTheme(),
    this.accessibility = const VideoPlayerAccessibilityTheme(),
    this.menus = const VideoPlayerMenuTheme(),
  });

  /// Returns a copy of this theme data, overriding only the
  /// specified properties.
  OmniVideoPlayerThemeData copyWith({
    VideoPlayerColorScheme? colors,
    VideoPlayerLabelTheme? labels,
    VideoPlayerIconTheme? icons,
    VideoPlayerShapeTheme? shapes,
    VideoPlayerBackdropTheme? backdrop,
    VideoPlayerAccessibilityTheme? accessibility,
    VideoPlayerMenuTheme? menus,
  }) {
    return OmniVideoPlayerThemeData(
      colors: colors ?? this.colors,
      labels: labels ?? this.labels,
      icons: icons ?? this.icons,
      shapes: shapes ?? this.shapes,
      backdrop: backdrop ?? this.backdrop,
      accessibility: accessibility ?? this.accessibility,
      menus: menus ?? this.menus,
    );
  }
}

/// Defines color properties for various UI elements of the video player.
@immutable
class VideoPlayerColorScheme {
  /// Color for active UI elements like the progress bar fill.
  final Color active;

  /// Gradient for active UI elements like the progress bar fill.
  final Gradient? activeGradient;

  /// Color for the draggable thumb on the progress bar.
  final Color? thumb;

  /// Color for inactive or disabled UI elements.
  final Color inactive;

  /// Background color of the video thumbnail display.
  final Color backgroundThumbnail;

  /// Color of the play/pause icon.
  final Color? playPauseIcon;

  /// Background color behind the play/pause icon.
  final Color playPauseBackground;

  /// Color of the live indicator badge (optional).
  final Color? liveIndicator;

  /// General icon color for controls (optional).
  final Color? icon;

  /// Background color for the error screen.
  final Color backgroundError;

  /// Text color for error messages.
  final Color textError;

  /// Default text color for labels and messages.
  final Color? textDefault;

  /// Background color of the quality dropdown menu.
  final Color menuBackground;

  /// Text color for unselected quality options.
  final Color menuText;

  /// Background color of the volume slider overlay.
  /// Typically a semi-transparent color, visible mainly on web
  /// when interacting with the volume control.
  final Color volumeOverlayBackground;

  /// Color of the volume slider's active track and thumb when volume is > 0.
  /// Used to customize the visual appearance of the active volume level indicator.
  final Color volumeColorActiveSlider;

  /// Color of the volume slider's active track and thumb when volume is 0 (muted).
  /// Used to provide visual feedback that the audio is completely muted.
  final Color volumeColorInactiveSlider;

  /// Text color for the selected quality option.
  final Color menuTextSelected;

  /// Icon color for the selected quality checkmark.
  final Color menuIconSelected;

  const VideoPlayerColorScheme({
    this.active = Colors.redAccent,
    this.thumb,
    this.inactive = Colors.grey,
    this.activeGradient,
    this.backgroundThumbnail = Colors.transparent,
    this.playPauseIcon = Colors.white,
    this.playPauseBackground = Colors.black,
    this.liveIndicator = Colors.red,
    this.icon = Colors.white,
    this.backgroundError = Colors.black,
    this.textError = Colors.white,
    this.textDefault = Colors.white,
    this.menuBackground = const Color(0xFF212121),
    this.menuText = Colors.white,
    this.menuTextSelected = Colors.redAccent,
    this.menuIconSelected = Colors.redAccent,
    this.volumeOverlayBackground = const Color(0xFF212121),
    this.volumeColorActiveSlider = Colors.white,
    this.volumeColorInactiveSlider = Colors.grey,
  });

  /// Creates a copy of this color scheme overriding
  /// the specified color values.
  VideoPlayerColorScheme copyWith({
    Color? active,
    Color? thumb,
    Color? inactive,
    Color? backgroundThumbnail,
    Color? playPauseIcon,
    Color? playPauseBackground,
    Color? liveIndicator,
    Color? icon,
    Color? backgroundError,
    Color? textError,
    Color? textDefault,
    Color? menuBackground,
    Color? menuText,
    Color? menuTextSelected,
    Color? menuIconSelected,
    Gradient? activeGradient,
    Color? volumeOverlayBackground,
    Color? volumeColorActiveSlider,
    Color? volumeColorInactiveSlider,
  }) {
    return VideoPlayerColorScheme(
      active: active ?? this.active,
      thumb: thumb ?? this.thumb,
      inactive: inactive ?? this.inactive,
      backgroundThumbnail: backgroundThumbnail ?? this.backgroundThumbnail,
      playPauseIcon: playPauseIcon ?? this.playPauseIcon,
      playPauseBackground: playPauseBackground ?? this.playPauseBackground,
      liveIndicator: liveIndicator ?? this.liveIndicator,
      icon: icon ?? this.icon,
      backgroundError: backgroundError ?? this.backgroundError,
      textError: textError ?? this.textError,
      textDefault: textDefault ?? this.textDefault,
      menuBackground: menuBackground ?? this.menuBackground,
      menuText: menuText ?? this.menuText,
      menuTextSelected: menuTextSelected ?? this.menuTextSelected,
      menuIconSelected: menuIconSelected ?? this.menuIconSelected,
      activeGradient: activeGradient ?? this.activeGradient,
      volumeOverlayBackground:
          volumeOverlayBackground ?? this.volumeOverlayBackground,
      volumeColorActiveSlider:
          volumeColorActiveSlider ?? this.volumeColorActiveSlider,
      volumeColorInactiveSlider:
          volumeColorInactiveSlider ?? this.volumeColorInactiveSlider,
    );
  }
}

/// Defines default string labels used in the video player.
@immutable
class VideoPlayerLabelTheme {
  /// Default error message displayed on playback failure.
  final String errorMessage;

  /// Label for the 'auto' video quality option.
  final String autoQualityLabel;

  const VideoPlayerLabelTheme({
    this.errorMessage = 'An error occurred while loading the video.',
    this.autoQualityLabel = 'auto',
  });

  /// Returns a copy of this label theme overriding only the provided fields.
  VideoPlayerLabelTheme copyWith({
    String? errorMessage,
    String? autoQualityLabel,
  }) {
    return VideoPlayerLabelTheme(
      errorMessage: errorMessage ?? this.errorMessage,
      autoQualityLabel: autoQualityLabel ?? this.autoQualityLabel,
    );
  }
}

/// Defines icon data used for various player controls and status indicators.
@immutable
class VideoPlayerIconTheme {
  /// Icon for exiting fullscreen mode.
  final IconData exitFullScreen;

  /// Icon for entering fullscreen mode.
  final IconData fullScreen;

  /// Icon representing volume on (mute).
  final IconData mute;

  /// Icon representing volume off (unmute).
  final IconData unMute;

  /// Icon used for replaying the video.
  final IconData replay;

  /// Animated icon used to toggle play/pause.
  final AnimatedIconData playPause;

  /// Icon shown on playback error.
  final IconData error;

  /// Icon for forwarding 5 seconds.
  final IconData forward5;

  /// Icon for forwarding 10 seconds.
  final IconData forward10;

  /// Icon for forwarding 30 seconds.
  final IconData forward30;

  /// Icon for replaying 5 seconds.
  final IconData replay5;

  /// Icon for replaying 10 seconds.
  final IconData replay10;

  /// Icon for replaying 30 seconds.
  final IconData replay30;

  /// Icon used for the quality change button.
  final IconData qualityChangeButton;

  /// Icon used to indicate the selected quality option.
  final IconData qualitySelectedCheck;

  /// Icon used for the playback speed change button.
  final IconData playbackSpeedButton;

  const VideoPlayerIconTheme({
    this.exitFullScreen = Icons.fullscreen_exit,
    this.fullScreen = Icons.fullscreen,
    this.mute = Icons.volume_up,
    this.unMute = Icons.volume_off,
    this.replay = Icons.replay,
    this.playPause = AnimatedIcons.play_pause,
    this.error = Icons.error,
    this.forward5 = Icons.forward_5,
    this.forward10 = Icons.forward_10,
    this.forward30 = Icons.forward_30,
    this.replay5 = Icons.replay_5,
    this.replay10 = Icons.replay_10,
    this.replay30 = Icons.replay_30,
    this.qualityChangeButton = Icons.high_quality,
    this.qualitySelectedCheck = Icons.check,
    this.playbackSpeedButton = Icons.speed,
  });

  /// Creates a copy of this icon theme with selective overrides.
  VideoPlayerIconTheme copyWith({
    IconData? exitFullScreen,
    IconData? fullScreen,
    IconData? mute,
    IconData? unMute,
    IconData? replay,
    AnimatedIconData? playPause,
    IconData? error,
    IconData? forward5,
    IconData? forward10,
    IconData? forward30,
    IconData? replay5,
    IconData? replay10,
    IconData? replay30,
    IconData? qualityChangeButton,
    IconData? qualitySelectedCheck,
    IconData? playbackSpeedButton,
  }) {
    return VideoPlayerIconTheme(
      exitFullScreen: exitFullScreen ?? this.exitFullScreen,
      fullScreen: fullScreen ?? this.fullScreen,
      mute: mute ?? this.mute,
      unMute: unMute ?? this.unMute,
      replay: replay ?? this.replay,
      playPause: playPause ?? this.playPause,
      error: error ?? this.error,
      forward5: forward5 ?? this.forward5,
      forward10: forward10 ?? this.forward10,
      forward30: forward30 ?? this.forward30,
      replay5: replay5 ?? this.replay5,
      replay10: replay10 ?? this.replay10,
      replay30: replay30 ?? this.replay30,
      qualityChangeButton: qualityChangeButton ?? this.qualityChangeButton,
      qualitySelectedCheck: qualitySelectedCheck ?? this.qualitySelectedCheck,
      playbackSpeedButton: playbackSpeedButton ?? this.playbackSpeedButton,
    );
  }
}

/// Defines shape-related styling options.
@immutable
class VideoPlayerShapeTheme {
  /// Border radius applied to the main video player UI.
  final double borderRadius;

  /// Border radius applied to the popup menus (quality, speed, volume).
  final double menuBorderRadius;

  /// Custom shape for the volume slider thumb.
  final SliderComponentShape? volumeSliderThumbShape;

  const VideoPlayerShapeTheme({
    this.borderRadius = 0,
    this.menuBorderRadius = 8.0,
    this.volumeSliderThumbShape,
  });

  /// Returns a copy with updated shape properties.
  VideoPlayerShapeTheme copyWith({
    double? borderRadius,
    double? menuBorderRadius,
    SliderComponentShape? volumeSliderThumbShape,
  }) => VideoPlayerShapeTheme(
    borderRadius: borderRadius ?? this.borderRadius,
    menuBorderRadius: menuBorderRadius ?? this.menuBorderRadius,
    volumeSliderThumbShape:
        volumeSliderThumbShape ?? this.volumeSliderThumbShape,
  );
}

/// Defines theming for the backdrop shading behind the player controls.
@immutable
class VideoPlayerBackdropTheme {
  /// Background color used for the backdrop shading.
  final Color? backgroundColor;

  /// Alpha transparency value (0-255) applied to the background color.
  final int? alpha;

  const VideoPlayerBackdropTheme({this.backgroundColor, this.alpha = 150});

  /// Returns a copy overriding the background color and/or alpha.
  VideoPlayerBackdropTheme copyWith({Color? backgroundColor, int? alpha}) =>
      VideoPlayerBackdropTheme(
        backgroundColor: backgroundColor ?? this.backgroundColor,
        alpha: alpha ?? this.alpha,
      );
}

/// Defines accessibility labels for screen readers and other assistive technologies.
@immutable
class VideoPlayerAccessibilityTheme {
  /// Semantic label for the play button.
  final String playButtonLabel;

  /// Semantic label for the pause button.
  final String pauseButtonLabel;

  /// Semantic label for the fullscreen toggle button.
  final String fullscreenButtonLabel;

  /// Semantic label for the exit fullscreen button.
  final String exitFullscreenButtonLabel;

  /// Semantic label for the mute button.
  final String muteButtonLabel;

  /// Semantic label for the unmute button.
  final String unmuteButtonLabel;

  /// Semantic label for the quality selection button.
  final String qualityButtonLabel;

  /// Semantic label for the playback speed button.
  final String playbackSpeedButtonLabel;

  /// Semantic label base for the controls visibility state.
  /// The actual label will depend on whether controls are visible or hidden.
  final String controlsVisibleLabel;

  /// Semantic label for the replay button when the video has finished.
  final String replayButtonLabel;

  const VideoPlayerAccessibilityTheme({
    this.playButtonLabel = 'Play video',
    this.pauseButtonLabel = 'Pause video',
    this.fullscreenButtonLabel = 'Enter fullscreen',
    this.exitFullscreenButtonLabel = 'Exit fullscreen',
    this.muteButtonLabel = 'Mute audio',
    this.unmuteButtonLabel = 'Unmute audio',
    this.qualityButtonLabel = 'Change video quality',
    this.playbackSpeedButtonLabel = 'Change playback speed',
    this.controlsVisibleLabel = 'Controls visible',
    this.replayButtonLabel = 'Replay video',
  });

  /// Returns a copy overriding only the provided fields.
  VideoPlayerAccessibilityTheme copyWith({
    String? playButtonLabel,
    String? pauseButtonLabel,
    String? fullscreenButtonLabel,
    String? exitFullscreenButtonLabel,
    String? muteButtonLabel,
    String? unmuteButtonLabel,
    String? qualityButtonLabel,
    String? playbackSpeedButtonLabel,
    String? controlsVisibleLabel,
    String? replayButtonLabel,
  }) {
    return VideoPlayerAccessibilityTheme(
      playButtonLabel: playButtonLabel ?? this.playButtonLabel,
      pauseButtonLabel: pauseButtonLabel ?? this.pauseButtonLabel,
      fullscreenButtonLabel:
          fullscreenButtonLabel ?? this.fullscreenButtonLabel,
      exitFullscreenButtonLabel:
          exitFullscreenButtonLabel ?? this.exitFullscreenButtonLabel,
      muteButtonLabel: muteButtonLabel ?? this.muteButtonLabel,
      unmuteButtonLabel: unmuteButtonLabel ?? this.unmuteButtonLabel,
      qualityButtonLabel: qualityButtonLabel ?? this.qualityButtonLabel,
      playbackSpeedButtonLabel:
          playbackSpeedButtonLabel ?? this.playbackSpeedButtonLabel,
      controlsVisibleLabel: controlsVisibleLabel ?? this.controlsVisibleLabel,
      replayButtonLabel: replayButtonLabel ?? this.replayButtonLabel,
    );
  }
}

/// Defines theming for popup menus and floating controls
/// (e.g., volume slider on web, quality selection, playback speed).
@immutable
class VideoPlayerMenuTheme {
  /// Configurable decoration for popup menus and floating containers.
  /// If null, a default semi-transparent black decoration is used.
  final Decoration? menuDecoration;

  const VideoPlayerMenuTheme({this.menuDecoration});

  /// Returns a copy overriding the menu decoration.
  VideoPlayerMenuTheme copyWith({Decoration? menuDecoration}) {
    return VideoPlayerMenuTheme(
      menuDecoration: menuDecoration ?? this.menuDecoration,
    );
  }
}
