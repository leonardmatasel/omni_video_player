import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/models/custom_player_widgets.dart';
import 'package:omni_video_player/omni_video_player/models/global_playback_control_settings.dart';
import 'package:omni_video_player/omni_video_player/models/player_ui_visibility_options.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';
import 'package:omni_video_player/omni_video_player/theme/omni_video_player_theme.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer.dart';

/// Configuration options for customizing the appearance and behavior of a video player.
///
/// [VideoPlayerConfiguration] provides a flexible way to define playback logic, theming,
/// interaction modes, and UI components of the `OmniVideoPlayer`.
///
/// This class is immutable and can be safely reused or cloned via [copyWith].
@immutable
class VideoPlayerConfiguration {
  /// Creates a new set of configuration options for a video player instance.
  VideoPlayerConfiguration({
    required this.videoSourceConfiguration,
    this.globalPlaybackControlSettings = const GlobalPlaybackControlSettings(),
    this.playerUIVisibilityOptions = const PlayerUIVisibilityOptions(),
    this.playerTheme = const OmniVideoPlayerThemeData(),
    this.customPlayerWidgets = const CustomPlayerWidgets(),
    this.liveLabel = "LIVE",
    this.enableBackgroundOverlayClip = true,
    globalKeyInitializer,
  }) {
    globalKeyPlayer = GlobalKey();
    this.globalKeyInitializer = globalKeyInitializer ?? GlobalKey();
  }

  /// A unique global key for the player widget, don't use it!
  late final GlobalKey globalKeyPlayer;

  /// A global key for the video player initializer state.
  ///
  /// Use this for refresh if encountering repeated errors, e.g.:
  /// ```dart
  /// final globalKeyInitializer = GlobalKey<VideoPlayerInitializerState>();
  /// globalKeyInitializer.currentState?.refresh();
  /// ```
  late final GlobalKey<VideoPlayerInitializerState> globalKeyInitializer;

  /// Defines how the video is loaded and played (URL, autoplay, volume, etc).
  final VideoSourceConfiguration videoSourceConfiguration;

  /// Controls global playback interactions like exclusive playback and mute sync.
  final GlobalPlaybackControlSettings globalPlaybackControlSettings;

  /// Flags that toggle visibility of player UI elements like seek bar, buttons, etc.
  final PlayerUIVisibilityOptions playerUIVisibilityOptions;

  /// Provides custom widget overrides like loading indicators, error placeholders, etc.
  final CustomPlayerWidgets customPlayerWidgets;

  /// Custom theming options for the video player controls and appearance.
  final OmniVideoPlayerThemeData playerTheme;

  /// Label displayed for live streams.
  final String liveLabel;

  /// Flag to enable or disable clipping of the background overlay using a rounded rectangle.
  ///
  /// To have effect, this, [backgroundOverlayColor], and [backgroundOverlayAlpha]
  /// must all be non-null and properly set in the [playerTheme].
  final bool? enableBackgroundOverlayClip;

  /// Returns a new [VideoPlayerConfiguration] instance with specified fields overridden.
  ///
  /// This allows for immutability while supporting customization.
  /// Use this method to derive a new configuration by modifying only the required parts.
  ///
  /// Parameters:
  ///
  /// - [videoSourceConfiguration]: Defines how the video is loaded and played.
  ///
  /// - [globalPlaybackControlSettings]: Controls global playback interactions like exclusive playback and mute sync.
  ///
  /// - [playerUIVisibilityOptions]: Flags that toggle visibility of player UI elements like seek bar, buttons, etc.
  ///
  /// - [playerTheme]: Theming configuration for colors, padding, typography, and overlays.
  ///
  /// - [customPlayerWidgets]: Provides custom widget overrides like loading indicators, error placeholders, etc.
  ///
  /// - [liveLabel]: Text displayed when the video is a live stream.
  ///
  /// - [enableBackgroundOverlayClip]: Whether to clip background overlays using a rounded rectangle.
  ///
  /// Returns a new [VideoPlayerConfiguration] with the specified fields replaced.
  ///
  /// Example usage:
  /// ```dart
  /// final newOptions = oldOptions.copyWith(
  ///   liveLabel: "LIVE NOW",
  ///   playerUIVisibilityOptions: oldOptions.playerUIVisibilityOptions.copyWith(showMuteUnMuteButton: false),
  /// );
  /// ```
  VideoPlayerConfiguration copyWith({
    VideoSourceConfiguration? videoSourceConfiguration,
    GlobalPlaybackControlSettings? globalPlaybackControlSettings,
    PlayerUIVisibilityOptions? playerUIVisibilityOptions,
    OmniVideoPlayerThemeData? playerTheme,
    CustomPlayerWidgets? customPlayerWidgets,
    String? liveLabel,
    bool? enableBackgroundOverlayClip,
  }) {
    return VideoPlayerConfiguration(
      videoSourceConfiguration:
          videoSourceConfiguration ?? this.videoSourceConfiguration,
      globalPlaybackControlSettings:
          globalPlaybackControlSettings ?? this.globalPlaybackControlSettings,
      playerUIVisibilityOptions:
          playerUIVisibilityOptions ?? this.playerUIVisibilityOptions,
      playerTheme: playerTheme ?? this.playerTheme,
      customPlayerWidgets: customPlayerWidgets ?? this.customPlayerWidgets,
      liveLabel: liveLabel ?? this.liveLabel,
      enableBackgroundOverlayClip:
          enableBackgroundOverlayClip ?? this.enableBackgroundOverlayClip,
    );
  }
}
