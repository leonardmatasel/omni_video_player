import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';
import 'package:omni_video_player/src/_webm/webm_webview_event_handler.dart';
import 'package:omni_video_player/src/_webm/webm_webview_initializer.dart';

void main() {
  late WebmVideoWebViewController controller;
  late WebmVideoWebViewEventHandler handler;
  var notified = 0;

  setUp(() {
    final config = VideoPlayerConfiguration(
      videoSourceConfiguration: VideoSourceConfiguration.network(
        videoUrl: Uri.parse('https://example.com/v.webm'),
      ),
    );
    controller = WebmVideoWebViewController(
      duration: const Duration(seconds: 1),
      isLive: false,
      size: const Size(1280, 720),
      callbacks: const VideoPlayerCallbacks(),
      options: config,
      videoUrlStr: 'https://example.com/v.webm',
      globalController: null,
      globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
      isFile: false,
    );
    handler = WebmVideoWebViewEventHandler(
      controller,
      config,
      const VideoPlayerCallbacks(),
    );
    notified = 0;
    controller.addListener(() => notified++);
  });

  test('a 640x480 Ready becomes the controller size', () async {
    await handler.handleReady({'duration': 0, 'width': 640, 'height': 480});

    expect(controller.size, const Size(640, 480));
  });

  for (final data in <Object?>[
    {'width': 0, 'height': 480},
    {'width': 640, 'height': 0},
    {'width': '640', 'height': 480},
    {'width': 640},
    null,
  ]) {
    test('size $data leaves the size alone', () {
      handler.handleVideoSize(data);

      expect(controller.size, const Size(1280, 720));
      expect(notified, 0);
    });
  }

  group('WebmVideoWebViewInitializer', () {
    for (final (startSize, expected) in [
      (const Size(360, 640), const Size(360, 640)),
      (null, const Size(1280, 720)),
    ]) {
      testWidgets('start size $startSize gives a $expected player', (
        tester,
      ) async {
        final source = VideoSourceConfiguration.network(
          videoUrl: Uri.parse('https://example.com/v.webm'),
        );
        final player = await WebmVideoWebViewInitializer(
          config: VideoPlayerConfiguration(videoSourceConfiguration: source),
          sourceConfig: source,
          callbacks: const VideoPlayerCallbacks(),
          videoUrl: 'https://example.com/v.webm',
          isFile: false,
          startSize: startSize,
        ).initialize();

        expect(player!.size, expected);
        await player.dispose();
      });
    }
  });
}
