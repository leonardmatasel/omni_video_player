import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:video_player/video_player.dart' show DurationRange;
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';

/// Immutable snapshot of the player's observable state, delivered via
/// `OmniPlaybackController.state` (a `ValueListenable<OmniVideoState>`).
@immutable
class OmniVideoState {
  final bool isReady;
  final bool isPlaying;
  final bool isBuffering;
  final bool isSeeking;
  final bool hasStarted;
  final bool isFinished;
  final bool hasError;
  final bool isFullScreen;
  final bool isLive;
  final bool isMuted;
  final bool isFullyVisible;
  final Duration position;
  final Duration duration;
  final List<DurationRange> buffered;
  final double volume;
  final double playbackSpeed;
  final Size size;
  final int rotationCorrection;
  final OmniVideoQuality? currentVideoQuality;
  final List<OmniVideoQuality>? availableVideoQualities;

  const OmniVideoState({
    this.isReady = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isSeeking = false,
    this.hasStarted = false,
    this.isFinished = false,
    this.hasError = false,
    this.isFullScreen = false,
    this.isLive = false,
    this.isMuted = false,
    this.isFullyVisible = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.buffered = const [],
    this.volume = 1.0,
    this.playbackSpeed = 1.0,
    this.size = Size.zero,
    this.rotationCorrection = 0,
    this.currentVideoQuality,
    this.availableVideoQualities,
  });

  OmniVideoState copyWith({
    bool? isReady,
    bool? isPlaying,
    bool? isBuffering,
    bool? isSeeking,
    bool? hasStarted,
    bool? isFinished,
    bool? hasError,
    bool? isFullScreen,
    bool? isLive,
    bool? isMuted,
    bool? isFullyVisible,
    Duration? position,
    Duration? duration,
    List<DurationRange>? buffered,
    double? volume,
    double? playbackSpeed,
    Size? size,
    int? rotationCorrection,
    OmniVideoQuality? currentVideoQuality,
    List<OmniVideoQuality>? availableVideoQualities,
  }) {
    return OmniVideoState(
      isReady: isReady ?? this.isReady,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      isSeeking: isSeeking ?? this.isSeeking,
      hasStarted: hasStarted ?? this.hasStarted,
      isFinished: isFinished ?? this.isFinished,
      hasError: hasError ?? this.hasError,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      isLive: isLive ?? this.isLive,
      isMuted: isMuted ?? this.isMuted,
      isFullyVisible: isFullyVisible ?? this.isFullyVisible,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      buffered: buffered ?? this.buffered,
      volume: volume ?? this.volume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      size: size ?? this.size,
      rotationCorrection: rotationCorrection ?? this.rotationCorrection,
      currentVideoQuality: currentVideoQuality ?? this.currentVideoQuality,
      availableVideoQualities:
          availableVideoQualities ?? this.availableVideoQualities,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OmniVideoState &&
          other.isReady == isReady &&
          other.isPlaying == isPlaying &&
          other.isBuffering == isBuffering &&
          other.isSeeking == isSeeking &&
          other.hasStarted == hasStarted &&
          other.isFinished == isFinished &&
          other.hasError == hasError &&
          other.isFullScreen == isFullScreen &&
          other.isLive == isLive &&
          other.isMuted == isMuted &&
          other.isFullyVisible == isFullyVisible &&
          other.position == position &&
          other.duration == duration &&
          listEquals(other.buffered, buffered) &&
          other.volume == volume &&
          other.playbackSpeed == playbackSpeed &&
          other.size == size &&
          other.rotationCorrection == rotationCorrection &&
          other.currentVideoQuality == currentVideoQuality &&
          listEquals(other.availableVideoQualities, availableVideoQualities);

  @override
  int get hashCode => Object.hash(
        isReady,
        isPlaying,
        isBuffering,
        isSeeking,
        hasStarted,
        isFinished,
        hasError,
        isFullScreen,
        isLive,
        isMuted,
        isFullyVisible,
        position,
        duration,
        Object.hashAll(buffered),
        volume,
        playbackSpeed,
        size,
        rotationCorrection,
        currentVideoQuality,
        availableVideoQualities == null
            ? null
            : Object.hashAll(availableVideoQualities!),
      );
}
