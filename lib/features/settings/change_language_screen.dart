import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String languageLabel(AppLocalizations l10n, Locale? locale) =>
    switch (locale?.languageCode) {
      null => l10n.languageSystem,
      'th' => l10n.languageThai,
      _ => l10n.languageEnglish,
    };

@RoutePage()
class ChangeLanguageScreen extends StatelessWidget {
  const ChangeLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<LocaleCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.language)),
      body: RadioGroup<Locale?>(
        groupValue: cubit.state,
        onChanged: (locale) => unawaited(cubit.setLocale(locale)),
        child: ListView(
          children: [
            for (final locale in [null, ...AppLocalizations.supportedLocales])
              RadioListTile<Locale?>(
                value: locale,
                title: Text(languageLabel(context.l10n, locale)),
              ),
          ],
        ),
      ),
    );
  }
}
