// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i6;
import 'package:corestone/features/home/home_screen.dart' as _i3;
import 'package:corestone/features/home/home_shell.dart' as _i4;
import 'package:corestone/features/settings/change_language_screen.dart' as _i1;
import 'package:corestone/features/settings/change_theme_screen.dart' as _i2;
import 'package:corestone/features/settings/settings_screen.dart' as _i5;

/// generated route for
/// [_i1.ChangeLanguageScreen]
class ChangeLanguageRoute extends _i6.PageRouteInfo<void> {
  const ChangeLanguageRoute({List<_i6.PageRouteInfo>? children})
    : super(ChangeLanguageRoute.name, initialChildren: children);

  static const String name = 'ChangeLanguageRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i1.ChangeLanguageScreen();
    },
  );
}

/// generated route for
/// [_i2.ChangeThemeScreen]
class ChangeThemeRoute extends _i6.PageRouteInfo<void> {
  const ChangeThemeRoute({List<_i6.PageRouteInfo>? children})
    : super(ChangeThemeRoute.name, initialChildren: children);

  static const String name = 'ChangeThemeRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i2.ChangeThemeScreen();
    },
  );
}

/// generated route for
/// [_i3.HomeScreen]
class HomeRoute extends _i6.PageRouteInfo<void> {
  const HomeRoute({List<_i6.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i3.HomeScreen();
    },
  );
}

/// generated route for
/// [_i4.HomeShellScreen]
class HomeShellRoute extends _i6.PageRouteInfo<void> {
  const HomeShellRoute({List<_i6.PageRouteInfo>? children})
    : super(HomeShellRoute.name, initialChildren: children);

  static const String name = 'HomeShellRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i4.HomeShellScreen();
    },
  );
}

/// generated route for
/// [_i5.SettingsScreen]
class SettingsRoute extends _i6.PageRouteInfo<void> {
  const SettingsRoute({List<_i6.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i6.PageInfo page = _i6.PageInfo(
    name,
    builder: (data) {
      return const _i5.SettingsScreen();
    },
  );
}
