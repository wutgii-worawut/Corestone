import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:corestone/core/storage/secure_store.dart';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';

const pinLength = 6;

/// The result of [PinRepository.verify]. [failedAttempts] is the persisted
/// count after this check, so it is 0 when [correct].
typedef PinCheck = ({bool correct, int failedAttempts});

/// Keeps a salted PBKDF2-HMAC-SHA256 hash of the app PIN, the failed
/// attempt counter and the biometric unlock choice in one [SecureStore] key,
/// never the PIN itself. The biometric choice lives with the PIN, so
/// whatever clears the PIN clears it too. One key
/// means a crash can never pair a new hash with an old counter. Operations
/// run one at a time, so two checks cannot both read the same counter.
class PinRepository {
  PinRepository(
    this._store, {
    this.iterations = defaultIterations,
    this._derive = _deriveOnIsolate,
  });

  static const key = 'app_pin';

  /// Unlock took a 337 ms median on the Pixel 5 emulator in CS-09, under the
  /// 400 ms budget. Re-measure on a low-end phone before raising it.
  static const defaultIterations = 150000;

  final SecureStore _store;
  final PinHasher _derive;

  /// Used for new hashes. A stored hash keeps the count it was made with.
  final int iterations;

  Future<void> _last = Future.value();

  Future<T> _serial<T>(Future<T> Function() op) {
    final result = _last.then((_) => op());
    _last = result.then((_) {}, onError: (_) {});
    return result;
  }

  /// True for an unreadable record too, so a corrupt store fails closed.
  Future<bool> hasPin() => _serial(() async => await _store.read(key) != null);

  /// 0 when there is no PIN. Throws [FormatException] for an unreadable
  /// record, as [verify] does.
  Future<int> failedAttempts() =>
      _serial(() async => (await _read())?.failed ?? 0);

  /// Replaces any PIN with [pin], with a new salt and no failed attempts.
  /// Keeps the biometric choice of a readable earlier PIN.
  Future<void> setPin(String pin) => _serial(() async {
    if (!isValidPin(pin)) throw ArgumentError('PIN must be $pinLength digits');
    final biometric = await _read().then(
      (record) => record?.biometric ?? false,
      onError: (Object _) => false,
    );
    final salt = _randomBytes(16);
    final hash = await _derive(pin, salt, iterations);
    await _write(
      _PinRecord(
        salt: salt,
        hash: hash,
        iterations: iterations,
        failed: 0,
        biometric: biometric,
      ),
    );
  });

  /// False when there is no PIN. Throws [FormatException] for an unreadable
  /// record.
  Future<bool> biometricEnabled() =>
      _serial(() async => (await _read())?.biometric ?? false);

  /// Does nothing when there is no PIN, since the choice means nothing then.
  Future<void> setBiometric({required bool enabled}) => _serial(() async {
    final record = await _read();
    if (record != null) await _write(record.copyWith(biometric: enabled));
  });

  /// After an unlock that did not use the PIN, such as biometrics.
  Future<void> resetFailedAttempts() => _serial(() async {
    final record = await _read();
    if (record != null) await _write(record.copyWith(failed: 0));
  });

  /// Counts the attempt as failed before hashing, so killing the app during
  /// the check cannot skip the count. A correct PIN resets it to 0.
  Future<PinCheck> verify(String pin) => _serial(() async {
    final record = await _read();
    if (record == null) return (correct: false, failedAttempts: 0);
    final counted = record.copyWith(failed: record.failed + 1);
    await _write(counted);
    final hash = await _derive(pin, record.salt, record.iterations);
    if (!_constantTimeEquals(hash, record.hash)) {
      return (correct: false, failedAttempts: counted.failed);
    }
    await _write(record.copyWith(failed: 0));
    return (correct: true, failedAttempts: 0);
  });

  Future<void> clear() => _serial(() => _store.delete(key));

  Future<_PinRecord?> _read() async {
    final raw = await _store.read(key);
    if (raw == null) return null;
    try {
      return _PinRecord.fromJson(jsonDecode(raw));
    } on Object {
      throw const FormatException('Unreadable PIN record');
    }
  }

  Future<void> _write(_PinRecord record) =>
      _store.write(key, jsonEncode(record.toJson()));
}

bool isValidPin(String pin) =>
    pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

typedef PinHasher = Future<List<int>> Function(
  String pin,
  List<int> salt,
  int iterations,
);

/// PBKDF2-HMAC-SHA256 on the calling isolate, without the package's default
/// pauses for the event loop.
Future<List<int>> derivePinHash(
  String pin,
  List<int> salt,
  int iterations,
) async {
  final key = await DartPbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
    pauseFrequency: 1 << 30,
  ).deriveKeyFromPassword(password: pin, nonce: salt);
  return key.extractBytes();
}

/// Keeps the hash off the isolate that draws frames.
Future<List<int>> _deriveOnIsolate(
  String pin,
  List<int> salt,
  int iterations,
) => Isolate.run(() => derivePinHash(pin, salt, iterations));

List<int> _randomBytes(int length) {
  final random = Random.secure();
  return List.generate(length, (_) => random.nextInt(256));
}

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

final class _PinRecord {
  const _PinRecord({
    required this.salt,
    required this.hash,
    required this.iterations,
    required this.failed,
    required this.biometric,
  });

  factory _PinRecord.fromJson(Object? json) {
    final map = json! as Map<String, Object?>;
    return _PinRecord(
      salt: base64Decode(map['salt']! as String),
      hash: base64Decode(map['hash']! as String),
      iterations: map['iterations']! as int,
      failed: map['failed']! as int,
      // Absent in records written before biometric unlock existed.
      biometric: map['biometric'] as bool? ?? false,
    );
  }

  final List<int> salt;
  final List<int> hash;
  final int iterations;
  final int failed;
  final bool biometric;

  _PinRecord copyWith({int? failed, bool? biometric}) => _PinRecord(
    salt: salt,
    hash: hash,
    iterations: iterations,
    failed: failed ?? this.failed,
    biometric: biometric ?? this.biometric,
  );

  Map<String, Object> toJson() => {
    'salt': base64Encode(salt),
    'hash': base64Encode(hash),
    'iterations': iterations,
    'failed': failed,
    'biometric': biometric,
  };
}
