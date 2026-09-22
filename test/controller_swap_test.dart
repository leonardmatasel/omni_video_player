import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/widgets/playback_center_button.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

import 'support/platform_channel_stubs.dart';

/// Espone [hasListeners], che e' protetto: serve a vedere a quale controller
/// sono appesi i bottoni.
class _SpyController extends WebmVideoWebViewController {
  _SpyController()
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

  bool get isListenedTo => hasListeners;
}

final _config = VideoPlayerConfiguration(
  videoSourceConfiguration: VideoSourceConfiguration.network(
    videoUrl: Uri.parse('https://example.com/v.webm'),
  ),
);

Widget _centerButton(_SpyController controller) => OmniVideoPlayerTheme(
  data: OmniVideoPlayerThemeData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Material(
      child: PlaybackCenterButton(
        controller: controller,
        configuration: _config,
        callbacks: const VideoPlayerCallbacks(),
        visible: true,
      ),
    ),
  ),
);

void main() {
  setUp(stubVolumeControllerChannel);

  testWidgets('the buttons follow the controller when the player is rebuilt '
      'on a new one', (tester) async {
    final released = _SpyController();
    final reborn = _SpyController();

    await tester.pumpWidget(_centerButton(released));
    expect(released.isListenedTo, isTrue);

    // Quello che succede dopo un release: stesso posto nell'albero, controller
    // nuovo.
    await tester.pumpWidget(_centerButton(reborn));

    expect(released.isListenedTo, isFalse);
    expect(reborn.isListenedTo, isTrue);
  });
}
