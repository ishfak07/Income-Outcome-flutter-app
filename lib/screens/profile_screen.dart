import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/expense_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../widgets/glass_card.dart';
import '../widgets/profile_avatar.dart';

/// ProfileScreen – Redesigned with profile photo, bio, quick actions,
/// budget summary, and navigation to all feature screens.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Consumer2<AuthProvider, ExpenseProvider>(
            builder: (context, auth, expenses, _) {
              final user = auth.user;
              final budget = user?.monthlyBudget ?? 0;
              final spent = expenses.totalThisMonth;
              final percent =
                  budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;

              return Column(
                children: [
                  // ─── HEADER CARD ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Top bar
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_rounded,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Text(
                                'My Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.settings_rounded,
                                  color: Colors.white70),
                              onPressed: () => Navigator.pushNamed(
                                  context, AppConstants.settingsRoute),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Avatar
                        ProfileAvatar(
                          avatarId: user?.avatarId,
                          name: user?.fullName ?? 'U',
                          size: 100,
                          showBorder: true,
                          showEditIcon: true,
                          onTap: () => Navigator.pushNamed(
                              context, AppConstants.editProfileRoute),
                        ),
                        const SizedBox(height: 14),

                        // Name
                        Text(
                          user?.fullName ?? 'User',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        if (user?.bio != null && user!.bio!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            user.bio!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white54,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Edit Profile button
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pushNamed(
                              context, AppConstants.editProfileRoute),
                          icon: const Icon(Icons.edit_rounded,
                              color: Colors.white, size: 16),
                          label: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05),

                  const SizedBox(height: 20),

                  // ─── BUDGET CARD ──────────────────────────────────
                  if (budget > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GlassCard(
                        margin: EdgeInsets.zero,
                        onTap: () => Navigator.pushNamed(
                            context, AppConstants.budgetRoute),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.account_balance_wallet_rounded,
                                    color: AppTheme.accentGreen, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Monthly Budget',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF1E293B),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${(percent * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: percent > 0.9
                                        ? Colors.red
                                        : percent > 0.7
                                            ? AppTheme.accentOrange
                                            : AppTheme.accentGreen,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                backgroundColor: isDark
                                    ? Colors.white.withOpacity(0.08)
                                    : const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation(
                                  percent > 0.9
                                      ? Colors.red
                                      : percent > 0.7
                                          ? AppTheme.accentOrange
                                          : AppTheme.accentGreen,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Spent: ${context.read<CurrencyProvider>().currencySymbol}${spent.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                                Text(
                                  'Budget: ${context.read<CurrencyProvider>().currencySymbol}${budget.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white54
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 200.ms)
                        .slideY(begin: 0.05),

                  const SizedBox(height: 20),

                  // ─── INFO CARDS ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _ProfileInfoTile(
                          icon: Icons.phone_outlined,
                          label: 'Phone Number',
                          value: user?.phoneNumber ?? '-',
                          isDark: isDark,
                          index: 0,
                        ),
                        _ProfileInfoTile(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: user?.email ?? '-',
                          isDark: isDark,
                          index: 1,
                        ),
                        _ProfileInfoTile(
                          icon: Icons.verified_user_outlined,
                          label: 'Email Verified',
                          value:
                              (user?.isEmailVerified ?? false) ? 'Yes ✓' : 'No',
                          isDark: isDark,
                          valueColor: (user?.isEmailVerified ?? false)
                              ? AppTheme.accentGreen
                              : Colors.red,
                          index: 2,
                        ),
                        _ProfileInfoTile(
                          icon: Icons.calendar_today_outlined,
                          label: 'Member Since',
                          value: user != null
                              ? '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'
                              : '-',
                          isDark: isDark,
                          index: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── QUICK ACTIONS ────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ).animate().fadeIn(duration: 300.ms, delay: 500.ms),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.bar_chart_rounded,
                                label: 'Statistics',
                                color: AppTheme.accentPink,
                                isDark: isDark,
                                onTap: () => Navigator.pushNamed(
                                    context, AppConstants.statisticsRoute),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Budget',
                                color: AppTheme.accentGreen,
                                isDark: isDark,
                                onTap: () => Navigator.pushNamed(
                                    context, AppConstants.budgetRoute),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.settings_rounded,
                                label: 'Settings',
                                color: AppTheme.accentOrange,
                                isDark: isDark,
                                onTap: () => Navigator.pushNamed(
                                    context, AppConstants.settingsRoute),
                              ),
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(duration: 300.ms, delay: 600.ms)
                            .slideY(begin: 0.05),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── LOGOUT ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showLogoutDialog(context),
                        icon:
                            const Icon(Icons.logout_rounded, color: Colors.red),
                        label: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 300.ms, delay: 700.ms)
                        .slideY(begin: 0.1, end: 0),
                  ),
                  const SizedBox(height: 32),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppConstants.loginRoute,
                  (route) => false,
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ─── QUICK ACTION CARD ──────────────────────────────────────────────

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── PROFILE INFO TILE ──────────────────────────────────────────────

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final Color? valueColor;
  final int index;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.valueColor,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        margin: EdgeInsets.zero,
        enableAnimation: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: valueColor ??
                          (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (200 + index * 100).ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }
}
