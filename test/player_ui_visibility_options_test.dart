import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';

void main() {
  group('PlayerUIVisibilityOptions.restoreOrientationsAfterFullscreen', () {
    test('defaults to null (previous behavior: restore all orientations)', () {
      const options = PlayerUIVisibilityOptions();
      expect(options.restoreOrientationsAfterFullscreen, isNull);
    });

    test('copyWith sets the orientations to restore on fullscreen exit', () {
      const options = PlayerUIVisibilityOptions();
      final updated = options.copyWith(
        restoreOrientationsAfterFullscreen: const [
          DeviceOrientation.portraitUp,
        ],
      );
      expect(
        updated.restoreOrientationsAfterFullscreen,
        const [DeviceOrientation.portraitUp],
      );
      // Unrelated field is left untouched.
      expect(updated.enableOrientationLock, options.enableOrientationLock);
    });
  });

  group('PlayerUIVisibilityOptions.videoFit', () {
    test('defaults to contain', () {
      expect(const PlayerUIVisibilityOptions().videoFit, BoxFit.contain);
    });

    test('copyWith overrides it and keeps it otherwise', () {
      final cover = const PlayerUIVisibilityOptions().copyWith(
        videoFit: BoxFit.cover,
      );
      expect(cover.videoFit, BoxFit.cover);
      expect(cover.copyWith(enableZoom: true).videoFit, BoxFit.cover);
    });
  });
}
