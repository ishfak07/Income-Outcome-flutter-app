import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/animated_button.dart';

/// EmailVerificationScreen - Handles email verification during registration.
/// Creates the Firebase account, sends a verification email, auto-polls
/// for verification status, and completes registration once verified.
class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  bool _verificationSent = false;
  late Map<String, String> _registrationData;

  // Auto-poll timer to check verification status every 3 seconds
  Timer? _pollTimer;
  bool _autoChecking = false;

  // Resend cooldown (60 seconds)
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _registrationData =
        ModalRoute.of(context)!.settings.arguments as Map<String, String>;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  /// Start auto-polling to check if email is verified every 3 seconds.
  void _startAutoPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _autoChecking) return;
      _autoChecking = true;

      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.checkVerificationAndComplete();

      if (success && mounted) {
        _pollTimer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified! Welcome aboard!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppConstants.homeRoute,
          (route) => false,
        );
      } else {
        // Clear the "not verified yet" error from auto-check so it doesn't flash
        if (mounted) authProvider.clearError();
      }
      _autoChecking = false;
    });
  }

  /// Start 60-second resend cooldown.
  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _cooldownSeconds--;
        if (_cooldownSeconds <= 0) {
          _cooldownSeconds = 0;
          timer.cancel();
        }
      });
    });
  }

  /// Register user and send email verification link.
  Future<void> _sendVerificationEmail() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.registerAndSendVerification(
      fullName: _registrationData['fullName']!,
      email: _registrationData['email']!,
      password: _registrationData['password']!,
      phoneNumber: _registrationData['phone']!,
    );

    if (success && mounted) {
      setState(() => _verificationSent = true);
      _startAutoPolling();
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Verification email sent to ${_registrationData['email']}'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  /// Resend the verification email.
  Future<void> _resendVerificationEmail() async {
    if (_cooldownSeconds > 0) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.resendVerificationEmail();

    if (mounted && authProvider.error == null) {
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Verification email resent to ${_registrationData['email']}'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    }
  }

  /// Manual check if email has been verified.
  Future<void> _checkVerification() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.checkVerificationAndComplete();

    if (success && mounted) {
      _pollTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified! Welcome aboard!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppConstants.homeRoute,
        (route) => false,
      );
    }
  }

  /// Open the default email app.
  Future<void> _openEmailApp() async {
    final uri = Uri.parse('mailto:');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Cancel registration, delete the unverified account, and go back.
  Future<void> _cancelRegistration() async {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    final authProvider = context.read<AuthProvider>();
    await authProvider.cancelRegistration();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: size.height * 0.04),
                // Back button
                IconButton(
                  onPressed: _cancelRegistration,
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ).animate().fadeIn(duration: 300.ms),
                const SizedBox(height: 24),
                // Header icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppTheme.primaryGradient,
                      boxShadow: AppTheme.neonGlow(AppTheme.primaryColor),
                    ),
                    child: const Icon(
                      Icons.mark_email_unread_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ).animate().scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1.0, 1.0),
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Verify Your Email',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    _verificationSent
                        ? 'We\'ve sent a verification link to\n${_registrationData['email'] ?? ''}'
                        : 'We\'ll send a verification link to\n${_registrationData['email'] ?? ''}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                const SizedBox(height: 40),

                if (!_verificationSent) ...[
                  // Send verification email button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return AnimatedGradientButton(
                        text: 'Send Verification Email',
                        icon: Icons.send_rounded,
                        isLoading: auth.isLoading,
                        onPressed: _sendVerificationEmail,
                      );
                    },
                  ),
                ] else ...[
                  // Auto-checking indicator
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Auto-checking verification status...',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 20),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withOpacity(0.05)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      children: [
                        _buildStep(
                          isDark: isDark,
                          number: '1',
                          text: 'Open your email inbox',
                          icon: Icons.inbox_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildStep(
                          isDark: isDark,
                          number: '2',
                          text: 'Click the verification link',
                          icon: Icons.link_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildStep(
                          isDark: isDark,
                          number: '3',
                          text: 'App will auto-detect — or tap below',
                          icon: Icons.check_circle_outline_rounded,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  // Email delivery tips
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.tips_and_updates_rounded,
                                color: Colors.orange.shade700, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Email not arriving?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Check your Spam / Junk folder\n'
                          '• Look for email from noreply@rumi-ishi-expense-tracker.firebaseapp.com\n'
                          '• Email may take 1-2 minutes to arrive\n'
                          '• Try Gmail — it works most reliably',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 200.ms),
                  const SizedBox(height: 20),
                  // Open Email App button
                  OutlinedButton.icon(
                    onPressed: _openEmailApp,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open Email App'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ).animate().fadeIn(duration: 300.ms, delay: 300.ms),
                  const SizedBox(height: 16),
                  // "I've Verified" button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return AnimatedGradientButton(
                        text: 'I\'ve Verified My Email',
                        icon: Icons.verified_rounded,
                        isLoading: auth.isLoading,
                        onPressed: _checkVerification,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Resend email with cooldown
                  Center(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final canResend =
                            !auth.isLoading && _cooldownSeconds == 0;
                        return TextButton(
                          onPressed:
                              canResend ? _resendVerificationEmail : null,
                          child: Text(
                            _cooldownSeconds > 0
                                ? 'Resend in ${_cooldownSeconds}s'
                                : 'Resend Verification Email',
                            style: TextStyle(
                              color: canResend
                                  ? AppTheme.primaryColor
                                  : (isDark
                                      ? Colors.white.withOpacity(0.3)
                                      : const Color(0xFF94A3B8)),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                // Error display
                Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    if (auth.error == null) return const SizedBox.shrink();
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              auth.error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn().shake();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a step row for the verification instructions.
  Widget _buildStep({
    required bool isDark,
    required String number,
    required String text,
    required IconData icon,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppTheme.primaryGradient,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          icon,
          size: 20,
          color:
              isDark ? Colors.white.withOpacity(0.6) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}
