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

  /// Failsafe so a dropped `seeked` event can't leave the seek stuck. (B4)
  Timer? _seekFallbackTimer;

  bool? wasPlayingBeforeGoOnFullScreen;
  double _volume = 100;
  double _previousVolume = 100;
  Duration _duration = Duration.zero;
  bool _hasKnownDuration = false;
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
    _seekFallbackTimer?.cancel();
    _globalController?.unregisterController(this);
    super.dispose();
  }

  /// Swallows notifications once disposed, so async tails (e.g. the resume
  /// after [switchFullScreenMode]'s awaited route when a playlist advanced)
  /// can't hit a disposed ChangeNotifier and throw.
  @override
  void notifyListeners() {
    if (_isDisposed) return;
    super.notifyListeners();
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
    if (!value) {
      _seekFallbackTimer?.cancel();
      callbacks.onSeekEnd?.call(currentPosition);
    }
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

  /// Assigning marks the duration as known; the constructor's placeholder
  /// bypasses this by writing `_duration` directly.
  set duration(Duration value) {
    if (isDisposed) return;
    _hasKnownDuration = true;
    if (_duration == value) return;
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

  /// The initializer seeds a one-second placeholder while the metadata is
  /// pending, so the duration counts as known only once the JS side has sent
  /// one — a value-based check would reject a genuinely sub-second video.
  @override
  bool get hasKnownDuration => _hasKnownDuration;

  @override
  bool get isFullScreen => _isFullScreen;
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
    if (useGlobalController && _globalController != null && !isFullScreen) {
      return await _globalController.requestPause();
    } else {
      return _evaluate('pause()');
    }
  }

  @override
  Future<void> play({bool useGlobalController = true}) async {
    _hasStarted = true;
    if (useGlobalController && _globalController != null && !isFullScreen) {
      return await _globalController.requestPlay(this);
    } else {
      return _evaluate('play()');
    }
  }

  @override
  int get rotationCorrection => 0;

  /// WebKit can't seek WebM in a WebView on iOS without freezing the decoder,
  /// so seeking is disabled there (the UI hides the seek bar / skip gestures).
  @override
  bool get supportsSeek => !Platform.isIOS;

  @override
  Future<void> seekTo(
    Duration position, {
    skipHasPlaybackStarted = false,
  }) async {
    // No-op where seeking is unsupported (WebM on iOS): a seek freezes the
    // decoder, so never issue one — belt-and-suspenders with the disabled UI.
    if (!supportsSeek) return;

    // Clamp instead of bailing out (B5): the old `else` branch left [isSeeking]
    // stuck true and the optimistic [currentPosition] could exceed duration.
    if (duration > Duration.zero && position > duration) {
      position = duration;
    }

    wasPlayingBeforeSeek = isPlaying;
    if (!skipHasPlaybackStarted) isSeeking = true;
    if (position.inMicroseconds != 0 && !skipHasPlaybackStarted) {
      hasStarted = true;
    }

    // HTML5 usa secondi floating point
    double seconds = position.inMilliseconds / 1000.0;
    await _evaluate('seekTo($seconds)');
    currentPosition = position;

    // Failsafe: if the 'seeked' event never arrives, complete the seek anyway
    // so controls don't stay frozen. Cancelled by the isSeeking setter. (B4)
    if (isSeeking) {
      _seekFallbackTimer?.cancel();
      _seekFallbackTimer = Timer(const Duration(seconds: 3), () {
        if (isDisposed || !isSeeking) return;
        isSeeking = false;
        if (wasPlayingBeforeSeek && !isFinished) {
          play(useGlobalController: false);
        }
      });
    }
  }

  @override
  Future<void> switchFullScreenMode(
    BuildContext context, {
    required Widget Function(BuildContext p1)? pageBuilder,
    void Function(bool p1)? onToggle,
  }) async {
    if (isFullScreen) {
      isFullScreen = false;
      notifyListeners();
      onToggle?.call(false);
      Navigator.of(context).pop();
    } else {
      wasPlayingBeforeGoOnFullScreen = isPlaying;
      isFullScreen = true;
      notifyListeners();
      onToggle?.call(true);

      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => pageBuilder!(context),
          transitionsBuilder: (_, animation, _, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  Future<void> replay({bool useGlobalController = true}) async {
    // Where seeking is unsupported (WebM on iOS), seekTo(0) is a no-op, so
    // replay by reloading the element from the start ("rebuild everything").
    if (!supportsSeek) {
      await _evaluate('restart()');
      return;
    }
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
    _globalController?.setCurrentVolume(volume, source: this);
  }

  @override
  void unMute() {
    volume = _previousVolume == 0 ? 1 : _previousVolume;
    _evaluate('unMute()');
    _globalController?.setCurrentVolume(volume, source: this);
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
