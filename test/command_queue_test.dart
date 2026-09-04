import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/src/controllers/video_playback_controller.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'support/fake_video_player_platform.dart';

void main() {
  late FakeVideoPlayerPlatform platform;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    platform = FakeVideoPlayerPlatform();
    VideoPlayerPlatform.instance = platform;
  });

  tearDown(() {
    platform.close();
    debugDefaultTargetPlatformOverride = null;
  });

  Future<VideoPlaybackController> newController() async {
    final controller = VideoPlaybackController.uri(
      Uri.parse('https://example.com/v.mp4'),
    );
    await controller.initialize();
    addTearDown(controller.dispose);
    platform.calls.clear();

    return controller;
  }

  test('a play issued on the heels of a seek still lands after it', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final controller = await newController();

    // Exactly how replay() issues them: no await in between.
    final seek = controller.seekTo(const Duration(seconds: 1));
    final play = controller.play();
    await Future.wait([seek, play]);

    // Unqueued, the fast play answers while the seek is still in flight and
    // ExoPlayer drops it: the video rewinds and never resumes.
    expect(platform.calls, ['seek:1000', 'play']);
  });

  test('a burst of seeks collapses to the last position', () async {
    final controller = await newController();

    final first = controller.seekTo(const Duration(seconds: 1));
    final second = controller.seekTo(const Duration(seconds: 2));
    final third = controller.seekTo(const Duration(seconds: 3));
    await Future.wait([first, second, third]);

    // A drag on the progress bar fires one of these per frame: replaying every
    // intermediate position leaves playback trailing the finger.
    expect(platform.calls, ['seek:3000']);
  });

  test('a seek already in flight is never dropped', () async {
    final controller = await newController();

    final running = controller.seekTo(const Duration(seconds: 1));
    await pumpEventQueue(times: 1);
    final queued = controller.seekTo(const Duration(seconds: 2));
    await Future.wait([running, queued]);

    expect(platform.calls, ['seek:1000', 'seek:2000']);
  });

  test(
    'commands are spaced on Android and immediate everywhere else',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final android = await newController();

      final spaced = Stopwatch()..start();
      await android.play();
      await android.pause();
      await android.play();
      spaced.stop();

      // Three commands, three 20ms gaps.
      expect(spaced.elapsedMilliseconds, greaterThan(50));

      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ios = await newController();

      final immediate = Stopwatch()..start();
      await ios.play();
      await ios.pause();
      await ios.play();
      immediate.stop();

      // AVPlayer has no such problem, so it pays nothing for it.
      expect(immediate.elapsedMilliseconds, lessThan(30));
    },
  );

  test('a failing command does not wedge the ones behind it', () async {
    final controller = await newController();

    platform.failPlay = true;
    await expectLater(controller.play(), throwsStateError);
    platform.failPlay = false;

    // Without the queue's own error handling everything queued behind a failed
    // command would wait on a future that never completes.
    await expectLater(controller.pause(), completes);
    expect(platform.calls, ['pause']);
  });

  test('a command on a disposed controller resolves without reaching the '
      'platform', () async {
    final controller = VideoPlaybackController.uri(
      Uri.parse('https://example.com/v.mp4'),
    );
    await controller.initialize();
    await controller.dispose();
    platform.calls.clear();

    await expectLater(controller.play(), completes);
    expect(platform.calls, isEmpty);
  });
}
