import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:omni_video_player/src/_others/generic_playback_controller.dart';
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

  Future<GenericPlaybackController> newController() async {
    final controller = await GenericPlaybackController.create(
      videoUrl: Uri.parse('https://example.com/v.mp4'),
      dataSource: null,
      file: null,
      initialPlaybackSpeed: null,
      callbacks: const VideoPlayerCallbacks(),
      type: VideoSourceType.network,
      globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
    );
    addTearDown(controller.dispose);
    platform.calls.clear();

    return controller;
  }

  test('a replay seeks back to zero off Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final controller = await newController();

    await controller.replay(useGlobalController: false);

    expect(platform.calls, contains('seek:0'));
    expect(platform.calls, isNot(contains('create')));
  });

  test('on Android a replay rebuilds the player instead of seeking', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final controller = await newController();

    await controller.replay(useGlobalController: false);

    // The flush behind a seek can take tens of seconds there; a fresh player
    // starts over with no flush at all.
    expect(platform.calls, contains('create'));
    expect(platform.calls, isNot(contains('seek:0')));
  });

  test('isReplaying covers the window and closes on playback', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final controller = await newController();

    final seen = <bool>[];
    controller.addListener(() => seen.add(controller.isReplaying));

    expect(controller.isReplaying, isFalse);
    await controller.replay(useGlobalController: false);

    // A UI reading isPlaying/isSeeking alone sees a stopped video for all of
    // this window and offers a restart that is already happening.
    expect(seen, contains(true));
    expect(controller.isReplaying, isFalse);
  });
}
