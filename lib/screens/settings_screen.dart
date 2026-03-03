import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/currency_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/currency_helper.dart';
import '../widgets/glass_card.dart';

/// SettingsScreen - App settings including theme, currency, password change, and about.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── APPEARANCE ─────────────────────────────────────────
              _SectionHeader(title: 'Appearance', isDark: isDark),
              const SizedBox(height: 12),
              Consumer<ThemeProvider>(
                builder: (context, theme, _) {
                  return _SettingsTile(
                    icon: theme.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    subtitle:
                        theme.isDarkMode ? 'Currently dark' : 'Currently light',
                    color: AppTheme.accentOrange,
                    isDark: isDark,
                    trailing: Switch(
                      value: theme.isDarkMode,
                      onChanged: (_) => theme.toggleTheme(),
                      activeColor: AppTheme.primaryColor,
                    ),
                    onTap: () => theme.toggleTheme(),
                    index: 0,
                  );
                },
              ),
              const SizedBox(height: 8),
              Consumer<CurrencyProvider>(
                builder: (context, currencyProvider, _) {
                  return _SettingsTile(
                    icon: Icons.language_rounded,
                    title: 'Country & Currency',
                    subtitle:
                        '${currencyProvider.flag} ${currencyProvider.countryName} (${currencyProvider.currencySymbol})',
                    color: AppTheme.accentCyan,
                    isDark: isDark,
                    onTap: () => _showCountryPicker(context, isDark),
                    index: 1,
                  );
                },
              ),
              const SizedBox(height: 24),

              // ─── ACCOUNT ───────────────────────────────────────────
              _SectionHeader(title: 'Account', isDark: isDark),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Edit Profile',
                subtitle: 'Name, phone, bio, photo',
                color: AppTheme.primaryColor,
                isDark: isDark,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.editProfileRoute),
                index: 1,
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                subtitle: 'Update your password',
                color: AppTheme.accentCyan,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.changePasswordRoute),
                index: 2,
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.fingerprint_rounded,
                title: 'Security',
                subtitle: 'PIN & fingerprint login',
                color: AppTheme.accentPink,
                isDark: isDark,
                onTap: () => Navigator.pushNamed(
                    context, AppConstants.securitySettingsRoute),
                index: 3,
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Budget',
                subtitle: 'Set monthly spending limit',
                color: AppTheme.accentGreen,
                isDark: isDark,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.budgetRoute),
                index: 4,
              ),
              const SizedBox(height: 24),

              // ─── DATA ──────────────────────────────────────────────
              _SectionHeader(title: 'Data', isDark: isDark),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.history_rounded,
                title: 'Expense History',
                subtitle: 'View and export all expenses',
                color: AppTheme.accentPurple,
                isDark: isDark,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.historyRoute),
                index: 4,
              ),
              const SizedBox(height: 8),
              _SettingsTile(
                icon: Icons.bar_chart_rounded,
                title: 'Statistics',
                subtitle: 'Charts and spending insights',
                color: AppTheme.accentPink,
                isDark: isDark,
                onTap: () =>
                    Navigator.pushNamed(context, AppConstants.statisticsRoute),
                index: 5,
              ),
              const SizedBox(height: 24),

              // ─── ABOUT ─────────────────────────────────────────────
              _SectionHeader(title: 'About', isDark: isDark),
              const SizedBox(height: 12),
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About App',
                subtitle: 'Version 1.0.0',
                color: const Color(0xFF78909C),
                isDark: isDark,
                onTap: () => _showAboutDialog(context, isDark),
                index: 6,
              ),
              const SizedBox(height: 32),

              // ─── LOGOUT ────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showLogoutDialog(context, isDark),
                  icon: const Icon(Icons.logout_rounded, color: Colors.red),
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showCountryPicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _CountryPickerSheet(isDark: isDark),
    );
  }

  void _showAboutDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              AppConstants.appFullName,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              AppConstants.appTagline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: AppTheme.accentPink,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Made with love by Faizul Ishfak',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, bool isDark) {
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;

  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;
  final Widget? trailing;
  final int index;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.isDark,
    this.onTap,
    this.trailing,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: EdgeInsets.zero,
      onTap: onTap,
      enableAnimation: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
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
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
              ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: (100 + index * 80).ms)
        .slideX(begin: 0.05, end: 0, duration: 300.ms);
  }
}

// ─── COUNTRY PICKER BOTTOM SHEET ────────────────────────────────────

class _CountryPickerSheet extends StatefulWidget {
  final bool isDark;

  const _CountryPickerSheet({required this.isDark});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<CurrencyInfo> _filtered = CurrencyHelper.allCurrencies;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = CurrencyHelper.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencyProvider = context.watch<CurrencyProvider>();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // ─── Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.white24 : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // ─── Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                'Select Country & Currency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
            // ─── Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearch,
                decoration: InputDecoration(
                  hintText: 'Search country or currency...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: widget.isDark
                      ? Colors.white.withOpacity(0.06)
                      : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 4),
            // ─── Country list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final info = _filtered[index];
                  final isSelected =
                      info.countryCode == currencyProvider.currency.countryCode;

                  return ListTile(
                    dense: true,
                    leading:
                        Text(info.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      info.countryName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : (widget.isDark
                                ? Colors.white
                                : const Color(0xFF1E293B)),
                      ),
                    ),
                    subtitle: Text(
                      '${info.currencyCode}  ${info.currencySymbol}',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDark
                            ? Colors.white38
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: AppTheme.primaryColor, size: 20)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () {
                      currencyProvider.setCountry(info);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
