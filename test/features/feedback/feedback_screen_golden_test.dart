@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/features/feedback/data/feedback_repository.dart';
import 'package:corestone/features/feedback/feedback_cubit.dart';
import 'package:corestone/features/feedback/feedback_screen.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    goldenTest(
      'Feedback renders in ${locale.languageCode}',
      fileName: 'feedback_${locale.languageCode}_light',
      builder: () => BlocProvider(
        create: (_) => FeedbackCubit(FakeFeedbackRepository()),
        child: Theme(
          data: AppTheme.light,
          child: Localizations(
            locale: locale,
            delegates: AppLocalizations.localizationsDelegates,
            child: const SizedBox(
              width: 400,
              height: 640,
              child: FeedbackView(),
            ),
          ),
        ),
      ),
    );
  }
}
