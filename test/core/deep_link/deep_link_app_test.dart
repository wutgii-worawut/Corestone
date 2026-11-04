import 'package:corestone/app.dart';
import 'package:corestone/core/deep_link/deep_link_service.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/features/settings/change_language_screen.dart';
import 'package:corestone/features/settings/change_theme_screen.dart';
import 'package:corestone/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  tearDown(sl.reset);

  Uri link(String path) => Uri.parse('https://$testLinkHost$path');

  Future<void> enter(WidgetTester tester, String pin) async {
    for (final digit in pin.split('')) {
      await tester.tap(find.widgetWithText(TextButton, digit));
      await tester.pump();
    }
  }

  testWidgets('a link while locked opens Settings only after unlock', (
    tester,
  ) async {
    await configureTestApp(unlocked: false);
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    sl<DeepLinkService>().open(link('/settings'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN'), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);

    await enter(tester, testPin);
    await tester.pumpAndSettle();
    expect(find.text('Enter your PIN'), findsNothing);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('theme and language links open over Settings', (tester) async {
    await configureTestApp();
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    sl<DeepLinkService>().open(link('/settings/theme'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangeThemeScreen), findsOneWidget);

    sl<DeepLinkService>().open(link('/settings/language'));
    await tester.pumpAndSettle();
    expect(find.byType(ChangeLanguageScreen), findsOneWidget);
    expect(find.byType(ChangeThemeScreen), findsNothing);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('an unknown link from Settings goes back to Home', (
    tester,
  ) async {
    await configureTestApp();
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    sl<DeepLinkService>().open(link('/settings'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);

    sl<DeepLinkService>().open(link('/no/such/screen'));
    await tester.pumpAndSettle();
    expect(find.text('Corestone stage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
