import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

import 'support/platform_channel_stubs.dart';

/// Un controller reale che registra play e pause invece di parlare con una
/// WebView che nei test non esiste.
///
/// Estende il controller WebM perché è quello con il costruttore più semplice:
/// così i quaranta membri dell'interfaccia arrivano gratis e restano da
/// sovrascrivere solo i due che ci interessa osservare.
class _RecordingController extends WebmVideoWebViewController {
  _RecordingController({required double volume, super.globalController})
    : _volume = volume,
      super(
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
        globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
        isFile: false,
      );

  double _volume;
  final List<String> calls = [];

  @override
  double get volume => _volume;

  @override
  set volume(double value) => _volume = value;

  @override
  bool get isMuted => _volume == 0;

  @override
  Future<void> play({bool useGlobalController = true}) async =>
      calls.add('play');

  @override
  Future<void> pause({bool useGlobalController = true}) async =>
      calls.add('pause');
}

void main() {
  setUp(() async {
    stubVolumeControllerChannel();
    // Il controller globale è un singleton condiviso fra i test del file.
    await GlobalPlaybackController().requestPause();
  });

  test('due player muti riproducono insieme', () async {
    final global = GlobalPlaybackController();
    final first = _RecordingController(volume: 0);
    final second = _RecordingController(volume: 0);

    await global.requestPlay(first);
    await global.requestPlay(second);

    // Il caso del report: il secondo che entra nel viewport metteva in pausa il
    // primo, quindi due GIF non potevano animarsi insieme.
    expect(first.calls, ['play']);
    expect(second.calls, ['play']);
  });

  test('un player muto non diventa il player corrente', () async {
    final global = GlobalPlaybackController();
    final muted = _RecordingController(volume: 0);

    await global.requestPlay(muted);

    expect(global.currentVideoPlaying, isNull);
  });

  test('un player audibile mette in pausa l\'audibile precedente', () async {
    final global = GlobalPlaybackController();
    final first = _RecordingController(volume: 1);
    final second = _RecordingController(volume: 1);

    await global.requestPlay(first);
    await global.requestPlay(second);

    expect(first.calls, ['play', 'pause']);
    expect(second.calls, ['play']);
    expect(global.currentVideoPlaying, same(second));
  });

  test('un player audibile non mette in pausa i muti', () async {
    final global = GlobalPlaybackController();
    final muted = _RecordingController(volume: 0);
    final audible = _RecordingController(volume: 1);

    await global.requestPlay(muted);
    await global.requestPlay(audible);

    expect(muted.calls, ['play']);
  });

  test('avviare la riproduzione non tocca il volume', () async {
    final global = GlobalPlaybackController();
    global.setCurrentVolume(1);
    final silent = _RecordingController(volume: 0);

    await global.requestPlay(silent);

    // Prima del fix `requestPlay` chiamava `unMute()`, rendendo audibile un
    // player creato di proposito muto.
    expect(silent.volume, 0);
  });

  test(
    'smutare un player in riproduzione lo fa entrare nell\'esclusività',
    () async {
      final global = GlobalPlaybackController();
      final audible = _RecordingController(volume: 1);
      final wasMuted = _RecordingController(volume: 0);

      await global.requestPlay(audible);
      await global.requestPlay(wasMuted);

      wasMuted.volume = 1;
      await global.handleVolumeChanged(wasMuted);

      expect(global.currentVideoPlaying, same(wasMuted));
      expect(audible.calls, ['play', 'pause']);
    },
  );

  test('mutare il player corrente lo fa uscire dall\'esclusività', () async {
    final global = GlobalPlaybackController();
    final audible = _RecordingController(volume: 1);

    await global.requestPlay(audible);
    audible.volume = 0;
    await global.handleVolumeChanged(audible);

    expect(global.currentVideoPlaying, isNull);
  });

  test('un cambio di fullscreen ri-valuta il wakelock', () async {
    // Il tap su fullscreen lo gestisce il singolo controller: senza il
    // listener registrato in registerController nessuno ri-valuterebbe.
    // Osservare *quale* decisione prende richiederebbe
    // WakelockPlusPlatformInterface, dipendenza scartata; senza stub
    // `WakelockPlus.enable()` fallisce sul canale e `_syncWakelock` logga,
    // quindi il log è la prova che il predicato è stato ri-eseguito.
    final messages = <String>[];
    final originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) messages.add(message);
    };
    addTearDown(() => debugPrint = originalDebugPrint);

    final global = GlobalPlaybackController();
    final controller = _RecordingController(
      volume: 0,
      globalController: global,
    );
    addTearDown(controller.dispose);

    // In riproduzione ma muto e non fullscreen: non merita il wakelock.
    controller.isPlaying = true;
    await pumpEventQueue();
    messages.clear();

    // Muto ma ora fullscreen: il predicato passa da false a true — un video
    // mutato guardato a schermo intero non deve far spegnere lo schermo.
    controller.isFullScreen = true;
    await pumpEventQueue();

    expect(
      messages.any((m) => m.contains('Failed to update wakelock')),
      isTrue,
      reason: 'nessun tentativo verso WakelockPlus dopo il fullscreen',
    );
  });
}
