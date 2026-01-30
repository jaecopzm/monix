import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/security_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlock;

  const LockScreen({super.key, required this.onUnlock});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final SecurityService _security = SecurityService();
  String _passcode = '';
  bool _error = false;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkBiometrics();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_tryBiometrics());
    }
  }

  Future<void> _checkBiometrics() async {
    final enabled = await _security.isBiometricsEnabled();
    final available = await _security.canUseBiometrics();
    setState(() => _biometricsAvailable = enabled && available);
    if (_biometricsAvailable) await _tryBiometrics();
  }

  Future<void> _tryBiometrics() async {
    if (!_biometricsAvailable) return;
    try {
      final authenticated = await _security.authenticateWithBiometrics();
      if (authenticated && mounted) widget.onUnlock();
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Biometric error: ${e.message}')),
        );
      }
    }
  }

  void _onNumberTap(String number) {
    if (_passcode.length < 4) {
      setState(() {
        _passcode += number;
        _error = false;
      });
      if (_passcode.length == 4) _verifyPasscode();
    }
  }

  Future<void> _verifyPasscode() async {
    final valid = await _security.verifyPasscode(_passcode);
    if (valid) {
      widget.onUnlock();
    } else {
      setState(() {
        _error = true;
        _passcode = '';
      });
    }
  }

  void _onDelete() {
    if (_passcode.isNotEmpty) {
      setState(() {
        _passcode = _passcode.substring(0, _passcode.length - 1);
        _error = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFF6C63FF), const Color(0xFF5A52D5)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/monixx-icon.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Enter Passcode',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Unlock to access your finances',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (i) => _buildDot(i < _passcode.length),
                ),
              ),
              if (_error) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Incorrect passcode',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              _buildKeypad(),
              if (_biometricsAvailable) ...[
                const SizedBox(height: 32),
                TextButton.icon(
                  onPressed: _tryBiometrics,
                  icon: const Icon(
                    Icons.fingerprint,
                    color: Colors.white,
                    size: 32,
                  ),
                  label: const Text(
                    'Use Biometrics',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(bool filled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.white : Colors.transparent,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: filled
            ? [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        _buildKeypadRow(['4', '5', '6']),
        _buildKeypadRow(['7', '8', '9']),
        _buildKeypadRow(['', '0', 'del']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: numbers.map((n) => _buildKey(n)).toList(),
    );
  }

  Widget _buildKey(String value) {
    if (value.isEmpty) return const SizedBox(width: 80, height: 80);
    return GestureDetector(
      onTap: () => value == 'del' ? _onDelete() : _onNumberTap(value),
      child: Container(
        margin: const EdgeInsets.all(8),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Center(
          child: value == 'del'
              ? const Icon(
                  Icons.backspace_outlined,
                  color: Colors.white,
                  size: 24,
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}
