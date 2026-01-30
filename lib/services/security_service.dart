import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _storage = const FlutterSecureStorage();
  final _auth = LocalAuthentication();

  Future<void> setPasscode(String passcode) async {
    await _storage.write(key: 'passcode', value: passcode);
  }

  Future<String?> getPasscode() {
    return _storage.read(key: 'passcode');
  }

  Future<void> removePasscode() async {
    await _storage.delete(key: 'passcode');
  }

  Future<bool> verifyPasscode(String passcode) async {
    final stored = await getPasscode();
    return stored == passcode;
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', enabled);
  }

  Future<bool> isBiometricsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometrics_enabled') ?? false;
  }

  Future<bool> canUseBiometrics() async {
    return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final canAuthenticate = await canUseBiometrics();
      if (!canAuthenticate) return false;

      return await _auth.authenticate(
        localizedReason: 'Authenticate to access Monixx',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
