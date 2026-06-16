import 'package:flutter/foundation.dart';

/// Optional playlist-level callbacks for [OmniVideoPlaylist].
class PlaylistCallbacks {
  /// Called when the current index changes (via next/previous/jumpTo).
  final void Function(int index)? onVideoChanged;

  /// Called when the last video finishes while [PlaylistConfiguration.autoAdvance]
  /// is true and looping is off (i.e. the playlist has played to the end).
  final VoidCallback? onPlaylistCompleted;

  const PlaylistCallbacks({this.onVideoChanged, this.onPlaylistCompleted});
}
