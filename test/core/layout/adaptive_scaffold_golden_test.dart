@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:corestone/core/layout/adaptive_scaffold.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [360.0, 700.0, 1024.0]) {
    final size = Size(width, 480);
    goldenTest(
      'AdaptiveScaffold at ${width.toInt()} wide',
      fileName: 'adaptive_scaffold_${width.toInt()}',
      builder: () => Theme(
        data: AppTheme.light,
        child: MediaQuery(
          data: MediaQueryData(size: size),
          child: SizedBox.fromSize(
            size: size,
            child: AdaptiveScaffold(
              selectedIndex: 1,
              onSelect: (_) {},
              destinations: const [
                (icon: Icon(Icons.home), label: 'Home'),
                (icon: Icon(Icons.settings), label: 'Settings'),
              ],
              body: const Center(child: Text('Body')),
            ),
          ),
        ),
      ),
    );
  }
}
