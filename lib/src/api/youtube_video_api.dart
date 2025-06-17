import 'dart:async';

import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Represents the URLs for both video and audio streams.
class YouTubeStreamUrls {
  final String videoStreamUrl;
  final String audioStreamUrl;

  YouTubeStreamUrls({
    required this.videoStreamUrl,
    required this.audioStreamUrl,
  });
}

class _TimedCacheEntry<T> {
  final Future<T> future;
  final DateTime timestamp;

  _TimedCacheEntry(this.future) : timestamp = DateTime.now();

  bool get isExpired => DateTime.now().difference(timestamp).inMinutes >= 5;
}

/// This service is inspired by the [`pod_player`](https://pub.dev/packages/pod_player) plugin.
///
/// Specifically, it refers to the following implementation (with bug fixes
/// introduced in more recent versions of the `youtube_explode_dart` library):
///
/// https://github.com/newtaDev/pod_player/blob/f3ea20e044d50bac6f35ac408edd65276f534540/lib/src/utils/video_apis.dart#L123
///
/// The applied modifications aim to ensure greater stability and compatibility
/// with the latest versions of the `youtube_explode_dart` package.
class YouTubeService {
  static YoutubeExplode yt = YoutubeExplode();

  /// Clears all cached video and live stream URLs.
  static void clearCache() {
    _videoCache.clear();
    _liveStreamCache.clear();
  }

  static final Map<VideoId, _TimedCacheEntry<YouTubeStreamUrls>> _videoCache =
      {};
  static final Map<VideoId, _TimedCacheEntry<String>> _liveStreamCache = {};

  /// Fetches the HLS URL for a live YouTube stream.
  /// Errors from the underlying `youtube_explode_dart` are rethrown
  /// and should be handled by the caller. No internal logging is performed.
  static Future<String> fetchLiveStreamUrl(VideoId videoId) async {
    final cached = _liveStreamCache[videoId];

    if (cached != null && !cached.isExpired) {
      return cached.future;
    }

    final future = () async {
      try {
        return await retry(() => _getQuietLiveUrl(videoId));
      } catch (_) {
        rethrow;
      }
    }();

    _liveStreamCache[videoId] = _TimedCacheEntry(future);
    return future;
  }

  /// Fetches the best available video and audio stream URLs based on preferences.
  ///
  /// - [videoId]: The ID of the YouTube video.
  /// - [preferredQualities]: A list of preferred video quality levels (e.g., 1080, 720).
  /// - [preferredVideoFormats]: A list of preferred video formats (e.g., mp4, webm).
  /// - [preferredAudioFormats]: A list of preferred audio formats (e.g., mp4a, opus).
  static Future<YouTubeStreamUrls> fetchVideoAndAudioUrls(
    VideoId videoId, {
    List<int>? preferredQualities,
    List<String>? preferredVideoFormats,
    List<String>? preferredAudioFormats,
  }) async {
    final cached = _videoCache[videoId];

    if (cached != null && !cached.isExpired) {
      return cached.future;
    }

    final future = () async {
      try {
        final StreamManifest manifest = await retry(
          () => _getQuietManifest(videoId),
        );

        // Filter video streams based on codec compatibility
        // working with videoPlayer: [avc1, av01, mp4a]
        // NOT working with videoPlayer: [vp09]
        // NOTE: mp4a is the fastest and the ones with a single encoding should be preferred
        final List<VideoStreamInfo> videoStreams = manifest.streams
            .whereType<VideoStreamInfo>()
            .where(
              (VideoStreamInfo it) =>
                  it.videoCodec.isNotEmpty &&
                  !it.codec.parameters['codecs'].toString().contains(
                        'vp09',
                      ) &&
                  it.videoCodec.contains('mp4a'),
            )
            .toList();

        // Filter audio streams based on codec compatibility
        // working with videoPlayer: [mp4a]
        // not working with videoPlayer: [opus]
        // NOTE: prefer mp4a and those with a single encoding
        final List<AudioStreamInfo> audioStreams = manifest.streams
            .whereType<AudioStreamInfo>()
            .where((AudioStreamInfo it) => it.audioCodec.isNotEmpty)
            .where((AudioStreamInfo it) => it.audioCodec.contains('mp4a'))
            .toList();

        // Convert video streams to a list of maps with relevant details
        final List<Map<String, dynamic>> availableVideoStreams = videoStreams
            .map(
              (VideoStreamInfo stream) => <String, Object>{
                'url': stream.url.toString(),
                'format': stream.container.name,
                'videoCodec': stream.codec.parameters['codecs'].toString(),
                'quality': int.tryParse(stream.qualityLabel.split('p')[0]) ?? 0,
                'size': stream.size.totalMegaBytes,
              },
            )
            .where((Map<String, Object> it) => (it['quality']! as int) != 0)
            .toList();

        // Convert audio streams to a list of maps with relevant details
        final List<Map<String, dynamic>> availableAudioStreams = audioStreams
            .map(
              (AudioStreamInfo stream) => <String, Object>{
                'url': stream.url.toString(),
                'format': stream.container.name,
                'audioCodec': stream.codec.parameters['codecs'].toString(),
                'size': stream.size.totalMegaBytes,
              },
            )
            .toList();

        // Sorting video streams: first by size, then by quality, and finally by user preferences
        availableVideoStreams.sort(_sortBySize);
        availableVideoStreams.sort(_sortByQuality);
        availableVideoStreams.sort(
          (a, b) => _sortByQualityPreference(a, b, preferredQualities),
        );
        availableVideoStreams.sort(
          (a, b) => _sortByFormatPreference(
            a['format'] as String,
            b['format'] as String,
            preferredVideoFormats,
          ),
        );

        // Sorting audio streams by size and preferred formats
        availableAudioStreams.sort(_sortBySize);
        availableAudioStreams.sort(
          (a, b) => _sortByFormatPreference(
            a['format'] as String,
            b['format'] as String,
            preferredAudioFormats,
          ),
        );
        /*
        ONLY FOR DEBUG
        print('==============================================');
        print('            Video Stream Information          ');
        print('==============================================');
        print('URL:           ${availableVideoStreams.first['url']}');
        print('Format:        ${availableVideoStreams.first['format']}');
        print('Video Codec:   ${availableVideoStreams.first['videoCodec']}');
        print('Quality:       ${availableVideoStreams.first['quality']}');
        print('Size:          ${availableVideoStreams.first['size']} MB');
        print('==============================================');

        print('==============================================');
        print('            Audio Stream Information          ');
        print('==============================================');
        print('URL:           ${availableAudioStreams.first['url']}');
        print('Format:        ${availableAudioStreams.first['format']}');
        print('Audio Codec:   ${availableAudioStreams.first['audioCodec']}');
        print('Size:          ${availableAudioStreams.first['size']} MB');
        print('==============================================');
        */

        if (availableVideoStreams.isEmpty || availableAudioStreams.isEmpty) {
          throw Exception('No compatible YouTube streams found.');
        }

        return YouTubeStreamUrls(
          videoStreamUrl: availableVideoStreams.isNotEmpty
              ? availableVideoStreams.first['url'] as String
              : '',
          audioStreamUrl: availableAudioStreams.isNotEmpty
              ? availableAudioStreams.first['url'] as String
              : '',
        );
      } catch (error) {
        print('YOUTUBE VIDEO ERROR: $error');
        rethrow;
      }
    }();
    _videoCache[videoId] = _TimedCacheEntry(future);
    return future;
  }

  static Future<bool> isLiveVideoYoutube(VideoId videoId) async {
    final videoMetaData = await retry(() => yt.videos.get(videoId));
    return videoMetaData.isLive;
  }

  static Future<Video> getVideoYoutubeDetails(VideoId videoId) async {
    return await yt.videos.get(videoId);
  }

  /// Helper method to sort streams by file size.
  static int _sortBySize(Map<String, dynamic> a, Map<String, dynamic> b) {
    final double sizeA = a['size'] as double;
    final double sizeB = b['size'] as double;

    return sizeA.compareTo(sizeB);
  }

  /// Helper method to sort streams by video quality.
  static int _sortByQuality(Map<String, dynamic> a, Map<String, dynamic> b) {
    final int qualityA = a['quality'] as int;
    final int qualityB = b['quality'] as int;
    return qualityA.compareTo(qualityB);
  }

  /// Helper method to prioritize preferred video qualities.
  static int _sortByQualityPreference(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    List<int>? qualities,
  ) {
    final int qualityA = a['quality'] as int;
    final int qualityB = b['quality'] as int;

    if (qualities != null && qualities.isNotEmpty) {
      final bool aPreferred = qualities.contains(qualityA);
      final bool bPreferred = qualities.contains(qualityB);
      if (aPreferred && !bPreferred) return -1;
      if (!aPreferred && bPreferred) return 1;
    }
    return 0;
  }

  /// Helper method to prioritize preferred formats.
  static int _sortByFormatPreference(
    String formatA,
    String formatB,
    List<String>? formats,
  ) {
    if (formats != null && formats.isNotEmpty) {
      final bool aPreferred = formats.contains(formatA);
      final bool bPreferred = formats.contains(formatB);
      if (aPreferred && !bPreferred) return -1;
      if (!aPreferred && bPreferred) return 1;
    }
    return 0;
  }

  static Future<String> _getQuietLiveUrl(VideoId id) {
    return runZoned(
      () => yt.videos.streamsClient.getHttpLiveStreamUrl(id),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          // drop any lines that look like retry‑logs
          if (line.toLowerCase().contains('retry')) return;
          parent.print(zone, line);
        },
      ),
    );
  }

  static Future<StreamManifest> _getQuietManifest(VideoId videoId) {
    return runZoned(
      () => yt.videos.streamsClient.getManifest(videoId),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          if (line.toLowerCase().contains('retry')) return;
          parent.print(zone, line);
        },
      ),
    );
  }
}

Future<T> retry<T>(
  Future<T> Function() action, {
  int retries = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  int attempt = 0;
  while (true) {
    try {
      return await action();
    } catch (e) {
      attempt++;
      if (attempt >= retries) rethrow;
      await Future.delayed(delay * attempt);
    }
  }
}
