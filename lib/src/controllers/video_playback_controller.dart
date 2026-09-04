import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// A [VideoPlayerController] subclass with owner tracking and safe disposal.
///
/// Handles multiple widgets sharing the same controller to prevent early disposal,
/// and optionally delegates [play] / [pause] to a [GlobalVideoPlayerManager]
/// to enforce a single active video at a time.
class VideoPlaybackController extends VideoPlayerController {
  /// Android is the platform this class bends for: it never takes audio focus,
  /// and its commands have to be spaced out.
  static bool get _isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Whether the controller is still mounted (not yet disposed).
  bool _mounted = true;

  /// Flag indicating if this stream is a live broadcast.
  final bool isLive;

  /// Creates a controller from a network [url].
  ///
  /// If [manager] is non-null, calls to [play] and [pause]
  /// are forwarded to it. Set [isLive] to true for live streams,
  /// which affects buffering logic.
  VideoPlaybackController.uri(
    super.url, {
    this.isLive = false,
    bool mixWithOthers = false,
    super.httpHeaders,
  }) : super.networkUrl(
         // YouTube live (and other live HLS) is returned as a manifest URL with
         // no `.m3u8` extension, so ExoPlayer/AVPlayer can't infer the format
         // and playback fails. Tell it explicitly that live streams are HLS.
         // VOD uses progressive mp4 streams, which are auto-detected.
         formatHint: isLive ? VideoFormat.hls : null,
         // Audio focus is exclusive on Android: whoever takes it makes
         // ExoPlayer pause every other player, muted or not.
         videoPlayerOptions: VideoPlayerOptions(
           mixWithOthers: mixWithOthers || _isAndroid,
         ),
       );

  /// Creates a controller for an asset video.
  ///
  /// Live flag is irrelevant for assets, defaults to false.
  VideoPlaybackController.asset(super.dataSource, {this.isLive = false})
    : super.asset();

  /// Creates a controller for an file video.
  ///
  /// Live flag is irrelevant for assets, defaults to false.
  VideoPlaybackController.file(super.file, {this.isLive = false})
    : super.file();

  /// Breathing room between two platform commands. ExoPlayer drops a `play`
  /// issued on the heels of a `seekTo` — the video rewinds and never resumes.
  /// AVPlayer and the web element don't, so they pay nothing for it.
  static Duration get _commandGap =>
      _isAndroid ? const Duration(milliseconds: 20) : Duration.zero;

  Future<void> _commands = Future<void>.value();

  /// Runs [command] after every command already queued, then waits [_commandGap].
  ///
  /// The mounted guard lives *inside* the closure: a command waiting its turn
  /// would otherwise fire on a controller disposed while it queued.
  ///
  /// Nothing here times out: the queue exists so that commands land in the
  /// order they were issued, and a deadline would break exactly that. A
  /// platform call that never answers does hold up the ones behind it — a
  /// player in that state is gone, and the way back is to rebuild it.
  Future<void> _enqueue(Future<void> Function() command) {
    final next = _commands.then((_) async {
      if (!_mounted) return;
      await command();
      final gap = _commandGap;
      if (_mounted && gap > Duration.zero) await Future<void>.delayed(gap);
    });
    // A failed command must not wedge the queue for everyone behind it.
    _commands = next.catchError((_) {});

    return next;
  }

  @override
  Future<void> play() => _enqueue(super.play);

  @override
  Future<void> pause() => _enqueue(super.pause);

  /// The seek still waiting its turn, and the future its callers hold.
  Duration? _queuedSeek;
  Future<void>? _queuedSeekResult;

  @override
  Future<void> seekTo(Duration position) {
    // A drag on the progress bar fires a burst of seeks: the one still waiting
    // is replaced rather than queued behind, or playback walks through every
    // intermediate position, always trailing the finger.
    _queuedSeek = position;

    return _queuedSeekResult ??= _enqueue(() {
      final target = _queuedSeek ?? position;
      _queuedSeek = null;
      _queuedSeekResult = null;

      return super.seekTo(target);
    });
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
    _queuedSeek = null;
    _queuedSeekResult = null;
    return super.dispose();
  }
}
