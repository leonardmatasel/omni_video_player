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

  tearDown(() => platform.close());

  // The fake player reports 10s.
  Future<GenericPlaybackController> newController({
    Duration? knownDuration,
  }) async {
    final controller = await GenericPlaybackController.create(
      videoUrl: Uri.parse('https://example.com/videoplayback'),
      dataSource: null,
      file: null,
      initialPlaybackSpeed: null,
      callbacks: const VideoPlayerCallbacks(),
      type: VideoSourceType.youtube,
      globalKeyPlayer: GlobalKey<OmniVideoPlayerInitializerState>(),
      qualityUrls: {
        OmniVideoQuality.high720: Uri.parse('https://example.com/720'),
        OmniVideoQuality.medium360: Uri.parse('https://example.com/360'),
      },
      currentVideoQuality: OmniVideoQuality.high720,
      knownDuration: knownDuration,
    );
    addTearDown(controller.dispose);

    return controller;
  }

  test('a known duration survives a quality switch', () async {
    final controller = await newController(
      knownDuration: const Duration(seconds: 5),
    );

    await controller.switchQuality(OmniVideoQuality.medium360);
    await controller.videoController.play();

    expect(controller.duration, const Duration(seconds: 5));
  });

  test('without a known duration the native one is used', () async {
    final controller = await newController();

    await controller.videoController.play();

    expect(controller.duration, const Duration(seconds: 10));
  });

  test('a known duration survives player events', () async {
    final controller = await newController(
      knownDuration: const Duration(seconds: 5),
    );

    await controller.videoController.play();

    expect(controller.duration, const Duration(seconds: 5));
  });
}
