import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:screen_border/screen_border.dart';

void main() {
  tearDown(ScreenCornerRadius.debugReset);

  group('ScreenCornerRadius.resolve', () {
    test('keeps per-corner dp values on Android 12+', () {
      final radius = ScreenCornerRadius.resolve(
        topLeft: 36,
        topRight: 42,
        bottomLeft: 42,
        bottomRight: 36,
        androidSdkInt: 34,
        // Android 12+ already reports dp; the pixel ratio must not scale them.
        devicePixelRatio: 3.0,
      );

      expect(radius.topLeft.x, 36);
      expect(radius.topRight.x, 42);
      expect(radius.bottomLeft.x, 42);
      expect(radius.bottomRight.x, 36);
    });

    test('converts the legacy Android px fallback to logical pixels', () {
      final radius = ScreenCornerRadius.resolve(
        topLeft: 99,
        topRight: 99,
        bottomLeft: 99,
        bottomRight: 99,
        androidSdkInt: 30,
        devicePixelRatio: 2.75,
      );

      expect(radius.topLeft.x, closeTo(36, 0.001));
      expect(radius.topRight.x, closeTo(36, 0.001));
      expect(radius.bottomLeft.x, closeTo(36, 0.001));
      expect(radius.bottomRight.x, closeTo(36, 0.001));
    });

    test('does not scale iOS radii', () {
      final radius = ScreenCornerRadius.resolve(
        topLeft: 47.33,
        topRight: 47.33,
        bottomLeft: 47.33,
        bottomRight: 47.33,
        devicePixelRatio: 3.0,
      );

      expect(radius.topLeft.x, closeTo(47.33, 0.001));
    });

    test('defaults to BorderRadius.zero when no corner is reported', () {
      final radius = ScreenCornerRadius.resolve(
        topLeft: 0,
        topRight: 0,
        bottomLeft: 0,
        bottomRight: 0,
        androidSdkInt: 34,
      );

      expect(radius, BorderRadius.zero);
    });

    test('returns custom fallback when no corner is reported', () {
      const customFallback = BorderRadius.all(Radius.circular(32));
      final radius = ScreenCornerRadius.resolve(
        topLeft: 0,
        topRight: 0,
        bottomLeft: 0,
        bottomRight: 0,
        androidSdkInt: 34,
        fallback: customFallback,
      );

      expect(radius, customFallback);
    });

    test('discards non-finite and negative radii', () {
      final radius = ScreenCornerRadius.resolve(
        topLeft: double.nan,
        topRight: -10,
        bottomLeft: 24,
        bottomRight: 24,
        androidSdkInt: 34,
      );

      expect(radius.topLeft.x, 0);
      expect(radius.topRight.x, 0);
      expect(radius.bottomLeft.x, 24);
      expect(radius.bottomRight.x, 24);
    });
  });

  group('ScreenCornerRadius.init', () {
    test('overrideRadius publishes immediately without querying plugin',
        () async {
      const panelRadius = BorderRadius.all(Radius.circular(32));

      await ScreenCornerRadius.init(
        fallback: BorderRadius.zero,
        overrideRadius: panelRadius,
      );

      expect(ScreenCornerRadius.value, panelRadius);
      expect(ScreenCornerRadius.fallback, BorderRadius.zero);
    });
  });
}
