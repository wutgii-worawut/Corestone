import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/router/app_router.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final routerConfig = sl<AppRouter>().config();
    return BlocProvider.value(
      value: sl<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) => MaterialApp.router(
          title: 'Corestone',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeMode,
          routerConfig: routerConfig,
        ),
      ),
    );
  }
}
