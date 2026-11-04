import 'package:flutter/widgets.dart';

/// Material 3 window size classes, picked by window width.
enum WindowSize {
  compact,
  medium,
  expanded;

  static WindowSize fromWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : expanded;

  static WindowSize of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);
}

extension WindowSizeContext on BuildContext {
  WindowSize get windowSize => WindowSize.of(this);
}
