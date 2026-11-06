import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/account_deletion_config.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_card.dart';

/// Provides the Google Play-required in-app pathway for users to request
/// deletion of their Pocketly account and associated data.
///
/// This screen intentionally submits a deletion request; it does not perform
/// destructive Firebase deletion directly on the client.
class AccountDeletionRequestScreen extends StatelessWidget {
  const AccountDeletionRequestScreen({super.key});

  bool get _supportEmailConfigured =>
      AccountDeletionConfig.supportEmail.isNotEmpty &&
      !AccountDeletionConfig.supportEmail.startsWith('REPLACE_');

  Future<void> _openDeletionPage(BuildContext context) async {
    final uri = Uri.parse(AccountDeletionConfig.deletionPageUrl);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the account deletion page.'),
        ),
      );
    }
  }

  Future<void> _requestByEmail(BuildContext context) async {
    if (!_supportEmailConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Pocketly support email is not configured yet. '
            'Set it before publishing the app.',
          ),
        ),
      );
      return;
    }

    final currentEmail = FirebaseAuth.instance.currentUser?.email?.trim();
    final registeredEmail = currentEmail != null && currentEmail.isNotEmpty
        ? currentEmail
        : '[enter your registered Pocketly email]';

    final body = '''Hello Pocketly Support,

I am requesting permanent deletion of my Pocketly account and the data associated with it.

Registered Pocketly email: $registeredEmail

I understand that account deletion is permanent and that I may be asked to verify ownership of the account.

Please do not ask me to send my password, PIN, or financial records.''';

    final uri = Uri(
      scheme: 'mailto',
      path: AccountDeletionConfig.supportEmail,
      queryParameters: {
        'subject': 'Pocketly account deletion request',
        'body': body,
      },
    );

    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not open an email app. Use the account deletion webpage instead.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryText =
        isDark ? Colors.white54 : const Color(0xFF64748B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delete Account'),
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassCard(
                enableAnimation: false,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Colors.red,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Request permanent account deletion',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: primaryText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pocketly currently processes account deletion by request. '
                      'Submitting a request does not delete the account instantly. '
                      'You may be asked to verify ownership before deletion is completed.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'WHAT WILL BE DELETED',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                enableAnimation: false,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    _DeletionItem(
                      icon: Icons.person_outline_rounded,
                      text: 'Firebase Authentication account',
                    ),
                    _DeletionItem(
                      icon: Icons.badge_outlined,
                      text: 'Pocketly profile information',
                    ),
                    _DeletionItem(
                      icon: Icons.payments_outlined,
                      text: 'Income and expense records',
                    ),
                    _DeletionItem(
                      icon: Icons.account_balance_wallet_outlined,
                      text: 'Budget and account-associated finance data',
                    ),
                    _DeletionItem(
                      icon: Icons.photo_outlined,
                      text: 'Uploaded profile photo, if present',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accentOrange.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      color: AppTheme.accentOrange,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Never send your password, PIN, bank details, or full transaction history in a deletion request.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: primaryText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _openDeletionPage(context),
                icon: const Icon(Icons.open_in_new_rounded),
                label: const Text('Open Account Deletion Page'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _requestByEmail(context),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Request Deletion by Email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Account deletion is permanent. Once completed, deleted account data normally cannot be restored.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletionItem extends StatelessWidget {
  const _DeletionItem({
    required this.icon,
    required this.text,
    this.showDivider = true,
  });

  final IconData icon;
  final String text;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          ),
      ],
    );
  }
}
