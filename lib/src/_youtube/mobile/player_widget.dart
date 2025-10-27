import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'controller.dart';

class YoutubeInappwebviewWidget extends StatelessWidget {
  final YoutubeMobilePlaybackController controller;

  const YoutubeInappwebviewWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final html = _playerHtml()
        .replaceAll('<<playerId>>', controller.playerId)
        .replaceAll('<<host>>', 'https://www.youtube-nocookie.com')
        .replaceAll(
          '<<playerVars>>',
          jsonEncode({
            'autoplay': 0,
            'mute': 1,
            'cc_lang_pref': 'en',
            'cc_load_policy': 0,
            'color': 'white',
            'controls': 0,
            'disablekb':
                kIsWeb &&
                    controller
                        .options
                        .playerUIVisibilityOptions
                        .enableForwardGesture &&
                    controller
                        .options
                        .playerUIVisibilityOptions
                        .enableBackwardGesture
                ? 0
                : 1,
            'enablejsapi': 1,
            'fs': 0,
            'hl': 'en',
            'iv_load_policy': 3,
            'modestbranding': 1,
            if (kIsWeb) ...{
              'origin': Uri.base.origin,
              'widget_referrer': Uri.base.origin,
            } else ...{
              'origin': 'https://www.youtube-nocookie.com',
              'widget_referrer': "https://www.youtube-nocookie.com",
            },
            'showinfo': 0,
            'autohide': 1,
            'playsinline': 1,
            'rel': 0,
          }),
        );

    return InAppWebView(
      initialData: InAppWebViewInitialData(
        data: html,
        encoding: 'utf-8',
        baseUrl: WebUri.uri(Uri.https('youtube-nocookie.com')),
        mimeType: 'text/html',
      ),
      initialSettings: InAppWebViewSettings(
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        allowsPictureInPictureMediaPlayback: true,
        allowsAirPlayForMediaPlayback: false,
        disallowOverScroll: true,
        transparentBackground: true,
        disableContextMenu: true,
        supportZoom: false,
        useHybridComposition: true,
      ),
      onWebViewCreated: (webViewController) {
        controller.setWebViewController(webViewController);
      },
    );
  }

  String _playerHtml() => '''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta
      name="viewport"
      content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no"
    />
    <style>
      html {
        width: 100%;
        height: 100%;
        pointer-events: none !important;
      }

      body {
        margin: 0;
        width: 100%;
        height: 100%;
        pointer-events: none !important;
      }

      .embed-container iframe,
      .embed-container object,
      .embed-container embed {
        position: absolute;
        top: 0;
        left: 0;
        width: 100% !important;
        height: 100% !important;
        pointer-events: none !important;
      }
    </style>
    <title>Youtube Player</title>
  </head>

  <body>
    <div class="embed-container">
      <div id="<<playerId>>"></div>
    </div>
    
    <script src="https://www.youtube.com/iframe_api"></script>

    <script>

      var host = "<<host>>";
      var player;
      var timerId;

      var lastVolume = null;
      var lastMuted = null;
      var lastTime = null;

      function onYouTubeIframeAPIReady() {
        player = new YT.Player("<<playerId>>", {
          host: host,
          playerVars: <<playerVars>>,
          events: {
            onReady: function (event) {
              handleFullScreenForMobilePlatform();
              sendMessage('Ready', event);
            },
            onStateChange: function (event) {
              clearTimeout(timerId);
              sendMessage('StateChange', event.data);
              if (event.data == 1) {
                timerId = setInterval(function () {
                  var state = {
                    'currentTime': player.getCurrentTime(),
                    'loadedFraction': player.getVideoLoadedFraction()
                  };

                  sendMessage('VideoState', JSON.stringify(state));
                }, 800);
              }
            },
            onPlaybackQualityChange: function (event) {
              sendMessage('PlaybackQualityChange', event.data);
            },
            onPlaybackRateChange: function (event) {
              sendMessage('PlaybackRateChange', event.data);
            },
            onApiChange: function (event) {
              sendMessage('ApiChange', event.data);
            },
            onError: function (event) {
              sendMessage('PlayerError', event.data);
            },
            onAutoplayBlocked: function (event) {
              sendMessage('AutoplayBlocked', event.data);
            },
            onContentSizeChanged: function (event) {
              sendMessage('onContentSizeChanged', event.data);
            },
          },
        });
        player.setSize(window.innerWidth, window.innerHeight);
      }

      window.addEventListener('message', (event) => {
        try {

          if (typeof event.data !== 'string') return;

          var data = JSON.parse(event.data);

          if (!data) return;

          if(data.function){
            var rawFunction = data.function.replaceAll('<<quote>>', '"');
            var result = eval(rawFunction);

            if(data.key) {
              var message = {}
              message[data.key] = result
              var messageString = JSON.stringify(message);

              event.source.postMessage(messageString , '*');
            }
          }
        } catch (e) { }
      }, false);

      window.onresize = function () {
        player.setSize(window.innerWidth, window.innerHeight);
      };

      function sendMessage(key, data) {
         var message = {};
         message[key] = data;
         message['playerId'] = '<<playerId>>';
         window.flutter_inappwebview.callHandler(key, data);
      }

      function getVideoData() {
        return prepareDataForPlatform(player.getVideoData());
      }

      function getPlaylist() {
        return prepareDataForPlatform(player.getPlaylist());
      }

      function getAvailablePlaybackRates(){
        return prepareDataForPlatform(player.getAvailablePlaybackRates());
      }

      function getPlaybackQuality() {
        return prepareDataForPlatform(player.getPlaybackQuality());
      }

      function getAvailableQualityLevels() {
        return prepareDataForPlatform(player.getAvailableQualityLevels());
      }

      function setPlaybackQuality(quality) {
        return player.setPlaybackQuality(quality);
      }

      function prepareDataForPlatform(data) {
        return data;
      }
      
      function loadById(loadSettings) {
        player.loadVideoById(loadSettings);
        return '';
      }

      function play() { player.playVideo(); return ''; }
      function pause() { player.pauseVideo(); return ''; }
      function seekTo(position, seekAhead) { player.seekTo(position, seekAhead); return ''; }

      function handleFullScreenForMobilePlatform() {
      }
    </script>
  </body>
</html>
  ''';
}
