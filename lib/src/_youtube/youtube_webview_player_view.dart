import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'youtube_webview_controller.dart';
import '../../omni_video_player/models/youtube_web_view_configuration.dart';

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

  YoutubeWebViewConfiguration get _webViewConfig =>
      widget.controller.options.videoSourceConfiguration.youtubeWebView;

  /// Whether [uri] is a load the embed legitimately performs, given whether it
  /// targets the main frame. Anything else is treated as a link that navigates
  /// away from the player and is blocked.
  bool _isAllowedNavigation(WebUri? webUri, bool isMainFrame) {
    final uri = webUri;
    if (uri == null) return true;
    final scheme = uri.scheme;
    // Initial / in-memory loads.
    if (scheme.isEmpty || scheme == 'data' || scheme == 'about' || scheme == 'blob') {
      return true;
    }
    final host = uri.host;
    bool hostIs(String h) => host == h || host.endsWith('.$h');

    // The main frame is our static embed page; it must only ever be our
    // youtube-nocookie host. Any other main-frame navigation (e.g. a YouTube
    // watch page busting out of the iframe) is a page change → block.
    if (isMainFrame) {
      return hostIs('youtube-nocookie.com');
    }

    // Sub-frame: allow the embed + its resource hosts.
    if (hostIs('youtube-nocookie.com') ||
        hostIs('googlevideo.com') ||
        hostIs('ytimg.com') ||
        hostIs('gstatic.com') ||
        hostIs('googleapis.com')) {
      return true;
    }
    // On youtube.com sub-frames, allow only the embed/player/API paths; block
    // human-facing pages (/watch, /channel, /@handle, /results, /shorts, home…).
    if (hostIs('youtube.com')) {
      final p = uri.path;
      const allowedPrefixes = [
        '/embed',
        '/youtubei',
        '/s/',
        '/iframe_api',
        '/api/',
        '/generate_204',
      ];
      return allowedPrefixes.any((pre) => p.startsWith(pre));
    }
    // Unknown host inside the player → block.
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadHtmlTemplate();
  }

  /// Loads the HTML template from the package assets and injects dynamic data.
  Future<void> _loadHtmlTemplate() async {
    final native = widget.controller.usesNativeCenterControls;

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
      // Must match the WebView baseUrl origin below (no 'www') for the
      // IFrame API handshake; previously mismatched.
      // 'modestbranding' and 'showinfo' were removed: both are deprecated and
      // ignored by YouTube.
      'origin': 'https://youtube-nocookie.com',
      'playsinline': 1,
      'rel': 0,
    });

    final html = rawHtml
        .replaceAll('<<playerId>>', widget.controller.playerId)
        .replaceAll('<<host>>', 'https://www.youtube-nocookie.com')
        .replaceAll('<<playerVars>>', playerVars)
        .replaceAll('<<pointerEvents>>', native ? 'auto' : 'none');

    setState(() => _htmlContent = html);
  }

  @override
  Widget build(BuildContext context) {
    if (_htmlContent == null) {
      return Center(child: widget.customLoader);
    }

    final native = widget.controller.usesNativeCenterControls;
    return IgnorePointer(
      ignoring: !native, // native mode: iframe interactive (YouTube handles taps)
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
          // Keep texture-based composition (not hybrid): hybrid composition
          // composites the WebView in the native view hierarchy, and with the
          // Flutter controls overlaid on top it forces per-frame texture copies
          // that make YouTube playback stutter.
          useHybridComposition: false,
          useWideViewPort: false,
          transparentBackground: false,
          disableContextMenu: true,
          supportZoom: false,
          disableHorizontalScroll: true,
          disableVerticalScroll: true,
          allowsAirPlayForMediaPlayback: true,
          allowsPictureInPictureMediaPlayback: true,
          userAgent: '',
          useShouldOverrideUrlLoading: true,
          supportMultipleWindows: false,
          javaScriptCanOpenWindowsAutomatically: false,
        ),
        onWebViewCreated: (webViewController) {
          widget.controller.setWebViewController(webViewController);
        },
        // YouTube serves some sub-resources (e.g. video streams) behind certs
        // whose CN doesn't match the host (ERR_CERT_COMMON_NAME_INVALID /
        // net_error -200). Without a handler the WebView stalls on the SSL
        // challenge until it times out, freezing playback. Proceed only for
        // trusted Google/YouTube hosts; cancel anything else so normal TLS
        // validation still applies.
        onReceivedServerTrustAuthRequest: (controller, challenge) async {
          const trustedHosts = [
            'youtube-nocookie.com',
            'youtube.com',
            'google.com',
            'googlevideo.com',
            'ytimg.com',
            'gstatic.com',
            'googleapis.com',
          ];
          final host = challenge.protectionSpace.host;
          final isTrusted = trustedHosts.any(
            (h) => host == h || host.endsWith('.$h'),
          );
          return ServerTrustAuthResponse(
            action: isTrusted
                ? ServerTrustAuthResponseAction.PROCEED
                : ServerTrustAuthResponseAction.CANCEL,
          );
        },
        onLoadStart: (_, _) => widget.controller.isReady = false,
        onLoadStop: (_, _) => widget.controller.isReady = false,
        onProgressChanged: (_, progress) =>
            widget.controller.isBuffering = progress != 100,
        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final uri = navigationAction.request.url;
          final isMainFrame = navigationAction.isForMainFrame;
          if (_isAllowedNavigation(uri, isMainFrame)) {
            return NavigationActionPolicy.ALLOW;
          }
          if (uri != null) _webViewConfig.onExternalLink?.call(uri);
          return NavigationActionPolicy.CANCEL;
        },
        onCreateWindow: (controller, createWindowAction) async {
          final uri = createWindowAction.request.url;
          if (uri != null) _webViewConfig.onExternalLink?.call(uri);
          return false; // block popups
        },
      ),
    );
  }
}
