import 'dart:collection';

import 'package:http/http.dart' as http;
import 'package:omni_video_player/omni_video_player/models/omni_video_quality.dart';

/// Utility class for parsing HLS master playlists
class HlsVideoApi {
  static Future<Map<OmniVideoQuality, Uri>> extractHlsVariantsByQuality(
    Uri masterUrl,
    List<OmniVideoQuality>? availableQualities,
  ) async {
    final response = await http.get(masterUrl);

    if (response.statusCode != 200) {
      throw Exception('Failed to load HLS playlist: ${response.statusCode}');
    }

    final lines = response.body.split('\n');

    final variants = SplayTreeMap<OmniVideoQuality, Uri>(
      (a, b) => b.index.compareTo(a.index),
    );

    for (int i = 0; i < lines.length - 1; i++) {
      final line = lines[i].trim();

      if (line.startsWith('#EXT-X-STREAM-INF:')) {
        final resolutionMatch =
            RegExp(r'RESOLUTION=(\d+)x(\d+)').firstMatch(line);
        int? height;
        if (resolutionMatch != null) {
          height = int.tryParse(resolutionMatch.group(2)!);
        }

        final nextLine = lines[i + 1].trim();
        if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
          final resolvedUri = masterUrl.resolve(nextLine);
          final quality = _mapHeightToQuality(height);
          if (quality != OmniVideoQuality.unknown &&
              (availableQualities == null ||
                  availableQualities.contains(quality))) {
            variants[quality] = resolvedUri;
          }
        }
      }
    }

    return variants;
  }

  static OmniVideoQuality _mapHeightToQuality(int? height) {
    if (height == null) return OmniVideoQuality.unknown;

    if (height <= 144) return OmniVideoQuality.low144;
    if (height <= 240) return OmniVideoQuality.low240;
    if (height <= 360) return OmniVideoQuality.medium360;
    if (height <= 480) return OmniVideoQuality.medium480;
    if (height <= 720) return OmniVideoQuality.high720;
    if (height <= 1080) return OmniVideoQuality.high1080;
    if (height <= 1440) return OmniVideoQuality.high1440;
    if (height <= 2160) return OmniVideoQuality.high2160;
    if (height <= 2880) return OmniVideoQuality.high2880;
    if (height <= 3072) return OmniVideoQuality.high3072;
    if (height <= 4320) return OmniVideoQuality.high4320;

    return OmniVideoQuality.unknown;
  }

  static Future<bool> isHlsUri(Uri uri) async {
    try {
      final response = await http.head(uri);
      final contentType = response.headers['content-type'] ?? '';
      return contentType.contains('application/vnd.apple.mpegurl') ||
          contentType.contains('application/x-mpegURL');
    } catch (_) {
      return false;
    }
  }

  static MapEntry<OmniVideoQuality, Uri> selectBestQualityVariant(
    Map<OmniVideoQuality, Uri> qualitiesMap, {
    List<OmniVideoQuality>? preferredQualities,
  }) {
    // 1. Se ho preferenze definite, cerco la prima qualità che esiste nella mappa
    if (preferredQualities != null && preferredQualities.isNotEmpty) {
      for (final preferred in preferredQualities) {
        if (qualitiesMap.containsKey(preferred)) {
          return MapEntry(preferred, qualitiesMap[preferred]!);
        }
      }
    }

    // 2. Nessuna delle preferenze è disponibile, prendo la qualità più alta
    final sorted = qualitiesMap.entries.toList()
      ..sort((a, b) => b.key.index.compareTo(a.key.index)); // decrescente

    return sorted.first;
  }
}
