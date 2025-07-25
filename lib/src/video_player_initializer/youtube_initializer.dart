import 'package:flutter/cupertino.dart';
import 'package:omni_video_player/src/api/youtube_video_api.dart';
import 'package:omni_video_player/src/controllers/default_playback_controller.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:video_player/video_player.dart' show VideoPlayer;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YouTubeInitializer implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final void Function()? onErrorCallback;

  YouTubeInitializer({
    required this.options,
    required this.callbacks,
    this.globalController,
    this.onErrorCallback,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    Uri videoUrl;
    Uri? audioUrl;
    Map<OmniVideoQuality, Uri>? qualityUrls;
    OmniVideoQuality? currentVideoQuality;

    final videoId = VideoId(
      options.videoSourceConfiguration.videoUrl!.toString(),
    );
    try {
      final ytVideo = await YouTubeService.getVideoYoutubeDetails(videoId);
      final isLive = ytVideo.isLive;

      if (isLive) {
        videoUrl = Uri.parse(await YouTubeService.fetchLiveStreamUrl(videoId));
      } else {
        final urls = await YouTubeService.fetchVideoAndAudioUrls(videoId,
            preferredQualities:
                options.videoSourceConfiguration.preferredQualities,
            availableQualities:
                options.videoSourceConfiguration.availableQualities);
        videoUrl = Uri.parse(urls.videoStreamUrl);
        audioUrl = Uri.parse(urls.audioStreamUrl);
        qualityUrls = urls.videoQualityUrls;
        currentVideoQuality = urls.currentQuality;
      }

      final controller = await DefaultPlaybackController.create(
        videoUrl: videoUrl,
        audioUrl: audioUrl,
        dataSource: null,
        isLive: isLive,
        globalController: globalController,
        initialPosition: options.videoSourceConfiguration.initialPosition,
        initialVolume: options.videoSourceConfiguration.initialVolume,
        callbacks: callbacks,
        type: options.videoSourceConfiguration.videoSourceType,
        globalKeyPlayer: options.globalKeyPlayer,
        qualityUrls: qualityUrls,
        currentVideoQuality: currentVideoQuality,
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
