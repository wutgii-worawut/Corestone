import 'dart:async';

import 'package:corestone/features/app_lock/biometric_service.dart';

/// Answers each prompt with [result], or with [pending] while it is set,
/// so a test can resolve a prompt after changing the lock.
class FakeBiometricService implements BiometricService {
  FakeBiometricService({this.available = true});

  bool available;
  BiometricResult result = BiometricResult.success;
  Completer<BiometricResult>? pending;
  int prompts = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate(BiometricPrompt prompt) async {
    prompts++;
    return pending?.future ?? result;
  }
}
