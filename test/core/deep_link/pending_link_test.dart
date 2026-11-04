import 'dart:async';

import 'package:corestone/core/deep_link/deep_link_routes.dart';
import 'package:corestone/core/deep_link/deep_link_service.dart';
import 'package:corestone/features/app_lock/app_lock_cubit.dart';
import 'package:corestone/features/auth/session_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _State<S> extends Cubit<S> {
  _State(super.initialState);

  void set(S state) => emit(state);
}

void main() {
  const host = 'dev.links.example.com';
  final settings = Uri.parse('https://$host/settings');
  final theme = Uri.parse('https://$host/settings/theme');

  late _State<SessionState> session;
  late _State<AppLockState> lock;
  late List<DeepLinkTarget> opened;
  late DeepLinkService links;

  void given(SessionState s, AppLockState l) {
    session = _State(s);
    lock = _State(l);
    opened = [];
    links = DeepLinkService(
      host: host,
      session: session,
      lock: lock,
      navigate: opened.add,
    );
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  tearDown(() => links.close());

  test('opens at once when signed in and unlocked', () {
    given(const SessionAuthenticated(), const AppLockUnlocked());
    links.open(settings);
    expect(opened, [isA<SettingsLink>()]);
  });

  test('signed out: held through login and PIN setup, opened once', () async {
    given(const SessionUnauthenticated(), const AppLockNoPin());
    links.open(settings);

    session.set(const SessionAuthenticated());
    await settle();
    expect(opened, isEmpty, reason: 'still has to set a PIN');

    lock.set(const AppLockUnlocked());
    await settle();
    expect(opened, [isA<SettingsLink>()]);

    lock
      ..set(const AppLockLocked(0))
      ..set(const AppLockUnlocked());
    await settle();
    expect(opened, hasLength(1), reason: 'a held link opens once');
  });

  test('locked: held until unlock', () async {
    given(const SessionAuthenticated(), const AppLockLocked(0));
    links.open(settings);
    lock.set(const AppLockLocked(1));
    await settle();
    expect(opened, isEmpty);

    lock.set(const AppLockUnlocked());
    await settle();
    expect(opened, [isA<SettingsLink>()]);
  });

  test('a newer link replaces a held one', () async {
    given(const SessionAuthenticated(), const AppLockLocked(0));
    links
      ..open(settings)
      ..open(theme);
    lock.set(const AppLockUnlocked());
    await settle();
    expect(opened, [isA<ThemeLink>()]);
  });

  test('a link for another host leaves the held one alone', () async {
    given(const SessionAuthenticated(), const AppLockLocked(0));
    links
      ..open(settings)
      ..open(Uri.parse('https://evil.example.com/settings/theme'));
    lock.set(const AppLockUnlocked());
    await settle();
    expect(opened, [isA<SettingsLink>()]);
  });

  test('sign-out drops a held link', () async {
    given(const SessionAuthenticated(), const AppLockLocked(0));
    links.open(settings);
    lock.set(const AppLockLockedOut());
    session.set(const SessionUnauthenticated());
    await settle();

    session.set(const SessionAuthenticated());
    lock.set(const AppLockUnlocked());
    await settle();
    expect(opened, isEmpty);
  });

  test('links from the platform stream go through the same rules', () async {
    given(const SessionAuthenticated(), const AppLockLocked(0));
    final platform = StreamController<Uri>();
    links.start(platform.stream);
    platform.add(settings);
    await settle();
    expect(opened, isEmpty);

    lock.set(const AppLockUnlocked());
    await settle();
    expect(opened, [isA<SettingsLink>()]);
    await platform.close();
  });

  group('notification tap', () {
    setUp(() => given(const SessionAuthenticated(), const AppLockUnlocked()));

    test('routes its link through the parser', () {
      links.openPush({'link': 'https://$host/settings/language'});
      expect(opened, [isA<LanguageLink>()]);
    });

    test('without a link, or with a bad one, opens Home', () {
      links
        ..openPush({})
        ..openPush({'link': 42})
        ..openPush({'link': 'http://[::1'});
      expect(opened, [isA<HomeLink>(), isA<HomeLink>(), isA<HomeLink>()]);
    });

    test('with an unknown path opens Home through UnknownLink', () {
      links.openPush({'link': 'https://$host/nope'});
      expect(opened.single, isA<UnknownLink>());
    });

    test('with a link for another host is ignored', () {
      links.openPush({'link': 'https://evil.example.com/settings'});
      expect(opened, isEmpty);
    });

    test('is held while locked like any link', () async {
      lock.set(const AppLockLocked(0));
      await settle();
      links.openPush({'link': 'https://$host/settings'});
      expect(opened, isEmpty);
      lock.set(const AppLockUnlocked());
      await settle();
      expect(opened, [isA<SettingsLink>()]);
    });
  });
}
