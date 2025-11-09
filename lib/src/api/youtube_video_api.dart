import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

/// Represents the URLs for both video and audio streams.
class YouTubeStreamUrls {
  final String videoStreamUrl;
  final String? audioStreamUrl;
  final Map<OmniVideoQuality, Uri> videoQualityUrls;
  final OmniVideoQuality currentQuality;

  YouTubeStreamUrls({
    required this.videoStreamUrl,
    required this.audioStreamUrl,
    required this.videoQualityUrls,
    required this.currentQuality,
  });
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
  static YoutubeExplode? yt = kIsWeb ? null : YoutubeExplode();

  static final Map<String, CachedYouTubeStream> _cache = {};

  static Future<YouTubeStreamUrls> fetchVideoAndAudioUrlsCached(
    VideoId videoId, {
    required Duration timeout,
    List<OmniVideoQuality>? preferredQualities,
    List<OmniVideoQuality>? availableQualities,
    List<String>? preferredVideoFormats,
    List<String>? preferredAudioFormats,
  }) async {
    final cached = _cache[videoId.value];
    if (cached != null && cached.isValid) {
      debugPrint('Using cached YouTube stream data');
      return cached.data;
    }

    final urls = await fetchVideoAndAudioUrls(
      videoId,
      timeout: timeout,
      preferredQualities: preferredQualities,
      availableQualities: availableQualities,
      preferredVideoFormats: preferredVideoFormats,
      preferredAudioFormats: preferredAudioFormats,
    );

    _cache[videoId.value] = CachedYouTubeStream(urls);

    return urls;
  }

  /// Fetches the HLS URL for a live YouTube stream.
  /// Errors from the underlying `youtube_explode_dart` are rethrown
  /// and should be handled by the caller. No internal logging is performed.
  static Future<String> fetchLiveStreamUrl(
    VideoId videoId,
    Duration timeout,
  ) async {
    final future = () async {
      try {
        return await retry(() => _getQuietLiveUrl(videoId), timeout: timeout);
      } catch (_) {
        rethrow;
      }
    }();

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
    required Duration timeout,
    List<OmniVideoQuality>? preferredQualities,
    List<OmniVideoQuality>? availableQualities,
    List<String>? preferredVideoFormats,
    List<String>? preferredAudioFormats,
  }) async {
    final future = () async {
      debugPrint(
        'Fetching YouTube video and audio streams with youtube_explode_dart...',
      );
      final StreamManifest manifest = await retry(
        () => _getQuietManifest(videoId),
        timeout: timeout,
      );

      List<VideoStreamInfo> videoStreams = manifest.streams
          .whereType<VideoStreamInfo>()
          .where((it) {
            return it.videoCodec.isNotEmpty && it.videoCodec.contains('avc');
          })
          .toList();

      if (videoStreams.isEmpty) {
        videoStreams = manifest.streams.whereType<MuxedStreamInfo>().where((
          MuxedStreamInfo it,
        ) {
          return it.videoCodec.isNotEmpty && it.videoCodec.contains('avc');
        }).toList();
      }

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
              'framerate': stream.framerate,
              'bitrate': stream.bitrate,
              'videoCodec': stream.codec.parameters['codecs'].toString(),
              'quality': omniVideoQualityFromString(stream.qualityLabel),
              'size': stream.size.totalMegaBytes,
            },
          )
          .where(
            (Map<String, Object> it) =>
                (it['quality']! as OmniVideoQuality) !=
                OmniVideoQuality.unknown,
          )
          .toList();

      availableVideoStreams.sort(_sortByQuality);

      // Convert audio streams to a list of maps with relevant details
      final List<Map<String, dynamic>> availableAudioStreams = audioStreams
          .map((AudioStreamInfo stream) {
            return <String, Object>{
              'url': stream.url.toString(),
              'format': stream.container.name,
              'audioCodec': stream.codec.parameters['codecs'].toString(),
              'bitrate': stream.bitrate,
              'size': stream.size.totalMegaBytes,
            };
          })
          .where(
            (Map<String, Object> it) =>
                (it['audioCodec']! as String).contains("mp4a"),
          )
          .toList();

      // Build a map of quality → Uri for all available qualities
      final Map<OmniVideoQuality, Uri> allQualityMap = {};
      for (final video in availableVideoStreams) {
        try {
          final quality = video['quality'] as OmniVideoQuality;
          final uri = Uri.parse(video['url'] as String);
          allQualityMap[quality] = uri;
        } catch (e) {
          debugPrint('Skipping video stream due to error: $e\n');
        }
      }

      // Filter the map to keep only the requested qualities (preferredQualities)
      Map<OmniVideoQuality, Uri> filteredQualityMap = allQualityMap;
      if (availableQualities != null) {
        filteredQualityMap = {
          for (final q in availableQualities)
            if (allQualityMap.containsKey(q)) q: allQualityMap[q]!,
        };
      }

      // Sorting video streams: first by size, then by quality, and finally by user preferences
      availableVideoStreams.sort(_sortBySize);
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

      if (availableVideoStreams.isEmpty) {
        throw Exception('No compatible YouTube video streams found.');
      }

      debugPrint(
        "Youtube video stream: ${availableVideoStreams.first['quality']} ${availableVideoStreams.first['videoCodec']} ${availableVideoStreams.first['size']} MB ${availableVideoStreams.first['bitrate']} ${availableVideoStreams.first['framerate']}",
      );

      if (availableAudioStreams.isEmpty) {
        throw Exception('No compatible YouTube audio streams found.');
      }

      debugPrint(
        "Youtube audio stream: ${availableAudioStreams.first['bitrate']} ${availableAudioStreams.first['audioCodec']} ${availableAudioStreams.first['size']} MB",
      );

      return YouTubeStreamUrls(
        videoStreamUrl: availableVideoStreams.isNotEmpty
            ? availableVideoStreams.first['url'] as String
            : '',
        audioStreamUrl:
            availableAudioStreams.isNotEmpty &&
                !availableVideoStreams.first['videoCodec'].contains('mp4a')
            ? availableAudioStreams.first['url'] as String
            : null,
        currentQuality:
            availableVideoStreams.first['quality'] as OmniVideoQuality,
        videoQualityUrls: filteredQualityMap,
      );
    }();
    return future;
  }

  static Future<bool> isLiveVideoYoutube(VideoId videoId) async {
    final videoMetaData = await retry(() => yt!.videos.get(videoId));
    return videoMetaData.isLive;
  }

  static Future<Video> getVideoYoutubeDetails(VideoId videoId) async {
    return await yt!.videos.get(videoId);
  }

  /// Helper method to sort streams by file size.
  static int _sortBySize(Map<String, dynamic> a, Map<String, dynamic> b) {
    final double sizeA = a['size'] as double;
    final double sizeB = b['size'] as double;

    return sizeA.compareTo(sizeB);
  }

  /// Helper method to sort streams by video quality.
  static int _sortByQuality(Map<String, dynamic> a, Map<String, dynamic> b) {
    final OmniVideoQuality qualityA = a['quality'] as OmniVideoQuality;
    final OmniVideoQuality qualityB = b['quality'] as OmniVideoQuality;
    return qualityA.compareTo(qualityB);
  }

  /// Helper method to prioritize preferred video qualities.
  static int _sortByQualityPreference(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    List<OmniVideoQuality>? qualities,
  ) {
    final OmniVideoQuality qualityA = a['quality'] as OmniVideoQuality;
    final OmniVideoQuality qualityB = b['quality'] as OmniVideoQuality;

    // If a preferred quality list is provided
    if (qualities != null && qualities.isNotEmpty) {
      final indexA = qualities.indexOf(qualityA);
      final indexB = qualities.indexOf(qualityB);

      final isAPreferred = indexA != -1;
      final isBPreferred = indexB != -1;

      if (isAPreferred && isBPreferred) {
        // Both qualities are in the preferred list: preserve the given order
        return indexA.compareTo(indexB);
      } else if (isAPreferred) {
        // Only A is preferred: it should come first
        return -1;
      } else if (isBPreferred) {
        // Only B is preferred: it should come first
        return 1;
      }

      // Neither is preferred: sort by descending quality (higher index = higher quality)
      return qualityB.index.compareTo(qualityA.index);
    }

    // No preference list: sort all by descending quality
    return qualityB.index.compareTo(qualityA.index);
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
      () => yt!.videos.streamsClient.getHttpLiveStreamUrl(id),
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
      () => yt!.videos.streamsClient.getManifest(
        videoId,
        // FIX BUG youtube_explode_dart of 23/09/25 https://github.com/Hexer10/youtube_explode_dart/issues/361
        ytClients: [YoutubeApiClient.androidVr],
      ),
      zoneSpecification: ZoneSpecification(
        print: (self, parent, zone, line) {
          if (line.toLowerCase().contains('retry')) return;
          parent.print(zone, line);
        },
      ),
    );
  }

  static Future<Size?> fetchYouTubeVideoSize(String videoId) async {
    final url = Uri.parse(
      'https://noembed.com/embed?url=https://www.youtube.com/watch?v=$videoId',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        final width = double.tryParse(jsonData['width'].toString());
        final height = double.tryParse(jsonData['height'].toString());

        if (width != null && height != null) {
          return Size(width, height);
        }
      } else {
        debugPrint(
          'Request of size failed with status: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error fetching video size: $e');
    }

    return null;
  }

  Future<ImageProvider<Object>?> loadYoutubeThumbnail(String? url) async {
    if (url == null) return null;

    final videoId = VideoId(url).value;
    final thumbUrl = "https://i3.ytimg.com/vi/$videoId/sddefault.jpg";

    try {
      final response = await http.head(Uri.parse(thumbUrl));
      if (response.statusCode == 200) return NetworkImage(thumbUrl);
    } catch (_) {
      // silently fail
    }
    return null;
  }
}

Future<T> retry<T>(
  Future<T> Function() action, {
  int retries = 5,
  Duration delay = const Duration(milliseconds: 200),
  Duration timeout = const Duration(seconds: 2),
}) async {
  int attempt = 0;

  final future = () async {
    while (true) {
      try {
        return await action();
      } catch (e) {
        attempt++;
        if (attempt >= retries) rethrow;
        await Future.delayed(delay * attempt);
      }
    }
  }();

  return future.timeout(
    timeout,
    onTimeout: () => throw TimeoutException(
      "Retry block timed out after ${timeout.inSeconds} seconds",
    ),
  );
}

class CachedYouTubeStream {
  final YouTubeStreamUrls data;
  final DateTime cachedAt;

  CachedYouTubeStream(this.data) : cachedAt = DateTime.now();

  bool get isValid => DateTime.now().difference(cachedAt) < Duration(hours: 1);
}
