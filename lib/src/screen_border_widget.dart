import 'package:flutter/widgets.dart';

import 'screen_corner_radius.dart';

/// A high-contrast, non-interactive framing border drawn flush around the
/// screen or viewport edge, following the physical display's rounded corners.
///
/// Can be used either as a wrapper around a [child]:
/// ```dart
/// ScreenBorder(
///   visible: isRecording,
///   child: CameraPreview(),
/// )
/// ```
/// or as a standalone overlay inside a [Stack] (or any bounded container):
/// ```dart
/// Stack(
///   children: [
///     CameraPreview(),
///     if (isRecording) const ScreenBorder(),
///   ],
/// )
/// ```
class ScreenBorder extends StatelessWidget {
  const ScreenBorder({
    super.key,
    this.color = defaultColor,
    this.width = 6.0,
    this.borderRadius,
    this.visible = true,
    this.child,
  });

  /// Default high-contrast vibrant red border color.
  static const Color defaultColor = Color(0xFFE41319);

  /// Color of the border stroke.
  final Color color;

  /// Thickness of the border stroke in logical pixels.
  final double width;

  /// Explicit corner geometry, or `null` to follow [ScreenCornerRadius].
  final BorderRadius? borderRadius;

  /// Whether the border overlay is drawn.
  final bool visible;

  /// Optional child widget to paint the border on top of.
  final Widget? child;

  Widget _buildFrame() {
    // No inset: the frame sits flush against the surface edge so its rounded
    // corners stay concentric with the display's own corner arc.
    return IgnorePointer(
      child: ExcludeSemantics(
        child: ValueListenableBuilder<BorderRadius>(
          valueListenable: ScreenCornerRadius.listenable,
          builder: (context, screenRadius, _) => DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? screenRadius,
              border: Border.all(color: color, width: width),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (child != null) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          child!,
          if (visible) Positioned.fill(child: _buildFrame()),
        ],
      );
    }
    if (!visible) {
      return const SizedBox.shrink();
    }
    return SizedBox.expand(child: _buildFrame());
  }
}
