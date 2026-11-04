import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:corestone/core/router/app_router.gr.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/settings/change_theme_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

@RoutePage()
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(themeModeLabel(context.watch<ThemeCubit>().state)),
            onTap: () =>
                unawaited(context.router.push(const ChangeThemeRoute())),
          ),
          if (kDebugMode)
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: const Text('Throw test error'),
              // Async so it reaches the bootstrap zone handler.
              onTap: () => unawaited(
                Future<void>.error(StateError('Test error from Settings')),
              ),
            ),
        ],
      ),
    );
  }
}
