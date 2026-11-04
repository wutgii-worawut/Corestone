@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/core/widgets/app_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final (name, theme) in [
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    goldenTest(
      'AppButton renders every variant in $name',
      fileName: 'app_button_$name',
      // A fixed pump draws the indeterminate spinner mid-sweep, not at t=0.
      pumpBeforeTest: pumpNTimes(1, const Duration(milliseconds: 300)),
      builder: () => Theme(
        data: _withGoldenTheme(theme),
        child: Builder(
          builder: (context) => ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: GoldenTestGroup(
              columns: 3,
              children: [
                for (final variant in AppButtonVariant.values) ...[
                  GoldenTestScenario(
                    name: '${variant.name} enabled',
                    child: AppButton(
                      label: 'Continue',
                      variant: variant,
                      onPressed: () {},
                    ),
                  ),
                  GoldenTestScenario(
                    name: '${variant.name} loading',
                    child: AppButton(
                      label: 'Continue',
                      variant: variant,
                      isLoading: true,
                      onPressed: () {},
                    ),
                  ),
                  GoldenTestScenario(
                    name: '${variant.name} disabled',
                    child: AppButton(
                      label: 'Continue',
                      variant: variant,
                      onPressed: null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

ThemeData _withGoldenTheme(ThemeData theme) {
  final scheme = theme.colorScheme;
  return theme.copyWith(
    extensions: [
      ...theme.extensions.values,
      GoldenTestTheme(
        backgroundColor: scheme.surface,
        borderColor: scheme.outlineVariant,
        nameTextStyle: theme.textTheme.labelMedium!.copyWith(
          color: scheme.onSurfaceVariant,
        ),
        padding: const EdgeInsets.all(8),
      ),
    ],
  );
}
