import 'package:flutter/material.dart';

@immutable
class VimeoVideoInfo {
  final String type;
  final String version;
  final String providerName;
  final String providerUrl;
  final String title;
  final String authorName;
  final String authorUrl;
  final String isPlus;
  final String accountType;
  final String html;
  final int width;
  final int height;
  final Duration duration;
  final String description;
  final String thumbnailUrl;
  final int thumbnailWidth;
  final int thumbnailHeight;
  final String thumbnailUrlWithPlayButton;
  final String uploadDate;
  final int videoId;
  final String uri;

  const VimeoVideoInfo({
    required this.type,
    required this.version,
    required this.providerName,
    required this.providerUrl,
    required this.title,
    required this.authorName,
    required this.authorUrl,
    required this.isPlus,
    required this.accountType,
    required this.html,
    required this.width,
    required this.height,
    required this.duration,
    required this.description,
    required this.thumbnailUrl,
    required this.thumbnailWidth,
    required this.thumbnailHeight,
    required this.thumbnailUrlWithPlayButton,
    required this.uploadDate,
    required this.videoId,
    required this.uri,
  });

  factory VimeoVideoInfo.fromJson(Map<String, dynamic> json) {
    return VimeoVideoInfo(
      type: json['type'] as String,
      version: json['version'] as String,
      providerName: json['provider_name'] as String,
      providerUrl: json['provider_url'] as String,
      title: json['title'] as String,
      authorName: json['author_name'] as String,
      authorUrl: json['author_url'] as String,
      isPlus: json['is_plus'] as String,
      accountType: json['account_type'] as String,
      html: json['html'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      duration: Duration(seconds: json['duration'] as int),
      description: json['description'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      thumbnailWidth: json['thumbnail_width'] as int,
      thumbnailHeight: json['thumbnail_height'] as int,
      thumbnailUrlWithPlayButton:
          json['thumbnail_url_with_play_button'] as String,
      uploadDate: json['upload_date'] as String,
      videoId: json['video_id'] as int,
      uri: json['uri'] as String,
    );
  }

  @override
  String toString() {
    return 'VimeoVideoInfo(\n'
        '  type: $type,\n'
        '  version: $version,\n'
        '  providerName: $providerName,\n'
        '  providerUrl: $providerUrl,\n'
        '  title: $title,\n'
        '  authorName: $authorName,\n'
        '  authorUrl: $authorUrl,\n'
        '  isPlus: $isPlus,\n'
        '  accountType: $accountType,\n'
        '  width: $width,\n'
        '  height: $height,\n'
        '  duration: $duration,\n'
        '  description: $description,\n'
        '  thumbnailUrl: $thumbnailUrl,\n'
        '  thumbnailWidth: $thumbnailWidth,\n'
        '  thumbnailHeight: $thumbnailHeight,\n'
        '  uploadDate: $uploadDate,\n'
        '  videoId: $videoId,\n'
        '  uri: $uri\n'
        ')';
  }
}
