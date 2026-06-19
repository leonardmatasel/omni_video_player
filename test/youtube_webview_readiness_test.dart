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

YouTubeWebViewController _controller(
  VideoPlayerConfiguration config,
  VideoPlayerCallbacks callbacks,
) =>
    YouTubeWebViewController.fromVideoId(
      videoId: 'pt8VYOfr8To',
      // Matches YouTubeWebViewInitializer: the duration is unknown at
      // construction (1s sentinel) and is only resolved later from the IFrame
      // API via getDuration().
      duration: const Duration(seconds: 1),
      isLive: false,
      size: const Size(640, 360),
      callbacks: callbacks,
      options: config,
      globalController: null,
      globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
    );

void main() {
  group('YouTubeWebViewController readiness', () {
    test(
        'becomes ready on state change even when getDuration is unavailable '
        '(iOS cued video reports duration 0)', () async {
      var created = false;
      final callbacks =
          VideoPlayerCallbacks(onControllerCreated: (_) => created = true);
      final config = _config();
      final controller = _controller(config, callbacks);
      final handler = YouTubeWebViewEventHandler(controller, config, callbacks);

      // No WebView is attached, so runWithResult('getDuration') resolves to an
      // unparseable value — the same situation as iOS, where a cued (not yet
      // played) video reports getDuration() == 0. Before the fix the
      // initializer early-returned here, isReady stayed false forever, and the
      // 30s readiness failsafe tore the player down in a refresh loop.
      await handler.handleStateChange(3);

      expect(
        controller.state.value.isReady,
        isTrue,
        reason: 'the player must be ready once the IFrame player is up, '
            'independently of whether the duration is known yet',
      );
      expect(
        created,
        isTrue,
        reason: 'onControllerCreated must fire so the host app receives the '
            'controller even for a cued video',
      );

      controller.dispose();
    });
  });
}
