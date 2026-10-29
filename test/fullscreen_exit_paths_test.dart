import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/omni_video_player_fullscreen.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_viewport.dart';
import 'package:omni_video_player/src/_others/generic_playback_controller.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'support/fake_video_player_platform.dart';
import 'support/platform_channel_stubs.dart';

// Stands in for the YouTube and Vimeo WebView controllers too: same
// switchFullScreenMode shape.
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

class _Probe extends StatelessWidget {
  const _Probe({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

final _toggles = <bool>[];

Widget _fullscreenPage(_StillController controller) => OmniVideoPlayerTheme(
  data: OmniVideoPlayerThemeData(),
  child: OmniVideoPlayerFullscreen(
    controller: controller,
    configuration: _config,
    callbacks: VideoPlayerCallbacks(onFullScreenToggled: _toggles.add),
  ),
);

/// Mounts the inline player (controls overlay over the viewport), opens
/// fullscreen and returns the inline context plus a way to rebuild the host.
Future<(BuildContext, StateSetter)> _openFullscreen(
  WidgetTester tester,
  _StillController controller, {
  void Function(bool)? onToggle,
}) async {
  final playerKey = GlobalKey();
  controller.sharedPlayerNotifier.value = _Probe(key: playerKey);
  late BuildContext playerContext;
  late StateSetter rebuildHost;
  await tester.pumpWidget(
    MaterialApp(
      home: StatefulBuilder(
        builder: (ctx, setState) {
          playerContext = ctx;
          rebuildHost = setState;
          return OmniVideoPlayerTheme(
            data: OmniVideoPlayerThemeData(),
            child: Material(
              child: Center(
                child: SizedBox(
                  width: 320,
                  height: 180,
                  child: OmniVideoPlayerControlsOverlay(
                    controller: controller,
                    configuration: _config,
                    callbacks: VideoPlayerCallbacks(
                      onFullScreenToggled: _toggles.add,
                    ),
                    child: OmniVideoPlayerViewport(
                      controller: controller,
                      isFullScreenDisplay: false,
                      aspectRatio: 16 / 9,
                      videoFit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
  controller.switchFullScreenMode(
    playerContext,
    pageBuilder: (_) => _fullscreenPage(controller),
    onToggle: onToggle,
  );
  await tester.pumpAndSettle();
  expect(find.byType(OmniVideoPlayerFullscreen), findsOneWidget);
  return (playerContext, rebuildHost);
}

Future<void> _swipeDown(WidgetTester tester, Offset at) async {
  final gesture = await tester.startGesture(at);
  for (var i = 0; i < 5; i++) {
    await gesture.moveBy(const Offset(0, 30));
  }
  await gesture.up();
  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    stubVolumeControllerChannel();
    _toggles.clear();
  });

  testWidgets('system back out of fullscreen puts the player back inline', (
    tester,
  ) async {
    final controller = _StillController();
    await _openFullscreen(tester, controller);

    // Android back: WidgetsApp.didPopRoute -> Navigator.maybePop.
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.byType(OmniVideoPlayerFullscreen), findsNothing);
    expect(find.byType(_Probe), findsOneWidget, reason: 'inline is blank');
    expect(controller.isFullScreen, isFalse);
  });

  testWidgets('button exit reports onToggle(false) once, after the pop', (
    tester,
  ) async {
    final controller = _StillController();
    final (playerContext, _) = await _openFullscreen(
      tester,
      controller,
      onToggle: _toggles.add,
    );
    expect(_toggles, [true]);

    controller.switchFullScreenMode(
      playerContext,
      pageBuilder: null,
      onToggle: _toggles.add,
    );
    expect(controller.isFullScreen, isTrue);
    expect(_toggles, [true]);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(find.byType(OmniVideoPlayerFullscreen), findsNothing);
    expect(controller.isFullScreen, isFalse);
    expect(_toggles, [true, false]);
  });

  testWidgets('system back resets the generic controller (control)', (
    tester,
  ) async {
    final platform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
    addTearDown(platform.close);
    final controller = (await tester.runAsync(
      () => GenericPlaybackController.create(
        videoUrl: Uri.parse('https://example.com/v.mp4'),
        dataSource: null,
        file: null,
        initialPlaybackSpeed: null,
        callbacks: const VideoPlayerCallbacks(),
        type: VideoSourceType.network,
        globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
      ),
    ))!;
    addTearDown(controller.dispose);
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) {
            context = ctx;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    controller.switchFullScreenMode(
      context,
      pageBuilder: (_) => const SizedBox.expand(),
    );
    await tester.pumpAndSettle();
    expect(controller.isFullScreen, isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(controller.isFullScreen, isFalse);
  });

  testWidgets('a vertical swipe inline after fullscreen does nothing', (
    tester,
  ) async {
    final controller = _StillController();
    final (playerContext, rebuildHost) = await _openFullscreen(
      tester,
      controller,
    );

    // Any rebuild of the inline overlay while fullscreen is open, e.g. the
    // view's setState when the video finishes there.
    rebuildHost(() {});
    await tester.pump();

    controller.switchFullScreenMode(playerContext, pageBuilder: null);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    expect(controller.isFullScreen, isFalse);
    _toggles.clear();

    await _swipeDown(tester, tester.getCenter(find.byType(_Probe)));

    expect(_toggles, isEmpty);
    expect(controller.isFullScreen, isFalse);
  });

  testWidgets('a vertical swipe in fullscreen exits', (tester) async {
    final controller = _StillController();
    await _openFullscreen(tester, controller);

    await _swipeDown(tester, tester.getCenter(find.byType(_Probe)));

    expect(find.byType(OmniVideoPlayerFullscreen), findsNothing);
  });
}
