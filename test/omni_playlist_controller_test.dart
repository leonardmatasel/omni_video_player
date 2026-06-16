import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player/controllers/omni_playlist_controller.dart';
import 'package:omni_video_player/omni_video_player/models/playlist_configuration.dart';
import 'package:omni_video_player/omni_video_player/models/video_source_configuration.dart';

VideoSourceConfiguration src(String id) => VideoSourceConfiguration.network(
      videoUrl: Uri.parse('https://example.com/$id.mp4'),
    );

PlaylistConfiguration cfg(
  int n, {
  int initialIndex = 0,
  bool loop = false,
  bool autoAdvance = false,
}) =>
    PlaylistConfiguration(
      items: [for (var i = 0; i < n; i++) src('v$i')],
      initialIndex: initialIndex,
      loop: loop,
      autoAdvance: autoAdvance,
    );

void main() {
  group('linear navigation', () {
    test('next/previous walk the queue and report boundaries', () {
      final c = OmniPlaylistController(configuration: cfg(3));
      expect(c.currentIndex, 0);
      expect(c.hasPrevious, false);
      expect(c.hasNext, true);
      expect(c.next(), true);
      expect(c.currentIndex, 1);
      expect(c.next(), true);
      expect(c.currentIndex, 2);
      expect(c.hasNext, false);
      expect(c.next(), false);
      expect(c.currentIndex, 2);
      expect(c.previous(), true);
      expect(c.currentIndex, 1);
    });

    test('jumpTo changes index; out of range throws', () {
      final c = OmniPlaylistController(configuration: cfg(3));
      c.jumpTo(2);
      expect(c.currentIndex, 2);
      expect(() => c.jumpTo(5), throwsRangeError);
    });

    test('currentSource reflects the current item', () {
      final c = OmniPlaylistController(configuration: cfg(2));
      final first = c.currentSource;
      c.next();
      expect(c.currentSource == first, false);
    });
  });

  group('loop', () {
    test('next wraps at end, previous wraps at start, buttons never disable', () {
      final c = OmniPlaylistController(configuration: cfg(3, loop: true));
      expect(c.hasPrevious, true);
      expect(c.hasNext, true);
      c.jumpTo(2);
      expect(c.next(), true);
      expect(c.currentIndex, 0);
      expect(c.previous(), true);
      expect(c.currentIndex, 2);
    });
  });

  group('config invariants', () {
    test('empty playlist throws ArgumentError', () {
      expect(
        () => OmniPlaylistController(
          configuration: const PlaylistConfiguration(items: []),
        ),
        throwsArgumentError,
      );
    });

    test('out-of-range initialIndex is clamped', () {
      final c = OmniPlaylistController(configuration: cfg(3, initialIndex: 99));
      expect(c.currentIndex, 2);
    });
  });

  group('dispose', () {
    test('mutators after dispose do not notify or throw', () {
      final c = OmniPlaylistController(configuration: cfg(3));
      var notified = false;
      c.addListener(() => notified = true);
      c.dispose();
      expect(c.next(), false);
      expect(c.previous(), false);
      c.jumpTo(1);
      expect(notified, false);
    });
  });
}
