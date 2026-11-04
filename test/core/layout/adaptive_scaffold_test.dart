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
        certPins: [],
      ),
    );
  });

  tearDown(sl.reset);

  testWidgets('keeps the selected tab when the window grows to expanded', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 720);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(1024, 720);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
    expect(rail.extended, isTrue);
    expect(rail.selectedIndex, 1);
    expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
  });
}
