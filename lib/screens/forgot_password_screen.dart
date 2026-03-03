import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/animated_button.dart';

/// ForgotPasswordScreen - Allows users to reset their password via email.
/// Firebase sends a password reset link; user sets a new password there
/// and returns to the app to log in.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  // Resend cooldown (60 seconds)
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
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

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success =
        await authProvider.sendPasswordReset(_emailController.text.trim());

    if (success && mounted) {
      setState(() => _emailSent = true);
      _startResendCooldown();
    }
  }

  Future<void> _resendResetEmail() async {
    if (_cooldownSeconds > 0) return;

    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();

    final success =
        await authProvider.sendPasswordReset(_emailController.text.trim());

    if (success && mounted) {
      _startResendCooldown();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset link resent to ${_emailController.text.trim()}'),
          backgroundColor: AppTheme.accentGreen,
        ),
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
                  onPressed: () => Navigator.of(context).pop(),
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
                    child: Icon(
                      _emailSent
                          ? Icons.mark_email_read_rounded
                          : Icons.lock_reset_rounded,
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
                    _emailSent ? 'Check Your Email' : 'Forgot Password?',
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
                    _emailSent
                        ? 'We\'ve sent a password reset link to\n${_emailController.text.trim()}'
                        : 'Enter your email address and we\'ll send\nyou a link to reset your password.',
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

                if (!_emailSent) ...[
                  // Email input form
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : const Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          validator: Validators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'Enter your registered email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 400.ms),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Send reset email button
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      return AnimatedGradientButton(
                        text: 'Send Reset Link',
                        icon: Icons.send_rounded,
                        isLoading: auth.isLoading,
                        onPressed: _sendResetEmail,
                      );
                    },
                  ),
                ] else ...[
                  // Success state — instructions
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
                          text: 'Click the password reset link',
                          icon: Icons.link_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildStep(
                          isDark: isDark,
                          number: '3',
                          text: 'Create your new password',
                          icon: Icons.lock_outline_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildStep(
                          isDark: isDark,
                          number: '4',
                          text: 'Come back and log in',
                          icon: Icons.login_rounded,
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
                  // Back to Login button
                  AnimatedGradientButton(
                    text: 'Back to Login',
                    icon: Icons.login_rounded,
                    isLoading: false,
                    onPressed: () {
                      Navigator.of(context).pushNamedAndRemoveUntil(
                        AppConstants.loginRoute,
                        (route) => false,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Resend option with cooldown
                  Center(
                    child: Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        final canResend =
                            !auth.isLoading && _cooldownSeconds == 0;
                        return TextButton(
                          onPressed: canResend ? _resendResetEmail : null,
                          child: Text(
                            _cooldownSeconds > 0
                                ? 'Resend in ${_cooldownSeconds}s'
                                : 'Resend Reset Link',
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
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
