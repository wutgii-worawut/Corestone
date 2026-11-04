import 'package:corestone/app.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  setUp(configureTestApp);

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
