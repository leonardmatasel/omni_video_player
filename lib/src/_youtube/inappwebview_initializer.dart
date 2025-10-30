import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_youtube/controller.dart';
import 'package:omni_video_player/src/_youtube/player_widget.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../api/youtube_video_api.dart';

class YouTubeMobileInappwebviewInitializer
    implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  String? videoId;
  final Video? ytVideo;
  final VideoSourceConfiguration videoSourceConfiguration;

  YouTubeMobileInappwebviewInitializer({
    required this.options,
    required this.videoSourceConfiguration,
    required this.callbacks,
    this.videoId,
    this.globalController,
    this.ytVideo,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    videoId =
        videoId ??
        VideoId(videoSourceConfiguration.videoUrl!.toString()).toString();

    final videoSize = await YouTubeService.fetchYouTubeVideoSize(videoId!);
    final Video? videoInfo = kIsWeb
        ? null
        : ytVideo ??
              await YouTubeService.getVideoYoutubeDetails(VideoId(videoId!));

    final controller = YoutubeMobilePlaybackController.fromVideoId(
      videoId: videoId!,
      duration: Duration(seconds: 1),
      isLive: kIsWeb ? false : videoInfo?.isLive ?? false,
      size: videoSize!,
      callbacks: callbacks,
      options: options,
      globalController: globalController,
      autoPlay: videoSourceConfiguration.autoPlay,
      globalKeyPlayer: options.globalKeyInitializer,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      controller.sharedPlayerNotifier.value = Hero(
        tag: options.globalKeyPlayer,
        child: YoutubeInappwebviewWidget(
          key: options.globalKeyPlayer,
          controller: controller,
        ),
      );
    });

    return controller;
  }
}
