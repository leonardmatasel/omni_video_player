import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_twitch/twitch_controller.dart';
import 'package:omni_video_player/src/_twitch/twitch_player_view.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playback_controller.dart';
import 'package:omni_video_player/omni_video_player/models/video_player_callbacks.dart';

class TwitchInitializer implements IOmniVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final VideoSourceConfiguration videoSourceConfiguration;

  TwitchInitializer({
    required this.options,
    this.globalController,
    required this.callbacks,
    required this.videoSourceConfiguration,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final videoId = videoSourceConfiguration.videoId;
    final channel = videoSourceConfiguration.channelName;

    // Se esiste il channelName => live, altrimenti video VOD
    final isLive = channel != null && channel.isNotEmpty;

    final controller = TwitchController.create(
      videoId: isLive ? channel : videoId!,
      isLive: isLive,
      globalController: globalController,
      initialPosition: videoSourceConfiguration.initialPosition,
      initialVolume: videoSourceConfiguration.initialVolume,
      duration: Duration(seconds: 1),
      size: Size(16, 9),
      callbacks: callbacks,
      globalKeyPlayer: options.globalKeyInitializer,
      options: options,
    );

    controller.sharedPlayerNotifier.value = Hero(
      tag: options.globalKeyInitializer,
      child: Stack(
        children: [
          TwitchPlayerView(
            key: options.globalKeyInitializer,
            videoId: isLive ? channel : videoId!,
            controller: controller,
            preferredQualities: videoSourceConfiguration.preferredQualities,
            autoPlay: videoSourceConfiguration.autoPlay,
          ),
          Container(color: Colors.transparent),
        ],
      ),
    );

    return controller;
  }
}
