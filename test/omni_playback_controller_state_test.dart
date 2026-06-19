// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';
import 'package:video_player/video_player.dart';

class _FakeController extends OmniPlaybackController {
  bool _playing = false;

  @override
  bool get isPlaying => _playing;

  void setPlaying(bool v) {
    _playing = v;
    notifyListeners();
  }

  // ── Methods ──────────────────────────────────────────────────────────────

  @override
  Future<void> play({bool useGlobalController = true}) async {}

  @override
  Future<void> pause({bool useGlobalController = true}) async {}

  @override
  Future<void> replay({bool useGlobalController = true}) async {}

  @override
  void toggleMute() {}

  @override
  void mute() {}

  @override
  void unMute() {}

  @override
  void seekTo(Duration position) {}

  @override
  Future<void> switchFullScreenMode(
    BuildContext context, {
    required Widget Function(BuildContext)? pageBuilder,
    void Function(bool)? onToggle,
  }) async {}

  @override
  Future<void> switchQuality(OmniVideoQuality quality) async {}

  @override
  Future<void> setPlaybackSpeed(double speed) async {}

  @override
  void loadVideoSource(VideoSourceConfiguration videoSourceConfiguration) {}

  // ── Identity getters (not deprecated) ────────────────────────────────────

  @override
  Uri? get videoUrl => null;

  @override
  String? get videoDataSource => null;

  @override
  File? get file => null;

  @override
  String? get videoId => null;

  @override
  VideoSourceType get videoSourceType => VideoSourceType.network;

  @override
  ValueNotifier<Widget?> get sharedPlayerNotifier => ValueNotifier(null);

  @override
  bool get isDisposed => false;

  @override
  Map<OmniVideoQuality, Uri>? get videoQualityUrls => null;

  // ── Observable getters (deprecated) ──────────────────────────────────────

  @override
  bool get isReady => false;

  @override
  bool get hasError => false;

  @override
  bool get isBuffering => false;

  @override
  double get volume => 1.0;

  @override
  bool get isMuted => false;

  @override
  bool get isSeeking => false;

  @override
  bool get hasStarted => false;

  @override
  bool get isFullScreen => false;

  @override
  Duration get currentPosition => Duration.zero;

  @override
  bool get isFinished => false;

  @override
  Duration get duration => Duration.zero;

  @override
  int get rotationCorrection => 0;

  @override
  Size get size => Size.zero;

  @override
  List<DurationRange> get buffered => const [];

  @override
  bool get isLive => false;

  @override
  double get playbackSpeed => 1.0;

  @override
  OmniVideoQuality? get currentVideoQuality => null;

  @override
  List<OmniVideoQuality>? get availableVideoQualities => null;

  // ── Setters ───────────────────────────────────────────────────────────────

  @override
  Future<void> setVolume(double value) async {}

  @override
  set isSeeking(bool value) {}

  @override
  bool get wasPlayingBeforeSeek => false;

  @override
  set wasPlayingBeforeSeek(bool value) {}
}

void main() {
  test('state reflects changes and emits once', () {
    final c = _FakeController();
    expect(c.state.value.isPlaying, isFalse);
    var ticks = 0;
    c.state.addListener(() => ticks++);
    c.setPlaying(true);
    expect(c.state.value.isPlaying, isTrue);
    expect(ticks, 1);
    c.notifyListeners(); // no change -> no emit
    expect(ticks, 1);
  });
}
