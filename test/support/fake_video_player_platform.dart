import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

/// A stand-in for the `video_player` backend that records every platform call,
/// so a test can assert the order the player really issues them in.
class FakeVideoPlayerPlatform extends VideoPlayerPlatform {
  FakeVideoPlayerPlatform({
    this.seekLatency = const Duration(milliseconds: 30),
  });

  /// How long a seek takes to answer. This is the command Android drops a
  /// `play` behind, so nothing interesting happens when it is instant.
  final Duration seekLatency;

  /// Makes the next `play` fail, the way a dead platform side would.
  bool failPlay = false;

  /// Calls in completion order: `create`, `play`, `pause`, `seek:<ms>`,
  /// `dispose`.
  final List<String> calls = <String>[];

  final List<StreamController<VideoEvent>> _events =
      <StreamController<VideoEvent>>[];
  int _nextPlayerId = 0;

  @override
  Future<void> init() async {}

  @override
  Future<int?> createWithOptions(VideoCreationOptions options) async {
    calls.add('create');

    return _nextPlayerId++;
  }

  @override
  Stream<VideoEvent> videoEventsFor(int playerId) {
    // `initialized` has to be emitted from onListen: sent any earlier there is
    // nobody subscribed yet, and initialize() waits forever.
    late StreamController<VideoEvent> events;
    events = StreamController<VideoEvent>(
      onListen: () => events.add(
        VideoEvent(
          eventType: VideoEventType.initialized,
          duration: const Duration(seconds: 10),
          size: const Size(640, 360),
        ),
      ),
    );
    _events.add(events);

    return events.stream;
  }

  @override
  Future<void> play(int playerId) async {
    if (failPlay) throw StateError('play failed');
    calls.add('play');
  }

  @override
  Future<void> pause(int playerId) async => calls.add('pause');

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    await Future<void>.delayed(seekLatency);
    calls.add('seek:${position.inMilliseconds}');
  }

  @override
  Future<Duration> getPosition(int playerId) async => Duration.zero;

  @override
  Future<void> dispose(int playerId) async => calls.add('dispose');

  @override
  Future<void> setLooping(int playerId, bool looping) async {}

  @override
  Future<void> setVolume(int playerId, double volume) async {}

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {}

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) async {}

  @override
  Widget buildView(int playerId) => const SizedBox.shrink();

  /// Closes the event streams handed out to the players.
  void close() {
    for (final events in _events) {
      events.close();
    }
    _events.clear();
  }
}
