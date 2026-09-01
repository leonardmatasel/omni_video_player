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

/// Un controller YouTube il cui lato JS non risponde mai con una durata, che è
/// esattamente ciò che fa `getDuration()` su uno stream live.
///
/// I metodi sovrascritti sono solo quelli che l'inizializzazione chiama e che
/// senza WebView non avrebbero nessuno con cui parlare.
class _NoDurationController extends YouTubeWebViewController {
  _NoDurationController({required super.isLive})
    : super(
        // Il segnaposto che mette YouTubeWebViewInitializer.
        duration: const Duration(seconds: 1),
        size: const Size(640, 360),
        callbacks: const VideoPlayerCallbacks(),
        options: _config(),
        videoId: 'Cp4RRAEgpeU',
        globalController: null,
        globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
      );

  @override
  Future<String> runWithResult(
    String functionName, {
    Map<String, dynamic>? data,
  }) async => '0';

  @override
  Future<void> pause({bool useGlobalController = true}) async {}

  @override
  Future<void> seekTo(
    Duration position, {
    dynamic skipHasPlaybackStarted = false,
  }) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}
}

void main() {
  test(
    'un live arrivato come non-live completa comunque l\'inizializzazione',
    () async {
      // Il caso reale: `isLive` lo decide un lookup di metadati a monte
      // (youtube_initializer.dart), che davanti a un blocco di
      // youtube_explode_dart torna `false` anche per un live.
      final controller = _NoDurationController(isLive: false);
      final handler = YouTubeWebViewEventHandler(
        controller,
        _config(),
        const VideoPlayerCallbacks(),
      );

      await handler.handleStateChange(-1);

      // Prima della fix il polling di getDuration() usciva con un `return`
      // lasciando isReady a false, e il "later state change will retry" non
      // arrivava mai: il player restava sullo spinner per sempre.
      expect(controller.isReady, isTrue);
      expect(controller.isLive, isTrue);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );

  test('un live dichiarato tale non passa nemmeno dal polling', () async {
    final controller = _NoDurationController(isLive: true);
    final handler = YouTubeWebViewEventHandler(
      controller,
      _config(),
      const VideoPlayerCallbacks(),
    );

    await handler.handleStateChange(-1);

    expect(controller.isReady, isTrue);
    expect(controller.duration, const Duration(seconds: 10000000));
  });
}
