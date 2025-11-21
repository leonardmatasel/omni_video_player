import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'youtube_webview_controller.dart';

class YouTubeWebViewPlayerView extends StatefulWidget {
  final YouTubeWebViewController controller;
  final Widget customLoader;

  const YouTubeWebViewPlayerView({
    super.key,
    required this.controller,
    required this.customLoader,
  });

  @override
  State<YouTubeWebViewPlayerView> createState() =>
      _YouTubeWebViewPlayerViewState();
}

class _YouTubeWebViewPlayerViewState extends State<YouTubeWebViewPlayerView> {
  String? _htmlContent;

  @override
  void initState() {
    super.initState();
    _loadHtmlTemplate();
  }

  /// Loads the HTML template from the package assets and injects dynamic data.
  Future<void> _loadHtmlTemplate() async {
    final rawHtml = await rootBundle.loadString(
      'packages/omni_video_player/assets/youtube_player.html',
    );

    final playerVars = jsonEncode({
      'autoplay': 0,
      'mute': 1,
      'cc_lang_pref': 'en',
      'cc_load_policy': 0,
      'controls': 0,
      'enablejsapi': 1,
      'fs': 0,
      'hl': 'en',
      'iv_load_policy': 3,
      'modestbranding': 1,
      'origin': 'https://www.youtube-nocookie.com',
      'showinfo': 0,
      'playsinline': 1,
      'rel': 0,
      'start': 0,
      'end': 0,
    });

    final html = rawHtml
        .replaceAll('<<playerId>>', widget.controller.playerId)
        .replaceAll('<<host>>', 'https://www.youtube-nocookie.com')
        .replaceAll('<<playerVars>>', playerVars);

    setState(() => _htmlContent = html);
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlContent == null) {
      return Center(child: widget.customLoader);
    }

    return IgnorePointer(
      ignoring: true,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(
          data: _htmlContent!,
          encoding: 'utf-8',
          baseUrl: WebUri.uri(Uri.https('youtube-nocookie.com')),
          mimeType: 'text/html',
        ),
        initialSettings: InAppWebViewSettings(
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          useHybridComposition: true,
          useWideViewPort: false,
          transparentBackground: true,
          disableContextMenu: true,
          supportZoom: false,
          disableHorizontalScroll: false,
          disableVerticalScroll: false,
          allowsAirPlayForMediaPlayback: true,
          allowsPictureInPictureMediaPlayback: true,
          userAgent: '',
        ),
        onWebViewCreated: (webViewController) {
          widget.controller.setWebViewController(webViewController);
        },
        onLoadStart: (_, _) => widget.controller.isReady = false,
        onLoadStop: (_, _) => widget.controller.isReady = false,
        onProgressChanged: (_, progress) =>
            widget.controller.isBuffering = progress != 100,
      ),
    );
  }
}
