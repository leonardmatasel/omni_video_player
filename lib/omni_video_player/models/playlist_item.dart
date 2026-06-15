import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';

/// Represents a single video item within an [OmniVideoPlaylist].
///
/// Each item wraps a [VideoSourceConfiguration] with optional display metadata
/// used for playlist UI (title, subtitle, thumbnail).
///
/// ### Example
/// ```dart
/// OmniPlaylistItem(
///   sourceConfiguration: VideoSourceConfiguration.youtube(
///     videoUrl: Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
///   ),
///   title: 'Never Gonna Give You Up',
///   subtitle: 'Rick Astley',
///   thumbnail: NetworkImage('https://img.youtube.com/vi/dQw4w9WgXcQ/0.jpg'),
/// )
/// ```
@immutable
class OmniPlaylistItem {
  /// The video source configuration for this playlist item.
  ///
  /// This defines the video URL, source type, quality preferences,
  /// autoplay settings, etc.
  final VideoSourceConfiguration sourceConfiguration;

  /// Optional title displayed in the playlist panel and "Up Next" overlay.
  final String? title;

  /// Optional subtitle (e.g., channel name, description).
  final String? subtitle;

  /// Optional thumbnail image for the playlist panel.
  ///
  /// If not provided, the player will attempt to load a thumbnail
  /// automatically (e.g., from YouTube or Vimeo APIs).
  final ImageProvider<Object>? thumbnail;

  /// Optional start position for this video.
  ///
  /// Useful for resume-from-position scenarios. If `null`,
  /// the video starts from the beginning (or uses the value from
  /// [sourceConfiguration.initialPosition]).
  final Duration? startPosition;

  /// Creates a new playlist item.
  const OmniPlaylistItem({
    required this.sourceConfiguration,
    this.title,
    this.subtitle,
    this.thumbnail,
    this.startPosition,
  });

  /// Returns a copy of this item with the specified fields overridden.
  OmniPlaylistItem copyWith({
    VideoSourceConfiguration? sourceConfiguration,
    String? title,
    String? subtitle,
    ImageProvider<Object>? thumbnail,
    Duration? startPosition,
  }) {
    return OmniPlaylistItem(
      sourceConfiguration: sourceConfiguration ?? this.sourceConfiguration,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      thumbnail: thumbnail ?? this.thumbnail,
      startPosition: startPosition ?? this.startPosition,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OmniPlaylistItem &&
          runtimeType == other.runtimeType &&
          sourceConfiguration == other.sourceConfiguration &&
          title == other.title &&
          subtitle == other.subtitle &&
          startPosition == other.startPosition;

  @override
  int get hashCode =>
      sourceConfiguration.hashCode ^
      title.hashCode ^
      subtitle.hashCode ^
      startPosition.hashCode;
}
