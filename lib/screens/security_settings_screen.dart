import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/local_auth_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';

/// SecuritySettingsScreen – Manage quick login methods (PIN & Biometrics).
/// Users can enable/disable fingerprint or 4-digit PIN for quick login.
class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _pinEnabled = false;
  bool _isLoading = true;
  String? _uid;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final authProvider = context.read<AuthProvider>();
    final uid = authProvider.currentUid;

    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    final biometricAvailable = await LocalAuthService.isBiometricAvailable();
    final biometricEnabled = await LocalAuthService.isBiometricEnabled(uid);
    final pinEnabled = await LocalAuthService.isPinEnabled(uid);

    setState(() {
      _uid = uid;
      _biometricAvailable = biometricAvailable;
      _biometricEnabled = biometricEnabled;
      _pinEnabled = pinEnabled;
      _isLoading = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_uid == null) return;

    if (value) {
      // Test biometric first
      final success = await LocalAuthService.authenticateWithBiometric();
      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Biometric authentication failed.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }

      await LocalAuthService.setBiometricEnabled(_uid!, true);
      await LocalAuthService.setAuthMethod(
          _uid!, LocalAuthService.methodBiometric);

      // Store user info for quick login
      final authProvider = context.read<AuthProvider>();
      if (authProvider.user != null) {
        await LocalAuthService.setLastLoggedInUid(_uid!);
        await LocalAuthService.setLastLoggedInEmail(authProvider.user!.email);
        await LocalAuthService.setLastLoggedInName(authProvider.user!.fullName);
        await LocalAuthService.setLinkedEmail(_uid!, authProvider.user!.email);
      }

      // Disable PIN if biometric is enabled
      if (_pinEnabled) {
        await LocalAuthService.setPinEnabled(_uid!, false);
        await LocalAuthService.removePin(_uid!);
      }

      setState(() {
        _biometricEnabled = true;
        _pinEnabled = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fingerprint login enabled!'),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } else {
      await LocalAuthService.setBiometricEnabled(_uid!, false);
      await LocalAuthService.setAuthMethod(_uid!, LocalAuthService.methodNone);

      setState(() => _biometricEnabled = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Fingerprint login disabled.'),
            backgroundColor: AppTheme.accentOrange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _togglePin(bool value) async {
    if (_uid == null) return;

    if (value) {
      // Navigate to PIN setup
      final pin = await Navigator.of(context).pushNamed(
        AppConstants.pinSetupRoute,
      );

      if (pin != null && pin is String && pin.length == 4) {
        await LocalAuthService.savePin(_uid!, pin);
        await LocalAuthService.setPinEnabled(_uid!, true);
        await LocalAuthService.setAuthMethod(_uid!, LocalAuthService.methodPin);

        // Store user info for quick login
        final authProvider = context.read<AuthProvider>();
        if (authProvider.user != null) {
          await LocalAuthService.setLastLoggedInUid(_uid!);
          await LocalAuthService.setLastLoggedInEmail(authProvider.user!.email);
          await LocalAuthService.setLastLoggedInName(
              authProvider.user!.fullName);
          await LocalAuthService.setLinkedEmail(
              _uid!, authProvider.user!.email);
        }

        // Disable biometric if PIN is enabled
        if (_biometricEnabled) {
          await LocalAuthService.setBiometricEnabled(_uid!, false);
        }

        setState(() {
          _pinEnabled = true;
          _biometricEnabled = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('PIN login enabled!'),
              backgroundColor: AppTheme.accentGreen,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } else {
      await LocalAuthService.setPinEnabled(_uid!, false);
      await LocalAuthService.removePin(_uid!);
      await LocalAuthService.setAuthMethod(_uid!, LocalAuthService.methodNone);

      setState(() => _pinEnabled = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PIN login disabled.'),
            backgroundColor: AppTheme.accentOrange,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _changePin() async {
    if (_uid == null) return;

    // Verify current PIN first
    final verified = await _showVerifyCurrentPinDialog();
    if (!verified) return;

    // Navigate to PIN setup for new PIN
    final newPin = await Navigator.of(context).pushNamed(
      AppConstants.pinSetupRoute,
    );

    if (newPin != null && newPin is String && newPin.length == 4) {
      await LocalAuthService.savePin(_uid!, newPin);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PIN changed successfully!'),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<bool> _showVerifyCurrentPinDialog() async {
    final pinController = TextEditingController();
    bool verified = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Verify Current PIN'),
          content: TextField(
            controller: pinController,
            keyboardType: TextInputType.number,
            maxLength: 4,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: 'Enter current 4-digit PIN',
              counterText: '',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (_uid != null) {
                  final valid = await LocalAuthService.verifyPin(
                      _uid!, pinController.text);
                  if (valid) {
                    verified = true;
                    Navigator.pop(ctx);
                  } else {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Incorrect PIN'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(
                'Verify',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );

    pinController.dispose();
    return verified;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _SectionHeader(title: 'Quick Login', isDark: isDark),
                    const SizedBox(height: 8),
                    Text(
                      'Set up a quick way to access your account without entering email & password every time.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white.withOpacity(0.5)
                            : const Color(0xFF64748B),
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 20),

                    // Fingerprint option
                    if (_biometricAvailable) ...[
                      _SecurityTile(
                        icon: Icons.fingerprint_rounded,
                        title: 'Fingerprint Login',
                        subtitle: _biometricEnabled
                            ? 'Enabled — use your fingerprint to log in'
                            : 'Use your fingerprint for quick login',
                        color: AppTheme.accentCyan,
                        isDark: isDark,
                        trailing: Switch(
                          value: _biometricEnabled,
                          onChanged: _toggleBiometric,
                          activeColor: AppTheme.primaryColor,
                        ),
                        index: 0,
                      ),
                      const SizedBox(height: 8),
                    ],

                    // PIN option
                    _SecurityTile(
                      icon: Icons.pin_rounded,
                      title: '4-Digit PIN Login',
                      subtitle: _pinEnabled
                          ? 'Enabled — use your PIN to log in'
                          : 'Set a 4-digit PIN for quick login',
                      color: AppTheme.accentPurple,
                      isDark: isDark,
                      trailing: Switch(
                        value: _pinEnabled,
                        onChanged: _togglePin,
                        activeColor: AppTheme.primaryColor,
                      ),
                      index: _biometricAvailable ? 1 : 0,
                    ),

                    // Change PIN button
                    if (_pinEnabled) ...[
                      const SizedBox(height: 8),
                      _SecurityTile(
                        icon: Icons.edit_rounded,
                        title: 'Change PIN',
                        subtitle: 'Update your 4-digit PIN',
                        color: AppTheme.accentOrange,
                        isDark: isDark,
                        onTap: _changePin,
                        index: _biometricAvailable ? 2 : 1,
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Info card
                    GlassCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.accentCyan,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Quick login methods are stored locally on this device. '
                              'You can always use email & password as a fallback. '
                              'Only one quick method can be active at a time.',
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white.withOpacity(0.6)
                                    : const Color(0xFF64748B),
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── HELPER WIDGETS ────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05);
  }
}

class _SecurityTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;
  final int index;

  const _SecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    this.trailing,
    this.onTap,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withOpacity(0.15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white.withOpacity(0.5)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
          if (onTap != null && trailing == null)
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
            ),
        ],
      ),
    ).animate().fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 100 * index),
        );
  }
}
