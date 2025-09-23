import 'package:flutter/cupertino.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/api/youtube_video_api.dart';
import 'package:omni_video_player/src/controllers/default_playback_controller.dart';
import 'package:omni_video_player/src/video_player_initializer/video_player_initializer_factory.dart';
import 'package:omni_video_player/src/video_player_initializer/youtube_web_view_initializer.dart';
import 'package:video_player/video_player.dart' show VideoPlayer;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../api/hls_video_api.dart';
import 'package:omni_video_player/src/utils/logger.dart';

class YouTubeInitializer implements IVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final void Function()? onErrorCallback;
  final VideoSourceConfiguration videoSourceConfiguration;

  YouTubeInitializer({
    required this.options,
    required this.callbacks,
    required this.videoSourceConfiguration,
    this.globalController,
    this.onErrorCallback,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final videoId = VideoId(
      videoSourceConfiguration.videoUrl!.toString(),
    );

    try {
      final ytVideo = await YouTubeService.getVideoYoutubeDetails(videoId);
      final isLive = ytVideo.isLive;
      Map<OmniVideoQuality, Uri>? qualitiesMap;
      MapEntry<OmniVideoQuality, Uri>? currentQualityEntry;

      final streamData = isLive
          ? await _loadLiveStream(
              videoId, videoSourceConfiguration.timeoutDuration)
          : await _loadOnDemandStream(
              videoId, videoSourceConfiguration.timeoutDuration);

      if (isLive) {
        qualitiesMap = await HlsVideoApi.extractHlsVariantsByQuality(
            streamData.videoUrl, videoSourceConfiguration.availableQualities);
        currentQualityEntry = HlsVideoApi.selectBestQualityVariant(qualitiesMap,
            preferredQualities: videoSourceConfiguration.preferredQualities);
      }

      final controller = await _createController(
        videoUrl: streamData.videoUrl,
        audioUrl: streamData.audioUrl,
        isLive: isLive,
        qualityUrls: isLive ? qualitiesMap : streamData.qualityUrls,
        currentQuality:
            isLive ? currentQualityEntry?.key : streamData.currentVideoQuality,
      );

      final duration = _parseYoutubeDuration(streamData.videoUrl.toString());

      if (duration != controller.videoController.value.duration.inSeconds &&
          duration != null) {
        controller.duration = Duration(seconds: duration.toInt());
      }

      _setSharedPlayer(controller);
      callbacks.onControllerCreated?.call(controller);
      return controller;
    } catch (e, _) {
      if (videoSourceConfiguration.enableYoutubeWebViewFallback) {
        logger.d(
            'YouTube stream initialization with youtube_explode_dart failed: ${e.toString()}');
        logger.d("Proceeding with WebView fallback...");
        return await _fallbackToWebView(videoId);
      } else {
        logger.e(
            "YouTube stream with youtube_explode_dart initialization failed: ${e.toString()}");
        onErrorCallback?.call();
        return null;
      }
    }
  }

  Future<_StreamData> _loadLiveStream(VideoId videoId, Duration timeout) async {
    final liveUrl = await YouTubeService.fetchLiveStreamUrl(videoId, timeout);
    return _StreamData(videoUrl: Uri.parse(liveUrl));
  }

  Future<_StreamData> _loadOnDemandStream(
      VideoId videoId, Duration timeout) async {
    final config = videoSourceConfiguration;
    final urls = await YouTubeService.fetchVideoAndAudioUrls(
      videoId,
      timeout: timeout,
      preferredQualities: config.preferredQualities,
      availableQualities: config.availableQualities,
    );

    return _StreamData(
      videoUrl: Uri.parse(urls.videoStreamUrl),
      audioUrl: Uri.parse(urls.audioStreamUrl),
      qualityUrls: urls.videoQualityUrls,
      currentVideoQuality: urls.currentQuality,
    );
  }

  double? _parseYoutubeDuration(String url) {
    final regex = RegExp(r"dur=([\d.]+)");
    final match = regex.firstMatch(url);
    if (match != null) {
      return double.tryParse(match.group(1)!);
    }
    return null;
  }

  Future<DefaultPlaybackController> _createController({
    required Uri videoUrl,
    Uri? audioUrl,
    required bool isLive,
    Map<OmniVideoQuality, Uri>? qualityUrls,
    OmniVideoQuality? currentQuality,
  }) {
    final config = videoSourceConfiguration;

    return DefaultPlaybackController.create(
      videoUrl: videoUrl,
      audioUrl: audioUrl,
      dataSource: null,
      file: null,
      isLive: isLive,
      globalController: globalController,
      initialPosition: config.initialPosition,
      initialVolume: config.initialVolume,
      initialPlaybackSpeed: config.initialPlaybackSpeed,
      callbacks: callbacks,
      type: config.videoSourceType,
      globalKeyPlayer: options.globalKeyInitializer,
      qualityUrls: qualityUrls,
      currentVideoQuality: currentQuality,
    );
  }

  void _setSharedPlayer(DefaultPlaybackController controller) {
    controller.sharedPlayerNotifier.value = Hero(
      tag: options.globalKeyPlayer,
      child: VideoPlayer(
        key: options.globalKeyPlayer,
        controller.videoController,
      ),
    );
  }

  Future<OmniPlaybackController?> _fallbackToWebView(VideoId videoId) async {
    try {
      final ytVideo =
          await YouTubeService.getVideoYoutubeDetails(videoId); // fallback call
      return await YouTubeWebViewInitializer(
        options: options,
        globalController: globalController,
        onErrorCallback: onErrorCallback,
        callbacks: callbacks,
        videoId: videoId.toString(),
        videoSourceConfiguration: videoSourceConfiguration,
        ytVideo: ytVideo, // pass already-fetched video
      ).initialize();
    } catch (_) {
      onErrorCallback?.call();
      return null;
    }
  }
}

// Helper class for stream metadata
class _StreamData {
  final Uri videoUrl;
  final Uri? audioUrl;
  final Map<OmniVideoQuality, Uri>? qualityUrls;
  final OmniVideoQuality? currentVideoQuality;

  _StreamData({
    required this.videoUrl,
    this.audioUrl,
    this.qualityUrls,
    this.currentVideoQuality,
  });
}
