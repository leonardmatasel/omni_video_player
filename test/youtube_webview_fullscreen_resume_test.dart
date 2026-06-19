import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_event_handler.dart';

VideoPlayerConfiguration _config() => VideoPlayerConfiguration(
      videoSourceConfiguration: VideoSourceConfiguration.network(
        videoUrl: Uri.parse('https://example.com/v.mp4'),
      ),
    );

YouTubeWebViewController _controller(VideoPlayerCallbacks callbacks) =>
    YouTubeWebViewController.fromVideoId(
      videoId: '123',
      // A known duration so handleStateChange skips first-time init and reaches
      // the play/pause transition handling.
      duration: const Duration(seconds: 100),
      isLive: false,
      size: const Size(640, 360),
      callbacks: callbacks,
      options: _config(),
      globalController: null,
      globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
    );

void main() {
  group('YouTube fullscreen transition resume', () {
    test(
        'multiple transient pauses during a fullscreen transition do not stick '
        '(WebView reparenting emits more than one pause)', () async {
      const callbacks = VideoPlayerCallbacks();
      final c = _controller(callbacks);
      final h = YouTubeWebViewEventHandler(c, _config(), callbacks);
      c.isPlaying = true;

      // Entering/leaving fullscreen opens the resume window.
      c.beginFullscreenResumeWindow();

      // The Hero flight reparents the WKWebView, so YouTube fires several
      // `paused` events in a row. The old one-shot flag resumed only the first.
      await h.handleStateChange(2);
      await h.handleStateChange(2);

      expect(
        c.state.value.isPlaying,
        isTrue,
        reason: 'reparent-induced pauses during the transition must be resumed, '
            'not recorded as a user pause',
      );
      c.dispose();
    });

    test('a pause outside any fullscreen transition is recorded as paused',
        () async {
      const callbacks = VideoPlayerCallbacks();
      final c = _controller(callbacks);
      final h = YouTubeWebViewEventHandler(c, _config(), callbacks);
      c.isPlaying = true;

      await h.handleStateChange(2);

      expect(c.state.value.isPlaying, isFalse,
          reason: 'a genuine pause must still be honored');
      c.dispose();
    });
  });
}
