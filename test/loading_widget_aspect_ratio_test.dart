import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_core/omni_video_player_initializer.dart';

import 'support/platform_channel_stubs.dart';

const _loaderKey = Key('loader');

/// Un loader a tutto campo, come l'anteprima sfocata di una GIF.
final _loader = SizedBox.expand(
  child: Container(key: _loaderKey, color: const Color(0xFF00FF00)),
);

Widget _player({double? customAspectRatioNormal}) => Directionality(
  textDirection: TextDirection.ltr,
  child: OmniVideoPlayerTheme(
    data: OmniVideoPlayerThemeData(),
    child: Center(
      child: SizedBox(
        width: 200,
        height: 400,
        child: OmniVideoPlayerInitializer(
          configuration: VideoPlayerConfiguration(
            videoSourceConfiguration: VideoSourceConfiguration.network(
              videoUrl: Uri.parse('https://example.invalid/portrait.webm'),
            ),
            customPlayerWidgets: CustomPlayerWidgets(loadingWidget: _loader),
            playerUIVisibilityOptions: PlayerUIVisibilityOptions(
              customAspectRatioNormal: customAspectRatioNormal,
            ),
          ),
          callbacks: const VideoPlayerCallbacks(),
          buildPlayer: (_, _, _) => const SizedBox.shrink(),
        ),
      ),
    ),
  ),
);

/// L'init arma un watchdog di prontezza che sopravvive alla fine del test.
/// Si smonta l'albero e si lascia scadere, altrimenti il framework segnala un
/// timer pendente al posto del vero esito.
Future<void> _drainReadinessWatchdog(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 20));
}

void main() {
  setUp(stubVolumeControllerChannel);

  group('loading widget:', () {
    testWidgets(
      'fills the player box while the aspect ratio is still unknown',
      (tester) async {
        await tester.pumpWidget(_player());

        // Prima della correzione erano 200x112.5: il 16/9 di ripiego.
        expect(tester.getSize(find.byKey(_loaderKey)), const Size(200, 400));

        await _drainReadinessWatchdog(tester);
      },
    );

    testWidgets('is boxed to the ratio once that ratio is known', (
      tester,
    ) async {
      await tester.pumpWidget(_player(customAspectRatioNormal: 1));

      expect(tester.getSize(find.byKey(_loaderKey)), const Size(200, 200));

      await _drainReadinessWatchdog(tester);
    });
  });
}
