import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/omni_video_player_fullscreen.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_viewport.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';
import 'package:omni_video_player/src/widgets/bottom_control_bar/gradient_bottom_control_bar.dart';

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

Widget _fullscreenPage(
  _StillController controller, [
  PlayerUIVisibilityOptions? options,
]) => OmniVideoPlayerTheme(
  data: OmniVideoPlayerThemeData(),
  child: OmniVideoPlayerFullscreen(
    controller: controller,
    configuration: options == null
        ? _config
        : _config.copyWith(playerUIVisibilityOptions: options),
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
      videoFit: BoxFit.contain,
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

  testWidgets('il fullscreen si vede sopra una OverlayEntry della app, '
      'col player in pagina', (tester) async {
    final tapped = <String>[];
    final controller = _StillController();
    late BuildContext playerContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            playerContext = context;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Overlay.of(context, rootOverlay: true).insert(
                OverlayEntry(
                  builder: (_) => GestureDetector(
                    onTap: () => tapped.add('host-entry'),
                    child: Container(color: const Color(0x88000000)),
                  ),
                ),
              );
            });

            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pump();

    // Qui il player sta in una route: il fullscreen va issato lo stesso, o la
    // entry della app gli resta sopra.
    controller.switchFullScreenMode(
      playerContext,
      pageBuilder: (_) => _fullscreenPage(controller),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(tester.getCenter(find.byType(MaterialApp)));
    await tester.pump();

    expect(tapped, isEmpty);
    expect(find.byType(OmniVideoPlayerFullscreen), findsOneWidget);

    // Chiudo e lascio scadere il timer dei controlli, o il test si lamenta.
    Navigator.of(playerContext).pop();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  for (final inOverlay in [false, true]) {
    final where = inOverlay ? 'in una OverlayEntry' : 'in una pagina';
    testWidgets('il player condiviso passa al fullscreen senza rimontarsi, '
        '$where', (tester) async {
      final controller = _StillController();
      final playerKey = GlobalKey();
      controller.sharedPlayerNotifier.value = _Probe(key: playerKey);
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

  group('la crescita', () {
    const inlineRect = Rect.fromLTWH(40, 100, 320, 180);
    // Video 16:9 a schermo intero su 800x600, come oggi.
    const fullRect = Rect.fromLTWH(0, 75, 800, 450);

    final fullscreen = find.byType(OmniVideoPlayerFullscreen);
    final controls = find.descendant(
      of: fullscreen,
      matching: find.byType(GradientBottomControlBar),
    );

    /// Pagina ospite spinta sopra una radice, col player inline a [at], nella
    /// pagina o in una OverlayEntry della radice: un pop di troppo toglierebbe
    /// la pagina. Torna il player condiviso e il contesto dei controlli inline.
    Future<(GlobalKey, BuildContext)> pumpHost(
      WidgetTester tester,
      _StillController controller, {
      Offset at = const Offset(40, 100),
      bool inOverlayEntry = false,
    }) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final playerKey = GlobalKey();
      controller.sharedPlayerNotifier.value = _Probe(key: playerKey);
      final navigator = GlobalKey<NavigatorState>();
      late BuildContext buttonContext;

      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const Text('radice')),
      );
      final player = Positioned(
        left: at.dx,
        top: at.dy,
        width: inlineRect.width,
        height: inlineRect.height,
        child: Material(
          child: OmniVideoPlayerControlsOverlay(
            controller: controller,
            configuration: _config,
            callbacks: const VideoPlayerCallbacks(),
            child: Builder(
              builder: (ctx) {
                buttonContext = ctx;
                return OmniVideoPlayerViewport(
                  controller: controller,
                  isFullScreenDisplay: false,
                  aspectRatio: 16 / 9,
                  videoFit: BoxFit.contain,
                );
              },
            ),
          ),
        ),
      );
      Widget themed(Widget child) =>
          OmniVideoPlayerTheme(data: OmniVideoPlayerThemeData(), child: child);

      navigator.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => themed(
            Material(
              child: Stack(
                children: [const Text('ospite'), if (!inOverlayEntry) player],
              ),
            ),
          ),
        ),
      );
      if (inOverlayEntry) {
        navigator.currentState!.overlay!.insert(
          OverlayEntry(builder: (_) => themed(Stack(children: [player]))),
        );
      }
      await tester.pumpAndSettle();
      return (playerKey, buttonContext);
    }

    /// maybePop risponde in un microtask: l'uscita ticca dal frame dopo.
    Future<void> startExit(WidgetTester tester) async {
      await tester.pump();
      await tester.pump();
    }

    Future<void> settle(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    }

    void expectRect(Rect actual, Rect expected) =>
        expect(actual, rectMoreOrLessEquals(expected, epsilon: 0.5));

    testWidgets('il video cresce dal posto inline, i controlli a crescita '
        'finita', (tester) async {
      final controller = _StillController();
      final (playerKey, buttonContext) = await pumpHost(tester, controller);
      expectRect(tester.getRect(find.byKey(playerKey)), inlineRect);

      controller.switchFullScreenMode(
        buttonContext,
        pageBuilder: (_) => _fullscreenPage(controller),
      );
      await tester.pump();

      expectRect(tester.getRect(find.byKey(playerKey)), inlineRect);
      expect(controls, findsNothing);

      await tester.pump(const Duration(milliseconds: 150));
      final halfway = tester.getRect(find.byKey(playerKey));
      expect(halfway.width, greaterThan(inlineRect.width));
      expect(halfway.width, lessThan(fullRect.width));
      expect(controls, findsNothing);

      await tester.pump(const Duration(milliseconds: 150));
      expectRect(tester.getRect(find.byKey(playerKey)), fullRect);
      // La rotta si dice completa al tick dopo i 300 ms.
      await tester.pumpAndSettle();
      expect(controls, findsOneWidget);
      expect(_Probe.mounts, 1);

      Navigator.of(buttonContext).maybePop();
      await settle(tester);
    });

    testWidgets("in uscita la pagina resta finche' il video non e' tornato, "
        'e un secondo pop non tocca la pagina ospite', (tester) async {
      final controller = _StillController();
      final (playerKey, buttonContext) = await pumpHost(tester, controller);
      var opened = true;
      controller
          .switchFullScreenMode(
            buttonContext,
            pageBuilder: (_) => _fullscreenPage(controller),
          )
          .then((_) => opened = false);
      await tester.pumpAndSettle();

      // Pulsante d'uscita dei controlli a schermo intero.
      controller.switchFullScreenMode(
        tester.element(controls),
        pageBuilder: null,
      );
      await startExit(tester);
      await tester.pump(const Duration(milliseconds: 150));

      expect(fullscreen, findsOneWidget);
      expect(
        find.descendant(of: fullscreen, matching: find.byKey(playerKey)),
        findsOneWidget,
      );
      expect(controls, findsNothing);
      expect(controller.isFullScreen, isTrue);
      expect(opened, isTrue);
      final halfway = tester.getRect(find.byKey(playerKey));
      expect(halfway.width, lessThan(fullRect.width));
      expect(halfway.width, greaterThan(inlineRect.width));

      // Secondo tap, tasto indietro e swipe durante l'uscita.
      controller.switchFullScreenMode(
        tester.element(fullscreen),
        pageBuilder: null,
      );
      await tester.binding.handlePopRoute();
      await tester.dragFrom(const Offset(400, 300), const Offset(0, 200));
      await tester.pump(const Duration(milliseconds: 50));
      expect(
        tester.getRect(find.byKey(playerKey)).width,
        lessThan(halfway.width),
        reason: "l'uscita e' ripartita",
      );

      await tester.pumpAndSettle();
      expect(fullscreen, findsNothing);
      expect(opened, isFalse);
      expect(controller.isFullScreen, isFalse);
      expectRect(tester.getRect(find.byKey(playerKey)), inlineRect);
      expect(_Probe.mounts, 1);
      expect(find.text('ospite'), findsOneWidget);

      await settle(tester);
      expect(find.text('ospite'), findsOneWidget);
    });

    testWidgets('col player in una OverlayEntry della app il video cresce '
        "e torna al suo posto", (tester) async {
      final controller = _StillController();
      final (playerKey, buttonContext) = await pumpHost(
        tester,
        controller,
        inOverlayEntry: true,
      );

      controller.switchFullScreenMode(
        buttonContext,
        pageBuilder: (_) => _fullscreenPage(controller),
      );
      await tester.pump();
      expectRect(tester.getRect(find.byKey(playerKey)), inlineRect);

      await tester.pumpAndSettle();
      expectRect(tester.getRect(find.byKey(playerKey)), fullRect);

      Navigator.of(buttonContext).maybePop();
      await startExit(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expect(fullscreen, findsOneWidget);

      await settle(tester);
      expect(fullscreen, findsNothing);
      expectRect(tester.getRect(find.byKey(playerKey)), inlineRect);
      expect(_Probe.mounts, 1);
      expect(find.text('ospite'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('col player fuori dallo schermo entrata e uscita sfumano', (
      tester,
    ) async {
      final controller = _StillController();
      final (playerKey, buttonContext) = await pumpHost(
        tester,
        controller,
        at: const Offset(-1000, 100),
      );

      controller.switchFullScreenMode(
        buttonContext,
        pageBuilder: (_) => _fullscreenPage(controller),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expectRect(
        tester.getRect(fullscreen),
        Offset.zero & const Size(800, 600),
      );
      final fade = find.ancestor(
        of: fullscreen,
        matching: find.byType(Opacity),
      );
      expect(
        tester.widget<Opacity>(fade.first).opacity,
        inExclusiveRange(0, 1),
      );
      expect(tester.takeException(), isNull);

      await tester.pumpAndSettle();
      expectRect(tester.getRect(find.byKey(playerKey)), fullRect);

      Navigator.of(buttonContext).maybePop();
      await startExit(tester);
      await tester.pump(const Duration(milliseconds: 150));
      expectRect(
        tester.getRect(fullscreen),
        Offset.zero & const Size(800, 600),
      );
      expect(
        tester.widget<Opacity>(fade.first).opacity,
        inExclusiveRange(0, 1),
      );

      await settle(tester);
      expect(fullscreen, findsNothing);
      expect(tester.takeException(), isNull);
      expect(_Probe.mounts, 1);
    });

    group('rotazione e barre dopo la crescita', () {
      const orientations = 'SystemChrome.setPreferredOrientations';
      late List<String> system;

      /// Le chiamate di orientamento e barre, in ordine, come arrivano al canale.
      void recordSystem(WidgetTester tester) {
        system = [];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == orientations ||
                call.method.startsWith('SystemChrome.setEnabledSystemUI')) {
              system.add('${call.method} ${call.arguments}');
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
      }

      const hideBars =
          'SystemChrome.setEnabledSystemUIMode SystemUiMode.immersiveSticky';
      const showBars =
          'SystemChrome.setEnabledSystemUIOverlays '
          '[SystemUiOverlay.top, SystemUiOverlay.bottom]';
      const portrait =
          '$orientations '
          '[DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]';
      const allOrientations =
          '$orientations [DeviceOrientation.portraitUp, '
          'DeviceOrientation.landscapeLeft, DeviceOrientation.portraitDown, '
          'DeviceOrientation.landscapeRight]';

      for (final turns in [true, false]) {
        testWidgets(
          'in entrata barre e orientamento a crescita finita, i controlli '
          '${turns ? 'appena lo schermo gira' : 'dopo 500 ms senza rotazione'}',
          (tester) async {
            final controller = _StillController();
            final (playerKey, buttonContext) = await pumpHost(
              tester,
              controller,
            );
            recordSystem(tester);

            controller.switchFullScreenMode(
              buttonContext,
              pageBuilder: (_) => _fullscreenPage(
                controller,
                const PlayerUIVisibilityOptions(
                  showScrubbingThumbnailPreview: false,
                  fullscreenOrientation: Orientation.portrait,
                ),
              ),
            );
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 150));
            expect(system, isEmpty);
            await tester.pump(const Duration(milliseconds: 150));
            expect(system, isEmpty);
            // La rotta si dice completa al frame dopo i 300 ms.
            await tester.pump(const Duration(milliseconds: 16));
            expectRect(tester.getRect(find.byKey(playerKey)), fullRect);
            expect(system, [hideBars, portrait]);
            expect(controls, findsNothing);

            if (turns) {
              tester.view.physicalSize = const Size(600, 800);
              await tester.pump();
              await tester.pump();
              expect(controls, findsOneWidget);
            } else {
              await tester.pump(const Duration(milliseconds: 450));
              expect(controls, findsNothing);
              await tester.pump(const Duration(milliseconds: 50));
              await tester.pump();
              expect(controls, findsOneWidget);
            }
            expect(system, [hideBars, portrait]);

            Navigator.of(buttonContext).maybePop();
            await settle(tester);
          },
        );
      }

      testWidgets("in uscita barre e orientamento tornano prima che il video "
          'rimpicciolisca, con una sola richiesta di orientamento', (
        tester,
      ) async {
        final controller = _StillController();
        final (playerKey, buttonContext) = await pumpHost(tester, controller);
        recordSystem(tester);
        var opened = true;
        controller
            .switchFullScreenMode(
              buttonContext,
              pageBuilder: (_) => _fullscreenPage(
                controller,
                const PlayerUIVisibilityOptions(
                  showScrubbingThumbnailPreview: false,
                  restoreOrientationsAfterFullscreen: [
                    DeviceOrientation.portraitUp,
                  ],
                ),
              ),
            )
            .then((_) => opened = false);
        await tester.pumpAndSettle();
        expect(controls, findsOneWidget);
        system.clear();

        Navigator.of(buttonContext).maybePop();
        await startExit(tester);
        expect(controls, findsNothing);
        expect(system, [
          showBars,
          '$orientations [DeviceOrientation.portraitUp]',
        ]);

        // Lo schermo non ha ancora girato: il video resta a tutto schermo.
        await tester.pump(const Duration(milliseconds: 150));
        expectRect(tester.getRect(find.byKey(playerKey)), fullRect);

        tester.view.physicalSize = const Size(600, 800);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));
        expect(fullscreen, findsOneWidget);
        expect(
          tester.getRect(find.byKey(playerKey)).width,
          lessThan(600),
          reason: 'la crescita all indietro non e partita',
        );

        await settle(tester);
        expect(fullscreen, findsNothing);
        expect(opened, isFalse);
        expect(system.where((c) => c.startsWith(orientations)), hasLength(1));
        expectRect(tester.getRect(find.byKey(playerKey)), inlineRect);
      });

      testWidgets('senza restoreOrientationsAfterFullscreen tornano tutti gli '
          'orientamenti, senza attesa', (tester) async {
        final controller = _StillController();
        final (playerKey, buttonContext) = await pumpHost(tester, controller);
        recordSystem(tester);
        controller.switchFullScreenMode(
          buttonContext,
          pageBuilder: (_) => _fullscreenPage(controller),
        );
        await tester.pumpAndSettle();
        system.clear();

        Navigator.of(buttonContext).maybePop();
        await startExit(tester);
        await tester.pump(const Duration(milliseconds: 150));
        expect(system, [showBars, allOrientations]);
        expect(
          tester.getRect(find.byKey(playerKey)).width,
          lessThan(fullRect.width),
        );

        await settle(tester);
        expect(system, [showBars, allOrientations]);
      });

      testWidgets('con enableOrientationLock spento si ripristina solo '
          "all'uscita", (tester) async {
        final controller = _StillController();
        final (_, buttonContext) = await pumpHost(tester, controller);
        recordSystem(tester);
        controller.switchFullScreenMode(
          buttonContext,
          pageBuilder: (_) => _fullscreenPage(
            controller,
            const PlayerUIVisibilityOptions(
              showScrubbingThumbnailPreview: false,
              enableOrientationLock: false,
              fullscreenOrientation: Orientation.portrait,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump();
        expect(controls, findsOneWidget, reason: 'niente attesa');
        expect(system, [hideBars]);

        Navigator.of(buttonContext).maybePop();
        await settle(tester);
        expect(system, [hideBars, showBars, allOrientations]);
      });
    });
  });
}
