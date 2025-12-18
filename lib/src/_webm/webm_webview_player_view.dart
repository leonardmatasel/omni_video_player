import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';

class WebVideoWebViewPlayerView extends StatefulWidget {
  final WebVideoWebViewController controller;
  final Widget customLoader;

  const WebVideoWebViewPlayerView({
    super.key,
    required this.controller,
    required this.customLoader,
  });

  @override
  State<WebVideoWebViewPlayerView> createState() =>
      _WebVideoWebViewPlayerViewState();
}

class _WebVideoWebViewPlayerViewState extends State<WebVideoWebViewPlayerView> {
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    _loadHtmlTemplate();
  }

  Future<void> _loadHtmlTemplate() async {
    // Carica il template HTML5 creato sopra
    final rawHtml = await rootBundle.loadString(
      'packages/omni_video_player/assets/webm_video_player.html',
    );

    // Inietta l'URL del video
    final html = rawHtml.replaceAll(
      '<<videoUrl>>',
      widget.controller.videoUrlStr,
    );

    setState(() => _htmlContent = html);
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlContent == null) {
      return Center(child: widget.customLoader);
    }

    return IgnorePointer(
      ignoring:
          true, // Imposta a false se vuoi che i controlli nativi HTML funzionino, true se usi overlay Flutter
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: _htmlContent!,
          encoding: 'utf-8',
          mimeType: 'text/html',
        ),
        initialSettings: InAppWebViewSettings(
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true, // Fondamentale per iOS
          useHybridComposition: false,
          useWideViewPort: false,
          transparentBackground: true,
          disableContextMenu: true,
          supportZoom: false,
          disableHorizontalScroll: true,
          disableVerticalScroll: true,
          allowsAirPlayForMediaPlayback: true,
          allowsPictureInPictureMediaPlayback: true,
          allowBackgroundAudioPlaying: false,
        ),
        onWebViewCreated: (webViewController) {
          widget.controller.setWebViewController(webViewController);
        },
      ),
    );
  }
}
