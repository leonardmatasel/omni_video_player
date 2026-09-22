import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_viewport.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

import 'support/platform_channel_stubs.dart';

/// Il controller col costruttore piu' semplice: il guard vive nella classe base,
/// quindi vale per tutti.
class _StillController extends WebmVideoWebViewController {
  _StillController()
    : super(
        duration: const Duration(seconds: 10),
        isLive: false,
        size: const Size(640, 360),
        callbacks: const VideoPlayerCallbacks(),
        options: _config,
        videoUrlStr: 'https://example.com/v.webm',
        globalController: null,
        globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
        isFile: false,
      );
}

final _config = VideoPlayerConfiguration(
  videoSourceConfiguration: VideoSourceConfiguration.network(
    videoUrl: Uri.parse('https://example.com/v.webm'),
  ),
);

Widget _viewport(_StillController controller, double aspectRatio) =>
    Directionality(
      textDirection: TextDirection.ltr,
      child: OmniVideoPlayerViewport(
        controller: controller,
        isFullScreenDisplay: false,
        aspectRatio: aspectRatio,
      ),
    );

void main() {
  setUp(stubVolumeControllerChannel);

  test('a disposed controller takes no listener and sends no notification', () async {
    final controller = _StillController();
    await controller.dispose();

    var notified = 0;
    expect(() => controller.addListener(() => notified++), returnsNormally);
    controller.notifyListeners();

    expect(notified, 0);
  });

  testWidgets('a viewport rebuilt on a disposed controller does not throw', (
    tester,
  ) async {
    final controller = _StillController();
    await tester.pumpWidget(_viewport(controller, 16 / 9));

    // Il player viene disposto (risorse, visibilita') mentre il suo albero
    // resta montato: il rebuild successivo riaggancia i listener.
    await controller.dispose();
    await tester.pumpWidget(_viewport(controller, 4 / 3));

    expect(tester.takeException(), isNull);
  });
}
