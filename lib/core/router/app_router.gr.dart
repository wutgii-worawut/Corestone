// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:auto_route/auto_route.dart' as _i11;
import 'package:corestone/features/app_lock/set_pin_screen.dart' as _i2;
import 'package:corestone/features/auth/presentation/login_screen.dart' as _i8;
import 'package:corestone/features/feedback/feedback_screen.dart' as _i5;
import 'package:corestone/features/home/home_screen.dart' as _i6;
import 'package:corestone/features/home/home_shell.dart' as _i7;
import 'package:corestone/features/settings/change_language_screen.dart' as _i1;
import 'package:corestone/features/settings/change_theme_screen.dart' as _i3;
import 'package:corestone/features/settings/delete_account_screen.dart' as _i4;
import 'package:corestone/features/settings/settings_screen.dart' as _i9;
import 'package:corestone/features/system/system_pages.dart' as _i12;
import 'package:corestone/features/system/system_screen.dart' as _i10;
import 'package:flutter/material.dart' as _i13;

/// generated route for
/// [_i1.ChangeLanguageScreen]
class ChangeLanguageRoute extends _i11.PageRouteInfo<void> {
  const ChangeLanguageRoute({List<_i11.PageRouteInfo>? children})
    : super(ChangeLanguageRoute.name, initialChildren: children);

  static const String name = 'ChangeLanguageRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i1.ChangeLanguageScreen();
    },
  );
}

/// generated route for
/// [_i2.ChangePinScreen]
class ChangePinRoute extends _i11.PageRouteInfo<void> {
  const ChangePinRoute({List<_i11.PageRouteInfo>? children})
    : super(ChangePinRoute.name, initialChildren: children);

  static const String name = 'ChangePinRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i2.ChangePinScreen();
    },
  );
}

/// generated route for
/// [_i3.ChangeThemeScreen]
class ChangeThemeRoute extends _i11.PageRouteInfo<void> {
  const ChangeThemeRoute({List<_i11.PageRouteInfo>? children})
    : super(ChangeThemeRoute.name, initialChildren: children);

  static const String name = 'ChangeThemeRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i3.ChangeThemeScreen();
    },
  );
}

/// generated route for
/// [_i4.DeleteAccountScreen]
class DeleteAccountRoute extends _i11.PageRouteInfo<void> {
  const DeleteAccountRoute({List<_i11.PageRouteInfo>? children})
    : super(DeleteAccountRoute.name, initialChildren: children);

  static const String name = 'DeleteAccountRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i4.DeleteAccountScreen();
    },
  );
}

/// generated route for
/// [_i5.FeedbackScreen]
class FeedbackRoute extends _i11.PageRouteInfo<void> {
  const FeedbackRoute({List<_i11.PageRouteInfo>? children})
    : super(FeedbackRoute.name, initialChildren: children);

  static const String name = 'FeedbackRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i5.FeedbackScreen();
    },
  );
}

/// generated route for
/// [_i6.HomeScreen]
class HomeRoute extends _i11.PageRouteInfo<void> {
  const HomeRoute({List<_i11.PageRouteInfo>? children})
    : super(HomeRoute.name, initialChildren: children);

  static const String name = 'HomeRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i6.HomeScreen();
    },
  );
}

/// generated route for
/// [_i7.HomeShellScreen]
class HomeShellRoute extends _i11.PageRouteInfo<void> {
  const HomeShellRoute({List<_i11.PageRouteInfo>? children})
    : super(HomeShellRoute.name, initialChildren: children);

  static const String name = 'HomeShellRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i7.HomeShellScreen();
    },
  );
}

/// generated route for
/// [_i8.LoginScreen]
class LoginRoute extends _i11.PageRouteInfo<void> {
  const LoginRoute({List<_i11.PageRouteInfo>? children})
    : super(LoginRoute.name, initialChildren: children);

  static const String name = 'LoginRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i8.LoginScreen();
    },
  );
}

/// generated route for
/// [_i9.SettingsScreen]
class SettingsRoute extends _i11.PageRouteInfo<void> {
  const SettingsRoute({List<_i11.PageRouteInfo>? children})
    : super(SettingsRoute.name, initialChildren: children);

  static const String name = 'SettingsRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      return const _i9.SettingsScreen();
    },
  );
}

/// generated route for
/// [_i10.SystemScreen]
class SystemRoute extends _i11.PageRouteInfo<SystemRouteArgs> {
  SystemRoute({
    required _i12.SystemPage page,
    _i13.Key? key,
    List<_i11.PageRouteInfo>? children,
  }) : super(
         SystemRoute.name,
         args: SystemRouteArgs(page: page, key: key),
         initialChildren: children,
       );

  static const String name = 'SystemRoute';

  static _i11.PageInfo page = _i11.PageInfo(
    name,
    builder: (data) {
      final args = data.argsAs<SystemRouteArgs>();
      return _i10.SystemScreen(page: args.page, key: args.key);
    },
  );
}

class SystemRouteArgs {
  const SystemRouteArgs({required this.page, this.key});

  final _i12.SystemPage page;

  final _i13.Key? key;

  @override
  String toString() {
    return 'SystemRouteArgs{page: $page, key: $key}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SystemRouteArgs) return false;
    return page == other.page && key == other.key;
  }

  @override
  int get hashCode => page.hashCode ^ key.hashCode;
}
