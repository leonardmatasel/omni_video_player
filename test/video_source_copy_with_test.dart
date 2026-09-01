import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/omni_video_player.dart';

void main() {
  test('copyWith porta dietro videoFile', () {
    final file = File('/tmp/muted_loop.webm');

    final config = VideoSourceConfiguration.file(
      videoFile: file,
    ).copyWith(autoPlay: true);

    // copyWith non inoltrava videoFile, quindi una config di tipo `file`
    // arrivava a FileInitializer senza file: GenericPlaybackController.create
    // scartava sia il ramo asset sia quello file e moriva sul `videoUrl!`.
    expect(config.videoFile, same(file));
    expect(config.videoSourceType, VideoSourceType.file);
    expect(config.autoPlay, isTrue);
  });

  test('copyWith porta dietro le altre sorgenti', () {
    final url = Uri.parse('https://example.com/v.mp4');

    final network = VideoSourceConfiguration.network(
      videoUrl: url,
    ).copyWith(autoPlay: true);
    expect(network.videoUrl, url);

    final vimeo = VideoSourceConfiguration.vimeo(
      videoId: '123',
    ).copyWith(autoPlay: true);
    expect(vimeo.videoId, '123');

    final asset = VideoSourceConfiguration.asset(
      videoDataSource: 'assets/v.mp4',
    ).copyWith(autoPlay: true);
    expect(asset.videoDataSource, 'assets/v.mp4');
  });
}
