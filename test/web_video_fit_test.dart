import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/src/_core/utils/omni_video_fit.dart';

const _probe = Key('probe');

/// Box quadrato 300x300 al centro di uno schermo 800x600.
final _box = Rect.fromCenter(
  center: const Offset(400, 300),
  width: 300,
  height: 300,
);

Widget _webFit(Future<Size> Function() videoSize, BoxFit fit) => MaterialApp(
  home: Center(
    child: SizedBox.fromSize(
      size: _box.size,
      child: OmniWebVideoFit(
        startSize: const Size(640, 360),
        videoSize: videoSize,
        fit: fit,
        child: const SizedBox.expand(key: _probe),
      ),
    ),
  ),
);

void main() {
  testWidgets('cover con la taglia di partenza mentre la richiesta e\' in '
      'corso', (tester) async {
    final pending = Completer<Size>();
    await tester.pumpWidget(_webFit(() => pending.future, BoxFit.cover));

    final rect = tester.getRect(find.byKey(_probe));
    expect(rect.height, moreOrLessEquals(300));
    expect(rect.width, moreOrLessEquals(300 * 16 / 9));
    expect((rect.center - _box.center).distance, lessThan(1e-6));
  });

  testWidgets('contain sta dentro il box', (tester) async {
    final pending = Completer<Size>();
    await tester.pumpWidget(_webFit(() => pending.future, BoxFit.contain));

    final rect = tester.getRect(find.byKey(_probe));
    expect(rect.width, moreOrLessEquals(300));
    expect(rect.height, moreOrLessEquals(300 * 9 / 16));
    expect((rect.center - _box.center).distance, lessThan(1e-6));
  });

  testWidgets('la taglia vera arrivata dopo ricalcola il fit', (tester) async {
    final real = Completer<Size>();
    await tester.pumpWidget(_webFit(() => real.future, BoxFit.cover));

    real.complete(const Size(360, 640));
    await tester.pump();

    final rect = tester.getRect(find.byKey(_probe));
    expect(rect.width, moreOrLessEquals(300));
    expect(rect.height, moreOrLessEquals(300 * 16 / 9));
  });

  testWidgets('una richiesta fallita lascia la taglia di partenza', (
    tester,
  ) async {
    await tester.pumpWidget(
      _webFit(() => Future.error(Exception('offline')), BoxFit.contain),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    final rect = tester.getRect(find.byKey(_probe));
    expect(rect.width, moreOrLessEquals(300));
    expect(rect.height, moreOrLessEquals(300 * 9 / 16));
  });

  testWidgets('la richiesta parte una volta sola fra un rebuild e l\'altro', (
    tester,
  ) async {
    var calls = 0;
    Future<Size> videoSize() {
      calls++;
      return Completer<Size>().future;
    }

    await tester.pumpWidget(_webFit(videoSize, BoxFit.cover));
    await tester.pumpWidget(_webFit(videoSize, BoxFit.contain));

    expect(calls, 1);
  });
}
