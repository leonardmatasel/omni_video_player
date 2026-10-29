import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_youtube/_utils/youtube_initializer.dart';
import 'package:omni_video_player/src/_youtube/_utils/youtube_webview_initializer.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/api/youtube_video_api.dart';

final _watch = Uri.parse('https://www.youtube.com/watch?v=kwWElKZVCBc');
final _short = Uri.parse('https://www.youtube.com/shorts/kwWElKZVCBc');

MockClient _oembed(int width, int height) => MockClient(
  (_) async => http.Response('{"width":$width,"height":$height}', 200),
);

Future<Size> _fetch(
  Uri url,
  http.Client client, {
  Duration timeout = const Duration(seconds: 3),
}) => http.runWithClient(
  () => YouTubeService.fetchVideoSize('abc', url, timeout: timeout),
  () => client,
);

void main() {
  group('YouTubeService.startSize', () {
    test('a /shorts/ URL starts 720x1280', () {
      expect(YouTubeService.startSize(_short), const Size(720, 1280));
    });

    test('a watch?v= URL starts 1280x720', () {
      expect(YouTubeService.startSize(_watch), const Size(1280, 720));
    });
  });

  group('YouTubeService.fetchVideoSize', () {
    test('asks oEmbed with the /shorts/ form of the id', () async {
      Uri? asked;
      final client = MockClient((request) async {
        asked = request.url;
        return http.Response('{"width":113,"height":200}', 200);
      });

      await _fetch(_watch, client);

      expect(asked?.host, 'www.youtube.com');
      expect(asked?.path, '/oembed');
      expect(
        asked?.queryParameters['url'],
        'https://www.youtube.com/shorts/abc',
      );
      expect(asked?.queryParameters['format'], 'json');
      expect(asked?.queryParameters['maxwidth'], '1280');
      expect(asked?.queryParameters['maxheight'], '1280');
    });

    for (final (url, answer) in [
      (_watch, const Size(113, 200)),
      (_short, const Size(200, 150)),
    ]) {
      test('a $answer oEmbed answer gives that size', () async {
        final size = await _fetch(
          url,
          _oembed(answer.width.toInt(), answer.height.toInt()),
        );
        expect(size, answer);
      });
    }

    for (final (failure, client) in [
      ('a non-200 status', MockClient((_) async => http.Response('', 404))),
      (
        'a network error',
        MockClient((_) => throw http.ClientException('offline')),
      ),
      for (final body in ['not json', '[]', '{"width":"a","height":0}'])
        ('the body $body', MockClient((_) async => http.Response(body, 200))),
    ]) {
      test('$failure keeps the start size', () async {
        expect(await _fetch(_short, client), YouTubeService.startSize(_short));
      });
    }

    test('a timeout keeps the start size', () async {
      final size = await _fetch(
        _short,
        MockClient((_) => Completer<http.Response>().future),
        timeout: const Duration(milliseconds: 10),
      );
      expect(size, YouTubeService.startSize(_short));
    });
  });

  group('YouTubeWebViewInitializer', () {
    YouTubeWebViewInitializer initializer(Uri url, {Size? startSize}) {
      final source = VideoSourceConfiguration.youtube(videoUrl: url);
      return YouTubeWebViewInitializer(
        config: VideoPlayerConfiguration(videoSourceConfiguration: source),
        sourceConfig: source,
        callbacks: const VideoPlayerCallbacks(),
        startSize: startSize,
      );
    }

    testWidgets('creates the player 9:16 without waiting on oEmbed', (
      tester,
    ) async {
      OmniPlaybackController? controller;
      http.runWithClient(
        () => initializer(_short).initialize().then((c) => controller = c),
        () => MockClient((_) => Completer<http.Response>().future),
      );
      await tester.pump();

      expect(controller?.size, YouTubeService.startSize(_short));

      await tester.pump(const Duration(seconds: 3));
      expect(controller!.size, YouTubeService.startSize(_short));
      await controller!.dispose();
    });

    testWidgets('a start size is the controller size until oEmbed answers', (
      tester,
    ) async {
      OmniPlaybackController? controller;
      http.runWithClient(
        () => initializer(
          _watch,
          startSize: const Size(360, 640),
        ).initialize().then((c) => controller = c),
        () => MockClient((_) => Completer<http.Response>().future),
      );
      await tester.pump();

      expect(controller?.size, const Size(360, 640));

      await tester.pump(const Duration(seconds: 3));
      await controller!.dispose();
    });

    testWidgets('the oEmbed answer becomes the controller size', (
      tester,
    ) async {
      final controller = await http.runWithClient(
        () => initializer(_watch).initialize(),
        () => _oembed(113, 200),
      );
      var notified = 0;
      controller!.addListener(() => notified++);
      await tester.pump();

      expect(controller.size, const Size(113, 200));
      (controller as YouTubeWebViewController).size = const Size(113, 200);
      expect(notified, 1);
      await controller.dispose();
    });
  });

  group('OmniVideoPlayerInitializerFactory.getStrategy', () {
    for (final forceWebViewOnly in [true, false]) {
      test('passes the start size to YouTube, forceWebViewOnly '
          '$forceWebViewOnly', () async {
        final source = VideoSourceConfiguration.youtube(
          videoUrl: _watch,
          webView: YoutubeWebViewConfiguration(
            forceWebViewOnly: forceWebViewOnly,
          ),
        );
        final strategy = await OmniVideoPlayerInitializerFactory.getStrategy(
          VideoSourceType.youtube,
          source,
          VideoPlayerConfiguration(videoSourceConfiguration: source),
          const VideoPlayerCallbacks(),
          null,
          startSize: const Size(360, 640),
        );

        final startSize = switch (strategy) {
          YouTubeWebViewInitializer s => s.startSize,
          YouTubeInitializer s => s.startSize,
          _ => null,
        };
        expect(startSize, const Size(360, 640));
        expect(strategy is YouTubeWebViewInitializer, forceWebViewOnly);
      });
    }
  });
}
