import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
      debugPrint('Failed to load video info, status: ${response.statusCode}');
      return null;
    }
  }
}
