import 'package:corestone/app.dart';
import 'package:corestone/core/di/injection.dart';
import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/core/submit_status.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/domain/account_repository.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:corestone/features/settings/delete_account_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

void main() {
  group('DeleteAccountCubit', () {
    late FakeAuthRepository fake;
    late TokenStore tokens;
    late SessionCubit session;

    setUp(() async {
      FlutterSecureStorage.setMockInitialValues({});
      fake = FakeAuthRepository();
      tokens = TokenStore(SecureStore());
      session = SessionCubit(fake, tokens);
      await session.signIn(email: 'a@b.co', password: 'pw');
    });

    tearDown(() => session.close());

    test('deletes on the server, then signs out', () async {
      final cubit = DeleteAccountCubit(fake, session);
      await cubit.delete();
      expect(fake.deleteCalls, 1);
      expect(cubit.state, isA<SubmitSucceeded>());
      expect(session.state, isA<SessionUnauthenticated>());
      expect(await tokens.read(), isNull);
    });

    test('a failure keeps the session', () async {
      fake.deleteFailure = const NetworkFailure();
      final cubit = DeleteAccountCubit(fake, session);
      await cubit.delete();
      expect(cubit.state, const SubmitFailed(NetworkFailure()));
      expect(session.state, isA<SessionAuthenticated>());
      expect(await tokens.read(), isNotNull);
    });
  });

  group('Settings', () {
    tearDown(sl.reset);

    testWidgets('deletes the account and lands on login', (tester) async {
      await configureTestApp(demoMode: true);
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Sign in'), findsOneWidget);
      expect((sl<AccountRepository>() as FakeAuthRepository).deleteCalls, 1);
      expect(await sl<TokenStore>().read(), isNull);
    });
  });
}
