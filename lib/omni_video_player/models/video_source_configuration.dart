import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/omni_video_player/models/youtube_web_view_configuration.dart';

/// Configuration object used to initialize video playback.
///
/// Depending on the [videoSourceType], provide exactly one of:
///
/// - [videoUrl] → for YouTube or network videos.
/// - [videoId] → for Vimeo videos.
/// - [videoDataSource] → for asset or local file videos.
///
/// ⚠️ **Rules:**
/// - Provide **only one** of [videoUrl], [videoId], or [videoDataSource].
/// - [videoId] is only valid for Vimeo.
/// - [videoUrl] is valid for YouTube and network streams.
/// - [videoDataSource] is valid for assets or local files.
///
/// ---
///
/// ### Factory Constructors:
///
/// **Vimeo**
/// ```dart
/// VideoSourceConfiguration.vimeo(
///   videoId: "123456789",
/// )
/// ```
///
/// **YouTube**
/// ```dart
/// VideoSourceConfiguration.youtube(
///   videoUrl: Uri.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
/// )
/// ```
///
/// **Network**
/// ```dart
/// VideoSourceConfiguration.network(
///   videoUrl: Uri.parse("https://example.com/video.mp4"),
/// )
/// ```
///
/// **Asset**
/// ```dart
/// VideoSourceConfiguration.asset(
///   videoDataSource: 'assets/videos/video.mp4',
/// )
/// ```
///
/// ---
///
/// ### Common playback options (modifiable with [copyWith]):
///
/// - [autoPlay]: Whether playback should start automatically (default: false).
/// - [initialPosition]: The initial playback position (default: Duration.zero).
/// - [initialVolume]: Initial volume level between 0.0 and 1.0 (default: 1.0).
/// - [initialPlaybackSpeed]: The initial playback speed for the video (default: 1.0).
/// - [autoMuteOnStart]: Whether playback should start muted (default: false).
/// - [preferredQualities]: Preferred video quality levels (default: [OmniVideoQuality.medium480]).
/// - [allowSeeking]: Whether seeking is allowed (default: true).
/// - [timeoutDuration]: Maximum wait time before considering playback failed (default: 30 seconds).
@immutable
class VideoSourceConfiguration {
  /// The video URL (for YouTube or network-based videos).
  final Uri? videoUrl;

  /// The video ID (only for Vimeo videos).
  final String? videoId;

  /// The asset or file path (for asset or local file videos).
  final String? videoDataSource;

  /// The file
  final File? videoFile;

  /// Defines the source type, must match the appropriate data source field.
  final VideoSourceType videoSourceType;

  /// Whether playback should start automatically.
  final bool autoPlay;

  /// The initial playback position.
  final Duration initialPosition;

  /// Initial volume level (range 0.0 to 1.0).
  final double initialVolume;

  /// The initial playback speed for the video.
  ///
  /// Default is `1.0` (normal speed). Values < 1.0 slow down playback,
  /// values > 1.0 speed it up.
  final double initialPlaybackSpeed;

  /// List of available playback speeds for the user to select from.
  ///
  /// Defaults to `[0.5, 1.0, 1.25, 1.5, 2.0]` if not specified.
  final List<double> availablePlaybackSpeed;

  /// Whether playback should start muted.
  final bool autoMuteOnStart;

  /// Preferred video quality levels in order of preference.
  ///
  /// The player will try to select the best available quality from this list
  /// according to the order provided.
  final List<OmniVideoQuality> preferredQualities;

  /// Whether the user is allowed to seek the video.
  final bool allowSeeking;

  /// Maximum wait time before considering playback failed.
  final Duration timeoutDuration;

  /// The list of available video qualities for this video.
  ///
  /// If specified, all entries in [preferredQualities] must also be included here.
  /// If not specified, all qualities are considered available.
  final List<OmniVideoQuality>? availableQualities;

  /// YouTube WebView player flags (force/fallback/native-controls).
  final YoutubeWebViewConfiguration youtubeWebView;

  /// Synchronizes the mute state across all video players controlled globally.
  ///
  /// When `true`, muting or unmuting one video will apply the same mute state to
  /// all other videos using the global playback controller.
  ///
  final bool synchronizeMuteAcrossPlayers;

  /// Keeps the video controller alive even when the widget is removed from the tree.
  ///
  /// When `true`, the controller is **not automatically disposed**, allowing the
  /// video state (position, buffer, etc.) to persist across rebuilds or navigation.
  ///
  /// ⚠️ Use with caution — if you never call `dispose()` manually, this may lead
  /// to memory leaks or OutOfMemory errors.
  final bool keepAlive;

  /// Whether the video should automatically pause when it leaves the viewport.
  ///
  /// Defaults to `true`.
  final bool pauseWhenOutOfView;

  /// Whether the player should automatically switch to fullscreen mode when initialization is complete.
  final bool autoFullScreenAtStart;

  /// Optional HTTP headers (e.g., for authentication) to send with the video request.
  final Map<String, String>? httpHeaders;

  /// Private constructor used by factory constructors and [copyWith].
  const VideoSourceConfiguration._({
    this.videoUrl,
    this.videoId,
    this.videoDataSource,
    this.videoFile,
    required this.videoSourceType,
    this.httpHeaders,
    this.autoPlay = false,
    this.initialPosition = Duration.zero,
    this.initialVolume = 1.0,
    this.initialPlaybackSpeed = 1.0,
    this.availablePlaybackSpeed = const [0.5, 1.0, 1.25, 1.5, 2.0],
    this.autoMuteOnStart = false,
    this.preferredQualities = const [OmniVideoQuality.medium480],
    this.availableQualities,
    this.allowSeeking = true,
    this.keepAlive = false,
    this.youtubeWebView = const YoutubeWebViewConfiguration(),
    this.synchronizeMuteAcrossPlayers = true,
    this.timeoutDuration = const Duration(seconds: 6),
    this.pauseWhenOutOfView = true,
    this.autoFullScreenAtStart = false,
  });

  /// Factory constructor for Vimeo videos.
  ///
  /// Example:
  /// ```dart
  /// VideoSourceConfiguration.vimeo(
  ///   videoId: "123456789",
  ///   preferredQualities: [OmniVideoQuality.high720, OmniVideoQuality.low144,],, // Optional
  /// )
  /// ```
  ///
  /// - [videoId]: the numeric ID from a Vimeo URL (e.g., https://vimeo.com/123456789).
  /// - [preferredQualities]: optional list of preferred video resolutions.
  ///   Only used for Vimeo sources. Default is [OmniVideoQuality.medium480].
  factory VideoSourceConfiguration.vimeo({
    required String videoId,
    List<OmniVideoQuality> preferredQualities = const [
      OmniVideoQuality.medium480,
    ],
  }) {
    return VideoSourceConfiguration._(
      videoId: videoId,
      videoSourceType: VideoSourceType.vimeo,
      preferredQualities: preferredQualities,
    );
  }

  /// Factory constructor for YouTube videos.
  ///
  /// Example:
  /// ```dart
  /// VideoSourceConfiguration.youtube(
  ///   videoUrl: Uri.parse("https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
  ///   preferredQualities: [OmniVideoQuality.high720, OmniVideoQuality.low144,], // Optional
  /// )
  /// ```
  ///
  /// - [videoUrl]: the full URL of a YouTube video.
  /// - [preferredQualities]: optional list of preferred video resolutions.
  ///   Only used for YouTube sources. Default is [OmniVideoQuality.medium480].
  factory VideoSourceConfiguration.youtube({
    required Uri videoUrl,
    List<OmniVideoQuality> preferredQualities = const [
      OmniVideoQuality.medium480,
    ],
    List<OmniVideoQuality>? availableQualities,
    YoutubeWebViewConfiguration webView = const YoutubeWebViewConfiguration(),
  }) {
    _validatePreferredQualities(
      preferred: preferredQualities,
      available: availableQualities,
    );

    return VideoSourceConfiguration._(
      videoUrl: videoUrl,
      videoSourceType: VideoSourceType.youtube,
      preferredQualities: preferredQualities,
      availableQualities: availableQualities,
      youtubeWebView: webView,
    );
  }

  static void _validatePreferredQualities({
    required List<OmniVideoQuality> preferred,
    List<OmniVideoQuality>? available,
  }) {
    if (available == null) return;

    final invalid = preferred.where((q) => !available.contains(q)).toList();
    if (invalid.isNotEmpty) {
      throw ArgumentError(
        'The following preferred qualities are not available: $invalid. '
        'All preferred qualities must be included in availableQualities.',
      );
    }
  }

  /// Factory constructor for network videos.
  ///
  /// Example:
  /// ```dart
  /// VideoSourceConfiguration.network(
  ///   videoUrl: Uri.parse("https://example.com/video.m3u8"),
  ///   preferredQualities: [OmniVideoQuality.high720, OmniVideoQuality.low144], // Optional
  ///   availableQualities: [OmniVideoQuality.low144, OmniVideoQuality.medium360, OmniVideoQuality.high720], // Optional
  /// )
  /// ```
  ///
  /// - [videoUrl]: the full URL of a network video stream or file (e.g., HLS .m3u8).
  /// - [preferredQualities]: optional list of preferred video quality levels in order of preference.
  ///   Only used for HLS (network) sources. Default is [OmniVideoQuality.medium480].
  /// - [availableQualities]: optional list of all available qualities for this video source.
  ///   If specified, all entries in [preferredQualities] must also be included here.
  ///   If not specified, all qualities are considered available.
  ///
  /// Note that for network sources (such as HLS streams), quality selection
  /// depends on the available stream variants and these lists help to control
  /// which qualities the player should prefer or consider. These quality lists
  /// are ignored for non-HLS network videos (e.g., direct mp4 URLs).
  factory VideoSourceConfiguration.network({
    required Uri videoUrl,
    Map<String, String>? httpHeaders,
    List<OmniVideoQuality> preferredQualities = const [
      OmniVideoQuality.medium480,
    ],
    List<OmniVideoQuality>? availableQualities,
  }) {
    _validatePreferredQualities(
      preferred: preferredQualities,
      available: availableQualities,
    );

    return VideoSourceConfiguration._(
      videoUrl: videoUrl,
      videoSourceType: VideoSourceType.network,
      httpHeaders: httpHeaders,
      preferredQualities: preferredQualities,
      availableQualities: availableQualities,
    );
  }

  /// Factory constructor for asset or local file videos.
  ///
  /// Requires a [videoDataSource].
  factory VideoSourceConfiguration.asset({required String videoDataSource}) {
    return VideoSourceConfiguration._(
      videoDataSource: videoDataSource,
      videoSourceType: VideoSourceType.asset,
    );
  }

  /// Factory constructor for file videos.
  ///
  /// Requires a [videoFile].
  factory VideoSourceConfiguration.file({required File videoFile}) {
    return VideoSourceConfiguration._(
      videoFile: videoFile,
      videoSourceType: VideoSourceType.file,
    );
  }

  /// Returns a new instance of [VideoSourceConfiguration] with updated common playback fields.
  ///
  /// The parameters that distinguish the video source ([videoUrl], [videoId], [videoDataSource], [videoSourceType])
  /// **cannot be modified** here to maintain consistency.
  VideoSourceConfiguration copyWith({
    bool? autoPlay,
    Duration? initialPosition,
    double? initialVolume,
    double? initialPlaybackSpeed,
    List<double>? availablePlaybackSpeed,
    bool? autoMuteOnStart,
    bool? allowSeeking,
    bool? synchronizeMuteAcrossPlayers,
    Duration? timeoutDuration,
    List<OmniVideoQuality>? preferredQualities,
    List<OmniVideoQuality>? availableQualities,
    YoutubeWebViewConfiguration? youtubeWebView,
    bool? keepAlive,
    bool? pauseWhenOutOfView,
    bool? autoFullScreenAtStart,
    Map<String, String>? httpHeaders,
  }) {
    final newPreferred = preferredQualities ?? this.preferredQualities;
    final newAvailable = availableQualities ?? this.availableQualities;

    _validatePreferredQualities(
      preferred: newPreferred,
      available: newAvailable,
    );

    return VideoSourceConfiguration._(
      videoUrl: videoUrl,
      videoId: videoId,
      videoDataSource: videoDataSource,
      videoSourceType: videoSourceType,
      autoPlay: autoPlay ?? this.autoPlay,
      initialPosition: initialPosition ?? this.initialPosition,
      initialVolume: initialVolume ?? this.initialVolume,
      initialPlaybackSpeed: initialPlaybackSpeed ?? this.initialPlaybackSpeed,
      availablePlaybackSpeed:
          availablePlaybackSpeed ?? this.availablePlaybackSpeed,
      autoMuteOnStart: autoMuteOnStart ?? this.autoMuteOnStart,
      preferredQualities: newPreferred,
      availableQualities: newAvailable,
      allowSeeking: allowSeeking ?? this.allowSeeking,
      timeoutDuration: timeoutDuration ?? this.timeoutDuration,
      youtubeWebView: youtubeWebView ?? this.youtubeWebView,
      synchronizeMuteAcrossPlayers:
          synchronizeMuteAcrossPlayers ?? this.synchronizeMuteAcrossPlayers,
      keepAlive: keepAlive ?? this.keepAlive,
      pauseWhenOutOfView: pauseWhenOutOfView ?? this.pauseWhenOutOfView,
      autoFullScreenAtStart:
          autoFullScreenAtStart ?? this.autoFullScreenAtStart,
      httpHeaders: httpHeaders ?? this.httpHeaders,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoSourceConfiguration &&
        other.videoUrl == videoUrl &&
        other.videoId == videoId &&
        other.videoDataSource == videoDataSource &&
        other.videoFile == videoFile &&
        other.videoSourceType == videoSourceType &&
        other.autoPlay == autoPlay &&
        other.initialPosition == initialPosition &&
        other.initialVolume == initialVolume &&
        other.initialPlaybackSpeed == initialPlaybackSpeed &&
        listEquals(other.availablePlaybackSpeed, availablePlaybackSpeed) &&
        other.autoMuteOnStart == autoMuteOnStart &&
        listEquals(other.preferredQualities, preferredQualities) &&
        other.allowSeeking == allowSeeking &&
        other.timeoutDuration == timeoutDuration &&
        listEquals(other.availableQualities, availableQualities) &&
        other.youtubeWebView == youtubeWebView &&
        other.synchronizeMuteAcrossPlayers == synchronizeMuteAcrossPlayers &&
        other.keepAlive == keepAlive &&
        other.pauseWhenOutOfView == pauseWhenOutOfView &&
        other.autoFullScreenAtStart == autoFullScreenAtStart &&
        mapEquals(other.httpHeaders, httpHeaders);
  }

  @override
  int get hashCode => Object.hashAll([
        videoUrl,
        videoId,
        videoDataSource,
        videoFile,
        videoSourceType,
        autoPlay,
        initialPosition,
        initialVolume,
        initialPlaybackSpeed,
        Object.hashAll(availablePlaybackSpeed),
        autoMuteOnStart,
        Object.hashAll(preferredQualities),
        allowSeeking,
        timeoutDuration,
        availableQualities == null ? null : Object.hashAll(availableQualities!),
        youtubeWebView,
        synchronizeMuteAcrossPlayers,
        keepAlive,
        pauseWhenOutOfView,
        autoFullScreenAtStart,
        httpHeaders == null
            ? null
            : Object.hashAllUnordered(
                httpHeaders!.entries.map((e) => Object.hash(e.key, e.value)),
              ),
      ]);
}
