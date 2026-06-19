import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_vimeo/vimeo_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';

VideoPlayerConfiguration _config() => VideoPlayerConfiguration(
      videoSourceConfiguration: VideoSourceConfiguration.network(
        videoUrl: Uri.parse('https://example.com/v.mp4'),
      ),
    );

VimeoController _vimeo({double initialVolume = 1.0}) => VimeoController.create(
      videoId: '123',
      globalController: null,
      initialPosition: Duration.zero,
      initialVolume: initialVolume,
      duration: const Duration(seconds: 100),
      size: const Size(640, 360),
      callbacks: const VideoPlayerCallbacks(),
      globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
      options: _config(),
    );

YouTubeWebViewController _youtube() => YouTubeWebViewController.fromVideoId(
      videoId: '123',
      duration: const Duration(seconds: 100),
      isLive: false,
      size: const Size(640, 360),
      callbacks: const VideoPlayerCallbacks(),
      options: _config(),
      globalController: null,
      globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
    );

void main() {
  group('VimeoController dispose safety', () {
    test('mutating notifying state after dispose does not throw', () {
      final c = _vimeo();
      c.dispose();

      // Before the fix these throw "A VimeoController was used after being
      // disposed." because the setters call notifyListeners() unconditionally.
      expect(() => c.currentPosition = const Duration(seconds: 5),
          returnsNormally);
      expect(() => c.isPlaying = true, returnsNormally);
      expect(() => c.isBuffering = true, returnsNormally);
      expect(() => c.isSeeking = true, returnsNormally);
    });

    test('seekTo after dispose completes without throwing', () async {
      final c = _vimeo();
      c.dispose();

      // Reproduces the crash: seekTo awaits a JS call, then writes
      // currentPosition (-> notifyListeners) after the controller is disposed.
      await expectLater(c.seekTo(const Duration(seconds: 1)), completes);
    });
  });

  group('VimeoController volume range', () {
    test('setVolume clamps to [0, 1] and updates state', () async {
      final c = _vimeo();

      // Simulates a polluted global volume leaking in from the YouTube player
      // (YouTube used a 0-100 scale internally). Vimeo.setVolume() throws a
      // RangeError for anything outside [0, 1].
      await c.setVolume(100);
      expect(c.state.value.volume, 1.0);

      await c.setVolume(-3);
      expect(c.state.value.volume, 0.0);

      c.dispose();
    });
  });

  group('YouTubeWebViewController volume scale', () {
    test('initial volume is normalised within [0, 1]', () {
      final c = _youtube();
      expect(c.state.value.volume, inInclusiveRange(0.0, 1.0));
      c.dispose();
    });

    test('unMute before any explicit volume stays within [0, 1]', () {
      final c = _youtube();
      c.mute();
      c.unMute();
      // A leftover 0-100 initial would make this 100 and pollute the shared
      // global volume that other players (e.g. Vimeo) read back.
      expect(c.state.value.volume, inInclusiveRange(0.0, 1.0));
      c.dispose();
    });
  });
}
