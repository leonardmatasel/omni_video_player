import 'dart:async';

import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/api/hls_video_api.dart';
import 'package:omni_video_player/src/_others/generic_playback_controller.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:video_player/video_player.dart' show VideoPlayer;

class NetworkInitializer implements IOmniVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration options;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final void Function()? onErrorCallback;
  final VideoSourceConfiguration videoSourceConfiguration;

  NetworkInitializer({
    required this.options,
    required this.callbacks,
    this.globalController,
    this.onErrorCallback,
    required this.videoSourceConfiguration,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    final isHlsVideo = await HlsVideoApi.isHlsUri(
      videoSourceConfiguration.videoUrl!,
    );

    Map<OmniVideoQuality, Uri>? qualitiesMap;
    MapEntry<OmniVideoQuality, Uri>? currentQualityEntry;

    if (isHlsVideo) {
      qualitiesMap = await HlsVideoApi.extractHlsVariantsByQuality(
        videoSourceConfiguration.videoUrl!,
        videoSourceConfiguration.availableQualities,
      );
      currentQualityEntry = HlsVideoApi.selectBestQualityVariant(
        qualitiesMap,
        preferredQualities: videoSourceConfiguration.preferredQualities,
      );
    }

    GenericPlaybackController? controller;

    int attempts = 0;
    while (true) {
      try {
        controller = await GenericPlaybackController.create(
          videoUrl: (currentQualityEntry != null)
              ? currentQualityEntry.value
              : videoSourceConfiguration.videoUrl!,
          dataSource: null,
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
          qualityUrls: qualitiesMap,
          currentVideoQuality: (currentQualityEntry != null)
              ? currentQualityEntry.key
              : null,
        );

        break;
      } catch (e, st) {
        attempts++;
        if (attempts >= 3 || (e is TimeoutException)) {
          rethrow;
        }

        debugPrint(
          'Failed to initialize DefaultPlaybackController (attempt $attempts), retrying in 250ms...\n$e\n$st',
        );
        await Future.delayed(const Duration(milliseconds: 250));
      }
    }

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
