import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_webm/webm_webview_event_handler.dart';
import 'package:video_player/video_player.dart' show DurationRange;

class WebmVideoWebViewController extends OmniPlaybackController {
  late final VideoPlayerCallbacks callbacks;
  late final VideoPlayerConfiguration options;
  late final WebmVideoWebViewEventHandler _eventHandler;

  // URL del video raw (webm/mp4)
  final String videoUrlStr;

  @override
  final ValueNotifier<Widget?> sharedPlayerNotifier = ValueNotifier(null);

  // STATES
  bool _hasError = false;
  bool _isReady = false;
  bool _isPlaying = false;
  bool _hasStarted = false;
  bool _isLive = false;
  bool _isSeeking = false;
  bool _isBuffering = false;
  bool _isFullyVisible = false;

  bool? wasPlayingBeforeGoOnFullScreen;
  double _volume = 100;
  double _previousVolume = 100;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  OmniVideoQuality? _currentVideoQuality;
  List<OmniVideoQuality>? _availableVideoQualities;
  bool _isFullScreen = false;
  late final GlobalPlaybackController? _globalController;
  GlobalKey<OmniVideoPlayerInitializerState> globalKeyPlayer;

  InAppWebViewController? _webViewController;
  InAppWebViewController? get webViewController => _webViewController;

  @override
  final Size size;

  final bool isFile;

  WebmVideoWebViewController({
    required Duration duration, // Spesso zero all'inizio per i file web
    required bool isLive,
    required this.size,
    required this.callbacks,
    required this.options,
    required this.videoUrlStr,
    required GlobalPlaybackController? globalController,
    required this.globalKeyPlayer,
    required this.isFile,
  }) {
    _duration = duration;
    _isLive = isLive;
    _globalController = globalController;
    _globalController?.registerController(this);
    _eventHandler = WebmVideoWebViewEventHandler(this, options, callbacks);
  }

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
    _initJavaScriptHandlers();
  }

  String get playerId => 'WebmVideo$hashCode';

  void _initJavaScriptHandlers() {
    // Handler quando il video è caricato e pronto
    webViewController?.addJavaScriptHandler(
      handlerName: 'Ready',
      callback: (args) {
        _eventHandler.handleReady(args.isNotEmpty ? args.first : null);
      },
    );

    // Cambio Stato (Play, Pause, Buffering)
    webViewController?.addJavaScriptHandler(
      handlerName: 'StateChange',
      callback: (args) {
        return _eventHandler.handleStateChange(args.first);
      },
    );

    // Errori
    webViewController?.addJavaScriptHandler(
      handlerName: 'PlayerError',
      callback: (args) => _eventHandler.handleError(args.first),
    );

    // Progresso Temporale
    webViewController?.addJavaScriptHandler(
      handlerName: 'PlaybackProgress',
      callback: (args) {
        _eventHandler.handlePlaybackProgress(args.first);
      },
    );

    webViewController?.addJavaScriptHandler(
      handlerName: 'Seeked',
      callback: (args) {
        _eventHandler.handleSeeked();
      },
    );
  }

  @override
  bool get isDisposed => _isDisposed;

  bool _isDisposed = false;

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _globalController?.unregisterController(this);
    super.dispose();
  }

  // Helper per eseguire JS
  Future<void> _evaluate(String js) async {
    if (_webViewController == null || isDisposed) return;
    try {
      await _webViewController!.evaluateJavascript(source: js);
    } catch (e) {
      debugPrint('Error evaluating JS: $js\n$e');
    }
  }

  // --- Implementazione Metodi OmniPlaybackController ---

  @override
  Map<OmniVideoQuality, Uri>? get videoQualityUrls => null;

  @override
  List<OmniVideoQuality>? get availableVideoQualities =>
      _availableVideoQualities;
  set availableVideoQualities(List<OmniVideoQuality>? value) {
    if (isDisposed) return;
    _availableVideoQualities = value;
    notifyListeners();
  }

  @override
  OmniVideoQuality? get currentVideoQuality => _currentVideoQuality;
  set currentVideoQuality(OmniVideoQuality? value) {
    if (isDisposed) return;
    _currentVideoQuality = value;
    notifyListeners();
  }

  @override
  Future<void> switchQuality(OmniVideoQuality quality) async {
    // WebM solitamente è file singolo, difficile cambiare qualità senza ricaricare URL diverso
    debugPrint("Switch quality not supported for raw web video");
  }

  @override
  bool get isSeeking => _isSeeking;
  @override
  set isSeeking(bool value) {
    if (isDisposed) return;
    _isSeeking = value;
    if (!value) callbacks.onSeekEnd?.call(currentPosition);
    notifyListeners();
  }

  @override
  bool wasPlayingBeforeSeek = false;

  @override
  List<DurationRange> get buffered => [];

  @override
  Duration get currentPosition => _currentPosition;
  set currentPosition(Duration value) {
    if (isDisposed) return;
    if (value > duration && duration != Duration.zero) return;
    _currentPosition = value;
    notifyListeners();
  }

  @override
  Duration get duration => _duration;
  set duration(Duration value) {
    if (isDisposed) return;
    _duration = value;
    notifyListeners();
  }

  @override
  bool get hasError => _hasError;
  set hasError(bool value) {
    if (isDisposed) return;
    _hasError = value;
    notifyListeners();
  }

  @override
  bool get hasStarted => _hasStarted;
  set hasStarted(bool value) {
    if (isDisposed) return;
    _hasStarted = value;
    notifyListeners();
  }

  @override
  bool get isBuffering => _isBuffering;
  set isBuffering(bool value) {
    if (isDisposed) return;
    _isBuffering = value;
    notifyListeners();
  }

  @override
  bool get isFinished =>
      hasStarted == true &&
      (duration == Duration.zero ||
          currentPosition.inSeconds >= (duration.inSeconds - 1));

  @override
  bool get isFullScreen => _isFullScreen;

  @override
  set isFullScreen(bool value) {
    if (isDisposed) return;
    _isFullScreen = value;
    notifyListeners();
  }

  @override
  bool get isLive => _isLive;
  set isLive(bool value) {
    if (isDisposed) return;
    _isLive = value;
    notifyListeners();
  }

  @override
  bool get isPlaying => _isPlaying;
  set isPlaying(bool value) {
    if (isDisposed) return;
    _isPlaying = value;
    notifyListeners();
  }

  @override
  bool get isReady => _isReady;
  set isReady(bool value) {
    if (isDisposed) return;
    _isReady = value;
    notifyListeners();
  }

  @override
  Future<void> pause({bool useGlobalController = true}) async {
    if (isDisposed) return;
    if (useGlobalController && _globalController != null && !isFullScreen) {
      return await _globalController.requestPause();
    } else {
      return _evaluate('pause()');
    }
  }

  @override
  Future<void> play({bool useGlobalController = true}) async {
    if (isDisposed) return;
    _hasStarted = true;
    if (useGlobalController && _globalController != null && !isFullScreen) {
      return await _globalController.requestPlay(this);
    } else {
      return _evaluate('play()');
    }
  }

  @override
  int get rotationCorrection => 0;

  @override
  Future<void> seekTo(
    Duration position, {
    skipHasPlaybackStarted = false,
  }) async {
    if (isDisposed) return;
    if (position <= duration) {
      wasPlayingBeforeSeek = isPlaying;
      if (!skipHasPlaybackStarted) isSeeking = true;
      if (position.inMicroseconds != 0 && !skipHasPlaybackStarted) {
        hasStarted = true;
      }

      // HTML5 usa secondi floating point
      double seconds = position.inMilliseconds / 1000.0;
      await _evaluate('seekTo($seconds)');
      currentPosition = position;
    } else {
      debugPrint('Seek position exceeds duration');
    }
  }

  @override
  Future<void> switchFullScreenMode(
    BuildContext context, {
    required Widget Function(BuildContext p1)? pageBuilder,
    void Function(bool p1)? onToggle,
  }) async {
    if (isFullScreen) {
      Navigator.of(context).pop();
    } else {
      wasPlayingBeforeGoOnFullScreen = isPlaying;
      isFullScreen = true;
      notifyListeners();
      onToggle?.call(true);
      GlobalPlaybackController().wasLastVideoFullscreen = true;

      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => pageBuilder!(context),
          transitionsBuilder: (_, animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );

      isFullScreen = false;
      notifyListeners();
      onToggle?.call(false);
      if (!isFinished) {
        GlobalPlaybackController().wasLastVideoFullscreen = false;
      }
    }
  }

  @override
  Future<void> replay({bool useGlobalController = true}) async {
    if (isDisposed) return;
    await pause(useGlobalController: useGlobalController);
    await seekTo(Duration.zero);
    await play(useGlobalController: useGlobalController);
  }

  @override
  double get volume => _volume;

  @override
  set volume(double value) {
    if (isDisposed) return;
    _evaluate('setVolume($value)');
    _volume = value;
    notifyListeners();
  }

  @override
  void toggleMute() => isMuted ? unMute() : mute();

  @override
  bool get isMuted => _volume == 0;

  @override
  void mute() {
    _previousVolume = _volume;
    volume = 0;
    _evaluate('mute()');
    _globalController?.setCurrentVolume(volume);
  }

  @override
  void unMute() {
    volume = _previousVolume == 0 ? 1 : _previousVolume;
    _evaluate('unMute()');
    _globalController?.setCurrentVolume(volume);
  }

  @override
  String? get videoDataSource => videoUrlStr;

  @override
  String? get videoId => null; // Non c'è ID specifico come su YT

  @override
  VideoSourceType get videoSourceType => VideoSourceType.network;

  @override
  Uri? get videoUrl => Uri.tryParse(videoUrlStr);

  @override
  double get playbackSpeed => _playbackSpeed;

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    if (isDisposed) return;
    if (speed <= 0) return;
    _playbackSpeed = speed;
    _evaluate('setPlaybackRate($speed)');
    notifyListeners();
  }

  @override
  void loadVideoSource(VideoSourceConfiguration videoSourceConfiguration) {
    // Implementa reload se necessario
  }

  @override
  bool get isFullyVisible => _isFullyVisible;
  @override
  set isFullyVisible(bool value) {
    if (isDisposed) return;
    _isFullyVisible = value;
    notifyListeners();
  }

  @override
  File? get file => null;
}
