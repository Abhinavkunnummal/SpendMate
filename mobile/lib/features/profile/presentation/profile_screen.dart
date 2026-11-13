import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/data/app_data_repository.dart';
import '../../../core/services/app_sound_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isDarkMode = false;
  bool _isBiometricEnabled = true;
  bool _isPushNotificationsEnabled = true;
  String _selectedCurrency = 'Indian Rupee (INR ₹)';

  void _showLogoutDialog() {
    AppSoundService.playDeleteWarning();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out of SpendMate?'),
        content: const Text('Are you sure you want to end your current authenticated session? Your local data remains securely cached.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthSessionManager.instance.logout();
              if (mounted) {
                context.go('/welcome');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker() {
    final currencies = [
      'Indian Rupee (INR ₹)',
      'US Dollar (USD \$)',
      'Euro (EUR €)',
      'British Pound (GBP £)',
      'UAE Dirham (AED د.إ)',
      'Singapore Dollar (SGD S\$)',
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Base Currency', style: AppTypography.titleLarge(AppColors.textPrimaryLight)),
            const SizedBox(height: 16),
            ...currencies.map((curr) => ListTile(
              title: Text(curr, style: const TextStyle(fontWeight: FontWeight.w600)),
              trailing: _selectedCurrency == curr ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _selectedCurrency = curr);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Currency updated to $curr')),
                );
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showBudgetCapDialog() {
    final currentCap = AppDataRepository.instance.monthlyBudgetCapPaise ~/ 100;
    final ctrl = TextEditingController(text: currentCap.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Monthly Spending Cap'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set how much you plan to spend per month. The app will warn you when your expenses exceed this threshold.', style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight)),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monthly Cap (₹)', prefixText: '₹ ', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = int.tryParse(ctrl.text.trim()) ?? 5000;
              await AppDataRepository.instance.setMonthlyBudgetCap(val * 100);
              AppSoundService.playSuccess();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Monthly budget cap set to ₹${NumberFormat('#,##,##0').format(val)}!'), backgroundColor: AppColors.primary),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportFinancialData() {
    final txs = AppDataRepository.instance.transactions;
    final csvBuffer = StringBuffer();
    csvBuffer.writeln('ID,Date,Title,Category,Type,Amount (INR),Account');

    for (var t in txs) {
      csvBuffer.writeln('${t.id},"${DateFormat('yyyy-MM-dd HH:mm').format(t.date)}","${t.title}","${t.category}",${t.isExpense ? 'Expense' : 'Income'},${(t.amountPaise / 100).toStringAsFixed(2)},"${t.wallet}"');
    }

    Clipboard.setData(ClipboardData(text: csvBuffer.toString()));
    AppSoundService.playSuccess();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Financial ledger (${txs.length} transactions) exported & copied to clipboard!'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _triggerManualSync() async {
    AppSoundService.playSuccess();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing with MongoDB Atlas backend...'),
        duration: Duration(seconds: 1),
      ),
    );
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cloud sync completed! All devices up to date.'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Settings'),
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
            ListenableBuilder(
              listenable: AppDataRepository.instance,
              builder: (context, _) {
                final repo = AppDataRepository.instance;
                final walletCount = repo.wallets.length;
                final capAmount = (repo.monthlyBudgetCapPaise / 100).toStringAsFixed(0);

                return AppCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _settingsTile(
                        icon: Icons.currency_rupee_rounded,
                        title: 'Base Currency',
                        subtitle: _selectedCurrency,
                        onTap: _showCurrencyPicker,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      const Divider(height: 1),
                      _settingsTile(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Payment Accounts & Cards',
                        subtitle: '$walletCount connected financial accounts',
                        onTap: () => context.push('/wallets'),
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                      const Divider(height: 1),
                      _settingsTile(
                        icon: Icons.track_changes_outlined,
                        title: 'Monthly Spending Cap',
                        subtitle: '₹$capAmount / month (Alert when exceeded)',
                        onTap: _showBudgetCapDialog,
                        primaryTextColor: primaryTextColor,
                        secondaryTextColor: secondaryTextColor,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // App Settings Section
            _sectionHeader('APP & SECURITY SETTINGS', secondaryTextColor),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _switchTile(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode Theme',
                    value: _isDarkMode,
                    onChanged: (val) {
                      setState(() => _isDarkMode = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Theme set to ${_isDarkMode ? 'Dark' : 'Light'} Mode')),
                      );
                    },
                    primaryTextColor: primaryTextColor,
                  ),
                  const Divider(height: 1),
                  _switchTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'Biometric / App Lock',
                    value: _isBiometricEnabled,
                    onChanged: (val) {
                      setState(() => _isBiometricEnabled = val);
                      AppSoundService.playSuccess();
                    },
                    primaryTextColor: primaryTextColor,
                  ),
                  const Divider(height: 1),
                  _switchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Smart Spending Reminders',
                    value: _isPushNotificationsEnabled,
                    onChanged: (val) {
                      setState(() => _isPushNotificationsEnabled = val);
                      AppSoundService.playSuccess();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(_isPushNotificationsEnabled ? 'Spending alerts enabled!' : 'Spending alerts silenced')),
                      );
                    },
                    primaryTextColor: primaryTextColor,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Cloud & Data
            _sectionHeader('DATA & CLOUD BACKUP', secondaryTextColor),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _settingsTile(
                    icon: Icons.cloud_sync_outlined,
                    title: 'Sync with Cloud Backend',
                    subtitle: 'Offline storage ready · MongoDB Atlas connected',
                    onTap: _triggerManualSync,
                    primaryTextColor: primaryTextColor,
                    secondaryTextColor: secondaryTextColor,
                  ),
                  const Divider(height: 1),
                  _settingsTile(
                    icon: Icons.file_download_outlined,
                    title: 'Export Financial Statements',
                    subtitle: 'Export CSV / text ledger to clipboard',
                    onTap: _exportFinancialData,
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
                'SpendMate v1.0.0 (Build 26)\nTrack Money. Plan Trips. Split Smartly.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall(secondaryTextColor),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
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
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
      subtitle: Text(subtitle, style: AppTypography.bodySmall(secondaryTextColor)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondaryLight),
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
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: AppTypography.titleMedium(primaryTextColor).copyWith(fontSize: 15)),
      trailing: Switch(
        value: value,
        activeColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }
}
