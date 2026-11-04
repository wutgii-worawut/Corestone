import 'package:corestone/core/storage/secure_store.dart';
import 'package:corestone/features/app_lock/pin_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SecureStore store;
  late PinRepository pins;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureStore();
    pins = PinRepository(store, iterations: 10);
  });

  test('stores a hash, never the PIN', () async {
    await pins.setPin('135790');
    final stored = await store.read(PinRepository.key);
    expect(stored, isNotNull);
    expect(stored, isNot(contains('135790')));
    expect(await pins.hasPin(), isTrue);
  });

  test('the right PIN verifies and a wrong one does not', () async {
    await pins.setPin('135790');
    expect((await pins.verify('135790')).correct, isTrue);
    expect((await pins.verify('135791')).correct, isFalse);
  });

  test('a new salt each time, so the same PIN stores differently', () async {
    await pins.setPin('135790');
    final first = await store.read(PinRepository.key);
    await pins.setPin('135790');
    expect(await store.read(PinRepository.key), isNot(first));
  });

  test('wrong PINs count up across instances and a right one resets', () async {
    await pins.setPin('135790');
    await pins.verify('000000');
    await pins.verify('000000');
    final restarted = PinRepository(store, iterations: 10);
    expect(await restarted.failedAttempts(), 2);
    expect((await restarted.verify('000000')).failedAttempts, 3);
    expect(await restarted.verify('135790'), (
      correct: true,
      failedAttempts: 0,
    ));
    expect(await restarted.failedAttempts(), 0);
  });

  test(
    'a stored hash still verifies after the default count changes',
    () async {
      await pins.setPin('135790');
      final stronger = PinRepository(store, iterations: 20);
      expect((await stronger.verify('135790')).correct, isTrue);
    },
  );

  test('rejects a PIN that is not six digits', () async {
    await expectLater(pins.setPin('12345'), throwsArgumentError);
    await expectLater(pins.setPin('12345a'), throwsArgumentError);
    expect(await pins.hasPin(), isFalse);
  });

  test('clear removes the PIN and its counter', () async {
    await pins.setPin('135790');
    await pins.verify('000000');
    await pins.clear();
    expect(await pins.hasPin(), isFalse);
    expect(await pins.failedAttempts(), 0);
    expect(await pins.verify('135790'), (correct: false, failedAttempts: 0));
  });
}
