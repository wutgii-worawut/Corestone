import 'package:corestone/app.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  tearDown(sl.reset);

  const home = 'Corestone stage';

  Future<void> enter(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.widgetWithText(TextButton, digit));
      await tester.pump();
    }
  }

  testWidgets('a cold start with a PIN shows the lock before Home', (
    tester,
  ) async {
    await configureTestApp(unlocked: false);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text(home), findsNothing);

    await enter(tester, testPin);
    await tester.pumpAndSettle();

    expect(find.text('Enter your PIN'), findsNothing);
    expect(find.text(home), findsOneWidget);
  });

  testWidgets('back on the lock screen does not reveal Home', (tester) async {
    await configureTestApp(unlocked: false);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.text(home), findsNothing);
  });

  testWidgets('a new user sets a PIN, confirms it, then sees Home', (
    tester,
  ) async {
    await configureTestApp(hasPin: false);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Create a 6-digit PIN'), findsOneWidget);
    expect(find.text(home), findsNothing);

    await enter(tester, testPin);
    expect(find.text('Enter the PIN again'), findsOneWidget);
    await enter(tester, '000000');
    expect(find.text('The PINs did not match. Try again.'), findsOneWidget);

    await enter(tester, testPin);
    await enter(tester, testPin);
    await tester.pumpAndSettle();

    expect(find.text(home), findsOneWidget);
  });

  testWidgets('forgot PIN signs out to login', (tester) async {
    await configureTestApp(unlocked: false);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Forgot PIN? Sign out'));
    await tester.tap(find.text('Forgot PIN? Sign out'));
    await tester.pumpAndSettle();

    expect(sl<SessionCubit>().state, isA<SessionUnauthenticated>());
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('Change PIN in Settings asks for the current PIN first', (
    tester,
  ) async {
    await configureTestApp();
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change PIN'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your current PIN'), findsOneWidget);
    await enter(tester, testPin);
    await tester.pumpAndSettle();

    expect(find.text('Create a 6-digit PIN'), findsOneWidget);
    await enter(tester, '246810');
    await enter(tester, '246810');
    await tester.pumpAndSettle();

    expect(find.text('PIN changed'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    final check = await sl<AppLockCubit>().confirmCurrentPin('246810');
    expect(check.correct, isTrue);
  });

  /// Pumps frames through a route transition and counts any with Home on.
  Future<int> framesShowingHome(WidgetTester tester) async {
    var frames = 0;
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (find.text(home).evaluate().isNotEmpty) frames++;
    }
    return frames;
  }

  testWidgets('five wrong PINs go to login without showing Home', (
    tester,
  ) async {
    await configureTestApp(unlocked: false);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    for (var i = 0; i < 5; i++) {
      await enter(tester, '000000');
      await tester.pump();
    }

    expect(await framesShowingHome(tester), 0);
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('forgot PIN goes to login without showing Home', (tester) async {
    await configureTestApp(unlocked: false);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Forgot PIN? Sign out'));
    await tester.tap(find.text('Forgot PIN? Sign out'));

    expect(await framesShowingHome(tester), 0);
  });

  testWidgets('a snackbar from the locked app stays hidden', (tester) async {
    await configureTestApp(unlocked: false);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    final hidden = tester.element(find.text(home, skipOffstage: false));
    ScaffoldMessenger.of(hidden)
        .showSnackBar(const SnackBar(content: Text('private')));
    await tester.pumpAndSettle();

    expect(find.text('private'), findsNothing);
  });
}
