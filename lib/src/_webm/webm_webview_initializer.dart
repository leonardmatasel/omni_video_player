import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/omni_video_player/controllers/global_playback_controller.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_initializer_factory.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';
import 'package:omni_video_player/src/_webm/webm_webview_player_view.dart';

/// Provides a fallback Web Video player (WebM/MP4) using an InAppWebView-based approach.
/// Useful for formats not natively supported on iOS (like VP8/VP9 WebM).
class WebmVideoWebViewInitializer
    implements IOmniVideoPlayerInitializerStrategy {
  final VideoPlayerConfiguration config;
  final VideoPlayerCallbacks callbacks;
  final GlobalPlaybackController? globalController;
  final VideoSourceConfiguration sourceConfig;
  final String videoUrl;

  const WebmVideoWebViewInitializer({
    required this.config,
    required this.sourceConfig,
    required this.callbacks,
    required this.videoUrl,
    this.globalController,
  });

  @override
  Future<OmniPlaybackController?> initialize() async {
    // Nota: A differenza di YouTube API, non possiamo sapere la dimensione esatta
    // del video prima di caricarlo nella WebView.
    // Impostiamo una dimensione standard 16:9 come placeholder.
    // La WebView con CSS "object-fit: contain" gestirà l'aspect ratio visivo.
    const defaultSize = Size(1280, 720);

    final controller = WebVideoWebViewController(
      duration: Duration(
        seconds: 1,
      ), // La durata verrà aggiornata dall'evento 'Ready' JS
      isLive: false, // Assumiamo false per file statici (mp4/webm)
      size: defaultSize,
      callbacks: callbacks,
      options: config,
      videoUrlStr: videoUrl,
      globalController: globalController,
      globalKeyPlayer: config.globalKeyInitializer,
    );

    // Register hero widget after layout is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.sharedPlayerNotifier.value = Hero(
        tag: config.globalKeyPlayer,
        child: WebVideoWebViewPlayerView(
          key: config.globalKeyPlayer,
          controller: controller,
          customLoader: config.customPlayerWidgets.loadingWidget,
        ),
      );
    });

    return controller;
  }
}
