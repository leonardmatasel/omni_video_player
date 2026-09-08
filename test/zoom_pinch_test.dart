import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

import 'support/platform_channel_stubs.dart';

const _videoKey = Key('video-surface');

/// Controller minimo: il WebM ha il costruttore piu' semplice e porta
/// `supportsSeek` true, quindi le zone di double-tap sono in scena.
class _Controller extends WebmVideoWebViewController {
  _Controller()
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

  final seeks = <Duration>[];

  @override
  bool get hasStarted => true;

  bool fullScreen = false;

  @override
  bool get isFullScreen => fullScreen;

  @override
  Future<void> seekTo(
    Duration position, {
    dynamic skipHasPlaybackStarted = false,
  }) async => seeks.add(position);
}

/// In play the auto-hide timer takes the controls away by itself: the closest
/// thing to what a device does while the video runs.
class _PlayingController extends _Controller {
  @override
  bool get isPlaying => true;

  @override
  bool get isReady => true;
}

late _Controller _controller;

Widget _overlay({
  required bool enableZoom,
  bool exitOnSwipe = false,
  _Controller? controller,
}) => MaterialApp(
  home: Scaffold(
    body: OmniVideoPlayerTheme(
      data: OmniVideoPlayerThemeData(),
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: OmniVideoPlayerControlsOverlay(
            controller: controller ?? _controller,
            configuration: VideoPlayerConfiguration(
              videoSourceConfiguration: VideoSourceConfiguration.network(
                videoUrl: Uri.parse('https://example.com/v.webm'),
              ),
              playerUIVisibilityOptions: PlayerUIVisibilityOptions(
                enableZoom: enableZoom,
                enableExitFullscreenOnVerticalSwipe: exitOnSwipe,
                showScrubbingThumbnailPreview: false,
              ),
            ),
            callbacks: const VideoPlayerCallbacks(),
            child: const SizedBox.expand(
              child: ColoredBox(color: Color(0xFF123456), key: _videoKey),
            ),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _pinchOut(WidgetTester tester) async {
  final center = tester.getCenter(find.byKey(_videoKey));
  final left = await tester.startGesture(center - const Offset(20, 0));
  final right = await tester.startGesture(center + const Offset(20, 0));
  await tester.pump();
  await left.moveBy(const Offset(-40, 0));
  await right.moveBy(const Offset(40, 0));
  await tester.pump();
  await left.up();
  await right.up();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() {
    stubVolumeControllerChannel();
    _controller = _Controller();
  });

  testWidgets('pinch-to-zoom scales the video surface', (tester) async {
    await tester.pumpWidget(_overlay(enableZoom: true));
    final before = tester.getRect(find.byKey(_videoKey));

    await _pinchOut(tester);

    expect(tester.getRect(find.byKey(_videoKey)).width, greaterThan(before.width));
  });

  testWidgets('enableZoom false leaves the video untouched', (tester) async {
    await tester.pumpWidget(_overlay(enableZoom: false));
    final before = tester.getRect(find.byKey(_videoKey));

    await _pinchOut(tester);

    expect(tester.getRect(find.byKey(_videoKey)).width, before.width);
  });

  testWidgets('pinch still zooms in fullscreen, where the exit swipe is armed', (
    tester,
  ) async {
    _controller.fullScreen = true;
    await tester.pumpWidget(_overlay(enableZoom: true, exitOnSwipe: true));
    final before = tester.getRect(find.byKey(_videoKey));

    await _pinchOut(tester);

    expect(
      tester.getRect(find.byKey(_videoKey)).width,
      greaterThan(before.width),
    );
  });

  testWidgets('pinch zooms with the controls hidden too', (tester) async {
    await tester.pumpWidget(
      _overlay(enableZoom: true, controller: _PlayingController()),
    );
    await tester.pump(const Duration(seconds: 8)); // auto-hide runs out
    final before = tester.getRect(find.byKey(_videoKey));

    await _pinchOut(tester);

    expect(
      tester.getRect(find.byKey(_videoKey)).width,
      greaterThan(before.width),
    );
  });

  testWidgets('double-tap to skip survives the zoom recognizer', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay(enableZoom: true));
    final center = tester.getCenter(find.byKey(_videoKey));
    final right = Offset(center.dx + 80, center.dy);

    await tester.tapAt(right);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(right);
    await tester.pump(const Duration(milliseconds: 400));

    expect(_controller.seeks, isNotEmpty);
  });
}
