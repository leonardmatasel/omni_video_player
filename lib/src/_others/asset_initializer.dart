import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_others/generic_playback_controller.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';

class AssetInitializer implements IOmniVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final VideoSourceConfiguration videoSourceConfiguration;

  AssetInitializer({
    required this.options,
    required this.callbacks,
    this.globalController,
    required this.videoSourceConfiguration,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final controller = await GenericPlaybackController.create(
      videoUrl: null,
      dataSource: videoSourceConfiguration.videoDataSource!,
      file: null,
      audioUrl: null,
      isLive: false,
      globalController: globalController,
      initialPosition: videoSourceConfiguration.initialPosition,
      initialVolume: videoSourceConfiguration.initialVolume,
      initialPlaybackSpeed: videoSourceConfiguration.initialPlaybackSpeed,
      callbacks: callbacks,
      type: videoSourceConfiguration.videoSourceType,
      globalKeyPlayer: options.globalKeyInitializer,
    );

    controller.sharedPlayerNotifier.value = Hero(
      tag: options.globalKeyPlayer,
      child: Video(
        key: options.globalKeyPlayer,
        controller: controller.videoController.videoController,
        fit: BoxFit.contain,
      ),
    );

    callbacks.onControllerCreated?.call(controller);
    return controller;
  }
}
