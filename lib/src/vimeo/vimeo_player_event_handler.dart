import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/controllers/vimeo_playback_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VimeoPlayerEventHandler {
  VimeoPlayerEventHandler(this.controller, this.options) {
    _events = {
      'onReady': onReady,
      'onPlay': onPlay,
      'onPause': onPause,
      //'onFinish': onFinish,
      'onSeek': onSeek,
      'onBufferStart': onBufferStart,
      'onBufferEnd': onBufferEnd,
      'onTimeUpdate': onTimeUpdate,
      'onError': onError,
    };
  }

  final VimeoPlaybackController controller;
  final VideoPlayerConfiguration options;

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

  Future<void> onBufferStart(Object data) async {
    controller.isBuffering = true;
  }

  Future<void> onBufferEnd(Object data) async {
    controller.isBuffering = false;
  }

  Future<void> onTimeUpdate(Object data) async {
    final map = data as Map<String, dynamic>;
    final seconds = (map['seconds'] as num).round();
    final duration = (map['duration'] as num).round();

    if (seconds >= duration) controller.pause();

    controller.currentPosition = Duration(seconds: seconds);
    controller.duration = Duration(seconds: duration);
  }

  Future<void> onReady(Object data) async {
    if (!_readyCompleter.isCompleted) _readyCompleter.complete();
    controller.isReady = true;
  }

  Future<void> onPlay(Object data) async {
    controller.isPlaying = true;
  }

  Future<void> onPause(Object data) async {
    controller.isPlaying = false;
  }

  Future<void> onSeek(Object data) async {
    controller.isSeeking = false;
    if (controller.wasPlayingBeforeSeek && !controller.isFinished) {
      controller.isPlaying = true;
      controller.play();
    }
  }

  void onApiChange(Object? data) {}

  void onError(Object data) {
    options.globalKeyInitializer.currentState!.refresh();
    controller.hasError = true;
  }

  Future<void> get isReady => _readyCompleter.future;
}
