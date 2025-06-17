import 'package:flutter/material.dart';

/// Settings for managing global playback behavior across multiple video players.
///
/// When enabled, these settings ensure exclusive playback control and synchronized mute state
/// for a consistent user experience, especially useful in feed-like interfaces (e.g., stories, reels).
@immutable
class GlobalPlaybackControlSettings {
  /// Enables a global playback controller that enforces only one video playing at a time.
  ///
  /// When `true`, starting playback on a new video will automatically pause any other
  /// currently playing videos within the app.
  ///
  /// This helps prevent audio conflicts and resource overuse in interfaces with multiple videos.
  final bool useGlobalPlaybackController;

  /// Synchronizes the mute state across all video players controlled globally.
  ///
  /// When `true`, muting or unmuting one video will apply the same mute state to
  /// all other videos using the global playback controller.
  ///
  /// **Important:** This setting only takes effect if [useGlobalPlaybackController] is `true`.
  final bool synchronizeMuteAcrossPlayers;

  /// Creates a new [GlobalPlaybackControlSettings] instance.
  ///
  /// Defaults:
  /// - [useGlobalPlaybackController] to `true`
  /// - [synchronizeMuteAcrossPlayers] to `true`
  const GlobalPlaybackControlSettings({
    this.useGlobalPlaybackController = true,
    this.synchronizeMuteAcrossPlayers = true,
  });

  /// Returns a new [GlobalPlaybackControlSettings] instance with specified fields overridden.
  ///
  /// Use this method to copy the current settings while updating only the desired properties.
  ///
  /// Parameters:
  /// - [useGlobalPlaybackController]: Override the global playback controller toggle.
  /// - [synchronizeMuteAcrossPlayers]: Override the mute synchronization toggle.
  GlobalPlaybackControlSettings copyWith({
    bool? useGlobalPlaybackController,
    bool? synchronizeMuteAcrossPlayers,
  }) {
    return GlobalPlaybackControlSettings(
      useGlobalPlaybackController:
          useGlobalPlaybackController ?? this.useGlobalPlaybackController,
      synchronizeMuteAcrossPlayers:
          synchronizeMuteAcrossPlayers ?? this.synchronizeMuteAcrossPlayers,
    );
  }
}
