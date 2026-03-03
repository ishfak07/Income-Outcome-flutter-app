import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';

/// ChangePasswordScreen – lets users change their password securely.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordC = TextEditingController();
  final _newPasswordC = TextEditingController();
  final _confirmPasswordC = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordC.dispose();
    _newPasswordC.dispose();
    _confirmPasswordC.dispose();
    super.dispose();
  }

  Future<void> _handleChangePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.changePassword(
        currentPassword: _currentPasswordC.text.trim(),
        newPassword: _newPasswordC.text.trim(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password changed successfully!'),
          backgroundColor: AppTheme.accentGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── HEADER ────────────────────────────────────────
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentCyan, AppTheme.primaryColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCyan.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    'Update your password',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                const SizedBox(height: 32),

                // ─── CURRENT PASSWORD ──────────────────────────────
                GlassCard(
                  margin: EdgeInsets.zero,
                  enableAnimation: false,
                  child: TextFormField(
                    controller: _currentPasswordC,
                    obscureText: _obscureCurrent,
                    decoration: _buildInputDecoration(
                      label: 'Current Password',
                      icon: Icons.lock_rounded,
                      isDark: isDark,
                      toggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                      isObscured: _obscureCurrent,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your current password';
                      }
                      return null;
                    },
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),

                // ─── NEW PASSWORD ──────────────────────────────────
                GlassCard(
                  margin: EdgeInsets.zero,
                  enableAnimation: false,
                  child: TextFormField(
                    controller: _newPasswordC,
                    obscureText: _obscureNew,
                    decoration: _buildInputDecoration(
                      label: 'New Password',
                      icon: Icons.lock_open_rounded,
                      isDark: isDark,
                      toggle: () => setState(() => _obscureNew = !_obscureNew),
                      isObscured: _obscureNew,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter a new password';
                      }
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      if (v.trim() == _currentPasswordC.text.trim()) {
                        return 'New password must differ from current';
                      }
                      return null;
                    },
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 300.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 16),

                // ─── CONFIRM PASSWORD ──────────────────────────────
                GlassCard(
                  margin: EdgeInsets.zero,
                  enableAnimation: false,
                  child: TextFormField(
                    controller: _confirmPasswordC,
                    obscureText: _obscureConfirm,
                    decoration: _buildInputDecoration(
                      label: 'Confirm New Password',
                      icon: Icons.check_circle_outline_rounded,
                      isDark: isDark,
                      toggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      isObscured: _obscureConfirm,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Re-enter the new password';
                      }
                      if (v.trim() != _newPasswordC.text.trim()) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 12),

                // ─── PASSWORD TIPS ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: AppTheme.accentCyan, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Use a strong password with at least 6 characters, mixing letters, numbers, and symbols.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white54
                                : const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
                const SizedBox(height: 32),

                // ─── SAVE BUTTON ───────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.accentCyan],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleChangePassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 300.ms, delay: 600.ms)
                    .slideY(begin: 0.1, end: 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback toggle,
    required bool isObscured,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: IconButton(
        icon: Icon(
          isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
          size: 20,
        ),
        onPressed: toggle,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor:
          isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF8FAFC),
    );
  }
}
