import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/_youtube/mobile/controller.dart';
import 'package:omni_video_player/src/_youtube/_model/youtube_player_state.dart';

class YoutubeMobilePlayerEventHandler {
  YoutubeMobilePlayerEventHandler(
    this.controller,
    this.options,
    this.callbacks,
  );

  final YoutubeMobilePlaybackController controller;
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;

  final Completer<void> _readyCompleter = Completer();

  Future<void> onReady([Object? data]) async {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
  }

  Future<void> onStateChange(Object? data) async {
    final stateCode = data is int ? data : int.tryParse(data.toString()) ?? -1;

    final playerState = YoutubePlayerState.values.firstWhere(
      (state) => state.code == stateCode,
      orElse: () => YoutubePlayerState.unknown,
    );

    controller.isReady = true;
    controller.isBuffering = false;

    if ((controller.duration == Duration(seconds: 1) ||
        controller.duration == Duration.zero)) {
      controller.isReady = false;
      controller.pause(useGlobalController: false);
      controller.hasStarted = false;

      final String duration = await controller.runWithResult("getDuration");
      final int? seconds = double.tryParse(duration)?.round();

      if (seconds != null && seconds > 0) {
        controller.isLive = seconds > 1000000 && kIsWeb;
        controller.duration = Duration(seconds: (seconds - 2));
      } else {
        return;
      }

      final config = options.videoSourceConfiguration;

      if (config.initialPosition.inSeconds >= 0) {
        await controller.seekTo(config.initialPosition);
        controller.hasStarted = false;
      }

      if (config.autoMuteOnStart) {
        controller.mute();
      } else {
        controller.volume = config.initialVolume;
      }

      if (!config.autoPlay ||
          (!controller.isFullyVisible && controller.hasStarted == false)) {
        controller.pause(useGlobalController: false);
        controller.hasStarted = false;
        controller.isPlaying = false;
      }

      controller.playbackSpeed = config.initialPlaybackSpeed;

      callbacks.onControllerCreated?.call(controller);
      controller.isReady = true;
    } else {
      if (playerState == YoutubePlayerState.playing &&
          controller.hasStarted == false) {
        controller.isReady = true;
      }

      if (controller.isSeeking == true) {
        controller.isSeeking = false;
        if (controller.wasPlayingBeforeSeek && !controller.isFinished) {
          controller.isPlaying = true;
          controller.play(useGlobalController: false);
        }
      }

      if (playerState == YoutubePlayerState.playing) {
        controller.isPlaying = true;
        controller.hasStarted = true;
      } else if (playerState == YoutubePlayerState.paused &&
          controller.wasPlayingBeforeGoOnFullScreen == true) {
        controller.play(useGlobalController: false);
        controller.wasPlayingBeforeGoOnFullScreen = null;
      } else if (playerState == YoutubePlayerState.paused) {
        controller.isPlaying = false;
      }
    }
  }

  void onPlaybackQualityChange(Object? data) {
    if (data is String) {
      final quality = omniVideoQualityFromYouTube(data);
      controller.currentVideoQuality = quality;
    }
  }

  void onPlaybackRateChange(Object? data) {}

  void onApiChange(Object? data) {}

  void onFullscreenButtonPressed(Object? data) {}

  void onError(Object? data) {
    options.globalKeyInitializer.currentState?.refresh();
    controller.hasError = true;
  }

  void onVideoState(Object? data) {
    if (data == null) return;

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

  void onAutoplayBlocked(Object? data) {
    debugPrint(
      'Autoplay was blocked by browser. '
      'Most modern browsers do not allow video with sound to autoplay. '
      'Try muting the video to autoplay.',
    );
  }

  Future<void> get isReady {
    return _readyCompleter.future;
  }
}
