import 'package:corner_radius_plugin/corner_radius_plugin.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Corner geometry of the display or spatial panel the app UI is painted on.
///
/// Phones and tablets are drawn edge-to-edge and the OS does not clip the
/// Flutter surface — the hardware display rounds the corners instead, and that
/// radius differs per device (and per corner on Android 12+). Overlays that hug
/// the screen edge, such as [ScreenBorder], listen to [listenable] so they
/// follow the same arc as the display they are drawn on.
class ScreenCornerRadius {
  ScreenCornerRadius._();

  static BorderRadius _fallback = BorderRadius.zero;

  /// Radius used before [init] completes or when the platform cannot report
  /// physical display corners (for example on desktop or web).
  static BorderRadius get fallback => _fallback;

  static final ValueNotifier<BorderRadius> _value = ValueNotifier<BorderRadius>(
    BorderRadius.zero,
  );

  /// Notifies listeners when the physical corner radii become available.
  static ValueListenable<BorderRadius> get listenable => _value;

  /// Corner radii of the visible surface, in Flutter logical pixels.
  static BorderRadius get value => _value.value;

  /// Replaces the cached radii in tests.
  @visibleForTesting
  static void debugSetValue(BorderRadius radius) => _value.value = radius;

  /// Resets [fallback] and [value] to [BorderRadius.zero] in tests.
  @visibleForTesting
  static void debugReset() {
    _fallback = BorderRadius.zero;
    _value.value = BorderRadius.zero;
  }

  /// Reads the physical display corner radii after the first frame.
  ///
  /// Android exposes `WindowInsets` rounded corners only once the window is
  /// laid out, so callers should not await this before `runApp`. The resolved
  /// value is published through [listenable] when it arrives.
  ///
  /// [fallback] is used immediately until the platform responds, and whenever
  /// the platform does not report rounded corners (such as desktop or web).
  ///
  /// [overrideRadius], when non-null, bypasses the platform query and publishes
  /// that radius directly (useful on head-worn displays such as Android XR or
  /// Meta Horizon OS where the runtime clips a spatial panel with a known
  /// corner radius).
  ///
  /// [androidSdkInt] selects the conversion for the plugin's legacy Android
  /// path (API < 31), which reports physical pixels rather than dp (see
  /// [resolve]).
  ///
  /// [devicePixelRatio] defaults to the implicit Flutter view's pixel ratio
  /// when omitted.
  static Future<void> init({
    BorderRadius fallback = BorderRadius.zero,
    BorderRadius? overrideRadius,
    int? androidSdkInt,
    double? devicePixelRatio,
  }) async {
    _fallback = fallback;
    if (overrideRadius != null) {
      _value.value = overrideRadius;
      return;
    }
    _value.value = fallback;
    try {
      await WidgetsBinding.instance.endOfFrame;
      final dpr = devicePixelRatio ??
          WidgetsBinding
              .instance.platformDispatcher.implicitView?.devicePixelRatio ??
          1.0;
      // Keep the plugin default at zero so an unavailable radius is reported
      // as no radius at all; [resolve] then uses [fallback]. Passing a non-zero
      // default here would be indistinguishable from a real physical-pixel
      // value on the legacy Android path and would be divided by the DPR.
      final raw = await CornerRadiusPlugin.init();
      _value.value = resolve(
        topLeft: raw.topLeft,
        topRight: raw.topRight,
        bottomLeft: raw.bottomLeft,
        bottomRight: raw.bottomRight,
        androidSdkInt: androidSdkInt,
        devicePixelRatio: dpr,
        fallback: fallback,
      );
    } catch (error) {
      debugPrint('ScreenCornerRadius: keeping fallback radius ($error)');
      _value.value = fallback;
    }
  }

  /// Converts the plugin's radii to logical pixels.
  ///
  /// Android 12+ (API 31+) reports dp and is used as-is. The plugin's pre-12
  /// fallback reads the framework `rounded_corner_radius` dimension, which is a
  /// physical-pixel value, so it is divided by [devicePixelRatio] here.
  /// A result without any rounded corner falls back to [fallback].
  @visibleForTesting
  static BorderRadius resolve({
    required double topLeft,
    required double topRight,
    required double bottomLeft,
    required double bottomRight,
    int? androidSdkInt,
    double devicePixelRatio = 1.0,
    BorderRadius fallback = BorderRadius.zero,
  }) {
    final legacyAndroid = androidSdkInt != null && androidSdkInt < 31;
    final scale =
        legacyAndroid && devicePixelRatio > 0 ? devicePixelRatio : 1.0;

    double logical(double radius) {
      final value = radius / scale;
      return value.isFinite && value > 0 ? value : 0.0;
    }

    final radii = (
      logical(topLeft),
      logical(topRight),
      logical(bottomLeft),
      logical(bottomRight),
    );

    if (radii.$1 == 0 && radii.$2 == 0 && radii.$3 == 0 && radii.$4 == 0) {
      return fallback;
    }

    return BorderRadius.only(
      topLeft: Radius.circular(radii.$1),
      topRight: Radius.circular(radii.$2),
      bottomLeft: Radius.circular(radii.$3),
      bottomRight: Radius.circular(radii.$4),
    );
  }
}
