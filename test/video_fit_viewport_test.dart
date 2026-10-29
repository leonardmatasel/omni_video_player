import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/omni_video_player_fullscreen.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_viewport.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

import 'support/platform_channel_stubs.dart';

/// Controller fermo, come in fullscreen_above_overlay_entry_test, con una
/// `size` che il test puo' cambiare.
class _StillController extends WebmVideoWebViewController {
  _StillController(this._size)
    : super(
        duration: const Duration(seconds: 10),
        isLive: false,
        size: _size,
        callbacks: const VideoPlayerCallbacks(),
        options: _config(BoxFit.contain),
        videoUrlStr: 'https://example.com/v.webm',
        globalController: null,
        globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
        isFile: false,
      );

  Size _size;

  @override
  Size get size => _size;

  set videoSize(Size value) {
    _size = value;
    notifyListeners();
  }
}

VideoPlayerConfiguration _config(
  BoxFit fit, {
  double? fullScreenRatio,
  Widget Function(BuildContext, Widget)? fullscreenWrapper,
}) => VideoPlayerConfiguration(
      videoSourceConfiguration: VideoSourceConfiguration.network(
        videoUrl: Uri.parse('https://example.com/v.webm'),
      ),
      playerUIVisibilityOptions: PlayerUIVisibilityOptions(
        showScrubbingThumbnailPreview: false,
        videoFit: fit,
        customAspectRatioFullScreen: fullScreenRatio,
      ),
      customPlayerWidgets: CustomPlayerWidgets(
        fullscreenWrapper: fullscreenWrapper,
      ),
    );

const _probe = Key('probe');

/// Box quadrato 300x300 al centro di uno schermo 800x600.
final _box = Rect.fromCenter(
  center: const Offset(400, 300),
  width: 300,
  height: 300,
);

_StillController _controllerWithProbe(Size size) {
  final controller = _StillController(size);
  controller.sharedPlayerNotifier.value = const SizedBox.expand(key: _probe);
  return controller;
}

Widget _viewport(_StillController controller, BoxFit fit) => MaterialApp(
  home: Center(
    child: SizedBox.fromSize(
      size: _box.size,
      child: OmniVideoPlayerViewport(
        controller: controller,
        isFullScreenDisplay: false,
        aspectRatio: 1,
        videoFit: fit,
      ),
    ),
  ),
);

void _expectRect(Rect actual, Rect expected) {
  for (final (a, e) in [
    (actual.left, expected.left),
    (actual.top, expected.top),
    (actual.right, expected.right),
    (actual.bottom, expected.bottom),
  ]) {
    expect(a, closeTo(e, 0.01), reason: '$actual != $expected');
  }
}

/// La sonda e' impaginata alla taglia che mostra: nessuna scala.
void _expectUnscaled(WidgetTester tester) {
  final size = tester.getSize(find.byKey(_probe));
  final shown = tester.getRect(find.byKey(_probe)).size;
  expect(size.width, closeTo(shown.width, 0.01));
  expect(size.height, closeTo(shown.height, 0.01));
}

/// 16:9 inscritto nel box, centrato.
final _landscapeContained = Rect.fromCenter(
  center: _box.center,
  width: 300,
  height: 300 * 9 / 16,
);

void main() {
  setUp(stubVolumeControllerChannel);

  testWidgets('cover riempie il box e taglia quello che esce', (tester) async {
    await tester.pumpWidget(
      _viewport(_controllerWithProbe(const Size(640, 360)), BoxFit.cover),
    );

    _expectRect(
      tester.getRect(find.byKey(_probe)),
      Rect.fromCenter(center: _box.center, width: 300 * 16 / 9, height: 300),
    );
    _expectUnscaled(tester);
    final clip = find.ancestor(
      of: find.byKey(_probe),
      matching: find.byType(ClipRect),
    );
    _expectRect(tester.getRect(clip.first), _box);
  });

  testWidgets('contain sta dentro il box, centrato, con le sue proporzioni', (
    tester,
  ) async {
    await tester.pumpWidget(
      _viewport(_controllerWithProbe(const Size(640, 360)), BoxFit.contain),
    );

    _expectRect(tester.getRect(find.byKey(_probe)), _landscapeContained);
    _expectUnscaled(tester);
  });

  testWidgets('fill ha la taglia del box', (tester) async {
    await tester.pumpWidget(
      _viewport(_controllerWithProbe(const Size(640, 360)), BoxFit.fill),
    );

    _expectRect(tester.getRect(find.byKey(_probe)), _box);
    _expectUnscaled(tester);
  });

  testWidgets('none tiene la taglia del video, centrata', (tester) async {
    await tester.pumpWidget(
      _viewport(_controllerWithProbe(const Size(200, 100)), BoxFit.none),
    );

    _expectRect(
      tester.getRect(find.byKey(_probe)),
      Rect.fromCenter(center: _box.center, width: 200, height: 100),
    );
    _expectUnscaled(tester);
  });

  testWidgets('quando la size del controller cambia il fit si ricalcola', (
    tester,
  ) async {
    final controller = _controllerWithProbe(const Size(640, 360));
    await tester.pumpWidget(_viewport(controller, BoxFit.contain));

    controller.videoSize = const Size(360, 640);
    await tester.pump();

    _expectRect(
      tester.getRect(find.byKey(_probe)),
      Rect.fromCenter(center: _box.center, width: 300 * 9 / 16, height: 300),
    );
  });

  testWidgets('size zero usa 16:9 senza eccezioni', (tester) async {
    await tester.pumpWidget(
      _viewport(_controllerWithProbe(Size.zero), BoxFit.contain),
    );

    expect(tester.takeException(), isNull);
    _expectRect(tester.getRect(find.byKey(_probe)), _landscapeContained);
  });

  testWidgets('un box 0x0 da\' al player taglia zero senza eccezioni', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox.shrink(
            child: OmniVideoPlayerViewport(
              controller: _controllerWithProbe(const Size(640, 360)),
              isFullScreenDisplay: false,
              aspectRatio: 1,
              videoFit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byKey(_probe)), Size.zero);
  });

  testWidgets('a schermo intero vale il videoFit della configurazione', (
    tester,
  ) async {
    await _pumpFullscreen(
      tester,
      _controllerWithProbe(const Size(640, 360)),
      _config(BoxFit.cover, fullScreenRatio: 1),
    );

    // Box quadrato a tutto schermo (600x600), video 16:9 in cover: alto 600.
    _expectRect(
      tester.getRect(find.byKey(_probe)),
      Rect.fromCenter(
        center: const Offset(400, 300),
        width: 600 * 16 / 9,
        height: 600,
      ),
    );

    await _unmountFullscreen(tester);
  });

  testWidgets('a schermo intero il box segue la size che arriva dopo', (
    tester,
  ) async {
    final controller = _controllerWithProbe(const Size(640, 360));
    await _pumpFullscreen(tester, controller, _config(BoxFit.contain));

    controller.videoSize = const Size(360, 640);
    await tester.pump();

    _expectRect(
      tester.getRect(find.byType(OmniVideoPlayerViewport)),
      Rect.fromCenter(
        center: const Offset(400, 300),
        width: 600 * 9 / 16,
        height: 600,
      ),
    );

    await _unmountFullscreen(tester);
  });

  testWidgets('a schermo intero un tick di sola posizione non ricostruisce', (
    tester,
  ) async {
    var builds = 0;
    final controller = _controllerWithProbe(const Size(640, 360));
    await _pumpFullscreen(
      tester,
      controller,
      _config(
        BoxFit.contain,
        fullscreenWrapper: (_, child) {
          builds++;
          return child;
        },
      ),
    );
    final before = builds;

    controller.videoSize = const Size(640, 360);
    await tester.pump();

    expect(builds, before);

    await _unmountFullscreen(tester);
  });

  testWidgets('video verticale col rapporto custom a schermo intero', (
    tester,
  ) async {
    await _pumpFullscreen(
      tester,
      _controllerWithProbe(const Size(360, 640)),
      _config(BoxFit.contain, fullScreenRatio: 16 / 9),
    );

    _expectRect(
      tester.getRect(find.byType(OmniVideoPlayerViewport)),
      Rect.fromCenter(
        center: const Offset(400, 300),
        width: 800,
        height: 450,
      ),
    );

    await _unmountFullscreen(tester);
  });

  testWidgets('in vista normale l\'overlay usa il rapporto custom normale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final configuration = _config(BoxFit.contain, fullScreenRatio: 16 / 9);

    await tester.pumpWidget(
      MaterialApp(
        home: OmniVideoPlayerTheme(
          data: OmniVideoPlayerThemeData(),
          child: Material(
            child: OmniVideoPlayerControlsOverlay(
              controller: _controllerWithProbe(const Size(640, 360)),
              configuration: configuration.copyWith(
                playerUIVisibilityOptions: configuration
                    .playerUIVisibilityOptions
                    .copyWith(customAspectRatioNormal: 9 / 16),
              ),
              callbacks: const VideoPlayerCallbacks(),
              child: const SizedBox.expand(key: _probe),
            ),
          ),
        ),
      ),
    );

    _expectRect(
      tester.getRect(find.byKey(_probe)),
      Rect.fromCenter(
        center: const Offset(400, 300),
        width: 600 * 9 / 16,
        height: 600,
      ),
    );

    await _unmountFullscreen(tester);
  });
}

/// Schermo intero su uno schermo 800x600.
Future<void> _pumpFullscreen(
  WidgetTester tester,
  _StillController controller,
  VideoPlayerConfiguration configuration,
) async {
  tester.view.physicalSize = const Size(800, 600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  controller.isFullScreen = true;

  await tester.pumpWidget(
    MaterialApp(
      home: OmniVideoPlayerTheme(
        data: OmniVideoPlayerThemeData(),
        child: OmniVideoPlayerFullscreen(
          controller: controller,
          configuration: configuration,
          callbacks: const VideoPlayerCallbacks(),
        ),
      ),
    ),
  );
}

Future<void> _unmountFullscreen(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 4));
}
