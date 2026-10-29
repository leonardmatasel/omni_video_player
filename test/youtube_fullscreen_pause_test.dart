import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_event_handler.dart';

VideoPlayerConfiguration _config() => VideoPlayerConfiguration(
  videoSourceConfiguration: VideoSourceConfiguration.youtube(
    videoUrl: Uri.parse('https://www.youtube.com/watch?v=Cp4RRAEgpeU'),
  ),
);

/// Un controller YouTube senza WebView che conta i play chiesti.
class _Controller extends YouTubeWebViewController {
  _Controller()
    : super(
        duration: const Duration(minutes: 3),
        isLive: false,
        size: const Size(640, 360),
        callbacks: const VideoPlayerCallbacks(),
        options: _config(),
        videoId: 'Cp4RRAEgpeU',
        globalController: null,
        globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
      );

  var plays = 0;

  @override
  Future<void> play({bool useGlobalController = true}) async => plays++;

  @override
  Future<void> run(String functionName, {Map<String, dynamic>? data}) async {}
}

const _paused = 2;
const _window = Duration(milliseconds: 600);

void main() {
  late _Controller controller;
  late YouTubeWebViewEventHandler handler;

  setUp(() {
    controller = _Controller();
    handler = YouTubeWebViewEventHandler(
      controller,
      _config(),
      const VideoPlayerCallbacks(),
    );
  });

  testWidgets('entro 600 ms dalla crescita le pause non fermano il video', (
    tester,
  ) async {
    controller.isPlaying = true;
    controller.ignorePausesWhileResizing();

    await handler.handleStateChange(_paused);
    await tester.pump(const Duration(milliseconds: 300));
    await handler.handleStateChange(_paused);
    await tester.pump(const Duration(milliseconds: 250));
    await handler.handleStateChange(_paused);

    expect(controller.plays, 3);
    expect(controller.isPlaying, isTrue);
    await tester.pump(_window);
  });

  testWidgets('una nuova crescita riapre la finestra da capo', (tester) async {
    controller.isPlaying = true;
    controller.ignorePausesWhileResizing();
    await tester.pump(const Duration(milliseconds: 500));
    controller.ignorePausesWhileResizing();
    await tester.pump(const Duration(milliseconds: 500));

    await handler.handleStateChange(_paused);

    expect(controller.plays, 1);
    expect(controller.isPlaying, isTrue);
    await tester.pump(_window);
  });

  testWidgets('dopo la finestra la pausa ferma il video', (tester) async {
    controller.isPlaying = true;
    controller.ignorePausesWhileResizing();
    await tester.pump(_window);

    await handler.handleStateChange(_paused);

    expect(controller.plays, 0);
    expect(controller.isPlaying, isFalse);
  });

  testWidgets('col video gia in pausa la pausa resta', (tester) async {
    controller.ignorePausesWhileResizing();

    await handler.handleStateChange(_paused);

    expect(controller.plays, 0);
    expect(controller.isPlaying, isFalse);
    await tester.pump(_window);
  });

  testWidgets("la pausa chiesta nella finestra non e' una pausa finta", (
    tester,
  ) async {
    controller.isPlaying = true;
    controller.ignorePausesWhileResizing();

    await controller.pause(useGlobalController: false);
    await handler.handleStateChange(_paused);

    expect(controller.plays, 0);
    expect(controller.isPlaying, isFalse);
    await tester.pump(_window);
  });

  testWidgets("entrata e uscita col tasto indietro aprono la finestra", (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (c) {
            context = c;
            return const SizedBox.expand();
          },
        ),
      ),
    );
    controller.isPlaying = true;

    controller.switchFullScreenMode(
      context,
      pageBuilder: (_) => const SizedBox.expand(),
    );
    await tester.pump();
    await handler.handleStateChange(_paused);
    expect(controller.plays, 1);
    await tester.pumpAndSettle();
    await tester.pump(_window);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump();
    await handler.handleStateChange(_paused);
    expect(controller.plays, 2);
    expect(controller.isPlaying, isTrue);

    await tester.pumpAndSettle();
    expect(controller.isFullScreen, isFalse);
    await tester.pump(_window);
  });
}
