import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;
export 'package:omni_video_player/src/_vimeo/web/web_listener_stub.dart'
    if (dart.library.js_interop) 'package:omni_video_player/src/_vimeo/web/web_listener_web.dart';

class VimeoVideoPlayer extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final bool mute;

  const VimeoVideoPlayer({
    super.key,
    required this.videoId,
    this.autoPlay = false,
    this.mute = false,
  });

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  late final String _viewId;

  @override
  void initState() {
    super.initState();
    // Crea un ID univoco per evitare conflitti se ci sono più video
    _viewId =
        'vimeo-player-${widget.videoId}-${DateTime.now().millisecondsSinceEpoch}';

    // Registra l'iframe nativo
    ui_web.platformViewRegistry.registerViewFactory(_viewId, (int viewId) {
      final iframe = web.HTMLIFrameElement()
        ..src =
            'https://player.vimeo.com/video/${widget.videoId}?autoplay=${widget.autoPlay ? 1 : 0}&muted=${widget.mute ? 1 : 0}&controls=1'
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true
        ..allow = 'autoplay; fullscreen; picture-in-picture';

      return iframe;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewId);
  }
}
