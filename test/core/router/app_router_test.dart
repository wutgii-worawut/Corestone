import 'package:corestone/app.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/locale/locale_cubit.dart';
import 'package:corestone/core/storage/prefs.dart';
import 'package:corestone/core/theme/theme_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    configureDependencies(
      const AppConfig(
        flavor: AppFlavor.stage,
        apiBaseUrl: 'https://api-stage.example.com',
        certSha256: '',
      ),
    );
  });

  tearDown(sl.reset);

  testWidgets('opens on Home with the flavor and switches to Settings', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text('Corestone stage'), findsOneWidget);
    expect(find.widgetWithText(AppBar, 'Settings'), findsNothing);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(find.text('Corestone stage'), findsNothing);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(find.text('Corestone stage'), findsOneWidget);
  });

  testWidgets('Settings then Theme switches to dark and saves it', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    // Theme and Language both start on System.
    expect(find.text('System'), findsNWidgets(2));

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    final context = tester.element(find.text('Dark'));
    expect(Theme.of(context).brightness, Brightness.dark);
    expect(await sl<Prefs>().getString(ThemeCubit.key), 'dark');

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('Settings then Language switches every string to Thai', (
    tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thai'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'ภาษา'), findsOneWidget);
    expect(find.text('ภาษาไทย'), findsOneWidget);
    expect(await sl<Prefs>().getString(LocaleCubit.key), 'th');

    // pageBack() finds the button by its English tooltip.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'การตั้งค่า'), findsOneWidget);
    expect(find.text('ธีม'), findsOneWidget);
    expect(find.text('หน้าหลัก'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
  });
}
