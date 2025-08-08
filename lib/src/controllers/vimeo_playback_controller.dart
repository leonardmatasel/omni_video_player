import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:video_player/video_player.dart';

class VimeoPlaybackController extends OmniPlaybackController {
  @override
  final String videoId;
  @override
  final ValueNotifier<Widget?> sharedPlayerNotifier = ValueNotifier(null);
  final VideoPlayerCallbacks callbacks;

  @override
  final String? videoDataSource = null;

  InAppWebViewController? _webViewController;

  bool _isPlaying = false;
  bool _isReady = false;
  Duration _currentPosition = Duration.zero;

  @override
  final Duration duration;
  Timer? _positionTimer;
  @override
  final Size size;

  bool _wasPlayingBeforeSeek = false;

  double _volume = 1;

  bool _isSeeking = false;
  bool _isFullScreen = false;
  bool _hasStarted = true;
  bool _isBuffering = true;
  bool _hasError = false;
  final GlobalPlaybackController? _globalController;
  double _previousVolume = 1.0;
  final List<VoidCallback> _onReadyQueue = [];

  void _executeOrQueue(VoidCallback action) {
    if (_isReady) {
      action();
    } else {
      _onReadyQueue.add(action);
    }
  }

  VimeoPlaybackController._(
    this.videoId,
    this._globalController,
    Duration initialPosition,
    double? initialVolume,
    this.duration,
    this.size,
    this.callbacks,
  ) {
    _executeOrQueue(() {
      seekTo(initialPosition, skipHasPlaybackStarted: true);
      if (initialVolume != null) {
        volume = initialVolume;
      }
    });
  }

  /// Creates and initializes a new [OmniPlaybackController] instance.
  static VimeoPlaybackController create({
    required String videoId,
    required GlobalPlaybackController? globalController,
    required Duration initialPosition,
    double? initialVolume,
    required Duration duration,
    required Size size,
    required VideoPlayerCallbacks callbacks,
  }) {
    return VimeoPlaybackController._(
      videoId,
      globalController,
      initialPosition,
      initialVolume,
      duration,
      size,
      callbacks,
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
  bool get isFinished => duration == currentPosition;

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

  Future<void> _evaluate(String js) async {
    if (_webViewController == null) return;
    try {
      await _webViewController!.evaluateJavascript(source: js);
    } catch (e) {
      debugPrint('Error evaluating JS: $js\n$e');
    }
  }

  DateTime? _lastTickTime;

  void startPositionTimer() {
    _positionTimer?.cancel();
    _lastTickTime = DateTime.now();

    _positionTimer = Timer.periodic(Duration(milliseconds: 500), (_) {
      if (_isPlaying) {
        final now = DateTime.now();
        final elapsed = now.difference(_lastTickTime!);
        _lastTickTime = now;

        final newPosition = _currentPosition + elapsed;

        if (newPosition > duration) {
          _currentPosition = duration;
          _positionTimer?.cancel();
          pause();
        } else {
          _currentPosition = newPosition;
        }

        notifyListeners();
      }
    });
  }

  void stopPositionTimer() {
    _positionTimer?.cancel();
  }

  void setWebViewController(InAppWebViewController? controller) {
    _webViewController = controller;
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
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
}
