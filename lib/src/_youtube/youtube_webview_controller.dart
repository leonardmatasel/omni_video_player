// Concrete controller: implements the @Deprecated state getters and may read
// them internally. The deprecations stay only for external consumers, so this
// bridge file opts out of the same-package deprecation diagnostic.
// ignore_for_file: deprecated_member_use_from_same_package
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_youtube/youtube_webview_event_handler.dart';
import 'package:video_player/video_player.dart' show DurationRange;

class YouTubeWebViewController extends OmniPlaybackController {
  late final VideoPlayerCallbacks callbacks;
  late final VideoPlayerConfiguration options;

  @override
  final ValueNotifier<Widget?> sharedPlayerNotifier = ValueNotifier(null);

  late final YouTubeWebViewEventHandler _eventHandler;

  // STATES
  bool _hasError = false;
  bool _isReady = false;
  bool _isPlaying = false;
  bool _hasStarted = false;
  bool _isLive = false;
  bool _isSeeking = false;
  bool _isBuffering = false;
  bool _isFullyVisible = false;
  bool _isLoadedVideo = false;
  bool? wasPlayingBeforeGoOnFullScreen;
  // Entering/leaving fullscreen reparents the WKWebView (Hero flight between
  // the normal and fullscreen viewports), which makes the YouTube iframe emit
  // one or more transient `paused` events. During this short window the event
  // handler resumes those instead of recording them as a user pause.
  Timer? _fullscreenResumeTimer;
  bool _resumeDuringFullscreenTransition = false;
  // Volume is tracked on a normalised 0.0-1.0 scale (the setter converts to
  // YouTube's 0-100 API). A 0-100 initial here would leak into the shared
  // GlobalPlaybackController and break other players (e.g. Vimeo's
  // player.setVolume() which only accepts 0-1).
  double _volume = 1.0;
  double _previousVolume = 1.0;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  OmniVideoQuality? _currentVideoQuality;
  List<OmniVideoQuality>? _availableVideoQualities;
  bool _isFullScreen = false;
  late final String _videoId;
  late final GlobalPlaybackController? _globalController;
  GlobalKey<OmniVideoPlayerInitializerState> globalKeyPlayer;

  InAppWebViewController? _webViewController;
  InAppWebViewController? get webViewController => _webViewController;

  void setWebViewController(InAppWebViewController controller) {
    _webViewController = controller;
    _initJavaScriptHandlers();
  }

  @override
  final Size size;

  YouTubeWebViewController({
    required Duration duration,
    required bool isLive,
    required this.size,
    required this.callbacks,
    required this.options,
    required String videoId,
    required GlobalPlaybackController? globalController,
    required this.globalKeyPlayer,
  }) {
    _duration = duration;
    _isLive = isLive;
    _videoId = videoId;
    _globalController = globalController;
    _globalController?.registerController(this);
    _eventHandler = YouTubeWebViewEventHandler(this, options, callbacks);
  }

  factory YouTubeWebViewController.fromVideoId({
    required String videoId,
    required Duration duration,
    required bool isLive,
    required Size size,
    required VideoPlayerCallbacks callbacks,
    required VideoPlayerConfiguration options,
    required GlobalPlaybackController? globalController,
    required GlobalKey<OmniVideoPlayerInitializerState> globalKeyPlayer,
    bool autoPlay = false,
  }) {
    final controller = YouTubeWebViewController(
      callbacks: callbacks,
      options: options,
      duration: duration,
      isLive: isLive,
      size: size,
      videoId: videoId,
      globalController: globalController,
      globalKeyPlayer: globalKeyPlayer,
    );

    return controller;
  }

  Future<void> loadVideoById({required String videoId}) async {
    debugPrint('[OMNI-DIAG] loadVideoById("$videoId")');
    final loadData = {
      'videoId': videoId,
      'startSeconds': 0,
      'endSeconds': null,
    };
    await webViewController?.evaluateJavascript(
      source: 'loadById(${jsonEncode(loadData)});',
    );
  }

  String get playerId => 'Youtube$hashCode';

  void _initJavaScriptHandlers() {
    webViewController?.addJavaScriptHandler(
      handlerName: 'Ready',
      callback: (_) async {
        debugPrint('[OMNI-DIAG] JS->Ready (isLoadedVideo=$_isLoadedVideo)');
        if (!_isLoadedVideo) {
          await loadVideoById(videoId: videoId!);
          _isLoadedVideo = true;
          play(useGlobalController: false);
        }
      },
    );
    webViewController?.addJavaScriptHandler(
      handlerName: 'StateChange',
      callback: (args) {
        debugPrint('[OMNI-DIAG] JS->StateChange = ${args.first}');
        return _eventHandler.handleStateChange(args.first);
      },
    );
    webViewController?.addJavaScriptHandler(
      handlerName: 'PlayerError',
      callback: (args) {
        debugPrint('[OMNI-DIAG] JS->PlayerError = ${args.first}');
        return _eventHandler.handleError(args.first);
      },
    );
    webViewController?.addJavaScriptHandler(
      handlerName: 'PlaybackProgress',
      callback: (args) {
        _eventHandler.handlePlaybackProgress(args.first);
      },
    );
    webViewController?.addJavaScriptHandler(
      handlerName: 'PlaybackRateChange',
      callback: (args) {
        _eventHandler.handlePlaybackRateChange(args.first);
      },
    );
    webViewController?.addJavaScriptHandler(
      handlerName: 'PlaybackQualityChange',
      callback: (args) {
        _eventHandler.handlePlaybackQualityChange(args.first);
      },
    );
  }

  @override
  bool get isDisposed => _isDisposed;

  bool _isDisposed = false;

  /// Disposes the resources created by [YoutubePlayerController].
  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _fullscreenResumeTimer?.cancel();
    _globalController?.unregisterController(this);
    super.dispose();
  }

  Future<void> run(String functionName, {Map<String, dynamic>? data}) async {
    final varArgs = await _prepareData(data);

    if (isDisposed) return;
    return webViewController?.evaluateJavascript(
      source: 'player.$functionName($varArgs);',
    );
  }

  Future<String> runWithResult(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    final varArgs = await _prepareData(data);

    try {
      final result = await webViewController?.evaluateJavascript(
        source: 'player.$functionName($varArgs);',
      );
      debugPrint(
        '[OMNI-DIAG] runWithResult($functionName) -> '
        '"$result" (${result.runtimeType})',
      );
      return result.toString();
    } catch (e) {
      debugPrint('[OMNI-DIAG] runWithResult($functionName) THREW: $e');
      rethrow;
    }
  }

  Future<void> _evaluate(String js) async {
    if (_webViewController == null) return;
    try {
      await _webViewController!.evaluateJavascript(source: js);
    } catch (e) {
      debugPrint('Error evaluating JS: $js\n$e');
    }
  }

  Future<String> _prepareData(Map<String, dynamic>? data) async {
    return data == null ? '' : jsonEncode(data);
  }

  @override
  Map<OmniVideoQuality, Uri>? get videoQualityUrls => null;

  @override
  List<OmniVideoQuality>? get availableVideoQualities =>
      _availableVideoQualities;

  set availableVideoQualities(List<OmniVideoQuality>? value) {
    _availableVideoQualities = value;
    notifyListeners();
  }

  @override
  OmniVideoQuality? get currentVideoQuality => _currentVideoQuality;
  set currentVideoQuality(OmniVideoQuality? value) {
    _currentVideoQuality = value;
    notifyListeners();
  }

  @override
  Future<void> switchQuality(OmniVideoQuality quality) async {
    debugPrint(
      "Switching quality to $quality: is not available because of the Youtube API. Doc: https://developers.google.com/youtube/iframe_api_reference",
    );
  }

  @override
  bool get isSeeking => _isSeeking;

  @override
  set isSeeking(bool value) {
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
    if (value > duration) return;
    _currentPosition = value;
    notifyListeners();
  }

  @override
  Duration get duration => _duration;
  set duration(Duration value) {
    _duration = value;
    notifyListeners();
  }

  @override
  bool get hasError => _hasError;

  set hasError(bool value) {
    _hasError = value;
    notifyListeners();
  }

  @override
  bool get hasStarted => _hasStarted;
  set hasStarted(bool value) {
    _hasStarted = value;
    notifyListeners();
  }

  @override
  bool get isBuffering => _isBuffering;
  set isBuffering(bool value) {
    if (value != _isBuffering) {
      debugPrint('[OMNI-DIAG] isBuffering $_isBuffering -> $value');
    }
    _isBuffering = value;
    notifyListeners();
  }

  @override
  bool get isFinished =>
      !isLive &&
      hasStarted == true &&
      (duration == Duration.zero ||
          currentPosition.inSeconds >= (duration.inSeconds - 1));

  @override
  bool get isFullScreen => _isFullScreen;

  set isFullScreen(bool value) {
    _isFullScreen = value;
    notifyListeners();
  }

  @override
  bool get isLive => _isLive;

  set isLive(bool value) {
    _isLive = value;
    notifyListeners();
  }

  @override
  bool get isPlaying => _isPlaying;
  set isPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }

  @override
  bool get isReady => _isReady;
  set isReady(bool value) {
    if (value != _isReady) {
      debugPrint('[OMNI-DIAG] isReady $_isReady -> $value');
    }
    _isReady = value;
    notifyListeners();
  }

  /// Opaque control surfaces are only needed when WE draw the center
  /// play/pause over the iframe (omni-custom mode), to mask YouTube's paused
  /// branding underneath. In native-controls mode YouTube owns the center, so
  /// our play/replay (shown only at start/end) keeps the normal translucency
  /// like every other player.
  @override
  bool get requiresOpaqueControlButtons => !usesNativeCenterControls;

  @override
  bool get usesNativeCenterControls =>
      options.videoSourceConfiguration.youtubeWebView.useNativeControls;

  @override
  Future<void> pause({bool useGlobalController = true}) async {
    if (useGlobalController && _globalController != null && !isFullScreen) {
      return await _globalController.requestPause();
    } else {
      return run('pauseVideo');
    }
  }

  @override
  Future<void> play({bool useGlobalController = true}) async {
    _hasStarted = true;
    if (useGlobalController && _globalController != null && !isFullScreen) {
      return await _globalController.requestPlay(this);
    } else {
      return await webViewController?.evaluateJavascript(source: 'play();');
    }
  }

  @override
  int get rotationCorrection => 0;

  @override
  Future<void> seekTo(
    Duration position, {
    skipHasPlaybackStarted = false,
  }) async {
    if (isLive) {
      isSeeking = false;
      return;
    }

    if (position <= duration) {
      wasPlayingBeforeSeek = isPlaying;

      if (!skipHasPlaybackStarted) {
        isSeeking = true;
      }

      if (position.inMicroseconds != 0 && !skipHasPlaybackStarted) {
        hasStarted = true;
      }

      await webViewController?.evaluateJavascript(
        source: 'seekTo(${position.inSeconds}, true);',
      );
      currentPosition = position;
    } else {
      debugPrint('Seek position exceeds duration');
    }
  }

  /// Whether a fullscreen enter/exit just happened. During this short window
  /// transient YouTube pause events (from the WebView being reparented during
  /// the Hero flight) are auto-resumed instead of being recorded as a user
  /// pause. See [_resumeDuringFullscreenTransition].
  bool get isInFullscreenTransition => _resumeDuringFullscreenTransition;

  /// Opens the resume window. Called on both fullscreen enter and exit.
  void beginFullscreenResumeWindow() {
    _fullscreenResumeTimer?.cancel();
    _resumeDuringFullscreenTransition = true;
    _fullscreenResumeTimer = Timer(const Duration(milliseconds: 1500), () {
      _resumeDuringFullscreenTransition = false;
    });
  }

  @override
  Future<void> switchFullScreenMode(
    BuildContext context, {
    required Widget Function(BuildContext p1)? pageBuilder,
    void Function(bool p1)? onToggle,
  }) async {
    if (isFullScreen) {
      debugPrint('[OMNI-DIAG] fullscreen EXIT isPlaying=$isPlaying isReady=$isReady isLive=$isLive');
      final wasPlaying = isPlaying;
      if (wasPlaying) beginFullscreenResumeWindow();
      isFullScreen = false;
      notifyListeners();
      onToggle?.call(false);
      Navigator.of(context).pop();

      // The reparent back to the normal viewport can leave the player wedged in
      // BUFFERING (state 3) — which the pause-resume window (state 2 only) does
      // not cover, so it sits on YouTube's spinner. Mirror the enter path:
      // re-assert playback once the transition settles to unwedge it.
      if (wasPlaying) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isDisposed) play(useGlobalController: false);
        });
      }
    } else {
      wasPlayingBeforeGoOnFullScreen = isPlaying;
      debugPrint('[OMNI-DIAG] fullscreen ENTER wasPlaying=$wasPlayingBeforeGoOnFullScreen isReady=$isReady isLive=$isLive');
      if (isPlaying) beginFullscreenResumeWindow();
      isFullScreen = true;
      notifyListeners();
      onToggle?.call(true);

      // FIX LIVE: Se il video è una live e stava riproducendo, forziamo
      // un play dopo mezzo secondo per evitare che il cambio rotta lo congeli.
      if (isLive && wasPlayingBeforeGoOnFullScreen == true) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!isDisposed) play(useGlobalController: false);
        });
      }

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
    await pause(useGlobalController: useGlobalController);
    await seekTo(Duration.zero);
    await play(useGlobalController: useGlobalController);
  }

  @override
  double get volume => _volume;

  @override
  Future<void> setVolume(double value) async {
    if (isDisposed) return;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0).toDouble();
    if (kIsWeb || Platform.isAndroid) {
      _evaluate('player.setVolume(${clamped * 100})');
    }
    _volume = clamped;
    notifyListeners();
  }

  @override
  void toggleMute() => isMuted ? unMute() : mute();

  @override
  bool get isMuted => _volume == 0;

  @override
  void mute() {
    _previousVolume = _volume;
    setVolume(0);
    run('mute');
    _globalController?.setCurrentVolume(volume);
  }

  @override
  void unMute() {
    volume = _previousVolume == 0 ? 1 : _previousVolume;
    run('unMute');
    _globalController?.setCurrentVolume(volume);
  }

  @override
  String? get videoDataSource => null;

  @override
  String? get videoId => _videoId;

  @override
  VideoSourceType get videoSourceType => VideoSourceType.youtube;

  @override
  Uri? get videoUrl => null;

  @override
  double get playbackSpeed => _playbackSpeed;

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed <= 0) {
      throw ArgumentError('Playback speed must be greater than 0');
    }
    _playbackSpeed = speed;
    _evaluate('player.setPlaybackRate($speed);');
    notifyListeners();
  }

  @override
  void loadVideoSource(VideoSourceConfiguration videoSourceConfiguration) {
    globalKeyPlayer.currentState?.refresh(
      videoSourceConfiguration: videoSourceConfiguration,
    );
  }

  @override
  bool get isFullyVisible => _isFullyVisible;

  @override
  set isFullyVisible(bool value) {
    _isFullyVisible = value;
    notifyListeners();
  }

  @override
  File? get file => null;
}
