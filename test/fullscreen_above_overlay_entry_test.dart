import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/omni_video_player_fullscreen.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_viewport.dart';
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

/// Sta per la WebView: se l'elemento viene smontato invece che spostato per
/// GlobalKey, [mounts] cresce e la WebView vera sarebbe stata distrutta.
class _Probe extends StatefulWidget {
  const _Probe({super.key});
  static int mounts = 0;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    _Probe.mounts++;
  }

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

Widget _fullscreenPage(_StillController controller) => OmniVideoPlayerTheme(
  data: OmniVideoPlayerThemeData(),
  child: OmniVideoPlayerFullscreen(
    controller: controller,
    configuration: _config,
    callbacks: const VideoPlayerCallbacks(),
  ),
);

Widget _inlinePlayer(_StillController controller) => OmniVideoPlayerTheme(
  data: OmniVideoPlayerThemeData(),
  child: Material(
    child: OmniVideoPlayerViewport(
      controller: controller,
      isFullScreenDisplay: false,
      aspectRatio: 16 / 9,
    ),
  ),
);

void main() {
  setUp(() {
    stubVolumeControllerChannel();
    _Probe.mounts = 0;
  });

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
                    return GestureDetector(
                      onTap: () => tapped.add('host-entry'),
                      child: Container(color: const Color(0x88000000)),
                    );
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
      pageBuilder: (_) => _fullscreenPage(controller),
    );
    await tester.pumpAndSettle();

    // Il tap al centro deve finire sul fullscreen, non sulla entry della app.
    await tester.tapAt(tester.getCenter(find.byType(MaterialApp)));
    await tester.pump();
    expect(tapped, isEmpty);
    expect(find.byType(OmniVideoPlayerFullscreen), findsOneWidget);

    // Uscendo, la entry della app torna a ricevere i tap.
    Navigator.of(entryContext).pop();
    await tester.pumpAndSettle();
    expect(find.byType(OmniVideoPlayerFullscreen), findsNothing);
    await tester.tapAt(tester.getCenter(find.byType(MaterialApp)));
    await tester.pump();
    expect(tapped, ['host-entry']);
  });

  for (final inOverlay in [false, true]) {
    final where = inOverlay ? 'in una OverlayEntry' : 'in una pagina';
    testWidgets('il player condiviso passa al fullscreen senza rimontarsi, '
        '$where', (tester) async {
      final controller = _StillController();
      final playerKey = GlobalKey();
      controller.sharedPlayerNotifier.value = Hero(
        tag: playerKey,
        child: _Probe(key: playerKey),
      );
      late BuildContext playerContext;

      Widget inline() => Builder(
        builder: (ctx) {
          playerContext = ctx;
          return _inlinePlayer(controller);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              if (!inOverlay) return inline();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Overlay.of(
                  context,
                  rootOverlay: true,
                ).insert(OverlayEntry(builder: (_) => inline()));
              });
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_Probe.mounts, 1);

      controller.switchFullScreenMode(
        playerContext,
        pageBuilder: (_) => _fullscreenPage(controller),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OmniVideoPlayerFullscreen), findsOneWidget);
      expect(_Probe.mounts, 1, reason: 'la WebView e stata ricreata');
    });
  }
}
