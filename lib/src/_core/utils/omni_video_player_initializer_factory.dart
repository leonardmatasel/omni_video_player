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
import 'package:omni_video_player/src/_vimeo/vimeo_initializer.dart';
import 'package:omni_video_player/src/_webm/webm_magic_bytes_checker.dart';
import 'package:omni_video_player/src/_webm/webm_webview_initializer.dart';
import 'package:omni_video_player/src/_youtube/_utils/youtube_initializer.dart';
import 'package:omni_video_player/src/_youtube/_utils/youtube_webview_initializer.dart';

abstract class IOmniVideoPlayerInitializerStrategy {
  Future<OmniPlaybackController?> initialize();
}

class OmniVideoPlayerInitializerFactory {
  /// Restituisce la strategia di inizializzazione corretta.
  /// È asincrona perché deve poter leggere i byte del file su iOS.
  static Future<IOmniVideoPlayerInitializerStrategy> getStrategy(
    VideoSourceType sourceType,
    VideoSourceConfiguration sourceConfig,
    VideoPlayerConfiguration config,
    VideoPlayerCallbacks callbacks,
    GlobalPlaybackController? globalController,
  ) async {
    final bool isIos = defaultTargetPlatform == TargetPlatform.iOS && !kIsWeb;

    switch (sourceType) {
      case VideoSourceType.youtube:
        if (sourceConfig.forceYoutubeWebViewOnly) {
          return YouTubeWebViewInitializer(
            config: config,
            globalController: globalController,
            callbacks: callbacks,
            sourceConfig: sourceConfig,
          );
        } else {
          return YouTubeInitializer(
            config: config,
            globalController: globalController,
            callbacks: callbacks,
            sourceConfig: sourceConfig,
          );
        }

      case VideoSourceType.vimeo:
        return VimeoInitializer(
          options: config,
          globalController: globalController,
          callbacks: callbacks,
          videoSourceConfiguration: sourceConfig,
        );

      case VideoSourceType.network:
        if (isIos && sourceConfig.videoUrl != null) {
          final isWebm = await WebmMagicBytesChecker.isNetworkWebm(
            sourceConfig.videoUrl!.toString(),
          );
          if (isWebm) {
            return _webVideoWebView(
              config,
              globalController,
              callbacks,
              sourceConfig,
              sourceConfig.videoUrl!.toString(),
            );
          }
        }
        return NetworkInitializer(
          options: config,
          globalController: globalController,
          callbacks: callbacks,
          videoSourceConfiguration: sourceConfig,
        );

      case VideoSourceType.asset:
        return AssetInitializer(
          options: config,
          globalController: globalController,
          callbacks: callbacks,
          videoSourceConfiguration: sourceConfig,
        );

      case VideoSourceType.file:
        return FileInitializer(
          options: config,
          globalController: globalController,
          callbacks: callbacks,
          videoSourceConfiguration: sourceConfig,
        );
    }
  }

  /// Helper per creare l'initializer basato su WebView
  static WebmVideoWebViewInitializer _webVideoWebView(
    VideoPlayerConfiguration config,
    GlobalPlaybackController? globalController,
    VideoPlayerCallbacks callbacks,
    VideoSourceConfiguration sourceConfig,
    String videoUrl,
  ) {
    return WebmVideoWebViewInitializer(
      config: config,
      globalController: globalController,
      callbacks: callbacks,
      sourceConfig: sourceConfig,
      videoUrl: videoUrl,
    );
  }
}
