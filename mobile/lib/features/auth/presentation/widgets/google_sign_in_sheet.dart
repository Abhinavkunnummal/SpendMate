import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/auth/auth_session_manager.dart';
import '../../../../core/services/app_sound_service.dart';
import '../../../../core/theme/app_colors.dart';

class GoogleSignInSheet {
  static Future<void> show(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          bool isAddingCustom = false;
          final customEmailCtrl = TextEditingController();
          final customNameCtrl = TextEditingController();
          bool isSigningIn = false;

          Future<void> signInWithAccount(String email, String name) async {
            setSheetState(() => isSigningIn = true);
            AppSoundService.playIncomeChime();

            await Future.delayed(const Duration(milliseconds: 400));

            await AuthSessionManager.instance.loginSuccess(
              token: 'google_oauth_${DateTime.now().millisecondsSinceEpoch}',
              refreshToken: 'google_refresh_${DateTime.now().millisecondsSinceEpoch}',
              userId: 'usr_g_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
              userName: name,
              phoneNumber: email,
              firebaseUid: 'firebase_uid_${email.hashCode.abs()}',
            );

            if (ctx.mounted) Navigator.pop(ctx);
            if (context.mounted) context.go('/dashboard');
          }

          return Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Google Logo
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4285F4),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Sign in with Google',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose an account to continue to SpendMate',
                    style: TextStyle(fontSize: 13, color: secondaryTextColor),
                  ),
                  const SizedBox(height: 20),

                  if (isSigningIn)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Signing into SpendMate...'),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    // Default Account 1: Abhinav Dev
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => signInWithAccount('abhinavdev810@gmail.com', 'Abhinav Dev'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF4285F4).withOpacity(0.15),
                              child: const Text('AD', style: TextStyle(color: Color(0xFF4285F4), fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Abhinav Dev',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: primaryTextColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'abhinavdev810@gmail.com',
                                    style: TextStyle(fontSize: 12, color: secondaryTextColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Custom Account Option
                    if (!isAddingCustom) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => setSheetState(() => isAddingCustom = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: isDark ? AppColors.borderDark : Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
                                child: Icon(Icons.person_add_alt_1_rounded, color: secondaryTextColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  'Use another Google account',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: primaryTextColor),
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: secondaryTextColor, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ENTER GOOGLE ACCOUNT DETAILS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            TextField(
                              controller: customNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Your Full Name',
                                hintText: 'e.g. Rahul Sharma',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: customEmailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Google Email Address',
                                hintText: 'e.g. rahul@gmail.com',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => setSheetState(() => isAddingCustom = false),
                                  child: const Text('Cancel'),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    final name = customNameCtrl.text.trim();
                                    final email = customEmailCtrl.text.trim();
                                    if (name.isEmpty || email.isEmpty || !email.contains('@')) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Please enter valid name and email')),
                                      );
                                      return;
                                    }
                                    signInWithAccount(email, name);
                                  },
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Sign In'),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],

                  const SizedBox(height: 20),
                  Text(
                    'To continue, Google will share your name and email address with SpendMate.',
                    style: TextStyle(fontSize: 11, color: secondaryTextColor, height: 1.3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
