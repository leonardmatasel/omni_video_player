import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/src/utils/logger.dart';
import 'package:omni_video_player/src/youtube/youtube_player_event_handler.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../omni_video_player/controllers/global_playback_controller.dart';
import '../../omni_video_player/models/video_player_configuration.dart';

typedef YoutubeWebResourceError = WebResourceError;

class YoutubePlaybackController extends OmniPlaybackController {
  late final YoutubePlayerEventHandler _eventHandler;

  late final WebViewController webViewController;

  final VideoPlayerCallbacks callbacks;
  final VideoPlayerConfiguration options;

  final Completer<void> _initCompleter = Completer();

  @override
  final ValueNotifier<Widget?> sharedPlayerNotifier = ValueNotifier(null);

  final String? key;

  // STATES
  bool _hasError = false;
  bool _isReady = false;
  bool _isPlaying = false;
  bool _hasStarted = false;
  bool _isLive = false;
  bool _isSeeking = false;
  bool _isBuffering = false;
  bool? wasPlayingBeforeGoOnFullScreen;
  double _volume = 100;
  double _previousVolume = 100;
  Duration _duration = Duration.zero;
  double _playbackSpeed = 1.0;
  Duration _currentPosition = Duration.zero;
  OmniVideoQuality? _currentVideoQuality;
  List<OmniVideoQuality>? _availableVideoQualities;
  bool _isFullScreen = false;
  late final String _videoId;
  late final GlobalPlaybackController? _globalController;

  @override
  final Size size;

  YoutubePlaybackController({
    required Duration duration,
    required bool isLive,
    required this.size,
    required this.callbacks,
    required this.options,
    required String videoId,
    required GlobalPlaybackController? globalController,
    ValueChanged<YoutubeWebResourceError>? onWebResourceError,
    this.key,
  }) {
    _duration = duration;
    _isLive = isLive;
    _videoId = videoId;
    _globalController = globalController;
    _eventHandler = YoutubePlayerEventHandler(this, options, callbacks);

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

  factory YoutubePlaybackController.fromVideoId({
    required String videoId,
    required Duration duration,
    required bool isLive,
    required Size size,
    required VideoPlayerCallbacks callbacks,
    required VideoPlayerConfiguration options,
    required GlobalPlaybackController? globalController,
    bool autoPlay = false,
    double? startSeconds,
    double? endSeconds,
  }) {
    final controller = YoutubePlaybackController(
      callbacks: callbacks,
      options: options,
      duration: duration,
      isLive: isLive,
      size: size,
      videoId: videoId,
      globalController: globalController,
      key: videoId,
    );

    controller.loadVideoById(
      videoId: videoId,
      startSeconds: startSeconds,
      endSeconds: endSeconds,
    );

    return controller;
  }

  Future<void> loadVideoById({
    required String videoId,
    double? startSeconds,
    double? endSeconds,
  }) {
    return run(
      'loadVideoById',
      data: {
        'videoId': videoId,
        'startSeconds': startSeconds,
        'endSeconds': endSeconds,
      },
    );
  }

  String get playerId => 'Youtube$hashCode';

  Future<void> init() async {
    await load(
      baseUrl: kIsWeb ? Uri.base.origin : "https://www.youtube.com",
      id: playerId,
    );

    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  Future<void> load({
    String? baseUrl,
    required String id,
  }) async {
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name.toLowerCase();
    final Map<String, String> playerData = {
      'playerId': id,
      'playerVars': jsonEncode({
        'autoplay': 0,
        'mute': 1,
        'cc_lang_pref': 'en',
        'cc_load_policy': 0,
        'color': 'white',
        'controls': 0,
        'disablekb': kIsWeb &&
                options.playerUIVisibilityOptions.enableForwardGesture &&
                options.playerUIVisibilityOptions.enableBackwardGesture
            ? 0
            : 1,
        'enablejsapi': 1,
        'fs': 0,
        'hl': 'en',
        'iv_load_policy': 3,
        'modestbranding': 1,
        if (kIsWeb) ...{
          'origin': Uri.base.origin,
          'widget_referrer': Uri.base.origin,
        } else ...{
          'origin': 'https://www.youtube.com',
          'widget_referrer': "https://www.youtube.com",
        },
        'showinfo': 0,
        'autohide': 1,
        'playsinline': 1,
        'rel': 0,
      }),
      'platform': platform,
      'host': 'https://www.youtube.com',
    };

    await webViewController.loadHtmlString(
      await _buildPlayerHTML(playerData),
      baseUrl: baseUrl,
    );
  }

  Future<String> _buildPlayerHTML(Map<String, String> data) async {
    final playerHtml = await rootBundle.loadString(
      'packages/omni_video_player/assets/youtube_player.html',
    );

    return playerHtml.replaceAllMapped(
      RegExp(r'<<([a-zA-Z]+)>>'),
      (m) => data[m.group(1)] ?? m.group(0)!,
    );
  }

  /// Disposes the resources created by [YoutubePlayerController].
  @override
  Future<void> dispose() async {
    super.dispose();
    await webViewController.removeJavaScriptChannel(playerId);
  }

  Future<void> run(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    await _initCompleter.future;

    final varArgs = await _prepareData(data);

    return webViewController.runJavaScript('player.$functionName($varArgs);');
  }

  Future<String> runWithResult(
    String functionName, {
    Map<String, dynamic>? data,
  }) async {
    await _initCompleter.future;

    final varArgs = await _prepareData(data);

    final result = await webViewController.runJavaScriptReturningResult(
      'player.$functionName($varArgs);',
    );
    return result.toString();
  }

  Future<void> _eval(String javascript) async {
    await _eventHandler.isReady;

    return webViewController.runJavaScript(javascript);
  }

  Future<String> _prepareData(Map<String, dynamic>? data) async {
    await _eventHandler.isReady;
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
    logger.i(
        "Switching quality to $quality: is not available because of the Youtube API. Doc: https://developers.google.com/youtube/iframe_api_reference");
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
    _isBuffering = value;
    notifyListeners();
  }

  @override
  bool get isFinished => duration == currentPosition;

  @override
  bool get isFullScreen => _isFullScreen;

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
    _isReady = value;
    notifyListeners();
  }

  @override
  Future<void> pause({bool useGlobalController = true}) {
    return run('pauseVideo');
  }

  @override
  Future<void> play({bool useGlobalController = true}) {
    return run('playVideo');
  }

  @override
  int get rotationCorrection => 0;

  @override
  Future<void> seekTo(
    Duration position,
  ) async {
    if (position <= duration) {
      if (position.inSeconds != 0) {
        hasStarted = true;
      }

      await _eval('player.seekTo(${position.inSeconds}, true)');
    } else {
      logger.i('Seek position exceeds duration');
    }
  }

  @override
  Future<void> switchFullScreenMode(BuildContext context,
      {required Widget Function(BuildContext p1)? pageBuilder,
      void Function(bool p1)? onToggle}) async {
    if (_isFullScreen) {
      _isFullScreen = false;
      wasPlayingBeforeGoOnFullScreen = null;
      notifyListeners();
      onToggle?.call(false);
      Navigator.of(context).pop();
    } else {
      _isFullScreen = true;
      notifyListeners();
      onToggle?.call(true);
      wasPlayingBeforeGoOnFullScreen = _isPlaying;
      await Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => pageBuilder!(context),
          transitionsBuilder: (_, animation, __, Widget child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
      wasPlayingBeforeGoOnFullScreen = null;
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
    if (kIsWeb || Platform.isAndroid) _eval('player.setVolume(${value * 100})');
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
    run('mute');
    _globalController?.setCurrentVolume(0);
  }

  @override
  void unMute() {
    volume = _previousVolume;
    run('unMute');
    _globalController?.setCurrentVolume(_previousVolume);
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
  set playbackSpeed(double speed) {
    if (speed <= 0) {
      throw ArgumentError('Playback speed must be greater than 0');
    }
    _playbackSpeed = speed;
    _eval('player.setPlaybackRate($speed);');
    notifyListeners();
  }
}
