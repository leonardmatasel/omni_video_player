import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'youtube_webview_controller.dart';

class YouTubeWebViewPlayerView extends StatefulWidget {
  final YouTubeWebViewController controller;

  const YouTubeWebViewPlayerView({super.key, required this.controller});

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
      'color': 'white',
      'controls': 0,
      'disablekb': 1,
      'enablejsapi': 1,
      'fs': 0,
      'hl': 'en',
      'iv_load_policy': 3,
      'modestbranding': 1,
      'origin': 'https://www.youtube-nocookie.com',
      'widget_referrer': "https://www.youtube-nocookie.com",
      'showinfo': 0,
      'autohide': 1,
      'playsinline': 1,
      'rel': 0,
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
      return const Center(child: CircularProgressIndicator());
    }

    return InAppWebView(
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
      ),
      onWebViewCreated: (webViewController) {
        widget.controller.setWebViewController(webViewController);
      },
      onLoadStart: (_, __) => widget.controller.isReady = false,
      onLoadStop: (_, __) => widget.controller.isReady = false,
      onProgressChanged: (_, progress) =>
          widget.controller.isBuffering = progress != 100,
    );
  }
}
