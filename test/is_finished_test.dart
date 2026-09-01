import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_vimeo/vimeo_controller.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_controller.dart';

VideoPlayerConfiguration _config() => VideoPlayerConfiguration(
  videoSourceConfiguration: VideoSourceConfiguration.network(
    videoUrl: Uri.parse('https://example.com/v.mp4'),
  ),
);

/// Le durate sono quelle misurate con ffprobe sui file reali del report.
const _subSecond = Duration(milliseconds: 966);
const _short = Duration(milliseconds: 1300);
const _awkward = Duration(milliseconds: 1960);

VimeoController _vimeo({required Duration duration}) => VimeoController.create(
  videoId: '123',
  globalController: null,
  initialPosition: Duration.zero,
  initialVolume: 1.0,
  duration: duration,
  size: const Size(640, 360),
  callbacks: const VideoPlayerCallbacks(),
  globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
  options: _config(),
);

YouTubeWebViewController _youtube({
  Duration duration = const Duration(seconds: 1),
  bool isLive = false,
}) => YouTubeWebViewController.fromVideoId(
  videoId: '123',
  duration: duration,
  isLive: isLive,
  size: const Size(640, 360),
  callbacks: const VideoPlayerCallbacks(),
  options: _config(),
  globalController: null,
  globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
);

WebmVideoWebViewController _webm({
  Duration duration = const Duration(seconds: 1),
}) => WebmVideoWebViewController(
  duration: duration,
  isLive: false,
  size: const Size(640, 360),
  callbacks: const VideoPlayerCallbacks(),
  options: _config(),
  videoUrlStr: 'https://example.com/v.webm',
  globalController: null,
  globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
  isFile: false,
);

void main() {
  group('isFinished — tolleranza di default (200ms)', () {
    test('non è finito a metà del video', () {
      final c = _vimeo(duration: _awkward)
        ..hasStarted = true
        ..currentPosition = const Duration(milliseconds: 1000);

      // Prima del fix questo era true su Generic: 1s troncato >= 1s troncato.
      expect(c.isFinished, isFalse);
    });

    test('è finito entro la tolleranza dalla fine', () {
      final c = _vimeo(duration: _awkward)
        ..hasStarted = true
        ..currentPosition = const Duration(milliseconds: 1800);

      expect(c.isFinished, isTrue);
    });

    test('non è finito appena fuori dalla tolleranza', () {
      final c = _vimeo(duration: _awkward)
        ..hasStarted = true
        ..currentPosition = const Duration(milliseconds: 1700);

      expect(c.isFinished, isFalse);
    });

    test('un video sotto il secondo non è finito a posizione zero', () {
      final c = _vimeo(duration: _subSecond)
        ..hasStarted = true
        ..currentPosition = Duration.zero;

      // Il caso peggiore del report: qui un contatore di loop si completava
      // prima che si vedesse un fotogramma.
      expect(c.isFinished, isFalse);
    });

    test('un video sotto il secondo è finito alla sua fine', () {
      final c = _vimeo(duration: _subSecond)
        ..hasStarted = true
        ..currentPosition = const Duration(milliseconds: 900);

      expect(c.isFinished, isTrue);
    });

    test('non è finito se la riproduzione non è iniziata', () {
      final c = _vimeo(duration: _short)..currentPosition = _short;

      expect(c.isFinished, isFalse);
    });

    test('non è finito se la durata non è nota', () {
      final c = _vimeo(duration: Duration.zero)
        ..hasStarted = true
        ..currentPosition = const Duration(seconds: 5);

      expect(c.isFinished, isFalse);
    });
  });

  group('isFinished — la tolleranza non supera un decimo della durata', () {
    test('un clip di 300ms non è finito a metà', () {
      final c = _vimeo(duration: const Duration(milliseconds: 300))
        ..hasStarted = true
        ..currentPosition = const Duration(milliseconds: 150);

      // Soglia 270ms. Senza il taglio a un decimo la tolleranza fissa la
      // metteva a 100ms, dove 150ms risultava già finito.
      expect(c.isFinished, isFalse);
    });

    test('lo stesso clip di 300ms è finito a 290ms', () {
      final c = _vimeo(duration: const Duration(milliseconds: 300))
        ..hasStarted = true
        ..currentPosition = const Duration(milliseconds: 290);

      expect(c.isFinished, isTrue);
    });
  });

  group('isFinished — uno stream live non è mai finito', () {
    test('resta falso anche con la posizione oltre la durata', () {
      final c = _youtube(duration: const Duration(seconds: 100), isLive: true)
        ..hasStarted = true
        ..currentPosition = const Duration(seconds: 100);

      expect(c.isFinished, isFalse);
    });
  });

  group('isFinished — YouTube allarga la tolleranza a un secondo', () {
    test('è finito un secondo prima della fine', () {
      final c = _youtube()..hasStarted = true;

      c.duration = const Duration(seconds: 100); // la strada del duration poll
      c.currentPosition = const Duration(milliseconds: 99000);

      // L'iframe arrotonda la durata e la posizione non raggiunge l'ultimo
      // fotogramma: la tolleranza larga è deliberata, non una svista.
      expect(c.isFinished, isTrue);
    });

    test('non è finito due secondi prima della fine', () {
      final c = _youtube()..hasStarted = true;

      c.duration = const Duration(seconds: 100);
      c.currentPosition = const Duration(seconds: 98);

      expect(c.isFinished, isFalse);
    });
  });

  group('isFinished — YouTube riconosce la durata solo dal duration poll', () {
    test('con il solo placeholder del costruttore non è mai finito', () {
      final c = _youtube()
        ..hasStarted = true
        ..currentPosition = Duration.zero;

      // GitHub #84: il Ready handler chiama play() prima che il poll risolva,
      // quindi hasStarted è true mentre la durata è ancora il segnaposto da 1s.
      // Con la tolleranza di un secondo la soglia diventa zero, e il player
      // risultava finito a posizione zero: pulsante replay al posto di play, e
      // nessun tap capace di far partire la riproduzione.
      expect(c.isFinished, isFalse);
    });

    test('un video da 3 secondi finisce comunque', () {
      final c = _youtube()..hasStarted = true;

      // L'handler memorizza getDuration() - 2, quindi un video reale da 3s
      // misura esattamente un secondo: indistinguibile per valore dal
      // segnaposto, e il motivo per cui la durata nota è un flag e non un
      // confronto.
      c.duration = const Duration(seconds: 1);
      c.currentPosition = const Duration(seconds: 1);

      expect(c.isFinished, isTrue);
    });
  });

  group('isFinished — WebM riconosce la durata solo dai metadati', () {
    test('con il solo placeholder del costruttore non è mai finito', () {
      final c = _webm()
        ..hasStarted = true
        ..currentPosition = const Duration(seconds: 1);

      // Il placeholder è Duration(seconds: 1): indistinguibile per valore da un
      // video reale da un secondo, quindi la durata si considera nota solo
      // quando arriva dal lato JS.
      expect(c.isFinished, isFalse);
    });

    test('dopo la durata dai metadati un video sotto il secondo finisce', () {
      final c = _webm()..hasStarted = true;

      c.duration = _subSecond; // è la strada che percorre l'evento JS
      c.currentPosition = const Duration(milliseconds: 900);

      // Prima del fix: duration > 1s era falso, quindi il video da 0.966s non
      // risultava mai finito su iOS.
      expect(c.isFinished, isTrue);
    });

    test('una durata dai metadati identica al placeholder conta come nota', () {
      final c = _webm()..hasStarted = true;

      c.duration = const Duration(seconds: 1);
      c.currentPosition = const Duration(milliseconds: 950);

      expect(c.isFinished, isTrue);
    });
  });
}
