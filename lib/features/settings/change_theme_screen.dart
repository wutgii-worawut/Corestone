import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'System',
  ThemeMode.light => 'Light',
  ThemeMode.dark => 'Dark',
};

@RoutePage()
class ChangeThemeScreen extends StatelessWidget {
  const ChangeThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.watch<ThemeCubit>();
    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
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
                title: Text(themeModeLabel(mode)),
              ),
          ],
        ),
      ),
    );
  }
}
