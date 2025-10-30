import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_type.dart';
import 'package:omni_video_player/src/_others/asset_initializer.dart';
import 'package:omni_video_player/src/_others/file_initializer.dart';
import 'package:omni_video_player/src/_others/network_initializer.dart';
import 'package:omni_video_player/src/_vimeo/initializer.dart';
import 'package:omni_video_player/src/_youtube/_utils/initializer.dart';
import 'package:omni_video_player/src/_youtube/inappwebview_initializer.dart';

abstract class IVideoPlayerInitializerStrategy {
  Future<OmniPlaybackController?> initialize();
}

class VideoPlayerInitializerFactory {
  static IVideoPlayerInitializerStrategy getStrategy(
    VideoSourceType sourceType,
    VideoSourceConfiguration videoSourceConfiguration,
    VideoPlayerConfiguration options,
    VideoPlayerCallbacks callbacks,
    GlobalPlaybackController? globalController,
  ) {
    switch (sourceType) {
      case VideoSourceType.youtube:
        if (videoSourceConfiguration.forceYoutubeWebViewOnly || kIsWeb) {
          return YouTubeMobileInappwebviewInitializer(
            options: options,
            globalController: globalController,
            callbacks: callbacks,
            videoSourceConfiguration: videoSourceConfiguration,
          );
        } else {
          return YouTubeInitializer(
            options: options,
            globalController: globalController,
            callbacks: callbacks,
            videoSourceConfiguration: videoSourceConfiguration,
          );
        }

      case VideoSourceType.vimeo:
        return VimeoInitializer(
          options: options,
          globalController: globalController,
          callbacks: callbacks,
          videoSourceConfiguration: videoSourceConfiguration,
        );
      case VideoSourceType.network:
        return NetworkInitializer(
          options: options,
          globalController: globalController,
          callbacks: callbacks,
          videoSourceConfiguration: videoSourceConfiguration,
        );
      case VideoSourceType.asset:
        return AssetInitializer(
          options: options,
          globalController: globalController,
          callbacks: callbacks,
          videoSourceConfiguration: videoSourceConfiguration,
        );
      case VideoSourceType.file:
        return FileInitializer(
          options: options,
          globalController: globalController,
          callbacks: callbacks,
          videoSourceConfiguration: videoSourceConfiguration,
        );
    }
  }
}
