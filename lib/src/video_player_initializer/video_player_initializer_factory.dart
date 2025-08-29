import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:omni_video_player/src/video_player_initializer/asset_initializer.dart';
import 'package:omni_video_player/src/video_player_initializer/network_initializer.dart';
import 'package:omni_video_player/src/video_player_initializer/vimeo_initializer.dart';
import 'package:omni_video_player/src/video_player_initializer/youtube_initializer.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/src/video_player_initializer/youtube_web_view_initializer.dart';

abstract class IVideoPlayerInitializerStrategy {
  Future<OmniPlaybackController?> initialize();
}

class VideoPlayerInitializerFactory {
  static IVideoPlayerInitializerStrategy getStrategy(
    VideoSourceType sourceType,
    VideoPlayerConfiguration options,
    VideoPlayerCallbacks callbacks,
    GlobalPlaybackController? globalController,
    VoidCallback onErrorCallback,
  ) {
    switch (sourceType) {
      case VideoSourceType.youtube:
        if (options.videoSourceConfiguration.forceYoutubeWebViewOnly ||
            kIsWeb) {
          return YouTubeWebViewInitializer(
            options: options,
            globalController: globalController,
            onErrorCallback: onErrorCallback,
            callbacks: callbacks,
          );
        } else {
          return YouTubeInitializer(
            options: options,
            globalController: globalController,
            onErrorCallback: onErrorCallback,
            callbacks: callbacks,
          );
        }

      case VideoSourceType.vimeo:
        return VimeoInitializer(
          options: options,
          globalController: globalController,
          onErrorCallback: onErrorCallback,
          callbacks: callbacks,
        );
      case VideoSourceType.network:
        return NetworkInitializer(
          options: options,
          globalController: globalController,
          onErrorCallback: onErrorCallback,
          callbacks: callbacks,
        );
      case VideoSourceType.asset:
        return AssetInitializer(
          options: options,
          globalController: globalController,
          onErrorCallback: onErrorCallback,
          callbacks: callbacks,
        );
    }
  }
}
