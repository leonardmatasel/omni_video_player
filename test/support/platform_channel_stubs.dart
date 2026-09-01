import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Neutralizes the platform channels that `GlobalPlaybackController` touches on
/// construction.
///
/// Without this its `_initVolumeListener` calls `getVolume` on a channel with no
/// handler, the cast of the `null` reply throws inside an unawaited future, and
/// the test fails for a reason unrelated to what it is checking.
void stubVolumeControllerChannel({double volume = 0.5}) {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  messenger.setMockMethodCallHandler(
    const MethodChannel('com.kurenai7968.volume_controller.method'),
    (call) async => switch (call.method) {
      'getVolume' => volume,
      _ => null,
    },
  );

  messenger.setMockStreamHandler(
    const EventChannel(
      'com.kurenai7968.volume_controller.volume_listener_event',
    ),
    MockStreamHandler.inline(onListen: (_, _) {}),
  );
}
