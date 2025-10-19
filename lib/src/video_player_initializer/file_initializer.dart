import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/controllers/default_playback_controller.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:video_player/video_player.dart' show VideoPlayer;

class FileInitializer implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final VideoSourceConfiguration videoSourceConfiguration;

  FileInitializer({
    required this.options,
    required this.callbacks,
    this.globalController,
    required this.videoSourceConfiguration,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    if (kIsWeb) {
      throw Exception(
        "File initializer is not supported on web, see DOC: https://pub.dev/packages/video_player_web",
      );
    }

    final controller = await DefaultPlaybackController.create(
      videoUrl: null,
      dataSource: null,
      file: videoSourceConfiguration.videoFile,
      audioUrl: null,
      isLive: false,
      globalController: globalController,
      initialPosition: videoSourceConfiguration.initialPosition,
      initialVolume: videoSourceConfiguration.initialVolume,
      initialPlaybackSpeed: videoSourceConfiguration.initialPlaybackSpeed,
      callbacks: callbacks,
      type: videoSourceConfiguration.videoSourceType,
      globalKeyPlayer: options.globalKeyInitializer,
      refreshOnUrlReuse: false,
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
  }
}
