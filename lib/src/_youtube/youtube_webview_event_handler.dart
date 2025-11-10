import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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
    controller
      ..isReady = false
      ..hasStarted = false;
    controller.pause(useGlobalController: false);

    final durationResult = await controller.runWithResult("getDuration");
    final durationSeconds = double.tryParse(durationResult)?.round();

    if (durationSeconds == null || durationSeconds <= 0) return;

    controller
      ..isLive = durationSeconds > 1_000_000 && kIsWeb
      ..duration = Duration(seconds: durationSeconds - 2);

    final sourceConfig = configuration.videoSourceConfiguration;

    // Apply initial playback settings
    await _applyInitialSettings(sourceConfig);

    // Notify callback
    callbacks.onControllerCreated?.call(controller);
    controller.isReady = true;
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
    controller.playbackSpeed = sourceConfig.initialPlaybackSpeed;

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
    controller.playbackSpeed = double.tryParse(data.toString()) ?? 1.0;
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
    if (controller.currentPosition >= controller.duration &&
        controller.duration != const Duration(seconds: 1)) {
      controller.pause(useGlobalController: false);
      controller.seekTo(Duration.zero);
    }
  }
}
