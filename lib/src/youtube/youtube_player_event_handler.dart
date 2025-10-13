import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/src/controllers/youtube_playback_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../omni_video_player/models/omni_video_quality.dart';
import '../../omni_video_player/models/video_player_configuration.dart';
import '../utils/logger.dart';
import 'model/youtube_player_state.dart';

class YoutubePlayerEventHandler {
  YoutubePlayerEventHandler(this.controller, this.options, this.callbacks) {
    _events = {
      'Ready': onReady,
      'StateChange': onStateChange,
      'PlaybackQualityChange': onPlaybackQualityChange,
      'PlaybackRateChange': onPlaybackRateChange,
      'PlayerError': onError,
      'FullscreenButtonPressed': onFullscreenButtonPressed,
      'VideoState': onVideoState,
      'AutoplayBlocked': onAutoplayBlocked,
    };
  }

  final YoutubePlaybackController controller;
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;

  final Completer<void> _readyCompleter = Completer();
  late final Map<String, ValueChanged<Object>> _events;

  void call(JavaScriptMessage javaScriptMessage) {
    if (controller.isDisposed) return;
    final data = Map.from(jsonDecode(javaScriptMessage.message));
    if (data['playerId'] != controller.playerId) return;

    for (final entry in data.entries) {
      if (entry.key == 'ApiChange') {
        onApiChange(entry.value);
      } else {
        _events[entry.key]?.call(entry.value ?? Object());
      }
    }
  }

  Future<void> onReady(Object data) async {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  Future<void> onStateChange(Object data) async {
    final stateCode = data as int;

    final playerState = YoutubePlayerState.values.firstWhere(
      (state) => state.code == stateCode,
      orElse: () => YoutubePlayerState.unknown,
    );

    controller.isReady = true;
    controller.isBuffering = false;

    if ((controller.duration == Duration(seconds: 1) ||
        controller.duration == Duration.zero)) {
      final String duration = await controller.runWithResult("getDuration");
      final int? seconds = double.tryParse(duration)?.round();

      if (seconds != null && seconds > 0) {
        // corrisponde a circa 11 giorni
        controller.isLive = seconds > 1000000 && kIsWeb;
        controller.duration = Duration(seconds: (seconds - 2));
      } else {
        return;
      }

      final config = options.videoSourceConfiguration;

      if (config.initialPosition.inSeconds >= 0) {
        await controller.seekTo(config.initialPosition);
        controller.hasStarted = false;
        controller.isPlaying = false;
      }

      if (!config.autoPlay ||
          (!controller.isFullyVisible && controller.hasStarted == false)) {
        controller.pause(useGlobalController: false);
        controller.hasStarted = false;
        controller.isPlaying = false;
      }

      controller.run('unMute');

      if (config.autoMuteOnStart) {
        controller.mute();
      } else if (controller.isMuted && !controller.hasStarted) {
        controller.run('mute');
      } else {
        controller.volume = config.initialVolume;
      }

      controller.playbackSpeed = config.initialPlaybackSpeed;

      callbacks.onControllerCreated?.call(controller);
    } else {
      if (playerState == YoutubePlayerState.playing &&
          controller.hasStarted == false) {
        controller.isReady = true;
      }

      if (controller.isSeeking == true) {
        controller.isSeeking = false;
        if (controller.wasPlayingBeforeSeek && !controller.isFinished) {
          controller.isPlaying = true;
          controller.play();
        }
      }

      if (playerState == YoutubePlayerState.playing) {
        controller.isPlaying = true;
        controller.hasStarted = true;
      } else if (playerState == YoutubePlayerState.paused &&
          controller.wasPlayingBeforeGoOnFullScreen == true) {
        controller.play();
        controller.wasPlayingBeforeGoOnFullScreen = null;
      } else if (playerState == YoutubePlayerState.paused) {
        controller.isPlaying = false;
      }
    }
  }

  void onPlaybackQualityChange(Object data) {
    if (data is String) {
      final quality = omniVideoQualityFromYouTube(data);
      controller.currentVideoQuality = quality;
    }
  }

  void onPlaybackRateChange(Object data) {}

  void onApiChange(Object? data) {}

  void onFullscreenButtonPressed(Object data) {}

  void onError(Object data) {
    logger.e(
      "YouTube API ErrorCode: $data, message: ${(data == 150 || data == 101) ? 'Embedding not allowed: usually happens with official music videos, copyrighted content (movies, sports, live events), videos with geographic restrictions, or when the uploader has disabled embedding in YouTube Studio' : 'Unknown error'}",
    );
    controller.hasError = true;
  }

  void onVideoState(Object data) {
    final json = jsonDecode(data.toString());

    final seconds = (json['currentTime'] ?? 0).truncate();

    if (seconds == 0) {
      return;
    }
    controller.currentPosition = Duration(seconds: seconds);

    if (controller.currentPosition >= controller.duration) {
      controller.pause();
      controller.seekTo(Duration.zero);
    }
  }

  void onAutoplayBlocked(Object data) {
    logger.i(
      'Autoplay was blocked by browser. '
      'Most modern browser does not allow video with sound to autoplay. '
      'Try muting the video to autoplay.',
    );
  }

  Future<void> get isReady => _readyCompleter.future;
}
