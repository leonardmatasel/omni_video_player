import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class WebmMagicBytesChecker {
  // Firma EBML (WebM/MKV): [0x1A, 0x45, 0xDF, 0xA3]
  static const List<int> webmSignature = [0x1A, 0x45, 0xDF, 0xA3];

  static bool _verifySignature(List<int> bytes) {
    if (bytes.length < 4) return false;
    for (int i = 0; i < 4; i++) {
      if (bytes[i] != webmSignature[i]) return false;
    }
    return true;
  }

  static Future<bool> isNetworkWebm(String url) async {
    // Fast path: decide from the URL extension with no network round-trip.
    // `uri.path` excludes the query string, so tokens like `?sig=...` don't
    // defeat the check. Only sniff the magic bytes when the extension is
    // inconclusive (e.g. an extensionless streaming URL).
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    if (path.endsWith('.webm') || path.endsWith('.mkv')) return true;
    if (path.endsWith('.mp4') ||
        path.endsWith('.m4v') ||
        path.endsWith('.mov') ||
        path.endsWith('.m3u8') ||
        path.endsWith('.m3u')) {
      return false;
    }

    try {
      // Range request: download only the first 4 bytes to read the signature.
      final response = await http.get(
        Uri.parse(url),
        headers: {'Range': 'bytes=0-3'},
      );
      return _verifySignature(response.bodyBytes);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAssetWebm(String assetPath) async {
    try {
      final data = await rootBundle.load(assetPath);
      final bytes = data.buffer.asUint8List(0, 4);
      return _verifySignature(bytes);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isFileWebm(String filePath) async {
    try {
      final file = File(filePath);
      final bytes = await file.openRead(0, 4).first;
      return _verifySignature(bytes);
    } catch (_) {
      return false;
    }
  }
}
