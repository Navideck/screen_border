# screen_border

A display-concentric screen border overlay widget for Flutter that automatically follows the physical display's rounded corners on iOS and Android (and falls back cleanly on desktop, web, or XR spatial panels).

## Features

- **Hardware-accurate rounded corners**: Queries physical display corner radii via `corner_radius_plugin` after the first frame, handling per-corner Android 12+ dp values and pre-12 physical-pixel scaling.
- **XR / desktop / web friendly**: Defaults to `BorderRadius.zero` on platforms without rounded display corners, and supports `fallback` and `overrideRadius` for fixed-clip surfaces like Android XR or Meta Horizon OS panels.
- **Non-interactive & accessible**: Wrapped in `IgnorePointer` and `ExcludeSemantics` so it never intercepts gestures or clutters TalkBack / VoiceOver trees.
- **Flexible usage**: Use as a wrapper around any `child` or as a standalone overlay in a `Stack`.

## Installation

Add `screen_border` to your `pubspec.yaml`:

```yaml
dependencies:
  screen_border:
    git:
      url: https://github.com/Navideck/screen_border.git
```

## Usage

### 1. Initialize at startup

Call `ScreenCornerRadius.init` (without awaiting it before `runApp`, since Android exposes `WindowInsets` rounded corners after the first frame):

```dart
import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:screen_border/screen_border.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(ScreenCornerRadius.init());
  runApp(const MyApp());
}
```

For head-worn displays with a known panel corner radius (e.g. Android XR 32 dp):

```dart
const panelRadius = BorderRadius.all(Radius.circular(32));
unawaited(
  ScreenCornerRadius.init(
    fallback: panelRadius,
    overrideRadius: isHeadset ? panelRadius : null,
    androidSdkInt: androidSdkInt,
  ),
);
```

### 2. Render `ScreenBorder`

**Wrapping a child:**

```dart
ScreenBorder(
  visible: isRecording,
  color: const Color(0xFFE41319),
  width: 6.0,
  child: MyCameraView(),
)
```

**As a standalone overlay inside a `Stack`:**

```dart
Stack(
  children: [
    MyCameraView(),
    if (isRecording) const ScreenBorder(),
  ],
)
```

## License

MIT License — Copyright (c) 2026 Navideck. See [LICENSE](LICENSE).
