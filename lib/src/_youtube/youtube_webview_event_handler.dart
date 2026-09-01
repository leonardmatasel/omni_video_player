import 'dart:async';
import 'dart:convert';
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

  /// Guards against overlapping [_initializeControllerFromYouTube] runs, since
  /// `handleStateChange` keeps firing while the duration is still unset.
  bool _initializing = false;

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
    if (_initializing) return;
    _initializing = true;
    try {
      controller
        ..isReady = false
        ..hasStarted = false;
      controller.pause(useGlobalController: false);

      int? durationSeconds;
      if (!controller.isLive) {
        // getDuration returns undefined/0 until the player has loaded its
        // metadata. Instead of giving up on the first call, poll a few times
        // while it finishes loading; only then complete initialization.
        for (var attempt = 0; attempt < 8; attempt++) {
          if (controller.isDisposed) return;
          final durationResult = await controller.runWithResult("getDuration");
          durationSeconds = double.tryParse(durationResult)?.round();
          if (durationSeconds != null && durationSeconds > 0) break;
          await Future.delayed(const Duration(milliseconds: 400));
        }
        if (durationSeconds == null || durationSeconds <= 0) {
          // No fixed duration after three seconds of polling means there is no
          // fixed duration: this is a live stream that reached us misclassified,
          // because `isLive` is decided by a metadata lookup upstream
          // (`youtube_initializer.dart`) that yields `false` whenever it fails —
          // a blocked youtube_explode_dart request, for instance.
          //
          // Returning here left `isReady` false forever: the "a later state
          // change will retry" this used to rely on never arrives, because the
          // player sits at UNSTARTED and YouTube only emits another state change
          // once something calls play. The result was a permanent spinner.
          //
          // ponytail: inferred from the poll rather than read from
          // `getVideoData().isLive`, which would mean parsing a JSON blob back
          // through the JS bridge. If a genuinely broken on-demand video ever
          // lands here it gets a live-styled player instead of a spinner, which
          // is the better of the two; read the flag properly if that shows up.
          controller.isLive = true;
        }
      }

      if (controller.isDisposed) return;

      if (controller.isLive) {
        // Per i live non c'è una durata fissa calcolabile accuratamente
        controller.duration = Duration(seconds: 10000000);
      } else {
        controller.duration = Duration(seconds: (durationSeconds ?? 0) - 2);
      }

      final sourceConfig = configuration.videoSourceConfiguration;

      // Apply initial playback settings
      await _applyInitialSettings(sourceConfig);

      // Notify callback
      callbacks.onControllerCreated?.call(controller);
      controller.isReady = true;
    } finally {
      _initializing = false;
    }
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
      controller.volume = sourceConfig.initialVolume;
    }

    // Apply playback speed
    controller.setPlaybackSpeed(sourceConfig.initialPlaybackSpeed);

    // Control autoplay and visibility
    if (!sourceConfig.autoPlay ||
        (!controller.isFullyVisible && !controller.hasStarted)) {
      // Init can finish late (the duration poll runs while the player loads).
      // If playback already kicked off in the meantime (user tap or autoplay),
      // don't clobber it with the initial pause. YT state 1 = playing,
      // 3 = buffering (a play was requested and is loading) — skip in both.
      final state = double.tryParse(
        (await controller.runWithResult('getPlayerState')).trim(),
      )?.round();
      const youTubePlaying = 1;
      const youTubeBuffering = 3;
      if (state != youTubePlaying && state != youTubeBuffering) {
        controller
          ..pause(useGlobalController: false)
          ..isPlaying = false
          ..hasStarted = false;
      }
    }
  }

  void _handlePlayingState() {
    controller
      ..isPlaying = true
      ..hasStarted = true
      ..isReady = true;
  }

  void _handlePausedState() {
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
