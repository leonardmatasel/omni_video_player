import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

/// An abstract interface for controlling video playback across multiple source types.
///
/// [OmniPlaybackController] defines a unified API for managing video playback,
/// supporting various sources such as network streams, local files, or third-party platforms
/// (e.g., YouTube, Vimeo). It includes methods for controlling playback, volume, seek,
/// fullscreen, and other media-related properties.
abstract class OmniPlaybackController with ChangeNotifier {
  /// Starts or resumes playback.
  ///
  /// If [useGlobalController] is `true`, a shared global instance is used for coordinated
  /// playback management (e.g., pausing other videos when this one plays).
  Future<void> play({bool useGlobalController = true});

  /// Pauses the current playback.
  ///
  /// If [useGlobalController] is `true`, affects the shared controller.
  Future<void> pause({bool useGlobalController = true});

  /// Restarts the video from the beginning.
  Future<void> replay({bool useGlobalController = true});

  /// Toggles the mute state between muted and unmuted.
  void toggleMute();

  /// Mutes the video.
  void mute();

  /// Unmutes the video.
  void unMute();

  /// Seeks the playback to the given [position].
  void seekTo(Duration position);

  /// Switches fullscreen mode for the video player.
  ///
  /// - [context] is the build context.
  /// - [pageBuilder] returns the widget to display in fullscreen.
  /// - [onToggle] is called with `true` when entering and `false` when exiting fullscreen.
  Future<void> switchFullScreenMode(
    BuildContext context, {
    required Widget Function(BuildContext)? pageBuilder,
    void Function(bool)? onToggle,
  });

  // ──────────────── Playback Metadata and State ────────────────

  /// Whether the current video is a live stream.
  bool get isLive;

  /// The resolved video URL, if available.
  Uri? get videoUrl;

  /// The raw data source of the video, such as a URL or asset path.
  String? get videoDataSource;

  /// A unique video identifier (e.g., YouTube/Vimeo video ID).
  String? get videoId;

  /// The type of video source (e.g., asset, network, YouTube, etc.).
  VideoSourceType get videoSourceType;

  /// A notifier containing the shared video player widget.
  ///
  /// This can be used to transfer the player across widget trees (e.g., fullscreen transitions).
  ValueNotifier<Widget?> get sharedPlayerNotifier;

  // ──────────────── Playback Status ────────────────

  /// Whether the video is fully initialized and ready to play.
  bool get isReady;

  /// Whether playback is currently active.
  bool get isPlaying;

  /// Whether an error occurred during initialization or playback.
  bool get hasError;

  /// Whether the video is currently buffering.
  bool get isBuffering;

  /// The current audio volume, from 0.0 (mute) to 1.0 (max).
  double get volume;

  /// Whether the video is currently muted.
  bool get isMuted;

  /// Whether the player is actively seeking to a position.
  bool get isSeeking;

  /// Whether playback has started at least once.
  bool get hasStarted;

  /// Whether the player is currently in fullscreen mode.
  bool get isFullScreen;

  /// The current playback position.
  Duration get currentPosition;

  /// Whether playback has reached the end of the video.
  bool get isFinished;

  /// The total duration of the video.
  Duration get duration;

  /// Degrees of rotation to apply for video orientation correction.
  int get rotationCorrection;

  /// The intrinsic size (width and height) of the video.
  Size get size;

  /// A buffered video duration.
  Duration get buffered;

  // ──────────────── Setters ────────────────

  /// Sets the audio volume, clamped between 0.0 and 1.0.
  set volume(double value);

  /// Sets whether the video is currently in a seeking state.
  ///
  /// Useful for suppressing UI updates during manual seeks.
  set isSeeking(bool value);

  /// Whether playback was active prior to a seek operation.
  bool get wasPlayingBeforeSeek;

  /// Updates the flag tracking playback state before seeking.
  set wasPlayingBeforeSeek(bool value);

  /// A map of available video qualities to their corresponding URIs.
  ///
  /// This can be used to switch between different video qualities.
  Map<OmniVideoQuality, Uri>? get videoQualityUrls;

  /// The currently selected video quality.
  OmniVideoQuality? get currentVideoQuality;

  /// List of selectable video qualities (e.g., 1080p, 720p).
  ///
  /// May be `null` if the source doesn't support multiple qualities.
  /// Useful for building a quality selector UI.
  List<OmniVideoQuality>? get availableVideoQualities;

  /// Switches the video playback quality to the specified [quality].
  ///
  /// Throws an exception if the specified quality is not available.
  Future<void> switchQuality(OmniVideoQuality quality);

  /// Gets the current playback speed of the video.
  ///
  /// Returns `1.0` for normal speed, `0.5` for half speed, `2.0` for double speed, etc.
  double get playbackSpeed;

  /// Sets the playback speed for both video and audio (if present).
  ///
  /// - [speed] must be greater than 0.0.
  /// - Typical values: 0.5 (half speed), 1.0 (normal), 1.5, 2.0 (double speed).
  ///
  /// Implementations should ensure that video and audio remain synchronized.
  set playbackSpeed(double speed);

  /// Loads a new video source dynamically, replacing the current one.
  ///
  /// - [videoSourceConfiguration] defines the new source (e.g., Vimeo, YouTube, Network).
  void loadVideoSource(VideoSourceConfiguration videoSourceConfiguration);

  /// Whether the video player widget is fully visible within the viewport.
  ///
  /// - Returns `true` if the entire player is currently visible on screen.
  /// - Returns `false` if the player is partially visible or not visible at all.
  ///
  /// This can be useful for scenarios such as:
  /// - Pausing videos when scrolled out of view.
  /// - Auto-playing only when the player is completely visible.
  bool isFullyVisible = false;
}
