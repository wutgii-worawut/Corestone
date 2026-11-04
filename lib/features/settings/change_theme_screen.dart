import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:corestone/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String themeModeLabel(AppLocalizations l10n, ThemeMode mode) =>
    switch (mode) {
      ThemeMode.system => l10n.themeSystem,
      ThemeMode.light => l10n.themeLight,
      ThemeMode.dark => l10n.themeDark,
    };

@RoutePage()
class ChangeThemeScreen extends StatelessWidget {
  const ChangeThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ThemeCubit>();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.theme)),
      body: RadioGroup<ThemeMode>(
        groupValue: cubit.state,
        onChanged: (mode) {
          if (mode != null) unawaited(cubit.setMode(mode));
        },
        child: ListView(
          children: [
            for (final mode in ThemeMode.values)
              RadioListTile<ThemeMode>(
                value: mode,
                title: Text(themeModeLabel(context.l10n, mode)),
              ),
          ],
        ),
      ),
    );
  }
}
