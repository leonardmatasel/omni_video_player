import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const TwitchSelectorPage(),
    );
  }
}

class TwitchSelectorPage extends StatefulWidget {
  const TwitchSelectorPage({super.key});

  @override
  State<TwitchSelectorPage> createState() => _TwitchSelectorPageState();
}

class _TwitchSelectorPageState extends State<TwitchSelectorPage> {
  String mode = "live"; // live / video / clip

  final TextEditingController liveController = TextEditingController(
    text: "amouranth",
  );

  final TextEditingController vodController = TextEditingController(
    text: "123456789",
  );

  final TextEditingController clipController = TextEditingController(
    text: "AgileDifferentPineapple4Head",
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Twitch Player Selector")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // MODE SELECTOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text("Live"),
                  selected: mode == "live",
                  onSelected: (_) => setState(() => mode = "live"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Video"),
                  selected: mode == "video",
                  onSelected: (_) => setState(() => mode = "video"),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text("Clip"),
                  selected: mode == "clip",
                  onSelected: (_) => setState(() => mode = "clip"),
                ),
              ],
            ),

            const SizedBox(height: 30),

            if (mode == "live") ...[
              TextField(
                controller: liveController,
                decoration: const InputDecoration(labelText: "Nome canale"),
              ),
            ],

            if (mode == "video") ...[
              TextField(
                controller: vodController,
                decoration: const InputDecoration(labelText: "ID Video Twitch"),
              ),
            ],

            if (mode == "clip") ...[
              TextField(
                controller: clipController,
                decoration: const InputDecoration(labelText: "Slug della clip"),
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                String value =
                    (mode == "live")
                        ? liveController.text
                        : (mode == "video")
                        ? vodController.text
                        : clipController.text;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TwitchPlayerPage(mode: mode, value: value),
                  ),
                );
              },
              child: const Text("Apri Player"),
            ),
          ],
        ),
      ),
    );
  }
}

class TwitchPlayerPage extends StatefulWidget {
  final String mode; // live / video / clip
  final String value;

  const TwitchPlayerPage({super.key, required this.mode, required this.value});

  @override
  State<TwitchPlayerPage> createState() => _TwitchPlayerPageState();
}

class _TwitchPlayerPageState extends State<TwitchPlayerPage> {
  InAppWebViewController? webController;

  double currentVolume = 1.0;
  double currentTime = 0.0;

  // HTML DINAMICO
  String twitchHtml() {
    String playerConfig = "";

    if (widget.mode == "live") {
      playerConfig = 'channel: "${widget.value}"';
    } else if (widget.mode == "video") {
      playerConfig = 'video: "${widget.value}"';
    } else {
      playerConfig = 'clip: "${widget.value}"';
    }

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
          controls: false, // <- QUI NASCONDI I CONTROLLI
          parent: ["localhost"]
        });
      }

      // Player Controls
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

  Future<void> _runJS(String js) async {
    if (webController != null) {
      await webController!.evaluateJavascript(source: js);
    }
  }

  Future<void> _updateVolume() async {
    var v = await webController?.evaluateJavascript(source: "getVolume();");
    if (v != null) {
      setState(() {
        currentVolume = double.tryParse(v.toString()) ?? currentVolume;
      });
    }
  }

  Future<void> _updateTime() async {
    var t = await webController?.evaluateJavascript(
      source: "getCurrentTime();",
    );
    if (t != null) {
      setState(() {
        currentTime = double.tryParse(t.toString()) ?? currentTime;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Twitch: ${widget.mode} → ${widget.value}")),

      body: Column(
        children: [
          // PLAYER
          Expanded(
            child: InAppWebView(
              initialData: InAppWebViewInitialData(
                data: twitchHtml(),
                baseUrl: WebUri("http://localhost"),
                encoding: "utf-8",
                mimeType: "text/html",
              ),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                supportZoom: false,
              ),
              onWebViewCreated: (controller) {
                webController = controller;
              },
            ),
          ),

          // CONTROLLER
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // PLAY / PAUSE / MUTE
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => _runJS("playVideo();"),
                      child: const Text("Play"),
                    ),
                    ElevatedButton(
                      onPressed: () => _runJS("pauseVideo();"),
                      child: const Text("Pause"),
                    ),
                    ElevatedButton(
                      onPressed: () => _runJS("muteVideo();"),
                      child: const Text("Mute"),
                    ),
                    ElevatedButton(
                      onPressed: () => _runJS("unmuteVideo();"),
                      child: const Text("Unmute"),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // VOLUME
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        currentVolume = (currentVolume - 0.1).clamp(0.0, 1.0);
                        _runJS("setVolume(${currentVolume.toString()});");
                      },
                      child: const Text("Vol -"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        currentVolume = (currentVolume + 0.1).clamp(0.0, 1.0);
                        _runJS("setVolume(${currentVolume.toString()});");
                      },
                      child: const Text("Vol +"),
                    ),
                    ElevatedButton(
                      onPressed: _updateVolume,
                      child: const Text("Get Vol"),
                    ),
                    Text(
                      "Vol: ${currentVolume.toStringAsFixed(2)}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // SEEK
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () => _runJS("seekVideo(10);"),
                      child: const Text("Seek 10s"),
                    ),
                    ElevatedButton(
                      onPressed: () => _runJS("seekVideo(60);"),
                      child: const Text("Seek 1m"),
                    ),
                    ElevatedButton(
                      onPressed: _updateTime,
                      child: const Text("Get Time"),
                    ),
                    Text(
                      "Time: ${currentTime.toStringAsFixed(1)}s",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
