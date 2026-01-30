import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class SecurityService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _kPinKey = 'biz_security_pin';

  /// Returns true if the device supports any biometric authentication.
  Future<bool> canCheckBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Attempts to authenticate using biometrics.
  Future<bool> authenticateWithBiometrics({String reason = 'Potvrďte identitu pre prístup k BizAgent'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Securely saves the 4-digit PIN.
  Future<void> savePin(String pin) async {
    await _storage.write(key: _kPinKey, value: pin);
  }

  /// Verifies if the provided PIN matches the saved one.
  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: _kPinKey);
    return savedPin == pin;
  }

  /// Checks if a PIN is already set.
  Future<bool> isPinSet() async {
    final pin = await _storage.read(key: _kPinKey);
    return pin != null && pin.length == 4;
  }

  /// Clears the PIN from secure storage.
  Future<void> clearPin() async {
    await _storage.delete(key: _kPinKey);
  }
}

final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

final sessionUnlockedProvider = StateProvider<bool>((ref) => false);
