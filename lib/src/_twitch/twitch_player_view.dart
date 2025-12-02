import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_twitch/twitch_controller.dart';

class TwitchPlayerView extends StatelessWidget {
  TwitchPlayerView({
    super.key,
    required this.videoId,
    required this.controller,
    required this.preferredQualities,
    required this.autoPlay,
    this.isLive = true, // true = channel live, false = VOD
  }) : assert(videoId.isNotEmpty, 'videoId cannot be empty!');

  final String videoId;
  final List<OmniVideoQuality> preferredQualities;
  final TwitchController controller;
  final bool autoPlay;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) => InAppWebView(
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          supportZoom: false,
          useHybridComposition: true,
        ),
        initialData: InAppWebViewInitialData(
          data: _buildHtmlContent(),
          baseUrl: WebUri("http://localhost"),
          encoding: "utf-8",
          mimeType: "text/html",
        ),
        onConsoleMessage: (web, msg) async {
          final message = msg.message;
          debugPrint("Twitch event: $message");

          if (message.startsWith('twitch:')) {
            // Se il player è pronto e non è live, recupera la durata
            if (message.contains('onReady') && !isLive) {
              try {
                final durationSec = await web.evaluateJavascript(
                  source: "player.getDuration();",
                );
                if (durationSec != null) {
                  controller.duration = Duration(
                    seconds:
                        double.tryParse(durationSec.toString())?.toInt() ?? 0,
                  );
                }
              } catch (_) {}
            }

            _manageTwitchPlayerEvent(message.split("twitch:")[1].trim());
          }
        },
        onWebViewCreated: (web) {
          controller.setWebViewController(web);
        },
        onLoadStart: (_, __) => controller.isReady = false,
        onLoadStop: (_, __) => controller.isReady = true,
        onProgressChanged: (c, p) => controller.isBuffering = p != 100,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HTML Twitch embed (gestisce sia live che video)
  // ---------------------------------------------------------------------------
  String _buildHtmlContent() {
    final playerConfig = isLive ? 'channel: "$videoId"' : 'video: "$videoId"';

    return """
<!DOCTYPE html>
<html>
  <body style="margin:0; padding:0; overflow:hidden; background:black;">
    <div id="twitch-embed" style="width:100%; height:100%;"></div>

    <script src="https://player.twitch.tv/js/embed/v1.js"></script>

    <script>
      var player = null;

      function loadPlayer() {
        player = new Twitch.Player("twitch-embed", {
          width: "100%",
          height: "100%",
          $playerConfig,
          controls: false,
          autoplay: ${autoPlay ? 'true' : 'false'},
          parent: ["localhost"]
        });

        try {
          player.addEventListener(Twitch.Player.READY, function() { console.log('twitch:onReady'); });
          player.addEventListener(Twitch.Player.PLAY, function() { console.log('twitch:onPlay'); });
          player.addEventListener(Twitch.Player.PAUSE, function() { console.log('twitch:onPause'); });
          player.addEventListener(Twitch.Player.ENDED, function() { console.log('twitch:onFinish'); });
          if (typeof Twitch.Player.SEEK !== 'undefined') {
            player.addEventListener(Twitch.Player.SEEK, function() { console.log('twitch:onSeek'); });
          }
        } catch (e) {
          console.log('twitch:onError');
        }
      }

      function playVideo() { player.play(); }
      function pauseVideo() { player.pause(); }
      function muteVideo() { player.setMuted(true); }
      function unmuteVideo() { player.setMuted(false); }
      function setVolume(v) { player.setVolume(v); }
      function getVolume() { return player.getVolume(); }
      function seekVideo(s) { player.seek(s); }
      function getCurrentTime() { return player.getCurrentTime(); }

      loadPlayer();
    </script>
  </body>
</html>
""";
  }

  // ---------------------------------------------------------------------------
  // Event management
  // ---------------------------------------------------------------------------
  void _manageTwitchPlayerEvent(String event) {
    switch (event) {
      case 'onReady':
        controller.isReady = true;
        if (controller.hasStarted && autoPlay) {
          controller.play();
        }
        break;
      case 'onPlay':
        controller.isPlaying = true;
        controller.startPositionTimer();
        break;
      case 'onPause':
        controller.isPlaying = false;
        controller.stopPositionTimer();
        break;
      case 'onFinish':
        controller.isPlaying = false;
        break;
      case 'onSeek':
        controller.isSeeking = false;
        if (controller.wasPlayingBeforeSeek && !controller.isFinished) {
          controller.isPlaying = true;
          controller.play();
        }
        break;
      case 'onError':
        controller.options.globalKeyInitializer.currentState?.refresh();
        controller.hasError = true;
        break;
    }
  }
}
