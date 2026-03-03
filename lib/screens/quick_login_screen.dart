import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/local_auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// QuickLoginScreen – Allows users to log in with PIN or biometrics
/// instead of entering email and password each time.
class QuickLoginScreen extends StatefulWidget {
  const QuickLoginScreen({super.key});

  @override
  State<QuickLoginScreen> createState() => _QuickLoginScreenState();
}

class _QuickLoginScreenState extends State<QuickLoginScreen> {
  final List<String> _pin = [];
  bool _hasError = false;
  String _errorMessage = '';
  String _userName = '';
  String _userEmail = '';
  String _authMethod = LocalAuthService.methodNone;
  String? _uid;
  bool _isLoading = true;
  int _attempts = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final uid = await LocalAuthService.getLastLoggedInUid();
    final name = await LocalAuthService.getLastLoggedInName();
    final email = await LocalAuthService.getLastLoggedInEmail();
    final method = uid != null
        ? await LocalAuthService.getAuthMethod(uid)
        : LocalAuthService.methodNone;

    setState(() {
      _uid = uid;
      _userName = name ?? 'User';
      _userEmail = email ?? '';
      _authMethod = method;
      _isLoading = false;
    });

    // Auto-trigger biometric if that's the method
    if (method == LocalAuthService.methodBiometric) {
      _authenticateWithBiometric();
    }
  }

  Future<void> _authenticateWithBiometric() async {
    final success = await LocalAuthService.authenticateWithBiometric();
    if (success && mounted) {
      await _performLogin();
    }
  }

  void _onKeyTap(String value) {
    if (_attempts >= _maxAttempts) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Too many attempts. Use email & password.';
      });
      return;
    }

    setState(() {
      _hasError = false;
      _errorMessage = '';
    });

    if (_pin.length < 4) {
      setState(() => _pin.add(value));
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      if (_pin.isNotEmpty) _pin.removeLast();
    });
  }

  Future<void> _verifyPin() async {
    if (_uid == null) return;

    final valid = await LocalAuthService.verifyPin(_uid!, _pin.join());
    if (valid) {
      await _performLogin();
    } else {
      _attempts++;
      setState(() {
        _hasError = true;
        _pin.clear();
        if (_attempts >= _maxAttempts) {
          _errorMessage = 'Too many attempts. Use email & password.';
        } else {
          _errorMessage =
              'Incorrect PIN. ${_maxAttempts - _attempts} attempts remaining.';
        }
      });
    }
  }

  Future<void> _performLogin() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();

    // First try: check if Firebase session is still active
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.homeRoute,
        (route) => false,
      );
      return;
    }

    // Second try: re-authenticate with stored credentials
    final reAuthSuccess =
        await authProvider.reAuthenticateWithStoredCredentials();

    if (!mounted) return;

    if (reAuthSuccess && authProvider.isLoggedIn) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.homeRoute,
        (route) => false,
      );
    } else {
      // Both methods failed — credentials missing or invalid
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Session expired. Please login with email & password.';
      });
    }
  }

  void _switchToEmailLogin() {
    Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            // User avatar / icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.neonGlow(AppTheme.primaryColor),
              ),
              child: Icon(
                _authMethod == LocalAuthService.methodBiometric
                    ? Icons.fingerprint_rounded
                    : Icons.lock_rounded,
                size: 36,
                color: Colors.white,
              ),
            ).animate().scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 500.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 20),
            // Welcome back text
            Text(
              'Welcome back,',
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFF64748B),
              ),
            ).animate().fadeIn(duration: 300.ms),
            const SizedBox(height: 4),
            Text(
              _userName,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 100.ms),
            const SizedBox(height: 4),
            Text(
              _userEmail,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? Colors.white.withOpacity(0.4)
                    : const Color(0xFF94A3B8),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 150.ms),
            const SizedBox(height: 32),

            if (_authMethod == LocalAuthService.methodPin) ...[
              // PIN title
              Text(
                'Enter your PIN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 20),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _hasError
                          ? Colors.red
                          : isFilled
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                      border: Border.all(
                        color: _hasError
                            ? Colors.red
                            : AppTheme.primaryColor.withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: isFilled && !_hasError
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),
            ],

            if (_authMethod == LocalAuthService.methodBiometric) ...[
              // Biometric prompt
              GestureDetector(
                onTap: _authenticateWithBiometric,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.grey.withOpacity(0.1),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.fingerprint_rounded,
                        size: 56,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tap to authenticate',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark
                              ? Colors.white.withOpacity(0.7)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms),
            ],

            // Error message
            if (_hasError) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fadeIn().shake(),
              ),
            ],

            const Spacer(flex: 1),

            // Number pad (only for PIN)
            if (_authMethod == LocalAuthService.methodPin)
              _buildNumberPad(isDark),

            const SizedBox(height: 16),

            // Switch to email login
            TextButton(
              onPressed: _switchToEmailLogin,
              child: Text(
                'Login with Email & Password instead',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberPad(bool isDark) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'delete'],
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: keys.map((row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((key) {
              if (key.isEmpty) {
                return const SizedBox(width: 72, height: 72);
              }
              if (key == 'delete') {
                return _buildKeyButton(
                  isDark: isDark,
                  child: Icon(
                    Icons.backspace_outlined,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    size: 24,
                  ),
                  onTap: _onDelete,
                );
              }
              return _buildKeyButton(
                isDark: isDark,
                child: Text(
                  key,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                onTap: () => _onKeyTap(key),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKeyButton({
    required bool isDark,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : Colors.grey.withOpacity(0.1),
        ),
        child: Center(child: child),
      ),
    );
  }
}
