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

    // Parsa la durata se arriva dal JS. Per i WebM a loadedmetadata è spesso
    // 0/Infinity/NaN (la durata reale arriva dopo, via PlaybackProgress):
    // non sovrascrivere con un valore non valido, o seek bar/replay impazziscono.
    if (data != null && data is Map<String, dynamic>) {
      final durationSec = data['duration'];
      if (durationSec is num && durationSec.isFinite && durationSec > 0) {
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
      controller.volume = sourceConfig.initialVolume;
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

    // The real WebM duration usually only becomes known after playback starts,
    // so keep correcting it here (drives the seek bar, total time, and the
    // end/replay state that were stuck because duration stayed 0).
    final durationSec = data['duration'];
    if (durationSec is num && durationSec.isFinite && durationSec > 0) {
      final newDuration = Duration(milliseconds: (durationSec * 1000).toInt());
      if (controller.duration != newDuration) {
        controller.duration = newDuration;
      }
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
