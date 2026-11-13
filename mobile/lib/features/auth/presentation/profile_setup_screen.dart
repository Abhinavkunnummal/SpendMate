import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/app_card.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nameController = TextEditingController(text: 'Kunal Verma');
  final _emailController = TextEditingController(text: 'kunal@example.com');
  final _budgetController = TextEditingController(text: '50000');
  String _selectedCurrency = 'INR';
  bool _isLoading = false;

  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'symbol': '₹', 'label': 'Indian Rupee'},
    {'code': 'USD', 'symbol': '\$', 'label': 'US Dollar'},
    {'code': 'EUR', 'symbol': '€', 'label': 'Euro'},
    {'code': 'GBP', 'symbol': '£', 'label': 'British Pound'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      context.go('/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar selector with camera badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                    child: Text(
                      'KV',
                      style: AppTypography.displayMedium(AppColors.primary),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Personalize Your Account',
                style: AppTypography.titleLarge(primaryTextColor),
              ),
              const SizedBox(height: 6),
              Text(
                'Customize your identity and core financial settings.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(secondaryTextColor),
              ),
              const SizedBox(height: 32),

              // Full Name Field
              AppTextField(
                label: 'Full Name',
                hint: 'e.g. Alex Morgan',
                controller: _nameController,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
              ),
              const SizedBox(height: 18),

              // Email Field (Optional)
              AppTextField(
                label: 'Email Address (Optional)',
                hint: 'alex@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
              ),
              const SizedBox(height: 18),

              // Currency Picker
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Currency',
                    style: AppTypography.labelSmall(secondaryTextColor),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCurrency,
                        isExpanded: true,
                        dropdownColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: _currencies.map((curr) {
                          return DropdownMenuItem<String>(
                            value: curr['code'],
                            child: Row(
                              children: [
                                Text(
                                  curr['symbol']!,
                                  style: AppTypography.titleMedium(AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${curr['code']} - ${curr['label']}',
                                  style: AppTypography.bodyMedium(primaryTextColor),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCurrency = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Monthly Budget Target Field
              AppTextField(
                label: 'Monthly Spending Target (₹)',
                hint: '50000',
                controller: _budgetController,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.track_changes_rounded, size: 20),
              ),
              const SizedBox(height: 36),

              // Complete Setup CTA
              AppButton(
                text: 'Complete Setup',
                isLoading: _isLoading,
                onPressed: _handleComplete,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
