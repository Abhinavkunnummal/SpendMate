import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/auth/auth_session_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _isBiometricEnabled = true;
  bool _isPushNotificationsEnabled = true;

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of SpendMate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthSessionManager.instance.logout();
              if (mounted) {
                context.go('/welcome');
              }
            },
            child: const Text('Log Out', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Profile Card
            ListenableBuilder(
              listenable: AuthSessionManager.instance,
              builder: (context, _) {
                final auth = AuthSessionManager.instance;
                final displayName = auth.displayName;
                final displayPhone = auth.phoneNumber ?? 'No phone linked';
                final initials = auth.userInitials;

                return AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                        child: Text(
                          initials,
                          style: AppTypography.titleLarge(AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.titleMedium(primaryTextColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              displayPhone,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20),
                        onPressed: () => context.push('/profile-setup'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Financial Preferences Section
            _sectionHeader('FINANCIAL PREFERENCES', secondaryTextColor),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _settingsTile(
                    icon: Icons.currency_rupee_rounded,
                    title: 'Base Currency',
                    subtitle: 'Indian Rupee (INR ₹)',
                    onTap: () {},
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  const Divider(),
                  _settingsTile(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'Payment Wallets',
                    subtitle: '4 connected accounts',
                    onTap: () => context.push('/wallets'),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  const Divider(),
                  _settingsTile(
                    icon: Icons.track_changes_outlined,
                    title: 'Monthly Spending Target',
                    subtitle: '₹50,000 / month',
                    onTap: () => context.push('/budgets'),
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Settings Section
            _sectionHeader('APP SETTINGS', secondaryTextColor),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    value: _isDarkMode,
                    onChanged: (val) => setState(() => _isDarkMode = val),
                    primaryTextColor: primaryTextColor,
                  ),
                  const Divider(),
                  _switchTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric / Face ID',
                    value: _isBiometricEnabled,
                    onChanged: (val) => setState(() => _isBiometricEnabled = val),
                    primaryTextColor: primaryTextColor,
                  ),
                  const Divider(),
                  _switchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Push Notifications',
                    value: _isPushNotificationsEnabled,
                    onChanged: (val) => setState(() => _isPushNotificationsEnabled = val),
                    primaryTextColor: primaryTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cloud & Data
            _sectionHeader('DATA & CLOUD SYNC', secondaryTextColor),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _settingsTile(
                    icon: Icons.cloud_done_outlined,
                    title: 'Sync Status',
                    subtitle: 'Offline cache active · Cloud up to date',
                    onTap: () {},
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  const Divider(),
                  _settingsTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export Financial Data',
                    subtitle: 'Download Excel / CSV statements',
                    onTap: () {},
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            AppButton(
              text: 'Log Out',
              variant: ButtonVariant.outline,
              icon: const Icon(Icons.logout_rounded, color: AppColors.coral, size: 20),
              onPressed: _showLogoutDialog,
            ),
            const SizedBox(height: 16),

            // App Version Info
            Center(
              child: Text(
                'SpendMate v1.0.0 (Build 24)\nDesigned with Apple Elegance',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(secondaryTextColor),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: AppTypography.labelSmall(color),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color primaryTextColor,
    required Color secondaryTextColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
      subtitle: Text(subtitle, style: AppTypography.bodySmall(secondaryTextColor)),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color primaryTextColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
      trailing: Switch.adaptive(
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
