import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_others/generic_playback_controller.dart';
import 'package:omni_video_player/src/_youtube/_utils/youtube_webview_initializer.dart';
import 'package:omni_video_player/src/api/youtube_video_api.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Handles initialization of YouTube videos using the YouTube Explode API.
/// Falls back to an InAppWebView-based player if needed.
class YouTubeInitializer implements IOmniVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration config;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final VideoSourceConfiguration sourceConfig;

  const YouTubeInitializer({
    required this.config,
    required this.callbacks,
    required this.sourceConfig,
    this.globalController,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final videoId = VideoId(sourceConfig.videoUrl!.toString());

    try {
      final videoInfo = await YouTubeService.getVideoYoutubeDetails(videoId);
      final isLiveStream = videoInfo?.isLive ?? false;

      final streamData = isLiveStream
          ? await _fetchLiveStream(videoId)
          : await _fetchOnDemandStream(videoId);

      final controller = await _buildController(streamData, isLiveStream);

      _maybeFixDuration(controller, streamData.videoUrl.toString());
      _registerSharedPlayer(controller);

      callbacks.onControllerCreated?.call(controller);
      return controller;
    } catch (error, _) {
      debugPrint("YouTube initialization error: $error");

      if (error is VideoUnplayableException) {
        rethrow;
      }

      if (sourceConfig.enableYoutubeWebViewFallback) {
        debugPrint("Fallback: switching to WebView mode...");
        return _initializeWebViewFallback(videoId);
      }

      final refreshed = await config.globalKeyInitializer.currentState
          ?.refresh();
      if (refreshed != true) rethrow;
      return null;
    }
  }

  // ----------------------------------------------------------
  // 🎥 Stream Fetchers
  // ----------------------------------------------------------

  Future<_YouTubeStreamData> _fetchLiveStream(VideoId id) async {
    final url = await YouTubeService.fetchLiveStreamUrl(
      id,
      sourceConfig.timeoutDuration,
    );
    return _YouTubeStreamData(videoUrl: Uri.parse(url));
  }

  Future<_YouTubeStreamData> _fetchOnDemandStream(VideoId id) async {
    final urls = await YouTubeService.fetchVideoAndAudioUrlsCached(
      id,
      timeout: sourceConfig.timeoutDuration,
      preferredQualities: sourceConfig.preferredQualities,
      availableQualities: sourceConfig.availableQualities,
    );

    return _YouTubeStreamData(
      videoUrl: Uri.parse(urls.videoStreamUrl),
      audioUrl: urls.audioStreamUrl != null
          ? Uri.parse(urls.audioStreamUrl!)
          : null,
      qualityUrls: urls.videoQualityUrls,
      currentQuality: urls.currentQuality,
    );
  }

  // ----------------------------------------------------------
  // 🧩 Controller Construction
  // ----------------------------------------------------------

  Future<GenericPlaybackController> _buildController(
    _YouTubeStreamData data,
    bool isLive,
  ) async {
    return GenericPlaybackController.create(
      videoUrl: data.videoUrl,
      audioUrl: data.audioUrl,
      dataSource: null,
      file: null,
      isLive: isLive,
      globalController: globalController,
      initialPosition: sourceConfig.initialPosition,
      initialVolume: sourceConfig.initialVolume,
      initialPlaybackSpeed: sourceConfig.initialPlaybackSpeed,
      callbacks: callbacks,
      type: sourceConfig.videoSourceType,
      globalKeyPlayer: config.globalKeyInitializer,
      qualityUrls: data.qualityUrls,
      currentVideoQuality: data.currentQuality,
    );
  }

  // ----------------------------------------------------------
  // ⚙️ Helpers
  // ----------------------------------------------------------

  void _maybeFixDuration(GenericPlaybackController controller, String url) {
    final duration = _extractDurationFromUrl(url);
    if (duration != null &&
        duration != controller.videoController.value.duration.inSeconds) {
      controller.duration = Duration(seconds: duration.toInt());
    }
  }

  double? _extractDurationFromUrl(String url) {
    final match = RegExp(r"dur=([\d.]+)").firstMatch(url);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }

  void _registerSharedPlayer(GenericPlaybackController controller) {
    controller.sharedPlayerNotifier.value = Hero(
      tag: config.globalKeyPlayer,
      child: VideoPlayer(
        key: config.globalKeyPlayer,
        controller.videoController,
      ),
    );
  }

  Future<OmniPlaybackController?> _initializeWebViewFallback(
    VideoId videoId,
  ) async {
    return YouTubeWebViewInitializer(
      config: config,
      callbacks: callbacks,
      globalController: globalController,
      sourceConfig: sourceConfig,
      videoId: videoId.toString(),
    ).initialize();
  }
}

// ----------------------------------------------------------
// 📦 Internal DTO
// ----------------------------------------------------------

class _YouTubeStreamData {
  final Uri videoUrl;
  final Uri? audioUrl;
  final Map<OmniVideoQuality, Uri>? qualityUrls;
  final OmniVideoQuality? currentQuality;

  const _YouTubeStreamData({
    required this.videoUrl,
    this.audioUrl,
    this.qualityUrls,
    this.currentQuality,
  });
}
