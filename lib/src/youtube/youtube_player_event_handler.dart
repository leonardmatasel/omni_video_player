import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:omni_video_player/src/controllers/youtube_playback_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/logger.dart';
import 'model/youtube_player_state.dart';

class YoutubePlayerEventHandler {
  YoutubePlayerEventHandler(this.controller) {
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

  final Completer<void> _readyCompleter = Completer();
  late final Map<String, ValueChanged<Object>> _events;

  void call(JavaScriptMessage javaScriptMessage) {
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

  void onPlaybackQualityChange(Object data) {}

  void onPlaybackRateChange(Object data) {}

  void onApiChange(Object? data) {}

  void onFullscreenButtonPressed(Object data) {}

  void onError(Object data) {
    controller.hasError = true;
  }

  void onVideoState(Object data) {
    final json = jsonDecode(data.toString());

    controller.currentPosition =
        Duration(seconds: (json['currentTime'] ?? 0).truncate());
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
