import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/controllers/vimeo_playback_controller.dart';

/// A Vimeo video player widget using [InAppWebView] for embedding the Vimeo iframe player.
///
/// This widget renders a fullscreen Vimeo video using a WebView with support for
/// playback events such as play, pause, finish, and seek. It also allows you to hook
/// into WebView lifecycle events.
///
/// The video is controlled via a [VimeoPlaybackController], which wraps the internal
/// WebView controller to provide video-related functionality.
///
/// ---
///
/// ### Example usage:
/// ```dart
/// VimeoVideoPlayer(
///   videoId: '123456789',
///   controller: myVimeoController,
///   onReady: () => print('Vimeo is ready!'),
///   onPlay: () => print('Playing...'),
/// )
/// ```
///
/// > **Note:** [videoId] is required and must not be empty.
class VimeoVideoPlayer extends StatefulWidget {
  /// Creates a [VimeoVideoPlayer] instance.
  ///
  /// Requires a non-empty [videoId] and a [VimeoPlaybackController].
  VimeoVideoPlayer({
    super.key,
    required this.videoId,
    required this.controller,
    required this.preferredQualities,
    required this.onError,
    required this.autoPlay,
  }) : assert(videoId.isNotEmpty, 'videoId cannot be empty!');

  /// The Vimeo video ID to be played.
  ///
  /// Example: for `https://vimeo.com/123456789`, the `videoId` is `'123456789'`.
  final String videoId;

  final VoidCallback onError;

  final List<OmniVideoQuality> preferredQualities;

  /// The [VimeoPlaybackController] that manages interaction with the embedded Vimeo player.
  ///
  /// This is required to access internal controls and state.
  final VimeoPlaybackController controller;

  final bool autoPlay;

  @override
  State<VimeoVideoPlayer> createState() => _VimeoVideoPlayerState();
}

class _VimeoVideoPlayerState extends State<VimeoVideoPlayer> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NOTE: Known hot-reload issue with WebView ID reuse:
    // https://github.com/pichillilorenzo/flutter_inappwebview/issues/2504
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (BuildContext context, Widget? child) => InAppWebView(
        initialSettings: InAppWebViewSettings(
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          useHybridComposition: true,
        ),
        initialData: InAppWebViewInitialData(
          data: _buildHtmlContent(),
          baseUrl: WebUri("https://player.vimeo.com"),
        ),
        onConsoleMessage: (controller, consoleMessage) {
          final message = consoleMessage.message;
          debugPrint('Vimeo event: $message');
          if (message.startsWith('vimeo:')) {
            _manageVimeoPlayerEvent(message.split("vimeo:")[1].trim());
          }
        },
        onWebViewCreated: (controller) {
          widget.controller.setWebViewController(controller);
        },
        onLoadStart: (_, __) => widget.controller.isReady = false,
        onLoadStop: (_, __) => widget.controller.isReady = false,
        onReceivedHttpError: (_, __, ___) => widget.onError.call(),
        onCloseWindow: (_) => widget.onError.call(),
        onReceivedError: (_, __, ___) => widget.onError.call(),
        onProgressChanged: (controller, progress) =>
            widget.controller.isBuffering = progress != 100,
      ),
    );
  }

  /// Generates the HTML content embedding the Vimeo iframe player.
  ///
  /// This HTML defines styling and JavaScript event listeners to communicate
  /// player events back to the Flutter side via console logs.
  String _buildHtmlContent() {
    return '''
    <!DOCTYPE html>
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
          html, body {
            margin: 0;
            padding: 0;
            height: 100vh;
            width: auto;
            background-color: black;
          }

          .video-container {
            display: flex;
            align-items: center;
            justify-content: center;
            width: 100%;
            height: 100%;
          }

          iframe {
            width: 100%;
            height: 100%;
            border: none;
          }
        </style>
        <script src="https://player.vimeo.com/api/player.js"></script>
      </head>
      <body>
        <div class="video-container">
          <iframe 
            id="player"
            src="${_buildIframeUrl()}"
          ></iframe>
        </div>
        <script>
          const player = new Vimeo.Player('player');
          player.ready().then(() => console.log('vimeo:onReady'));
          player.on('play', () => console.log('vimeo:onPlay'));
          player.on('pause', () => console.log('vimeo:onPause'));
          player.on('ended', () => console.log('vimeo:onFinish'));
          player.on('seeked', () => console.log('vimeo:onSeek'));
          player.on('error', () => console.log('vimeo:onError'));
        </script>
      </body>
    </html>
  ''';
  }

  /// Constructs the Vimeo iframe URL with player parameters.
  ///
  /// Reference: https://help.vimeo.com/hc/en-us/articles/12426260232977-About-Player-parameters
  String _buildIframeUrl() {
    return 'https://player.vimeo.com/video/${widget.videoId}?'
        'autoplay=${false}'
        '&max_quality=${widget.preferredQualities.first.qualityString}'
        '&loop=${true}'
        '&portrait=${false}'
        '&muted=${false}'
        '&title=${false}'
        '&byline=${false}'
        '&controls=${false}'
        '&dnt=${false}';
  }

  /// Handles playback-related events received from the embedded Vimeo player.
  void _manageVimeoPlayerEvent(String event) {
    switch (event) {
      case 'onReady':
        widget.controller.isReady = true;
        if (widget.controller.hasStarted && widget.autoPlay) {
          widget.controller.play();
        }
        break;
      case 'onPlay':
        widget.controller.isPlaying = true;
        widget.controller.startPositionTimer();
        break;
      case 'onPause':
        widget.controller.isPlaying = false;
        widget.controller.stopPositionTimer();
        break;
      case 'onFinish':
        widget.controller.isPlaying = false;
        break;
      case 'onSeek':
        widget.controller.isSeeking = false;
        if (widget.controller.wasPlayingBeforeSeek) {
          widget.controller.isPlaying = true;
          widget.controller.play();
        }
        break;
      case 'onError':
        widget.onError.call();
        widget.controller.hasError = true;
        break;
    }
  }
}
