import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// A controller wrapping [media_kit] Player with similar API to VideoPlayerController.
class VideoPlaybackController {
  /// The underlying media_kit player.
  final Player _player;

  /// Whether the controller is still mounted (not yet disposed).
  bool _mounted = true;

  /// Flag indicating if this stream is a live broadcast.
  final bool isLive;

  /// Video widget controller
  late final VideoController videoController;

  VideoPlaybackController.uri(
    String url, {
    this.isLive = false,
    bool mixWithOthers = false,
  }) : _player = Player() {
    _player.open(Media(url));
    videoController = VideoController(_player);
  }

  VideoPlaybackController.asset(String assetPath, {this.isLive = false})
    : _player = Player() {
    _player.open(Media(assetPath));
    videoController = VideoController(_player);
  }

  VideoPlaybackController.file(File file, {this.isLive = false})
    : _player = Player() {
    _player.open(Media(file.path));
    videoController = VideoController(_player);
  }

  Future<void> play() async {
    if (_mounted) {
      await _player.play();
    }
  }

  Future<void> pause() async {
    if (_mounted) {
      await _player.pause();
    }
  }

  /// MediaKit does not expose exact buffering state like video_player.
  /// We'll approximate it using `position` and `duration`.
  bool get isActuallyBuffering {
    // For simplicity, if position is less than duration and not playing
    if (kIsWeb) return false;
    if (Platform.isAndroid || Platform.isIOS) {
      return !isPlaying && !isLive && currentPosition < duration;
    }
    return false;
  }

  Future<void> dispose() async {
    _mounted = false;
    await _player.dispose();
  }

  // --- Getters / setters ---
  bool get isReady => _player.platform?.completer.isCompleted ?? true;

  bool get isPlaying => _player.state.playing;

  bool get isMuted => _player.state.volume == 0;

  double get volume => _player.state.volume;

  set volume(double value) => _player.setVolume(value);

  double get playbackSpeed => _player.state.rate;

  set playbackSpeed(double speed) => _player.setRate(speed);

  Duration get currentPosition => _player.state.position;

  Duration get duration => _player.state.duration;

  int get rotationCorrection => 0;

  Size get size => Size(
    _player.state.videoParams.w?.toDouble() ?? 16,
    _player.state.videoParams.h?.toDouble() ?? 9,
  );

  bool get hasError => false;

  Duration get buffered => _player.state.buffer;
}
