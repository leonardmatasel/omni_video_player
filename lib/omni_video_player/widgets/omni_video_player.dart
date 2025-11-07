import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/src/_core/omni_video_player_manager.dart';

/// A configurable and extensible video player supporting multiple video sources.
///
/// Supports YouTube, network URLs, and local videos (other platforms planned).
/// Handles theming, initialization, controller binding, and error display.
class OmniVideoPlayer extends StatelessWidget {
  const OmniVideoPlayer({
    super.key,
    required this.configuration,
    required this.callbacks,
  });

  /// Video playback configuration and source information.
  final VideoPlayerConfiguration configuration;

  /// Callback handlers for player lifecycle and state changes.
  final VideoPlayerCallbacks callbacks;

  @override
  Widget build(BuildContext context) {
    return OmniVideoPlayerManager(
      configuration: configuration,
      callbacks: callbacks,
    );
  }
}
