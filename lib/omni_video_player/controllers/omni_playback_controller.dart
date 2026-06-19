// This base controller defines the @Deprecated state getters AND bridges them
// into `state` via `_snapshot()`. It is the sanctioned home of the deprecation,
// so it opts out of the same-package deprecation diagnostic. The deprecations
// stay only for EXTERNAL plugin consumers; the library's own widgets read
// `controller.state.value.*` instead.
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:video_player/video_player.dart';

/// An abstract interface for controlling video playback across multiple source types.
///
/// [OmniPlaybackController] defines a unified API for managing video playback,
/// supporting various sources such as network streams, local files, or third-party platforms
/// (e.g., YouTube, Vimeo). It includes methods for controlling playback, volume, seek,
/// fullscreen, and other media-related properties.
abstract class OmniPlaybackController with ChangeNotifier {
  ValueNotifier<OmniVideoState>? _stateNotifier;

  /// Reactive snapshot of the player's observable state. Use with
  /// `ValueListenableBuilder` or read `controller.state.value` synchronously —
  /// no `addListener`/`setState` needed.
  ValueListenable<OmniVideoState> get state =>
      _stateNotifier ??= ValueNotifier<OmniVideoState>(_snapshot());

  OmniVideoState _snapshot() => OmniVideoState(
        isReady: isReady,
        isPlaying: isPlaying,
        isBuffering: isBuffering,
        isSeeking: isSeeking,
        hasStarted: hasStarted,
        isFinished: isFinished,
        hasError: hasError,
        isFullScreen: isFullScreen,
        isLive: isLive,
        isMuted: isMuted,
        isFullyVisible: isFullyVisible,
        position: currentPosition,
        duration: duration,
        buffered: buffered,
        volume: volume,
        playbackSpeed: playbackSpeed,
        size: size,
        rotationCorrection: rotationCorrection,
        currentVideoQuality: currentVideoQuality,
        availableVideoQualities: availableVideoQualities,
      );

  @override
  void notifyListeners() {
    // Refresh `state` BEFORE notifying ChangeNotifier listeners, so internal
    // widgets that rebuild via `notifyListeners()` (AnimatedBuilder /
    // addListener) read an up-to-date `state.value` in the same frame.
    final n = _stateNotifier;
    if (n != null && !isDisposed) {
      final next = _snapshot();
      if (n.value != next) n.value = next;
    }
    super.notifyListeners();
  }

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
  @Deprecated('Use controller.state.value.isLive instead. Removed in 6.0.0.')
  bool get isLive;

  /// The resolved video URL, if available.
  Uri? get videoUrl;

  /// The raw data source of the video, such as a URL or asset path.
  String? get videoDataSource;

  File? get file;

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
  @Deprecated('Use controller.state.value.isReady instead. Removed in 6.0.0.')
  bool get isReady;

  /// Whether playback is currently active.
  @Deprecated('Use controller.state.value.isPlaying instead. Removed in 6.0.0.')
  bool get isPlaying;

  /// Whether an error occurred during initialization or playback.
  @Deprecated('Use controller.state.value.hasError instead. Removed in 6.0.0.')
  bool get hasError;

  /// Whether the video is currently buffering.
  @Deprecated('Use controller.state.value.isBuffering instead. Removed in 6.0.0.')
  bool get isBuffering;

  /// The current audio volume, from 0.0 (mute) to 1.0 (max).
  @Deprecated('Use controller.state.value.volume instead. Removed in 6.0.0.')
  double get volume;

  /// Whether the video is currently muted.
  @Deprecated('Use controller.state.value.isMuted instead. Removed in 6.0.0.')
  bool get isMuted;

  /// Whether the player is actively seeking to a position.
  @Deprecated('Use controller.state.value.isSeeking instead. Removed in 6.0.0.')
  bool get isSeeking;

  /// Whether playback has started at least once.
  @Deprecated('Use controller.state.value.hasStarted instead. Removed in 6.0.0.')
  bool get hasStarted;

  /// Whether the player is currently in fullscreen mode.
  @Deprecated('Use controller.state.value.isFullScreen instead. Removed in 6.0.0.')
  bool get isFullScreen;

  /// The current playback position.
  @Deprecated('Use controller.state.value.position instead. Removed in 6.0.0.')
  Duration get currentPosition;

  /// Whether playback has reached the end of the video.
  @Deprecated('Use controller.state.value.isFinished instead. Removed in 6.0.0.')
  bool get isFinished;

  /// The total duration of the video.
  @Deprecated('Use controller.state.value.duration instead. Removed in 6.0.0.')
  Duration get duration;

  /// Degrees of rotation to apply for video orientation correction.
  @Deprecated('Use controller.state.value.rotationCorrection instead. Removed in 6.0.0.')
  int get rotationCorrection;

  /// Whether control-button surfaces should be drawn opaque (no translucency).
  ///
  /// Returns `true` for sources rendered behind a WebView that displays its own
  /// native controls underneath (e.g. the YouTube IFrame player), so the custom
  /// controls fully mask them. Defaults to `false`.
  bool get requiresOpaqueControlButtons => false;

  /// Whether the player should use the source's NATIVE center play/pause
  /// (e.g. the YouTube IFrame) instead of our custom center button. Default
  /// `false`. When `true`, the controls overlay suppresses the custom center
  /// button mid-playback and the tap-to-toggle over the video.
  bool get usesNativeCenterControls => false;

  /// The intrinsic size (width and height) of the video.
  @Deprecated('Use controller.state.value.size instead. Removed in 6.0.0.')
  Size get size;

  /// A list of buffered video ranges.
  @Deprecated('Use controller.state.value.buffered instead. Removed in 6.0.0.')
  List<DurationRange> get buffered;

  // ──────────────── Setters ────────────────

  /// Sets the audio volume, clamped to [0.0, 1.0]. Updates `state` automatically.
  Future<void> setVolume(double volume);

  /// Sets the audio volume, clamped between 0.0 and 1.0.
  @Deprecated('Use setVolume() instead. Removed in 6.0.0.')
  set volume(double value) => setVolume(value);

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
  @Deprecated('Use controller.state.value.currentVideoQuality instead. Removed in 6.0.0.')
  OmniVideoQuality? get currentVideoQuality;

  /// List of selectable video qualities (e.g., 1080p, 720p).
  ///
  /// May be `null` if the source doesn't support multiple qualities.
  /// Useful for building a quality selector UI.
  @Deprecated('Use controller.state.value.availableVideoQualities instead. Removed in 6.0.0.')
  List<OmniVideoQuality>? get availableVideoQualities;

  /// Switches the video playback quality to the specified [quality].
  ///
  /// Throws an exception if the specified quality is not available.
  Future<void> switchQuality(OmniVideoQuality quality);

  /// Gets the current playback speed of the video.
  ///
  /// Returns `1.0` for normal speed, `0.5` for half speed, `2.0` for double speed, etc.
  @Deprecated('Use controller.state.value.playbackSpeed instead. Removed in 6.0.0.')
  double get playbackSpeed;

  /// Sets the playback speed for both video and audio (if present).
  ///
  /// - [speed] must be greater than 0.0.
  /// - Typical values: 0.5 (half speed), 1.0 (normal), 1.5, 2.0 (double speed).
  ///
  /// Implementations should ensure that video and audio remain synchronized.
  Future<void> setPlaybackSpeed(double speed);

  /// Loads a new video source dynamically, replacing the current one.
  ///
  /// - [videoSourceConfiguration] defines the new source (e.g., Vimeo, YouTube, Network).
  void loadVideoSource(VideoSourceConfiguration videoSourceConfiguration);

  /// Returns `true` if this controller has been disposed and can no longer be used.
  bool get isDisposed;

  /// Whether the video player widget is fully visible within the viewport.
  ///
  /// - Returns `true` if the entire player is currently visible on screen.
  /// - Returns `false` if the player is partially visible or not visible at all.
  ///
  /// This can be useful for scenarios such as:
  /// - Pausing videos when scrolled out of view.
  /// - Auto-playing only when the player is completely visible.
  @Deprecated('Use controller.state.value.isFullyVisible instead. Removed in 6.0.0.')
  bool isFullyVisible = false;
}
