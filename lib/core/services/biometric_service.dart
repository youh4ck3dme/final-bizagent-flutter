import 'package:local_auth/local_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  // Legacy name mapping for old callers
  Future<bool> isBiometricAvailable() => canCheckBiometrics();

  Future<bool> authenticate({
    String localizedReason = 'Prihláste sa pomocou biometrie',
  }) async {
    try {
      // Simplified call to avoid potential versioning issues with 'options' class
      return await _auth.authenticate(
        localizedReason: localizedReason,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});
