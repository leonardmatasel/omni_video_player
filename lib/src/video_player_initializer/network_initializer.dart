import 'package:flutter/cupertino.dart';
import 'package:omni_video_player/src/api/hls_video_api.dart';
import 'package:omni_video_player/src/controllers/default_playback_controller.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:video_player/video_player.dart' show VideoPlayer;

class NetworkInitializer implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final void Function()? onErrorCallback;

  NetworkInitializer({
    required this.options,
    required this.callbacks,
    this.globalController,
    this.onErrorCallback,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    try {
      final isHlsVideo = await HlsVideoApi.isHlsUri(
          options.videoSourceConfiguration.videoUrl!);

      Map<OmniVideoQuality, Uri>? qualitiesMap;
      MapEntry<OmniVideoQuality, Uri>? currentQualityEntry;

      if (isHlsVideo) {
        qualitiesMap = await HlsVideoApi.extractHlsVariantsByQuality(
            options.videoSourceConfiguration.videoUrl!,
            options.videoSourceConfiguration.availableQualities);
        currentQualityEntry = HlsVideoApi.selectBestQualityVariant(qualitiesMap,
            preferredQualities:
                options.videoSourceConfiguration.preferredQualities);
      }

      final controller = await DefaultPlaybackController.create(
        videoUrl: (currentQualityEntry != null)
            ? currentQualityEntry.value
            : options.videoSourceConfiguration.videoUrl!,
        dataSource: null,
        audioUrl: null,
        isLive: false,
        globalController: globalController,
        initialPosition: options.videoSourceConfiguration.initialPosition,
        initialVolume: options.videoSourceConfiguration.initialVolume,
        callbacks: callbacks,
        type: options.videoSourceConfiguration.videoSourceType,
        globalKeyPlayer: options.globalKeyPlayer,
        qualityUrls: qualitiesMap,
        currentVideoQuality:
            (currentQualityEntry != null) ? currentQualityEntry.key : null,
      );

      controller.sharedPlayerNotifier.value = Hero(
        tag: options.globalKeyPlayer,
        child: VideoPlayer(
          key: options.globalKeyPlayer,
          controller.videoController,
        ),
      );

      callbacks.onControllerCreated?.call(controller);
      return controller;
    } catch (e) {
      onErrorCallback?.call();
      return null;
    }
  }
}
