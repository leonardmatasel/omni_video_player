import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// A [VideoPlayerController] subclass with owner tracking and safe disposal.
///
/// Handles multiple widgets sharing the same controller to prevent early disposal,
/// and optionally delegates [play] / [pause] to a [GlobalVideoPlayerManager]
/// to enforce a single active video at a time.
class VideoPlaybackController extends VideoPlayerController {
  /// Whether the controller is still mounted (not yet disposed).
  bool _mounted = true;

  /// Flag indicating if this stream is a live broadcast.
  final bool isLive;

  /// Creates a controller from a network [url].
  ///
  /// If [manager] is non-null, calls to [play] and [pause]
  /// are forwarded to it. Set [isLive] to true for live streams,
  /// which affects buffering logic.
  VideoPlaybackController.uri(super.url, {this.isLive = false})
      : super.networkUrl(
          videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
        );

  /// Creates a controller for an asset video.
  ///
  /// Live flag is irrelevant for assets, defaults to false.
  VideoPlaybackController.asset(super.dataSource, {this.isLive = false})
      : super.asset();

  @override
  Future<void> play() async {
    if (_mounted) await super.play();
  }

  @override
  Future<void> pause() async {
    if (_mounted) await super.pause();
  }

  /// Returns a more reliable buffering state on Android for non‑live videos.
  ///
  /// On Android the `value.isBuffering` flag is not always accurate. For non‑live,
  /// non‑completed videos, this getter compares the current position (`value.position`)
  /// to the end of the last buffered range (`value.buffered.lastOrNull`). If the position
  /// exceeds that value, the video is considered buffering.
  ///
  /// This workaround, inspired by issue [https://github.com/flutter/flutter/issues/165149]
  /// and PR [https://github.com/fluttercommunity/chewie/pull/912], applies only to non‑live
  /// streams, since live streams may have empty or irrelevant buffers. Additionally,
  /// the buffering issue occurs in `video_player_android` versions up to 2.8.2, while
  /// version 2.7.17 does not exhibit it.
  bool get isActuallyBuffering {
    if (kIsWeb) {
      return value.isBuffering;
    }

    if (Platform.isAndroid) {
      if (value.isBuffering && !value.isCompleted && !isLive) {
        final int buffer = value.buffered.lastOrNull?.end.inMicroseconds ?? -1;
        final int position = value.position.inMicroseconds;
        return position >= buffer;
      } else {
        return false;
      }
    } else {
      return value.isBuffering;
    }
  }

  @override
  Future<void> dispose() {
    _mounted = false;
    return super.dispose();
  }
}
