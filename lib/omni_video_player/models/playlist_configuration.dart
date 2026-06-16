import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';

/// Configuration for a minimal [OmniVideoPlaylist].
///
/// A playlist is an ordered list of [VideoSourceConfiguration]s navigated with
/// previous/next buttons. There is no shuffle and no "repeat one"; set [loop]
/// to wrap around the ends, and [autoAdvance] to move on automatically when a
/// video finishes.
class PlaylistConfiguration {
  /// The ordered videos. Must contain at least one item.
  final List<VideoSourceConfiguration> items;

  /// Index of the first video to play. Clamped into `[0, items.length)`.
  final int initialIndex;

  /// When true, the playlist advances to the next video automatically once the
  /// current one finishes (no countdown UI). Defaults to false (manual only).
  final bool autoAdvance;

  /// When true, previous/next wrap around the ends (repeat-all) and the
  /// navigation buttons never disable. Defaults to false.
  final bool loop;

  const PlaylistConfiguration({
    required this.items,
    this.initialIndex = 0,
    this.autoAdvance = false,
    this.loop = false,
  });
}
