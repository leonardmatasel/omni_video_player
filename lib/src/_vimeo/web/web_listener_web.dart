// web_listener_web.dart
import 'package:web/web.dart' as web;
import 'dart:js_interop';

void setupWebListener(Function(dynamic) onEvent) {
  web.window.onMessage.listen((event) {
    final data = event.data;

    if (data is JSAny) {
      final dartData = data.dartify();
      if (dartData is Map && dartData['vimeoEvent'] != null) {
        onEvent(dartData['vimeoEvent']);
      }
    }
  });
}
