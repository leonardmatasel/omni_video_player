import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../utils/logger.dart';
import '../vimeo/vimeo_player_event_handler.dart';

class VimeoPlaybackController extends OmniPlaybackController {
  @override
  final String videoId;
  @override
  final ValueNotifier<Widget?> sharedPlayerNotifier = ValueNotifier(null);
  final VideoPlayerCallbacks callbacks;

  @override
  final String? videoDataSource = null;

  late final WebViewController webViewController;
  late final VimeoPlayerEventHandler _eventHandler;
  final Completer<void> _initCompleter = Completer();

  String get playerId => 'Vimeo$hashCode';

  bool _isPlaying = false;
  bool _isReady = false;
  bool _isBuffering = false;
  Duration _currentPosition = Duration.zero;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  bool _isFullyVisible = false;

  GlobalKey<VideoPlayerInitializerState> globalKeyPlayer;

  @override
  Duration get duration => _duration;

  set duration(Duration value) {
    _duration = value;
    notifyListeners();
  }

  @override
  final Size size;

  bool _wasPlayingBeforeSeek = false;

  double _volume = 1;

  bool _isSeeking = false;
  bool _isFullScreen = false;
  bool _hasStarted = true;
  bool _hasError = false;
  final GlobalPlaybackController? _globalController;
  double _previousVolume = 1.0;
  final List<VoidCallback> _onReadyQueue = [];

  VimeoPlaybackController._(
    this.videoId,
    this._globalController,
    Duration initialPosition,
    double? initialVolume,
    this.size,
    this.callbacks,
    this.globalKeyPlayer,
  ) {
    _eventHandler = VimeoPlayerEventHandler(this);

    late final PlatformWebViewControllerCreationParams webViewParams;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      webViewParams = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      webViewParams = const PlatformWebViewControllerCreationParams();
    }

    webViewController = WebViewController.fromPlatformCreationParams(
      webViewParams,
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(playerId, onMessageReceived: _eventHandler.call)
      ..enableZoom(false);

    final webViewPlatform = webViewController.platform;
    if (webViewPlatform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      webViewPlatform.setMediaPlaybackRequiresUserGesture(false);
    } else if (webViewPlatform is WebKitWebViewController) {
      webViewPlatform.setAllowsBackForwardNavigationGestures(false);
    }
  }

  /// Creates and initializes a new [OmniPlaybackController] instance.
  static VimeoPlaybackController create({
    required String videoId,
    required GlobalPlaybackController? globalController,
    required Duration initialPosition,
    required double? initialVolume,
    required Size size,
    required VideoPlayerCallbacks callbacks,
    required GlobalKey<VideoPlayerInitializerState> globalKeyPlayer,
  }) {
    return VimeoPlaybackController._(
      videoId,
      globalController,
      initialPosition,
      initialVolume,
      size,
      callbacks,
      globalKeyPlayer,
    );
  }

  Future<void> init() async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();

    await webViewController.loadHtmlString(
      await _buildPlayerHTML(<String, String>{
        'videoId': videoId,
        'platform': platform,
        'playerId': playerId,
      }),
      baseUrl: kIsWeb ? Uri.base.origin : "https://player.vimeo.com",
    );

    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await webViewController.removeJavaScriptChannel(playerId);
  }

  Future<String> _buildPlayerHTML(Map<String, String> data) async {
    final playerHtml = await rootBundle.loadString(
      'packages/omni_video_player/assets/vimeo_player.html',
    );

    return playerHtml.replaceAllMapped(
      RegExp(r'<<([a-zA-Z]+)>>'),
      (m) => data[m.group(1)] ?? m.group(0)!,
    );
  }

  @override
  bool get wasPlayingBeforeSeek => _wasPlayingBeforeSeek;

  @override
  set wasPlayingBeforeSeek(bool value) {
    if (isSeeking) return;
    _wasPlayingBeforeSeek = value;
    notifyListeners();
  }

  @override
  bool get isLive => false; // doesn't exist on vimeo

  @override
  Uri? get videoUrl => null;

  @override
  VideoSourceType get videoSourceType => VideoSourceType.vimeo;

  @override
  bool get isReady => _isReady;

  set isReady(bool value) {
    _isReady = value;
    if (value) {
      for (final action in _onReadyQueue) {
        action();
      }
      _onReadyQueue.clear();
    }
    if (value) callbacks.onControllerCreated?.call(this);
    notifyListeners();
  }

  @override
  bool get isPlaying => _isPlaying;

  set isPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }

  @override
  bool get isBuffering => _isBuffering;

  set isBuffering(bool value) {
    _isBuffering = value;
    notifyListeners();
  }

  @override
  bool get hasError => _hasError;

  set hasError(bool value) {
    _hasError = value;
    notifyListeners();
  }

  @override
  bool get isMuted => volume == 0;

  @override
  bool get isSeeking => _isSeeking;

  @override
  set isSeeking(bool value) {
    _isSeeking = value;
    if (!value) callbacks.onSeekEnd?.call(currentPosition);
    notifyListeners();
  }

  @override
  bool get hasStarted => _hasStarted;
  set hasStarted(bool value) {
    _hasStarted = value;
    notifyListeners();
  }

  @override
  bool get isFullScreen => _isFullScreen;

  @override
  Duration get currentPosition => _currentPosition;

  set currentPosition(Duration value) {
    _currentPosition = value;
    notifyListeners();
  }

  @override
  bool get isFinished =>
      currentPosition >= duration && duration != Duration.zero;

  @override
  int get rotationCorrection => 0;

  @override
  List<DurationRange> get buffered => [];

  @override
  Future<void> play({bool useGlobalController = true}) async {
    hasStarted = true;
    if (useGlobalController && _globalController != null) {
      return await _globalController.requestPlay(this);
    } else {
      await _evaluate("player.play();");
    }
  }

  @override
  Future<void> pause({bool useGlobalController = true}) async {
    if (useGlobalController && _globalController != null) {
      return await _globalController.requestPause();
    } else {
      await _evaluate("player.pause();");
    }
  }

  @override
  Future<void> replay({bool useGlobalController = true}) async {
    await Future.wait([
      pause(useGlobalController: useGlobalController),
      seekTo(Duration.zero),
      play(useGlobalController: useGlobalController),
    ]);
  }

  @override
  double get volume => _volume;

  @override
  set volume(double value) {
    _evaluate("player.setVolume($volume);");
    _volume = value;
    notifyListeners();
  }

  @override
  void toggleMute() => isMuted ? unMute() : mute();

  @override
  void mute() {
    _previousVolume = _volume;
    _volume = 0;
    _globalController?.setCurrentVolume(0);
  }

  @override
  void unMute() {
    _volume = _previousVolume;
    _globalController?.setCurrentVolume(_previousVolume);
  }

  @override
  Future<void> seekTo(
    Duration position, {
    skipHasPlaybackStarted = false,
  }) async {
    if (position <= duration) {
      wasPlayingBeforeSeek = isPlaying;

      if (!skipHasPlaybackStarted) {
        isSeeking = true;
        pause();
      }

      if (position.inMicroseconds != 0 && !skipHasPlaybackStarted) {
        hasStarted = true;
      }

      await _evaluate("player.setCurrentTime(${position.inSeconds});");
      currentPosition = position;
    } else {
      throw ArgumentError('Seek position exceeds duration');
    }
  }

  @override
  Future<void> switchFullScreenMode(
    BuildContext context, {
    required Widget Function(BuildContext)? pageBuilder,
    void Function(bool)? onToggle,
  }) async {
    if (_isFullScreen) {
      _isFullScreen = false;
      notifyListeners();
      onToggle?.call(false);
      Navigator.of(context).pop();
    } else {
      _isFullScreen = true;
      notifyListeners();
      onToggle?.call(true);

      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => pageBuilder!(context),
          transitionsBuilder: (_, animation, __, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  void runOnReady(VoidCallback action) {
    if (isReady) {
      action();
    } else {
      _onReadyQueue.add(action);
    }
  }

  Future<void> _evaluate(String js) async {
    await _initCompleter.future;

    try {
      await webViewController.runJavaScript(js);
    } catch (e) {
      logger.d('Error evaluating JS: $js\n$e');
    }
  }

  @override
  Map<OmniVideoQuality, Uri>? get videoQualityUrls => null;

  @override
  OmniVideoQuality? get currentVideoQuality => null;

  @override
  Future<void> switchQuality(OmniVideoQuality quality) {
    throw UnimplementedError();
  }

  @override
  List<OmniVideoQuality>? get availableVideoQualities => null;

  @override
  double get playbackSpeed => _playbackSpeed;

  @override
  set playbackSpeed(double speed) {
    if (speed <= 0) {
      throw ArgumentError('Playback speed must be greater than 0');
    }
    _playbackSpeed = speed;
    _evaluate("player.setPlaybackRate($speed);");
    notifyListeners();
  }

  @override
  void loadVideoSource(VideoSourceConfiguration videoSourceConfiguration) {
    globalKeyPlayer.currentState
        ?.refresh(videoSourceConfiguration: videoSourceConfiguration);
  }

  @override
  bool get isFullyVisible => _isFullyVisible;

  @override
  set isFullyVisible(bool value) {
    _isFullyVisible = value;
    notifyListeners();
  }
}
