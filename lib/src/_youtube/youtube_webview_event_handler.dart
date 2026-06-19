// WebView event machinery: it drives the controller from iframe JS events
// (writes via concrete setters) and reads LIVE controller state for control flow,
// which must not go through the reactive snapshot. The deprecations stay only for
// external consumers, so this bridge file opts out of the diagnostic.
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // [OMNI-DIAG] for debugPrint (remove after debug)
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/_model/youtube_player_state.dart';

/// Handles YouTube mobile player events triggered from WebView.
///
/// This class acts as an adapter between raw YouTube JS events and
/// the `YoutubeWebViewController` state logic, providing controlled
/// updates for play/pause, seeking, buffering, and error management.
class YouTubeWebViewEventHandler {
  final YouTubeWebViewController controller;
  final VideoPlayerConfiguration configuration;
  final VideoPlayerCallbacks callbacks;

  YouTubeWebViewEventHandler(
    this.controller,
    this.configuration,
    this.callbacks,
  );

  /// Whether the one-time post-load setup has already run.
  ///
  /// Readiness is intentionally decoupled from the video duration: a *cued*
  /// (not-yet-played) video reports `getDuration() == 0` on iOS WKWebView until
  /// playback actually starts, whereas Android reports it up-front. Gating
  /// readiness on a positive duration therefore froze iOS only — the player
  /// never became ready, and the 30s readiness failsafe tore the WebView down
  /// and re-created it in an endless loop.
  bool _hasInitialized = false;

  // -------------------------------------
  // 🎬 STATE CHANGE
  // -------------------------------------

  Future<void> handleStateChange(Object? data) async {
    final stateCode = data is int ? data : int.tryParse(data.toString()) ?? -1;

    final playerState = YoutubePlayerState.values.firstWhere(
      (state) => state.code == stateCode,
      orElse: () => YoutubePlayerState.unknown,
    );

    controller
      ..isReady = true
      ..isBuffering = false;

    // Initialize controller when duration is not yet available
    if (_isDurationUnset) {
      await _initializeControllerFromYouTube();
      return;
    }

    // Handle state transitions
    switch (playerState) {
      case YoutubePlayerState.playing:
        _handlePlayingState();
        break;
      case YoutubePlayerState.paused:
        _handlePausedState();
        break;
      default:
        break;
    }

    // Resume after seeking if necessary
    if (controller.isSeeking) {
      _handleSeekCompletion();
    }
  }

  bool get _isDurationUnset =>
      controller.duration == const Duration(seconds: 1) ||
      controller.duration == Duration.zero;

  Future<void> _initializeControllerFromYouTube() async {
    debugPrint(
      '[OMNI-DIAG] init: ENTER (durationUnset=$_isDurationUnset '
      'hasInit=$_hasInitialized)',
    );

    // Probe the real duration. For a cued (not-yet-played) video iOS reports 0
    // until playback starts, so this can legitimately be 0/unknown here and
    // only resolve on a later state change (e.g. once the user presses play).
    // Capture it whenever it becomes available — but never block readiness on
    // it (see [_hasInitialized]).
    final durationResult = await controller.runWithResult("getDuration");
    final durationSeconds = double.tryParse(durationResult)?.round();
    debugPrint(
      '[OMNI-DIAG] init: getDuration raw="$durationResult" '
      'parsed=$durationSeconds isLive=${controller.isLive}',
    );

    final hasRealDuration =
        controller.isLive || (durationSeconds != null && durationSeconds > 0);
    if (hasRealDuration) {
      // Per i live non c'è una durata fissa calcolabile accuratamente
      controller.duration = controller.isLive
          ? Duration(seconds: 10000000)
          : Duration(seconds: (durationSeconds ?? 0) - 2);
    }

    // One-time post-load setup. Runs as soon as the IFrame player is up,
    // regardless of whether the duration is known yet, so the loader is
    // dismissed and the 30s readiness failsafe does not tear the WebView down
    // and re-create it in a loop. Later state changes only refine the duration.
    if (_hasInitialized) return;
    _hasInitialized = true;

    controller
      ..isReady = false
      ..hasStarted = false;
    controller.pause(useGlobalController: false);

    final sourceConfig = configuration.videoSourceConfiguration;

    // Apply initial playback settings
    await _applyInitialSettings(sourceConfig);

    // Notify callback
    callbacks.onControllerCreated?.call(controller);
    controller.isReady = true;
    debugPrint(
      '[OMNI-DIAG] init: COMPLETE -> isReady=true (durationKnown=$hasRealDuration)',
    );
  }

  Future<void> _applyInitialSettings(
    VideoSourceConfiguration sourceConfig,
  ) async {
    // Seek to the starting position
    if (sourceConfig.initialPosition.inSeconds >= 0) {
      await controller.seekTo(
        sourceConfig.initialPosition,
        skipHasPlaybackStarted: true,
      );
      controller.hasStarted = false;
    }

    // Apply initial volume or mute
    if (sourceConfig.autoMuteOnStart) {
      controller.mute();
    } else {
      controller.setVolume(sourceConfig.initialVolume);
    }

    // Apply playback speed
    controller.setPlaybackSpeed(sourceConfig.initialPlaybackSpeed);

    // Control autoplay and visibility
    if (!sourceConfig.autoPlay ||
        (!controller.isFullyVisible && !controller.hasStarted)) {
      controller
        ..pause(useGlobalController: false)
        ..isPlaying = false
        ..hasStarted = false;
    }
  }

  void _handlePlayingState() {
    controller
      ..isPlaying = true
      ..hasStarted = true
      ..isReady = true;
  }

  void _handlePausedState() {
    debugPrint(
      '[OMNI-DIAG] handlePaused inFsTransition=${controller.isInFullscreenTransition} '
      'wasPlayingBeforeFS=${controller.wasPlayingBeforeGoOnFullScreen}',
    );
    // A pause that lands during a fullscreen transition is the WKWebView being
    // reparented (Hero flight), not the user. The flight emits several pauses
    // in a row, so keep resuming for the whole window instead of consuming a
    // one-shot flag (which left later pauses — especially on exit — stuck).
    if (controller.isInFullscreenTransition) {
      controller.play(useGlobalController: false);
      return;
    }
    if (controller.wasPlayingBeforeGoOnFullScreen == true) {
      controller.play(useGlobalController: false);
      controller.wasPlayingBeforeGoOnFullScreen = null;
    } else {
      controller.isPlaying = false;
    }
  }

  void _handleSeekCompletion() {
    controller.isSeeking = false;
    if (controller.wasPlayingBeforeSeek && !controller.isFinished) {
      controller
        ..isPlaying = true
        ..play(useGlobalController: false);
    }
  }

  // -------------------------------------
  // ⚙️ QUALITY / SPEED
  // -------------------------------------

  void handlePlaybackQualityChange(Object? data) {
    if (data is! String) return;
    final newQuality = omniVideoQualityFromYouTube(data);
    controller.currentVideoQuality = newQuality;
  }

  void handlePlaybackRateChange(Object? data) {
    controller.setPlaybackSpeed(double.tryParse(data.toString()) ?? 1.0);
  }

  // -------------------------------------
  // ❌ ERROR HANDLING
  // -------------------------------------

  void handleError(Object? data) {
    controller.hasError = true;
    configuration.globalKeyInitializer.currentState?.refresh();
  }

  // -------------------------------------
  // 🕒 PROGRESS UPDATES
  // -------------------------------------

  void handlePlaybackProgress(Object? data) {
    if (data == null) return;

    final json = jsonDecode(data.toString());
    final seconds = (json['currentTime'] ?? 0).truncate();

    if (seconds == 0) return;

    controller.currentPosition = Duration(seconds: seconds);

    // Loop when end of video is reached
    if (!controller.isLive &&
        controller.currentPosition >= controller.duration &&
        controller.duration != const Duration(seconds: 1) &&
        controller.hasStarted == true) {
      controller.pause(useGlobalController: false);
    }
  }
}
