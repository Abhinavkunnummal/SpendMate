import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/services/app_sound_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // App Branding Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SpendMate',
                      style: AppTypography.labelLarge(AppColors.primary),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Hero Visual Graphic Cards Stack (Apple Wallet inspired)
              Container(
                width: 240,
                height: 190,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 28),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Net Worth',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '₹1,42,850',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Headline & Subtitle
              Text(
                'Track Money.\nPlan Trips. Split Smartly.',
                textAlign: TextAlign.center,
                style: AppTypography.displayMedium(primaryTextColor),
              ),
              const SizedBox(height: 12),
              Text(
                'Personal expense tracking and multi-payer group splits engineered for effortless financial clarity.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(secondaryTextColor),
              ),
              const SizedBox(height: 28),

              // Value Pillars
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _featurePill('Multi-Payer Splits', Icons.call_split_rounded, isDark),
                  _featurePill('Debt Minimizer', Icons.auto_graph_rounded, isDark),
                  _featurePill('Offline Ready', Icons.cloud_done_rounded, isDark),
                ],
              ),
              const SizedBox(height: 36),

              // Actions
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () async {
                    AppSoundService.playIncomeChime();
                    const email = 'abhinavdev810@gmail.com';
                    const name = 'Abhinav Dev';
                    await AuthSessionManager.instance.loginSuccess(
                      token: 'google_oauth_token_${DateTime.now().millisecondsSinceEpoch}',
                      refreshToken: 'google_refresh_${DateTime.now().millisecondsSinceEpoch}',
                      userId: 'usr_google_abhinavdev',
                      userName: name,
                      phoneNumber: email,
                      firebaseUid: 'firebase_uid_${email.hashCode.abs()}',
                    );
                    if (context.mounted) context.go('/dashboard');
                  },
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Color(0xFF4285F4), shape: BoxShape.circle),
                        child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Text('Continue with Google', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              AppButton(
                text: 'Get Started with Phone / Password',
                onPressed: () => context.push('/login'),
              ),
              const SizedBox(height: 12),
              AppButton(
                text: 'I already have an account',
                variant: ButtonVariant.ghost,
                onPressed: () => context.push('/login'),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featurePill(String text, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.labelSmall(
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
