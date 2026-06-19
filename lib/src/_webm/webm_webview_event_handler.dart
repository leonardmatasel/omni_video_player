// WebView event machinery: it drives the controller from iframe JS events
// (writes via concrete setters) and reads LIVE controller state for control flow,
// which must not go through the reactive snapshot. The deprecations stay only for
// external consumers, so this bridge file opts out of the diagnostic.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

class WebmVideoWebViewEventHandler {
  final WebmVideoWebViewController controller;
  final VideoPlayerConfiguration configuration;
  final VideoPlayerCallbacks callbacks;

  WebmVideoWebViewEventHandler(
    this.controller,
    this.configuration,
    this.callbacks,
  );

  // -------------------------------------
  // 🏁 READY / LOADED METADATA
  // -------------------------------------
  Future<void> handleReady(Object? data) async {
    controller.isReady = true;

    // Parsa la durata se arriva dal JS
    if (data != null && data is Map<String, dynamic>) {
      final durationSec = data['duration'];
      if (durationSec != null && durationSec is num) {
        controller.duration = Duration(
          milliseconds: (durationSec * 1000).toInt(),
        );
      }
    }

    // Impostazioni iniziali
    final sourceConfig = configuration.videoSourceConfiguration;
    await _applyInitialSettings(sourceConfig);

    callbacks.onControllerCreated?.call(controller);
  }

  Future<void> _applyInitialSettings(
    VideoSourceConfiguration sourceConfig,
  ) async {
    // Seek iniziale
    if (sourceConfig.initialPosition.inSeconds > 0) {
      await controller.seekTo(
        sourceConfig.initialPosition,
        skipHasPlaybackStarted: true,
      );
    }

    // Volume
    if (sourceConfig.autoMuteOnStart) {
      controller.mute();
    } else {
      controller.setVolume(sourceConfig.initialVolume);
    }

    // Speed
    controller.setPlaybackSpeed(sourceConfig.initialPlaybackSpeed);

    // Autoplay
    // Nota: Su Web/Mobile browser autoplay con audio spesso è bloccato.
    // Il video deve essere mutato o richiedere gesto utente.
    // InAppWebView "mediaPlaybackRequiresUserGesture: false" aiuta molto qui.
    if (sourceConfig.autoPlay) {
      controller.play(useGlobalController: false);
    }
  }

  // -------------------------------------
  // 🎬 STATE CHANGE
  // -------------------------------------

  Future<void> handleStateChange(Object? data) async {
    final status = data.toString();

    switch (status) {
      case 'playing':
        controller.isBuffering = false;
        controller.isPlaying = true;
        controller.hasStarted = true;
        break;

      case 'paused':
        controller.isBuffering = false;
        controller.isPlaying = false;
        break;

      case 'buffering':
        controller.isBuffering = true;
        break;

      case 'ended':
        controller.pause(useGlobalController: false);
        break;
    }
  }

  // -------------------------------------
  // 🕒 PROGRESS UPDATES
  // -------------------------------------

  void handleSeeked() {
    if (controller.isSeeking) {
      controller.isSeeking = false;

      // Ripristina la riproduzione se necessario
      if (controller.wasPlayingBeforeSeek) {
        controller.play(useGlobalController: false);
      }
    }
  }

  void handlePlaybackProgress(Object? data) {
    if (data == null || data is! Map<String, dynamic>) return;

    final currentSec = data['currentTime'];
    if (currentSec is num) {
      controller.currentPosition = Duration(
        milliseconds: (currentSec * 1000).toInt(),
      );
    }
  }

  // -------------------------------------
  // ❌ ERROR HANDLING
  // -------------------------------------

  void handleError(Object? data) {
    debugPrint("WebVideo Error: $data");
    controller.hasError = true;
    configuration.globalKeyInitializer.currentState?.refresh();
  }
}
