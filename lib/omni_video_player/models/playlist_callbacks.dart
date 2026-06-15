import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_item.dart';

/// Callback hooks for responding to playlist-level events in [OmniVideoPlaylist].
///
/// These callbacks complement the per-video [VideoPlayerCallbacks] and provide
/// notifications for playlist navigation, auto-advance, and completion.
///
/// ### Example
/// ```dart
/// PlaylistCallbacks(
///   onVideoChanged: (index, item) {
///     print('Now playing: ${item.title} at index $index');
///   },
///   onPlaylistFinished: () {
///     print('Playlist has ended');
///   },
/// )
/// ```
@immutable
class PlaylistCallbacks {
  /// Called when the active video changes (via next, previous, jumpTo, or auto-advance).
  ///
  /// [index] is the new video's index in the playlist.
  /// [item] is the new [OmniPlaylistItem] being played.
  final void Function(int index, OmniPlaylistItem item)? onVideoChanged;

  /// Called when a video starts playing after initialization.
  ///
  /// [index] is the index of the video that started.
  final void Function(int index)? onVideoStarted;

  /// Called when the playlist reaches its end without looping.
  ///
  /// This fires only when [PlaylistRepeatMode.none] is active and the last
  /// video finishes playback.
  final VoidCallback? onPlaylistFinished;

  /// Called when an individual video item in the playlist finishes playback.
  ///
  /// [index] is the index of the completed video.
  /// [item] is the [OmniPlaylistItem] that finished.
  ///
  /// This fires before auto-advance or repeat logic, so you can use it
  /// to track per-video completion (e.g. analytics, watch history).
  final void Function(int index, OmniPlaylistItem item)? onVideoItemCompleted;

  /// Called just before auto-advancing to the next video.
  ///
  /// [fromIndex] is the index of the video that just finished.
  /// [toIndex] is the index of the next video about to play.
  final void Function(int fromIndex, int toIndex)? onAdvancing;

  /// Called when the repeat mode is changed.
  final void Function(PlaylistRepeatMode mode)? onRepeatModeChanged;

  /// Called when shuffle mode is toggled.
  final void Function(bool isShuffled)? onShuffleToggled;

  /// Creates a new set of playlist callback hooks.
  const PlaylistCallbacks({
    this.onVideoChanged,
    this.onVideoStarted,
    this.onVideoItemCompleted,
    this.onPlaylistFinished,
    this.onAdvancing,
    this.onRepeatModeChanged,
    this.onShuffleToggled,
  });

  /// Returns a new [PlaylistCallbacks] instance with the specified callbacks overridden.
  PlaylistCallbacks copyWith({
    void Function(int index, OmniPlaylistItem item)? onVideoChanged,
    void Function(int index)? onVideoStarted,
    void Function(int index, OmniPlaylistItem item)? onVideoItemCompleted,
    VoidCallback? onPlaylistFinished,
    void Function(int fromIndex, int toIndex)? onAdvancing,
    void Function(PlaylistRepeatMode mode)? onRepeatModeChanged,
    void Function(bool isShuffled)? onShuffleToggled,
  }) {
    return PlaylistCallbacks(
      onVideoChanged: onVideoChanged ?? this.onVideoChanged,
      onVideoStarted: onVideoStarted ?? this.onVideoStarted,
      onVideoItemCompleted: onVideoItemCompleted ?? this.onVideoItemCompleted,
      onPlaylistFinished: onPlaylistFinished ?? this.onPlaylistFinished,
      onAdvancing: onAdvancing ?? this.onAdvancing,
      onRepeatModeChanged: onRepeatModeChanged ?? this.onRepeatModeChanged,
      onShuffleToggled: onShuffleToggled ?? this.onShuffleToggled,
    );
  }
}
