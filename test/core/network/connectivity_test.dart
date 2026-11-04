import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:corestone/app.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/network/connectivity_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('ConnectivityCubit', () {
    late StreamController<List<ConnectivityResult>> changes;
    late ConnectivityCubit cubit;

    setUp(() {
      changes = StreamController();
      cubit = ConnectivityCubit(changes.stream);
    });

    tearDown(() => cubit.close());

    Future<ConnectivityState> after(List<ConnectivityResult> results) async {
      changes.add(results);
      await pumpEventQueue();
      return cubit.state;
    }

    test('starts online before the platform answers', () {
      expect(cubit.state, isA<Online>());
    });

    test('is offline only when no interface is up', () async {
      expect(await after([ConnectivityResult.none]), isA<Offline>());
      expect(await after([ConnectivityResult.mobile]), isA<Online>());
      expect(await after([]), isA<Offline>());
      expect(
        await after([ConnectivityResult.vpn, ConnectivityResult.wifi]),
        isA<Online>(),
      );
    });

    test('a platform error keeps the last state', () async {
      await after([ConnectivityResult.none]);
      changes.addError(StateError('no plugin'));
      await pumpEventQueue();

      expect(cubit.state, isA<Offline>());
    });
  });

  group('ConnectivityBanner', () {
    tearDown(sl.reset);

    const banner = 'No network connection';

    testWidgets('shows while offline and clears when back online', (
      tester,
    ) async {
      final changes = StreamController<List<ConnectivityResult>>();
      await configureTestApp(connectivity: changes.stream);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text(banner), findsNothing);

      changes.add([ConnectivityResult.none]);
      await tester.pumpAndSettle();
      expect(find.text(banner), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget, reason: 'app state kept');

      changes.add([ConnectivityResult.wifi]);
      await tester.pumpAndSettle();
      expect(find.text(banner), findsNothing);
      await changes.close();
    });

    testWidgets('shows on the lock screen too', (tester) async {
      await configureTestApp(
        unlocked: false,
        connectivity: Stream.value([ConnectivityResult.none]),
      );
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      expect(find.text('Enter your PIN'), findsOneWidget);
      expect(find.text(banner), findsOneWidget);
    });
  });
}
