import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'package:web/web.dart' as web;

class YoutubePlayerWidget extends StatelessWidget {
  final String videoId;
  final bool autoPlay;
  final bool mute;
  final int start;

  const YoutubePlayerWidget({
    super.key,
    required this.videoId,
    required this.autoPlay,
    required this.mute,
    required this.start,
  });

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    final iframeHtml =
        '''
<iframe 
  width="100%" 
  height="100%" 
  style="border:none;" 
  src="https://www.youtube.com/embed/$videoId?autoplay=${autoPlay ? 1 : 0}&mute=${mute ? 1 : 0}&start=$start" 
  title="YouTube video player" 
  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" 
  referrerpolicy="strict-origin-when-cross-origin" 
  allowfullscreen
></iframe>
''';

    final viewType = 'youtube-embed-$videoId';

    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final div = web.HTMLDivElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.border = 'none'
        ..innerHTML = iframeHtml.toJS;
      return div;
    });

    return HtmlElementView(viewType: viewType);
  }
}
