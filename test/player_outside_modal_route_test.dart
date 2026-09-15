import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

import 'support/platform_channel_stubs.dart';

const _playerKey = Key('player-in-overlay');

/// Stesso trucco di seek_loader_test.dart: il controller WebM ha il costruttore
/// piu' semplice, e i quaranta membri dell'interfaccia arrivano gratis.
class _StillController extends WebmVideoWebViewController {
  _StillController()
    : super(
        duration: const Duration(seconds: 10),
        isLive: false,
        size: const Size(640, 360),
        callbacks: const VideoPlayerCallbacks(),
        options: VideoPlayerConfiguration(
          videoSourceConfiguration: VideoSourceConfiguration.network(
            videoUrl: Uri.parse('https://example.com/v.webm'),
          ),
        ),
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
  playerUIVisibilityOptions: const PlayerUIVisibilityOptions(
    showScrubbingThumbnailPreview: false,
  ),
);

Widget _player() => OmniVideoPlayerTheme(
  data: OmniVideoPlayerThemeData(),
  child: Material(
    color: Colors.transparent,
    child: Center(
      child: SizedBox(
        key: _playerKey,
        width: 200,
        height: 200,
        child: OmniVideoPlayerControlsOverlay(
          controller: _StillController(),
          configuration: _config,
          callbacks: const VideoPlayerCallbacks(),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(stubVolumeControllerChannel);

  testWidgets('un player in una OverlayEntry del Navigator non ha ModalRoute e '
      'deve montarsi lo stesso', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            // L'entry vive accanto alla route, non dentro: nessun _ModalScope
            // fra i suoi antenati.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Overlay.of(
                context,
              ).insert(OverlayEntry(builder: (_) => _player()));
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(_playerKey), findsOneWidget);
  });
}
