import 'package:corestone/core/errors/failure.dart';
import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/core/submit_status.dart';
import 'package:corestone/core/validators/validators.dart';
import 'package:corestone/features/auth/data/fake_auth_repository.dart';
import 'package:corestone/features/auth/data/token_store.dart';
import 'package:corestone/features/auth/presentation/login_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeAuthRepository auth;
  late TokenStore tokens;
  late SessionCubit session;
  late LoginCubit cubit;
  late List<SubmitStatus> statuses;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    auth = FakeAuthRepository();
    tokens = TokenStore(SecureStore());
    session = SessionCubit(auth, tokens);
    cubit = LoginCubit(session);
    statuses = [];
    cubit.stream.listen((state) => statuses.add(state.status));
  });

  tearDown(() async {
    await cubit.close();
    await session.close();
  });

  Future<void> fillAndSubmit({String password = 'demo-password'}) async {
    cubit
      ..emailChanged(' demo@corestone.dev ')
      ..passwordChanged(password);
    await cubit.submit();
  }

  test('an untouched form shows no errors', () {
    expect(cubit.state.emailError, isNull);
    expect(cubit.state.passwordError, isNull);
  });

  test('success signs in and stores the session', () async {
    await fillAndSubmit();
    expect(cubit.state.status, isA<SubmitSucceeded>());
    expect(statuses, contains(isA<Submitting>()));
    expect(session.state, isA<SessionAuthenticated>());
    expect(await tokens.read(), isNotNull);
  });

  for (final (name, failure) in [
    ('wrong password', const UnauthorizedFailure()),
    ('offline', const NetworkFailure()),
    ('server error', const ServerFailure(500)),
  ]) {
    test('$name fails, keeps the input and stays signed out', () async {
      auth.signInFailure = failure;
      await fillAndSubmit(password: 'nope');
      expect(cubit.state.status, SubmitFailed(failure));
      expect(cubit.state.email, ' demo@corestone.dev ');
      expect(cubit.state.password, 'nope');
      expect(session.state, isNot(isA<SessionAuthenticated>()));
      expect(await tokens.read(), isNull);
    });
  }

  test('editing after a failure clears it', () async {
    auth.signInFailure = const UnauthorizedFailure();
    await fillAndSubmit();
    cubit.passwordChanged('demo-password2');
    expect(cubit.state.status, isA<SubmitIdle>());
  });

  test('an invalid form shows errors and never calls the server', () async {
    cubit.emailChanged('demo');
    await cubit.submit();
    expect(cubit.state.emailError, FieldError.invalidEmail);
    expect(cubit.state.passwordError, FieldError.required);
    expect(cubit.state.status, isA<SubmitIdle>());
    expect(statuses, isNot(contains(isA<Submitting>())));
    expect(session.state, isNot(isA<SessionAuthenticated>()));
  });

  test('a second submit while one is in flight is ignored', () async {
    cubit
      ..emailChanged('demo@corestone.dev')
      ..passwordChanged('pw');
    final first = cubit.submit();
    cubit.emailChanged('other@corestone.dev');
    expect(cubit.state.status, isA<Submitting>());
    await cubit.submit();
    await first;
    expect(statuses.whereType<Submitting>(), hasLength(1));
  });
}
