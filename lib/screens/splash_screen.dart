import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../providers/auth_provider.dart';
import '../services/local_auth_service.dart';
import '../main.dart' show firebaseInitialized, firebaseError;
import 'package:provider/provider.dart';

/// SplashScreen - Animated logo and app name with auto-navigation.
/// Checks auth state and routes accordingly.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    // Wait for splash animation
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // If Firebase is not initialized, show error and stay on splash
    if (!firebaseInitialized) {
      if (mounted) {
        _showFirebaseErrorDialog();
      }
      return;
    }

    // Check if quick login is available FIRST (PIN/biometric gate)
    final hasQuickLogin = await LocalAuthService.hasQuickLoginAvailable();
    if (hasQuickLogin && mounted) {
      Navigator.of(context)
          .pushReplacementNamed(AppConstants.quickLoginRoute);
      return;
    }

    // No quick login — check Firebase session normally
    final authProvider = context.read<AuthProvider>();
    await authProvider.initialize();

    if (!mounted) return;

    if (authProvider.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
    } else if (mounted) {
      Navigator.of(context).pushReplacementNamed(AppConstants.loginRoute);
    }
  }

  void _showFirebaseErrorDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkCard
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 8),
            Text('Firebase Not Configured'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Firebase is not set up yet. To use this app, you need to:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            const Text('1. Create a Firebase project',
                style: TextStyle(fontSize: 13)),
            const Text('2. Add your Android/iOS app',
                style: TextStyle(fontSize: 13)),
            const Text('3. Download google-services.json',
                style: TextStyle(fontSize: 13)),
            const Text('4. Run: flutterfire configure',
                style: TextStyle(fontSize: 13)),
            const SizedBox(height: 12),
            const Text(
              'See FIREBASE_SETUP.md for details.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            if (firebaseError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $firebaseError',
                  style: const TextStyle(fontSize: 11, color: Colors.red),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [AppTheme.darkBg, AppTheme.darkSurface]
                : [AppTheme.lightBg, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
                boxShadow: AppTheme.neonGlow(AppTheme.primaryColor),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 56,
                color: Colors.white,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.elasticOut,
                )
                .then()
                .animate(
                  onPlay: (controller) => controller.repeat(reverse: true),
                )
                .scale(
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(1.05, 1.05),
                  duration: 1500.ms,
                ),
            const SizedBox(height: 32),
            // App name
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: 2,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 600.ms),
            const SizedBox(height: 8),
            // Tagline
            Text(
              AppConstants.appTagline,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withOpacity(0.5)
                    : const Color(0xFF64748B),
                letterSpacing: 0.5,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 800.ms)
                .slideY(begin: 0.3, end: 0, duration: 600.ms),
            const SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppTheme.primaryColor.withOpacity(0.6),
              ),
            ).animate().fadeIn(duration: 400.ms, delay: 1200.ms),
          ],
        ),
      ),
    );
  }
}
