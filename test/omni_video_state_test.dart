import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';

void main() {
  group('OmniVideoState', () {
    const a = OmniVideoState(
      isReady: true,
      isPlaying: true,
      position: Duration(seconds: 1),
      duration: Duration(seconds: 10),
      size: Size(16, 9),
    );
    test('value equality + hashCode', () {
      const b = OmniVideoState(
        isReady: true,
        isPlaying: true,
        position: Duration(seconds: 1),
        duration: Duration(seconds: 10),
        size: Size(16, 9),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('copyWith changes one field', () {
      final c = a.copyWith(isPlaying: false);
      expect(c.isPlaying, isFalse);
      expect(c.position, a.position);
      expect(a == c, isFalse);
    });
  });
}
