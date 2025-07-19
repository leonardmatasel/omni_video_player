/// Video quality.
enum OmniVideoQuality {
  /// Unknown video quality.
  /// (This should be reported to the project's repo if this is *NOT* a DASH Stream .)
  unknown,

  /// Low quality (144p).
  low144,

  /// Low quality (240p).
  low240,

  /// Medium quality (360p).
  medium360,

  /// Medium quality (480p).
  medium480,

  /// High quality (720p).
  high720,

  /// High quality (1080p).
  high1080,

  /// High quality (1440p).
  high1440,

  /// High quality (2160p).
  high2160,

  /// High quality (2880p).
  high2880,

  /// High quality (3072p).
  high3072,

  /// High quality (4320p).
  high4320
}

extension QString on OmniVideoQuality {
  String get qualityString {
    return switch (this) {
      OmniVideoQuality.unknown => 'Unknown',
      OmniVideoQuality.low144 => '144p',
      OmniVideoQuality.low240 => '240p',
      OmniVideoQuality.medium360 => '360p',
      OmniVideoQuality.medium480 => '480p',
      OmniVideoQuality.high720 => '720p',
      OmniVideoQuality.high1080 => '1080p',
      OmniVideoQuality.high1440 => '1440p',
      OmniVideoQuality.high2160 => '2160p',
      OmniVideoQuality.high2880 => '2880p',
      OmniVideoQuality.high3072 => '3072p',
      OmniVideoQuality.high4320 => '4320p',
    };
  }

  int compareTo(OmniVideoQuality other) {
    //Natural order based on the reverse order of the enums, that is, from the highest to the lowest quality.
    return other.index.compareTo(index);
  }

  /// Static method to convert string to enum
  static OmniVideoQuality fromString(String qualityStr) {
    switch (qualityStr) {
      case '144p':
        return OmniVideoQuality.low144;
      case '240p':
        return OmniVideoQuality.low240;
      case '360p':
        return OmniVideoQuality.medium360;
      case '480p':
        return OmniVideoQuality.medium480;
      case '720p':
        return OmniVideoQuality.high720;
      case '1080p':
        return OmniVideoQuality.high1080;
      case '1440p':
        return OmniVideoQuality.high1440;
      case '2160p':
        return OmniVideoQuality.high2160;
      case '2880p':
        return OmniVideoQuality.high2880;
      case '3072p':
        return OmniVideoQuality.high3072;
      case '4320p':
        return OmniVideoQuality.high4320;
      default:
        return OmniVideoQuality.unknown;
    }
  }
}

OmniVideoQuality omniVideoQualityFromString(String qualityStr) {
  switch (qualityStr) {
    case '144p':
      return OmniVideoQuality.low144;
    case '240p':
      return OmniVideoQuality.low240;
    case '360p':
      return OmniVideoQuality.medium360;
    case '480p':
      return OmniVideoQuality.medium480;
    case '720p':
      return OmniVideoQuality.high720;
    case '1080p':
      return OmniVideoQuality.high1080;
    case '1440p':
      return OmniVideoQuality.high1440;
    case '2160p':
      return OmniVideoQuality.high2160;
    case '2880p':
      return OmniVideoQuality.high2880;
    case '3072p':
      return OmniVideoQuality.high3072;
    case '4320p':
      return OmniVideoQuality.high4320;
    default:
      return OmniVideoQuality.unknown;
  }
}
