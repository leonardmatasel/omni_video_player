import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_player_controls_overlay.dart';
import 'package:omni_video_player/src/_webm/webm_webview_controller.dart';
import 'package:omni_video_player/src/widgets/indicators/loader_indicator.dart';

import 'support/platform_channel_stubs.dart';

const _loaderKey = Key('custom-loader');

/// Un controller fermo su un seek. Estende il controller WebM perché è quello
/// con il costruttore più semplice: i quaranta membri dell'interfaccia arrivano
/// gratis (stesso trucco di global_playback_exclusivity_test.dart).
class _SeekingController extends WebmVideoWebViewController {
  _SeekingController()
    : super(
        duration: const Duration(seconds: 10),
        isLive: false,
        size: const Size(640, 360),
        callbacks: const VideoPlayerCallbacks(),
        options: VideoPlayerConfiguration(
          videoSourceConfiguration: VideoSourceConfiguration.network(
            videoUrl: Uri.parse('https://example.com/v.webm'),
          ),
        ),
        videoUrlStr: 'https://example.com/v.webm',
        globalController: null,
        globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
        isFile: false,
      );

  @override
  bool get isSeeking => true;
}

VideoPlayerConfiguration _config({
  bool showLoadingWidget = true,
  bool showSeekingIndicator = true,
  bool withCustomLoader = true,
}) => VideoPlayerConfiguration(
  videoSourceConfiguration: VideoSourceConfiguration.network(
    videoUrl: Uri.parse('https://example.com/v.webm'),
  ),
  customPlayerWidgets: withCustomLoader
      ? CustomPlayerWidgets(
          loadingWidget: SizedBox.expand(
            child: Container(key: _loaderKey, color: const Color(0xFF00FF00)),
          ),
        )
      : const CustomPlayerWidgets(),
  playerUIVisibilityOptions: PlayerUIVisibilityOptions(
    showLoadingWidget: showLoadingWidget,
    showSeekingIndicator: showSeekingIndicator,
    showPlayPauseReplayButton: false,
    showVideoBottomControlsBar: false,
    // Evita di far partire il VideoPlayerController di anteprima, assente
    // nell'ambiente di test (nessun binding video_player registrato).
    showScrubbingThumbnailPreview: false,
  ),
);

// Serve un ModalRoute (RouteAwareListener) e un Material ancestor (InkWell
// dei bottoni).
Widget _overlay(VideoPlayerConfiguration config) => MaterialApp(
  home: Scaffold(
    body: OmniVideoPlayerTheme(
      data: OmniVideoPlayerThemeData(),
      child: Center(
        child: SizedBox(
          width: 200,
          height: 200,
          child: OmniVideoPlayerControlsOverlay(
            controller: _SeekingController(),
            configuration: config,
            callbacks: const VideoPlayerCallbacks(),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUp(stubVolumeControllerChannel);

  testWidgets('a seek draws the caller loader, never a spinner of its own', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay(_config()));

    expect(find.byKey(_loaderKey), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('showSeekingIndicator off leaves the seek bare', (tester) async {
    await tester.pumpWidget(_overlay(_config(showSeekingIndicator: false)));

    expect(find.byKey(_loaderKey), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('a seek falls back to the package loader when none is given', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay(_config(withCustomLoader: false)));

    expect(find.byType(LoaderIndicator), findsOneWidget);
  });

  testWidgets('showLoadingWidget off silences the seek loader too', (
    tester,
  ) async {
    await tester.pumpWidget(_overlay(_config(showLoadingWidget: false)));

    expect(find.byKey(_loaderKey), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
