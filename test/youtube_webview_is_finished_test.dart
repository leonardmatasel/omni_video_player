import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';

VideoPlayerConfiguration _config() => VideoPlayerConfiguration(
      videoSourceConfiguration: VideoSourceConfiguration.youtube(
        videoUrl: Uri.parse('https://youtu.be/abc'),
      ),
    );

YouTubeWebViewController _youtube({Duration duration = Duration.zero}) =>
    YouTubeWebViewController.fromVideoId(
      videoId: 'abc',
      duration: duration,
      isLive: false,
      size: const Size(640, 360),
      callbacks: const VideoPlayerCallbacks(),
      options: _config(),
      globalController: null,
      globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
    );

void main() {
  group('YouTubeWebViewController.isFinished duration guard', () {
    test('is not finished while the duration is still unknown (zero)', () {
      final c = _youtube();
      // The Ready handler calls play() before the duration poll resolves,
      // which sets hasStarted while duration is still zero.
      c.hasStarted = true;

      // Before the fix this was true, so the replay button replaced the play
      // button on load and taps could never start playback.
      expect(c.isFinished, isFalse);
      c.dispose();
    });

    test('is not finished on the 1s placeholder duration', () {
      final c = _youtube(duration: const Duration(seconds: 1));
      c.hasStarted = true;

      expect(c.isFinished, isFalse);
      c.dispose();
    });

    test('is finished once a real duration is known and playback is at the end',
        () {
      final c = _youtube(duration: const Duration(seconds: 100));
      c.hasStarted = true;
      c.currentPosition = const Duration(seconds: 99);

      expect(c.isFinished, isTrue);
      c.dispose();
    });

    test('is not finished mid-playback with a real duration', () {
      final c = _youtube(duration: const Duration(seconds: 100));
      c.hasStarted = true;
      c.currentPosition = const Duration(seconds: 10);

      expect(c.isFinished, isFalse);
      c.dispose();
    });
  });
}
