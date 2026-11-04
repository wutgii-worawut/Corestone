import 'dart:async';

import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/router/app_router.dart';
import 'package:corestone/core/router/app_router.gr.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final routerConfig = sl<AppRouter>().config();
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider.value(value: sl<LocaleCubit>()),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          title: 'Corestone',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: context.watch<ThemeCubit>().state,
          locale: context.watch<LocaleCubit>().state,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: routerConfig,
          builder: (context, child) => BlocListener<SessionCubit, SessionState>(
            bloc: sl<SessionCubit>(),
            listener: (context, state) => unawaited(
              sl<AppRouter>().replaceAll([
                if (state is SessionAuthenticated)
                  const HomeShellRoute()
                else
                  const LoginRoute(),
              ]),
            ),
            child: child!,
          ),
        ),
      ),
    );
  }
}
