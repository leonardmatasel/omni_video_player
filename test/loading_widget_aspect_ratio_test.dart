import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/omni_video_player_initializer.dart';
import 'package:omni_video_player/src/_core/omni_video_player_thumbnail.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'support/fake_video_player_platform.dart';
import 'support/platform_channel_stubs.dart';

const _loaderKey = Key('loader');

/// Un loader a tutto campo, come l'anteprima sfocata di una GIF.
final _loader = SizedBox.expand(
  child: Container(key: _loaderKey, color: const Color(0xFF00FF00)),
);

/// Thumbnail risolta in modo sincrono: nessuna decodifica da aspettare.
class _SyncImage extends ImageProvider<_SyncImage> {
  _SyncImage(this.image);

  final ui.Image image;

  @override
  Future<_SyncImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_SyncImage key, ImageDecoderCallback decode) =>
      OneFrameImageStreamCompleter(
        SynchronousFuture(ImageInfo(image: image.clone())),
      );
}

Widget _player({
  double? customAspectRatioNormal,
  ImageProvider? thumbnail,
  Widget? loadingWidget,
  bool inList = false,
  Key? key,
  String video = 'portrait.webm',
}) {
  final player = OmniVideoPlayerInitializer(
    key: key,
    configuration: VideoPlayerConfiguration(
      videoSourceConfiguration: VideoSourceConfiguration.network(
        videoUrl: Uri.parse('https://example.invalid/$video'),
      ),
      customPlayerWidgets: CustomPlayerWidgets(
        loadingWidget: loadingWidget ?? _loader,
        thumbnail: thumbnail,
      ),
      playerUIVisibilityOptions: PlayerUIVisibilityOptions(
        customAspectRatioNormal: customAspectRatioNormal,
      ),
    ),
    callbacks: const VideoPlayerCallbacks(),
    buildPlayer: (_, _, _) => const SizedBox.shrink(),
  );
  return Directionality(
    textDirection: TextDirection.ltr,
    child: OmniVideoPlayerTheme(
      data: OmniVideoPlayerThemeData(),
      child: Center(
        child: SizedBox(
          width: 200,
          height: 400,
          // Una ListView da' al player un'altezza illimitata.
          child: inList ? ListView(children: [player]) : player,
        ),
      ),
    ),
  );
}

/// L'init arma timer che sopravvivono al test: il watchdog di prontezza e il
/// timeout di 30s di `initialize`. Si smonta l'albero e si lasciano scadere,
/// altrimenti il framework segnala un timer pendente al posto del vero esito.
Future<void> _drainReadinessWatchdog(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 31));
}

void main() {
  setUp(stubVolumeControllerChannel);

  group('loading widget:', () {
    testWidgets(
      'fills the player box while the aspect ratio is still unknown',
      (tester) async {
        await tester.pumpWidget(_player());

        // Rapporto ignoto: riempie il box, non il 16/9 di ripiego (200x112.5).
        expect(tester.getSize(find.byKey(_loaderKey)), const Size(200, 400));

        await _drainReadinessWatchdog(tester);
      },
    );

    testWidgets('is boxed to the ratio once that ratio is known', (
      tester,
    ) async {
      await tester.pumpWidget(_player(customAspectRatioNormal: 1));

      expect(tester.getSize(find.byKey(_loaderKey)), const Size(200, 200));

      await _drainReadinessWatchdog(tester);
    });
  });

  testWidgets(
    'thumbnail: keeps its own proportions while the video ratio is unknown',
    (tester) async {
      final portrait = (await tester.runAsync(
        () => createTestImage(width: 100, height: 150),
      ))!;
      await tester.pumpWidget(_player(thumbnail: _SyncImage(portrait)));
      await tester.pump();

      // Tiene il suo 2:3: non riempie il box (200x400), non il 16/9 di ripiego (200x112.5).
      expect(
        tester.getSize(find.byType(VideoPlayerThumbnail)),
        const Size(200, 300),
      );

      await _drainReadinessWatchdog(tester);
    },
  );
  group('unbounded height:', () {
    const smallLoader = SizedBox.square(key: _loaderKey, dimension: 20);

    testWidgets('loader centred on the thumbnail', (tester) async {
      final wide = (await tester.runAsync(
        () => createTestImage(width: 160, height: 90),
      ))!;
      await tester.pumpWidget(
        _player(
          thumbnail: _SyncImage(wide),
          loadingWidget: smallLoader,
          inList: true,
        ),
      );
      await tester.pump();

      expect(
        tester.getCenter(find.byKey(_loaderKey)),
        tester.getCenter(find.byType(VideoPlayerThumbnail)),
      );

      await _drainReadinessWatchdog(tester);
    });

    testWidgets('an unknown ratio holds a 16:9 box, loader centred', (
      tester,
    ) async {
      await tester.pumpWidget(
        _player(loadingWidget: smallLoader, inList: true),
      );

      final player = find.byType(OmniVideoPlayerInitializer);
      expect(tester.getSize(player), const Size(200, 112.5));
      expect(
        tester.getCenter(find.byKey(_loaderKey)),
        tester.getCenter(player),
      );

      await _drainReadinessWatchdog(tester);
    });

    testWidgets('a custom ratio keeps its own box', (tester) async {
      await tester.pumpWidget(
        _player(
          customAspectRatioNormal: 1,
          loadingWidget: smallLoader,
          inList: true,
        ),
      );

      expect(
        tester.getSize(find.byType(OmniVideoPlayerInitializer)),
        const Size(200, 200),
      );

      await _drainReadinessWatchdog(tester);
    });
  });

  group('released off view:', () {
    late VideoPlayerPlatform original;
    late FakeVideoPlayerPlatform platform;
    final key = GlobalKey<OmniVideoPlayerInitializerState>();
    final player = find.byType(OmniVideoPlayerInitializer);
    const portraitBox = Size(200, 200 * 640 / 360);

    setUp(() {
      original = VideoPlayerPlatform.instance;
      platform = FakeVideoPlayerPlatform(size: const Size(360, 640));
      VideoPlayerPlatform.instance = platform;
    });

    tearDown(() {
      platform.close();
      VideoPlayerPlatform.instance = original;
    });

    /// A portrait video, ready in a ListView, then scrolled away.
    Future<void> releasePortrait(
      WidgetTester tester, {
      double? customAspectRatioNormal,
    }) async {
      await tester.pumpWidget(
        _player(
          key: key,
          video: 'portrait.mp4',
          inList: true,
          customAspectRatioNormal: customAspectRatioNormal,
        ),
      );
      await tester.pump();
      platform.holdInitialized = true;
      key.currentState!.releaseForOffView();
      await tester.pump();
    }

    testWidgets('the placeholder keeps the real ratio', (tester) async {
      await releasePortrait(tester);

      // Senza la taglia ricordata il box sarebbe il 16:9 stimato (200x112.5).
      expect(tester.getSize(player), portraitBox);

      await _drainReadinessWatchdog(tester);
    });

    testWidgets('a custom ratio boxes it, the video size is remembered', (
      tester,
    ) async {
      await releasePortrait(tester, customAspectRatioNormal: 1);

      expect(tester.getSize(player), const Size(200, 200));
      // Senza rapporto custom il box torna alla taglia ricordata.
      await tester.pumpWidget(
        _player(key: key, video: 'portrait.mp4', inList: true),
      );
      expect(tester.getSize(player), portraitBox);

      await _drainReadinessWatchdog(tester);
    });

    testWidgets('back on screen, the box holds until the player is ready', (
      tester,
    ) async {
      await releasePortrait(tester);
      // Il VisibilityDetector vede il placeholder e reinizializza.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(platform.calls.where((c) => c == 'create'), hasLength(2));
      expect(tester.getSize(player), portraitBox);

      await _drainReadinessWatchdog(tester);
    });

    testWidgets('a new source forgets it', (tester) async {
      await releasePortrait(tester);
      key.currentState!.refresh(
        videoSourceConfiguration: VideoSourceConfiguration.network(
          videoUrl: Uri.parse('https://example.invalid/other.mp4'),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.getSize(player), const Size(200, 112.5));

      await _drainReadinessWatchdog(tester);
    });
  });
}
