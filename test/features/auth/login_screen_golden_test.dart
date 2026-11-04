@Tags(['golden'])
library;

import 'package:alchemist/alchemist.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/core/theme/app_theme.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/presentation/login_cubit.dart';
import 'package:corestone/features/auth/presentation/login_screen.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:corestone/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final locale in AppLocalizations.supportedLocales) {
    goldenTest(
      'Login renders in ${locale.languageCode}',
      fileName: 'login_${locale.languageCode}_light',
      builder: () => BlocProvider(
        create: (_) => LoginCubit(
          SessionCubit(FakeAuthRepository(), TokenStore(SecureStore())),
        ),
        child: Theme(
          data: AppTheme.light,
          child: Localizations(
            locale: locale,
            delegates: AppLocalizations.localizationsDelegates,
            child: const SizedBox(width: 400, height: 560, child: LoginView()),
          ),
        ),
      ),
    );
  }
}
