import 'package:corestone/app.dart';
import 'package:corestone/core/config/app_config.dart';
import 'package:corestone/core/di/injection.dart';
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
}
