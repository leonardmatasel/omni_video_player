import 'package:flutter/material.dart';
import 'package:omni_video_player/omni_video_player.dart';

/// Every source shape against every [BoxFit] and box ratio, to check
/// `videoFit` by eye on device and web.
class VideoFit extends StatefulWidget {
  const VideoFit({super.key});

  @override
  State<VideoFit> createState() => _VideoFitState();
}

typedef _Sample = (String label, VideoSourceConfiguration Function() source);

const _forceWebView = YoutubeWebViewConfiguration(forceWebViewOnly: true);

VideoSourceConfiguration _youtube(String url, {bool webView = false}) =>
    VideoSourceConfiguration.youtube(
      videoUrl: Uri.parse(url),
      webView: webView ? _forceWebView : const YoutubeWebViewConfiguration(),
    );

final List<_Sample> _samples = [
  (
    'YouTube 16:9',
    () => _youtube('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
  ),
  (
    'YouTube 16:9 · WebView',
    () =>
        _youtube('https://www.youtube.com/watch?v=dQw4w9WgXcQ', webView: true),
  ),
  (
    'YouTube 4:3 · WebView',
    () =>
        _youtube('https://www.youtube.com/watch?v=jNQXAC9IVRw', webView: true),
  ),
  (
    'YouTube Short /shorts/ · WebView',
    () => _youtube('https://www.youtube.com/shorts/kwWElKZVCBc', webView: true),
  ),
  (
    'YouTube Short watch?v= · WebView',
    () =>
        _youtube('https://www.youtube.com/watch?v=kwWElKZVCBc', webView: true),
  ),
  (
    'Vimeo (426x240)',
    () => VideoSourceConfiguration.vimeo(videoId: '1017406920'),
  ),
  (
    'webm 2.35:1 (640x272)',
    () => VideoSourceConfiguration.network(
      videoUrl: Uri.parse('https://media.w3.org/2010/05/sintel/trailer.webm'),
    ),
  ),
  (
    'webm 16:9 (640x360)',
    () => VideoSourceConfiguration.network(
      videoUrl: Uri.parse(
        'https://wiki.yoctoproject.org/wiki/images/a/a6/Big-buck-bunny_trailer.webm',
      ),
    ),
  ),
  (
    'mp4 16:9 (320x176)',
    () => VideoSourceConfiguration.network(
      videoUrl: Uri.parse('https://www.w3schools.com/tags/mov_bbb.mp4'),
    ),
  ),
  (
    'mp4 verticale 9:16 (asset 360x640)',
    () => VideoSourceConfiguration.asset(
      videoDataSource: 'assets/portrait_9x16.mp4',
    ),
  ),
  (
    'HLS 4:3 (400x300)',
    () => VideoSourceConfiguration.network(
      videoUrl: Uri.parse(
        'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8',
      ),
    ),
  ),
];

const Map<String, double?> _ratios = {
  'auto': null,
  '1:1': 1,
  '9:16': 9 / 16,
  '16:9': 16 / 9,
  '4:3': 4 / 3,
};

class _VideoFitState extends State<VideoFit> {
  int _sample = 0;
  BoxFit _fit = BoxFit.cover;
  String _ratio = '1:1';
  bool _autoFullScreen = false;

  @override
  Widget build(BuildContext context) {
    final ratio = _ratios[_ratio];
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<int>(
                value: _sample,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                items: [
                  for (var i = 0; i < _samples.length; i++)
                    DropdownMenuItem(value: i, child: Text(_samples[i].$1)),
                ],
                onChanged: (v) => setState(() => _sample = v!),
              ),
              DropdownButton<BoxFit>(
                value: _fit,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                items: [
                  for (final f in BoxFit.values)
                    DropdownMenuItem(value: f, child: Text(f.name)),
                ],
                onChanged: (v) => setState(() => _fit = v!),
              ),
              DropdownButton<String>(
                value: _ratio,
                dropdownColor: Colors.grey[800],
                style: const TextStyle(color: Colors.white),
                items: [
                  for (final r in _ratios.keys)
                    DropdownMenuItem(value: r, child: Text('box $r')),
                ],
                onChanged: (v) => setState(() => _ratio = v!),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch(
                    value: _autoFullScreen,
                    onChanged: (v) => setState(() => _autoFullScreen = v),
                  ),
                  const Text(
                    'autoFullScreenAtStart',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // A new key per combination: the player re-initializes from scratch.
          OmniVideoPlayer(
            key: ValueKey((_sample, _fit, _ratio, _autoFullScreen)),
            callbacks: const VideoPlayerCallbacks(),
            configuration: VideoPlayerConfiguration(
              videoSourceConfiguration: _samples[_sample].$2().copyWith(
                autoFullScreenAtStart: _autoFullScreen,
              ),
              playerUIVisibilityOptions: PlayerUIVisibilityOptions().copyWith(
                videoFit: _fit,
                customAspectRatioNormal: ratio,
                customAspectRatioFullScreen: ratio,
                enableZoom: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
