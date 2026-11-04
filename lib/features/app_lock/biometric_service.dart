import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

/// The outcome of one biometric prompt.
enum BiometricResult {
  success,

  /// The user dismissed the prompt or asked for the PIN instead.
  cancelled,

  /// No biometric hardware.
  notAvailable,

  /// Hardware, but no fingerprint or face enrolled any more.
  notEnrolled,

  /// Too many failed matches. The OS locks biometrics for a while.
  lockedOut,
  error,
}

/// The localized text of the system prompt.
typedef BiometricPrompt = ({String reason, String cancel});

/// Wraps `local_auth`. Biometrics only, without the device passcode, since
/// the app PIN pad is the fallback.
class BiometricService {
  BiometricService([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  /// Hardware present and at least one biometric enrolled.
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported() &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on Object {
      return false;
    }
  }

  Future<BiometricResult> authenticate(BiometricPrompt prompt) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: prompt.reason,
        biometricOnly: true,
        authMessages: [
          AndroidAuthMessages(cancelButton: prompt.cancel),
          IOSAuthMessages(cancelButton: prompt.cancel),
        ],
      );
      return ok ? BiometricResult.success : BiometricResult.cancelled;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricResult.cancelled,
        LocalAuthExceptionCode.noBiometricHardware =>
          BiometricResult.notAvailable,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet => BiometricResult.notEnrolled,
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout => BiometricResult.lockedOut,
        _ => BiometricResult.error,
      };
    } on Object {
      return BiometricResult.error;
    }
  }
}
