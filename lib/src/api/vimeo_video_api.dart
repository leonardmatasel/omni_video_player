import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:omni_video_player/src/utils/logger.dart';

import '../vimeo/model/vimeo_video_info.dart';

class VimeoVideoApi {
  static Future<VimeoVideoInfo?> fetchVimeoVideoInfo(String videoId) async {
    final url = Uri.parse(
      'https://vimeo.com/api/oembed.json?url=https://vimeo.com/$videoId',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      return VimeoVideoInfo.fromJson(jsonData);
    } else {
      logger.e('Failed to load video info, status: ${response.statusCode}');
      return null;
    }
  }

  static Future<Map<String, dynamic>> getSignedUrl(
      String videoId, String token) async {
    final response = await http.get(
      Uri.parse("https://api.vimeo.com/videos/$videoId"),
      headers: {
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final hash = Uri.parse(json['player_embed_url']).queryParameters['h'];
      final width = json['width'];
      final height = json['height'];

      if (hash == null) {
        throw Exception("Hash Vimeo not found into response: ${response.body}");
      }

      return {
        "hash": hash,
        "width": width,
        "height": height,
      };
    } else {
      throw Exception("Error Vimeo API: ${response.body}");
    }
  }
}
