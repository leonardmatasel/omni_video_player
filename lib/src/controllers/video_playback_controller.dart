import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// A controller wrapping [media_kit] Player with similar API to VideoPlayerController.
class VideoPlaybackController with ChangeNotifier {
  /// The underlying media_kit player.
  final Player player;

  /// Whether the controller is still mounted (not yet disposed).
  bool _mounted = true;

  /// Flag indicating if this stream is a live broadcast.
  final bool isLive;

  /// Video widget controller
  late final VideoController videoController;

  // Lista di subscription per cancellarle tutte al dispose
  final List<StreamSubscription> _subscriptions = [];

  bool _isReady = false;

  VideoPlaybackController.uri(
    String url, {
    this.isLive = false,
    bool mixWithOthers = false,
  }) : player = Player() {
    player.open(Media(url), play: false);
    videoController = VideoController(player);
    _listenToStreams();
  }

  VideoPlaybackController.asset(String assetPath, {this.isLive = false})
    : player = Player() {
    player.open(Media("asset:///$assetPath"), play: false);
    videoController = VideoController(player);
    _listenToStreams();
  }

  VideoPlaybackController.file(File file, {this.isLive = false})
    : player = Player() {
    player.open(Media("file:///${file.path}"), play: false);
    videoController = VideoController(player);
    _listenToStreams();
  }

  void _listenToStreams() {
    final streams = [
      player.stream.position,
      player.stream.duration,
      player.stream.volume,
      player.stream.rate,
      player.stream.buffer,
      player.stream.videoParams,
      player.stream.track,
      player.stream.error,
    ];

    videoController.waitUntilFirstFrameRendered.then(
      (value) => _isReady = true,
    );

    player.stream.playing.listen((_) => notifyListeners());

    // --- throttling ---
    Timer? notifyTimer;
    void throttledNotify() {
      if (notifyTimer?.isActive ?? false) return;
      notifyTimer = Timer(const Duration(milliseconds: 500), () {
        if (_mounted) notifyListeners();
      });
    }

    for (final s in streams) {
      _subscriptions.add(s.listen((_) => throttledNotify()));
    }
  }

  Future<void> play() async {
    if (_mounted) {
      await player.play();
    }
  }

  Future<void> pause() async {
    if (_mounted) {
      await player.pause();
    }
  }

  bool get isBuffering => false;

  @override
  Future<void> dispose() async {
    _mounted = false;
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await player.dispose();
    super.dispose();
  }

  // --- Getters / setters ---
  bool get isReady => _isReady;

  bool get isPlaying => player.state.playing;

  bool get isMuted => player.state.volume == 0;

  double get volume => player.state.volume;

  double get playbackSpeed => player.state.rate;

  set playbackSpeed(double speed) => player.setRate(speed);

  Duration get currentPosition => player.state.position;

  Duration get duration => player.state.duration;

  int get rotationCorrection => 0;

  Size get size => Size(
    player.state.width?.toDouble() ?? 16,
    player.state.height?.toDouble() ?? 9,
  );

  bool get hasError => false;

  Duration get buffer => player.state.buffer;
}
