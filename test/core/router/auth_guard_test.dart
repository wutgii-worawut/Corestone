import 'package:corestone/app.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

Future<void> startApp(WidgetTester tester, {required bool signedIn}) async {
  await configureTestApp(signedIn: signedIn);
  await tester.pumpWidget(const App());
  await tester.pumpAndSettle();
}

final _signIn = find.widgetWithText(AppBar, 'Sign in');
final _home = find.text('Corestone stage');

void main() {
  tearDown(sl.reset);

  testWidgets('without a session the app opens on sign-in', (tester) async {
    await startApp(tester, signedIn: false);
    expect(_signIn, findsOneWidget);
    expect(_home, findsNothing);
  });

  testWidgets('with a session the app opens on Home', (tester) async {
    await startApp(tester, signedIn: true);
    expect(_home, findsOneWidget);
    expect(_signIn, findsNothing);
  });

  testWidgets('a new session moves sign-in to setting a PIN', (tester) async {
    await startApp(tester, signedIn: false);
    await sl<TokenStore>().write(testTokens);
    await sl<SessionCubit>().restore();
    await tester.pumpAndSettle();
    expect(find.text('Create a 6-digit PIN'), findsOneWidget);
    expect(_signIn, findsNothing);
    expect(_home, findsNothing);
  });

  testWidgets('Sign out in Settings returns to sign-in', (tester) async {
    await startApp(tester, signedIn: true);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(_signIn, findsNothing);
    expect(await sl<TokenStore>().read(), isNotNull);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(_signIn, findsOneWidget);
    expect(await sl<TokenStore>().read(), isNull);
    expect(await sl<PinRepository>().hasPin(), isFalse);
  });

  testWidgets('a forced logout returns to sign-in', (tester) async {
    await startApp(tester, signedIn: true);
    sl<SessionCubit>().sessionExpired();
    await tester.pumpAndSettle();
    expect(_signIn, findsOneWidget);
    expect(await sl<PinRepository>().hasPin(), isFalse);
  });
}
