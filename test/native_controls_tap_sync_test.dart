import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';
import 'package:omni_video_player/src/utils/animated_fade_visibility.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/gradient_bottom_control_bar.dart';

import 'support/platform_channel_stubs.dart';

const _videoKey = Key('video-surface');

/// Controller in native mode, like the YouTube WebView with
/// `useNativeControls: true`; [native] false gives the plain overlay.
class _NativeController extends WebmVideoWebViewController {
  _NativeController({this.native = true, this.playing = true})
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

  final bool native;
  bool playing;

  @override
  bool get usesNativeCenterControls => native;

  @override
  bool get hasStarted => true;

  @override
  bool get isPlaying => playing;

  @override
  bool get isReady => true;
}

var _iframeTaps = 0;

/// The iframe stands in as a TapGestureRecognizer, the one the WebView gets.
Widget _overlay([_NativeController? controller]) => MaterialApp(
  home: Scaffold(
    body: OmniVideoPlayerTheme(
      data: OmniVideoPlayerThemeData(),
      child: Center(
        child: SizedBox(
          width: 300,
          height: 300,
          child: OmniVideoPlayerControlsOverlay(
            controller: controller ?? _NativeController(),
            configuration: VideoPlayerConfiguration(
              videoSourceConfiguration: VideoSourceConfiguration.network(
                videoUrl: Uri.parse('https://example.com/v.webm'),
              ),
              playerUIVisibilityOptions: PlayerUIVisibilityOptions(
                showScrubbingThumbnailPreview: false,
              ),
            ),
            callbacks: const VideoPlayerCallbacks(),
            child: GestureDetector(
              onTap: () => _iframeTaps++,
              child: const SizedBox.expand(
                child: ColoredBox(color: Color(0xFF123456), key: _videoKey),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

bool _barVisible(WidgetTester tester) => tester
    .widget<AnimatedFadeVisibility>(
      find.descendant(
        of: find.byType(GradientBottomControlBar),
        matching: find.byType(AnimatedFadeVisibility),
      ),
    )
    .visible;

/// Touches left of center, off the non-native center button.
Future<void> _touch(WidgetTester tester, Offset move) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(_videoKey)) - const Offset(100, 0),
  );
  await tester.pump(const Duration(milliseconds: 50));
  await gesture.moveBy(move);
  await gesture.up();
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  setUp(() {
    stubVolumeControllerChannel();
    _iframeTaps = 0;
  });

  testWidgets('a still tap reaches both our bar and the iframe', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay());
    await tester.pump(const Duration(seconds: 8)); // auto-hide runs out

    await _touch(tester, Offset.zero);

    expect(_iframeTaps, 1);
    expect(_barVisible(tester), isTrue);
  });

  testWidgets('a tap that slips 18 px still reaches the bar and the iframe', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay());
    await tester.pump(const Duration(seconds: 8));

    await _touch(tester, const Offset(18, 0));

    expect(_iframeTaps, 1);
    expect(_barVisible(tester), isTrue);
  });

  testWidgets('a tap that slips 19 px reaches neither the bar nor the iframe', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay());
    await tester.pump(const Duration(seconds: 8));

    await _touch(tester, const Offset(19, 0));

    expect(_iframeTaps, 0);
    expect(_barVisible(tester), isFalse);
  });

  testWidgets('a 30 px drag back to the start reaches neither the bar nor '
      'the iframe', (tester) async {
    await tester.pumpWidget(_overlay());
    await tester.pump(const Duration(seconds: 8));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_videoKey)) - const Offset(100, 0),
    );
    await gesture.moveBy(const Offset(30, 0));
    await gesture.moveBy(const Offset(-30, 0));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(_iframeTaps, 0);
    expect(_barVisible(tester), isFalse);
  });

  testWidgets('a second tap keeps the bar and restarts its 3 s', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay());
    await tester.pump(const Duration(seconds: 8));

    await _touch(tester, Offset.zero);
    await tester.pump(const Duration(seconds: 2));
    await _touch(tester, Offset.zero);

    expect(_barVisible(tester), isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(_barVisible(tester), isTrue); // 4.4 s after the first tap
    await tester.pump(const Duration(seconds: 1));
    expect(_barVisible(tester), isFalse);
  });

  testWidgets('a tap in pause, then play: the bar shows and hides after 3 s', (
    tester,
  ) async {
    final controller = _NativeController(playing: false);
    await tester.pumpWidget(_overlay(controller));
    await tester.pump(const Duration(seconds: 8));

    await _touch(tester, Offset.zero);
    expect(_barVisible(tester), isFalse); // hidden in pause by default
    controller
      ..playing = true
      ..notifyListeners();
    await tester.pump();

    expect(_barVisible(tester), isTrue);
    await tester.pump(const Duration(milliseconds: 2900));
    expect(_barVisible(tester), isTrue);
    await tester.pump(const Duration(milliseconds: 200));
    expect(_barVisible(tester), isFalse);
  });

  testWidgets('outside native mode a second tap still hides the bar', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay(_NativeController(native: false)));
    await tester.pump(const Duration(seconds: 8));

    await _touch(tester, Offset.zero);
    expect(_barVisible(tester), isTrue);
    await _touch(tester, Offset.zero);

    expect(_barVisible(tester), isFalse);
  });
}
