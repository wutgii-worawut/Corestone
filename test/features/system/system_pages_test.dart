import 'package:corestone/app.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/features/system/system_pages.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('presentationOf', () {
    // One instance of every subtype. The switch has no default case, so a
    // new subtype fails to compile until it has a row there; add one here.
    const table = <(Failure, FailurePresentation)>[
      (NetworkFailure(), FailurePresentation.inline),
      (UnauthorizedFailure(), FailurePresentation.session),
      (ForbiddenFailure(), FailurePresentation.inline),
      (NotFoundFailure(), FailurePresentation.inline),
      (ClientFailure(422), FailurePresentation.inline),
      (ServerFailure(500), FailurePresentation.inline),
      (MaintenanceFailure(), FailurePresentation.maintenancePage),
      (BadResponseFailure(), FailurePresentation.inline),
      (PinningFailure(), FailurePresentation.secureConnectionPage),
      (UnknownFailure(), FailurePresentation.inline),
    ];

    for (final (failure, expected) in table) {
      test('$failure shows as ${expected.name}', () {
        expect(presentationOf(failure), expected);
      });
    }

    test('only the page presentations open a page', () {
      expect(
        {
          for (final p in FailurePresentation.values)
            if (p.page != null) p,
        },
        {
          FailurePresentation.maintenancePage,
          FailurePresentation.secureConnectionPage,
        },
      );
    });
  });

  group('SystemPages.guard', () {
    tearDown(sl.reset);

    Future<void> pumpApp(WidgetTester tester) async {
      await configureTestApp();
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
    }

    /// Fails with each of [failures] in turn, then succeeds.
    ({ResultFutureFn action, List<int> calls}) failing(List<Failure> failures) {
      final calls = <int>[];
      return (
        calls: calls,
        action: () async {
          calls.add(calls.length);
          return calls.length <= failures.length
              ? Left(failures[calls.length - 1])
              : const Right('data');
        },
      );
    }

    testWidgets('an inline failure returns at once with no page', (
      tester,
    ) async {
      await pumpApp(tester);
      final call = failing([const ServerFailure(500)]);

      final result = await sl<SystemPages>().guard(call.action);

      expect(result, const Left<Failure, String>(ServerFailure(500)));
      expect(call.calls, hasLength(1));
      expect(find.text('Try again'), findsNothing);
    });

    testWidgets('Retry on the maintenance page reruns the action', (
      tester,
    ) async {
      await pumpApp(tester);
      final call = failing([const MaintenanceFailure()]);

      final result = sl<SystemPages>().guard(call.action);
      await tester.pumpAndSettle();
      expect(find.text('Down for maintenance'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(await result, const Right<Failure, String>('data'));
      expect(find.text('Down for maintenance'), findsNothing);
      expect(find.text('Corestone stage'), findsOneWidget);
    });

    testWidgets('back from the page returns the failure to the caller', (
      tester,
    ) async {
      await pumpApp(tester);
      final call = failing([const PinningFailure()]);

      final result = sl<SystemPages>().guard(call.action);
      await tester.pumpAndSettle();
      expect(find.text("Can't connect securely"), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(await result, const Left<Failure, String>(PinningFailure()));
      expect(call.calls, hasLength(1));
    });

    testWidgets('concurrent failures share one page', (tester) async {
      await pumpApp(tester);
      final first = failing([const MaintenanceFailure()]);
      final second = failing([const MaintenanceFailure()]);

      final results = [
        sl<SystemPages>().guard(first.action),
        sl<SystemPages>().guard(second.action),
      ];
      await tester.pumpAndSettle();
      expect(find.text('Down for maintenance'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(await Future.wait(results), [
        const Right<Failure, String>('data'),
        const Right<Failure, String>('data'),
      ]);
    });
  });
}

typedef ResultFutureFn = Future<Either<Failure, String>> Function();
