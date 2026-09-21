import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/omni_video_player_fullscreen.dart';
import 'package:omni_video_player/src/_core/utils/fullscreen_overlay_host.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

import 'support/platform_channel_stubs.dart';

/// Stesso trucco di player_outside_modal_route_test.dart: il controller WebM ha
/// il costruttore piu' semplice, e i quaranta membri dell'interfaccia arrivano
/// gratis.
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
  playerUIVisibilityOptions: const PlayerUIVisibilityOptions(
    showScrubbingThumbnailPreview: false,
  ),
);

/// Il player della app vive in una OverlayEntry sopra la route: senza il
/// fullscreen in cima all'overlay, la entry coprirebbe il fullscreen.
Widget _hostEntry(List<String> tapped) => GestureDetector(
  onTap: () => tapped.add('host-entry'),
  child: Container(color: const Color(0x88000000)),
);

void main() {
  setUp(stubVolumeControllerChannel);

  testWidgets('il fullscreen si vede sopra una OverlayEntry della app', (
    tester,
  ) async {
    final tapped = <String>[];
    final controller = _StillController();
    late BuildContext entryContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Overlay.of(context, rootOverlay: true).insert(
                OverlayEntry(
                  builder: (ctx) {
                    entryContext = ctx;
                    return _hostEntry(tapped);
                  },
                ),
              );
            });
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    controller.switchFullScreenMode(
      entryContext,
      pageBuilder: (_) => FullscreenOverlayHost(
        child: OmniVideoPlayerTheme(
          data: OmniVideoPlayerThemeData(),
          child: OmniVideoPlayerFullscreen(
            controller: controller,
            configuration: _config,
            callbacks: const VideoPlayerCallbacks(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Il tap al centro deve finire sul fullscreen, non sulla entry della app.
    await tester.tapAt(tester.getCenter(find.byType(MaterialApp)));
    await tester.pump();
    expect(tapped, isEmpty);
    expect(find.byType(OmniVideoPlayerFullscreen), findsOneWidget);

    // Uscendo, la entry della app torna a ricevere i tap e il fullscreen sparisce.
    Navigator.of(entryContext).pop();
    await tester.pumpAndSettle();
    expect(find.byType(OmniVideoPlayerFullscreen), findsNothing);
    await tester.tapAt(tester.getCenter(find.byType(MaterialApp)));
    await tester.pump();
    expect(tapped, ['host-entry']);
  });
}
