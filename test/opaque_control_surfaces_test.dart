import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omni_video_player/src/widgets/opaque_control_surfaces.dart';

void main() {
  group('OpaqueControlSurfaces.of', () {
    testWidgets('returns false when no ancestor is present', (tester) async {
      late bool value;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            value = OpaqueControlSurfaces.of(context);
            return const SizedBox();
          },
        ),
      );
      expect(value, isFalse);
    });

    testWidgets('returns the ancestor opaque value', (tester) async {
      late bool value;
      await tester.pumpWidget(
        OpaqueControlSurfaces(
          opaque: true,
          child: Builder(
            builder: (context) {
              value = OpaqueControlSurfaces.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(value, isTrue);
    });
  });
}
