import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_vimeo/controller.dart';
import 'package:omni_video_player/src/_vimeo/player_widget.dart';
import 'package:omni_video_player/src/api/vimeo_video_api.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/omni_video_player.dart';

class VimeoInitializer implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final VideoSourceConfiguration videoSourceConfiguration;

  VimeoInitializer({
    required this.options,
    this.globalController,
    required this.callbacks,
    required this.videoSourceConfiguration,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final videoId = options.videoSourceConfiguration.videoId!;
    final vimeoVideoInfo = await VimeoVideoApi.fetchVimeoVideoInfo(videoId);

    if (vimeoVideoInfo == null) {
      throw Exception('Failed to fetch Vimeo video info');
    }

    final controller = VimeoPlaybackController.create(
      videoId: videoId,
      globalController: globalController,
      initialPosition: options.videoSourceConfiguration.initialPosition,
      initialVolume: options.videoSourceConfiguration.initialVolume,
      duration: vimeoVideoInfo.duration,
      size: Size(
        vimeoVideoInfo.width.toDouble(),
        vimeoVideoInfo.height.toDouble(),
      ),
      callbacks: callbacks,
      globalKeyPlayer: options.globalKeyInitializer,
      options: options,
    );

    controller.sharedPlayerNotifier.value = Hero(
      tag: options.globalKeyPlayer,
      child: VimeoVideoPlayer(
        key: options.globalKeyPlayer,
        videoId: videoId,
        controller: controller,
        preferredQualities: options.videoSourceConfiguration.preferredQualities,
        autoPlay: options.videoSourceConfiguration.autoPlay,
      ),
    );

    return controller;
  }
}
