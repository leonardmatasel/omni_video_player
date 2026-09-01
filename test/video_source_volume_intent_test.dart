import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';

VideoSourceConfiguration _network({double? initialVolume}) =>
    VideoSourceConfiguration.network(
      videoUrl: Uri.parse('https://example.com/v.mp4'),
    ).copyWith(initialVolume: initialVolume);

void main() {
  test('senza volume esplicito il volume effettivo è 1.0', () {
    final config = VideoSourceConfiguration.network(
      videoUrl: Uri.parse('https://example.com/v.mp4'),
    );

    expect(config.initialVolume, 1.0);
    expect(config.hasExplicitVolume, isFalse);
  });

  test('un volume esplicito viene ricordato come tale', () {
    final config = _network(initialVolume: 0);

    expect(config.initialVolume, 0);
    expect(config.hasExplicitVolume, isTrue);
  });

  test('anche un volume esplicito pari al default conta come esplicito', () {
    final config = _network(initialVolume: 1.0);

    expect(config.hasExplicitVolume, isTrue);
  });

  test('copyWith senza argomento preserva l\'intenzione', () {
    final config = _network(initialVolume: 0.3).copyWith(autoPlay: true);

    expect(config.initialVolume, 0.3);
    expect(config.hasExplicitVolume, isTrue);
  });

  test(
    'copyWith senza argomento su una config non esplicita resta non esplicita',
    () {
      final config = VideoSourceConfiguration.network(
        videoUrl: Uri.parse('https://example.com/v.mp4'),
      ).copyWith(autoPlay: true);

      expect(config.initialVolume, 1.0);
      expect(config.hasExplicitVolume, isFalse);
    },
  );

  test('l\'intenzione entra in uguaglianza e hash', () {
    final implicit = VideoSourceConfiguration.network(
      videoUrl: Uri.parse('https://example.com/v.mp4'),
    );
    final explicit = _network(initialVolume: 1.0);

    expect(implicit == explicit, isFalse);
    expect(implicit.hashCode == explicit.hashCode, isFalse);
  });
}
