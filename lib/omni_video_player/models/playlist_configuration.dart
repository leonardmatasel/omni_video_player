import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_item.dart';

/// Defines the repeat behavior for playlist playback.
enum PlaylistRepeatMode {
  /// No repeat — playback stops after the last video.
  none,

  /// Repeat the entire playlist from the beginning after the last video.
  all,

  /// Repeat the current video indefinitely.
  one,
}

/// Configuration options for playlist behavior in [OmniVideoPlaylist].
///
/// Controls how videos are queued, auto-advanced, looped, and shuffled.
///
/// ### Example
/// ```dart
/// PlaylistConfiguration(
///   items: [
///     OmniPlaylistItem(
///       sourceConfiguration: VideoSourceConfiguration.youtube(
///         videoUrl: Uri.parse('https://youtube.com/watch?v=...'),
///       ),
///       title: 'Video 1',
///     ),
///     OmniPlaylistItem(
///       sourceConfiguration: VideoSourceConfiguration.network(
///         videoUrl: Uri.parse('https://example.com/video.mp4'),
///       ),
///       title: 'Video 2',
///     ),
///   ],
///   autoAdvance: true,
///   repeatMode: PlaylistRepeatMode.all,
/// )
/// ```
@immutable
class PlaylistConfiguration {
  /// The ordered list of videos in this playlist.
  ///
  /// Must contain at least one item.
  final List<OmniPlaylistItem> items;

  /// The index of the video to play first.
  ///
  /// Must be within `[0, items.length)`.
  /// Defaults to `0` (the first item).
  final int initialIndex;

  /// Whether to automatically advance to the next video when the current one finishes.
  ///
  /// When `true`, a countdown overlay is shown before advancing (configurable via
  /// [advanceDelay]). The user can cancel or skip the countdown.
  ///
  /// Defaults to `true`.
  final bool autoAdvance;

  /// The repeat mode for the playlist.
  ///
  /// - [PlaylistRepeatMode.none]: Stop after the last video.
  /// - [PlaylistRepeatMode.all]: Loop the entire playlist.
  /// - [PlaylistRepeatMode.one]: Repeat the current video.
  ///
  /// Defaults to [PlaylistRepeatMode.none].
  final PlaylistRepeatMode repeatMode;

  /// Whether to shuffle the playback order.
  ///
  /// When `true`, videos are played in a randomized order. The original order
  /// is preserved internally and restored when shuffle is turned off.
  ///
  /// Defaults to `false`.
  final bool shuffled;

  /// The delay before auto-advancing to the next video.
  ///
  /// During this time, an "Up Next" overlay is displayed with:
  /// - A countdown timer
  /// - The next video's title and thumbnail
  /// - "Play Now" and "Cancel" buttons
  ///
  /// Defaults to `5 seconds`.
  final Duration advanceDelay;

  /// Creates a new playlist configuration.
  ///
  /// [items] must not be empty. [initialIndex] must be within bounds.
  const PlaylistConfiguration({
    required this.items,
    this.initialIndex = 0,
    this.autoAdvance = true,
    this.repeatMode = PlaylistRepeatMode.none,
    this.shuffled = false,
    this.advanceDelay = const Duration(seconds: 5),
  })  : assert(items.length > 0, 'Playlist must contain at least one item.'),
        assert(
          initialIndex >= 0,
          'initialIndex must be >= 0.',
        );

  /// Returns a copy of this configuration with the specified fields overridden.
  PlaylistConfiguration copyWith({
    List<OmniPlaylistItem>? items,
    int? initialIndex,
    bool? autoAdvance,
    PlaylistRepeatMode? repeatMode,
    bool? shuffled,
    Duration? advanceDelay,
  }) {
    return PlaylistConfiguration(
      items: items ?? this.items,
      initialIndex: initialIndex ?? this.initialIndex,
      autoAdvance: autoAdvance ?? this.autoAdvance,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffled: shuffled ?? this.shuffled,
      advanceDelay: advanceDelay ?? this.advanceDelay,
    );
  }
}
