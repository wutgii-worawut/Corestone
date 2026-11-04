@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:corestone/features/system/system_screen.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final page in SystemPage.values) {
    for (final locale in AppLocalizations.supportedLocales) {
      goldenTest(
        '${page.name} page renders in ${locale.languageCode}',
        fileName: 'system_${page.name}_${locale.languageCode}_light',
        builder: () => Theme(
          data: AppTheme.light,
          child: Localizations(
            locale: locale,
            delegates: AppLocalizations.localizationsDelegates,
            child: SizedBox(
              width: 400,
              height: 560,
              child: SystemScreen(page: page),
            ),
          ),
        ),
      );
    }
  }
}
