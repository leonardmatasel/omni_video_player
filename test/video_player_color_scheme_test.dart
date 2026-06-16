import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';

void main() {
  group('VideoPlayerColorScheme control button colors', () {
    test(
      'defaults: controlButtonBackground black, controlButtonIcon white',
      () {
        const scheme = VideoPlayerColorScheme();
        expect(scheme.controlButtonBackground, Colors.black);
        expect(scheme.controlButtonIcon, Colors.white);
      },
    );

    test('copyWith overrides control button colors', () {
      const scheme = VideoPlayerColorScheme();
      final updated = scheme.copyWith(
        controlButtonBackground: Colors.deepPurple,
        controlButtonIcon: Colors.amber,
      );
      expect(updated.controlButtonBackground, Colors.deepPurple);
      expect(updated.controlButtonIcon, Colors.amber);
      // Unrelated field unchanged.
      expect(updated.active, scheme.active);
    });
  });

  group('Playlist theme defaults', () {
    test('VideoPlayerIconTheme exposes default skip icons', () {
      const icons = VideoPlayerIconTheme();
      expect(icons.skipNext, Icons.skip_next_rounded);
      expect(icons.skipPrevious, Icons.skip_previous_rounded);
    });

    test('VideoPlayerAccessibilityTheme exposes default track labels', () {
      const accessibility = VideoPlayerAccessibilityTheme();
      expect(accessibility.nextTrackLabel, 'Next video');
      expect(accessibility.previousTrackLabel, 'Previous video');
    });
  });
}
