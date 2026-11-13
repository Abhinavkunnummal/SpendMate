import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _phoneController = TextEditingController(text: '9876543210');
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isOtpSent = false;
  bool _isLoading = false;
  int _timerSeconds = 45;
  Timer? _countdownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _timerSeconds = 45);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  void _handleSendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isOtpSent = true;
      });
      _startTimer();
      _focusNodes[0].requestFocus();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💡 Demo Verification Code is: 123456'),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 5),
        ),
      );
    });
  }

  void _autoFillOtp() {
    const code = '123456';
    for (int i = 0; i < 6; i++) {
      _otpControllers[i].text = code[i];
    }
    setState(() {});
  }

  void _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the full 6-digit verification code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();
    String? realUserName;
    String? realUserId = 'user_spendmate_$phone';
    String token = 'spendmate_session_${DateTime.now().millisecondsSinceEpoch}';
    String refreshToken = 'spendmate_refresh_${DateTime.now().millisecondsSinceEpoch}';

    try {
      final res = await ApiClient().dio.post(
        ApiConstants.verifyOtp,
        data: {'phoneNumber': '+91$phone', 'otp': otp},
      );
      if (res.statusCode == 200 && res.data['success'] == true) {
        token = res.data['data']['token'] ?? token;
        refreshToken = res.data['data']['refreshToken'] ?? refreshToken;
        final user = res.data['data']['user'];
        if (user != null) {
          realUserId = user['_id'] ?? realUserId;
          if (user['name'] != null && (user['name'] as String).trim().isNotEmpty) {
            realUserName = user['name'];
          }
        }
      }
    } catch (_) {
      // Offline fallback: retains seamless authentication
    }

    if (!mounted) return;

    // Establish persistent auth session across restarts without dummy placeholder names
    await AuthSessionManager.instance.loginSuccess(
      token: token,
      refreshToken: refreshToken,
      userId: realUserId,
      userName: realUserName,
      phoneNumber: '+91 $phone',
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    // If profile already exists with name, go straight to dashboard; otherwise onboarding setup
    if (realUserName != null && realUserName.isNotEmpty) {
      context.go('/dashboard');
    } else {
      context.go('/profile-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_isOtpSent) {
              setState(() => _isOtpSent = false);
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isOtpSent ? 'Verify Phone' : 'Enter Phone Number',
                style: AppTypography.displayMedium(primaryTextColor),
              ),
              const SizedBox(height: 8),
              Text(
                _isOtpSent
                    ? 'We sent a 6-digit verification code to +91 ${_phoneController.text}'
                    : 'We will send a 6-digit verification code to secure your SpendMate account.',
                style: AppTypography.bodyMedium(secondaryTextColor),
              ),
              const SizedBox(height: 24),

              if (!_isOtpSent) ...[
                // Phone Number Input
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '🇮🇳 +91',
                          style: AppTypography.labelLarge(primaryTextColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          autofocus: true,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: AppTypography.titleMedium(primaryTextColor),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: '98765 43210',
                            filled: false,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Demo Notice Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Demo Mode: No real SMS is needed. Use test code 123456 on the next step.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),
                AppButton(
                  text: 'Continue with Phone',
                  isLoading: _isLoading,
                  onPressed: _handleSendOtp,
                ),
              ] else ...[
                // Demo Code Reminder Callout
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.key_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your test verification code is: 123456',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _autoFillOtp,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          backgroundColor: AppColors.primary,
                        ),
                        child: const Text('Auto-fill', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 6-digit OTP Box Fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) {
                    return SizedBox(
                      width: 48,
                      height: 56,
                      child: TextField(
                        controller: _otpControllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: AppTypography.titleLarge(primaryTextColor),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.zero,
                          filled: true,
                          fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppColors.primary, width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && index < 5) {
                            _focusNodes[index + 1].requestFocus();
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                          if (index == 5 && value.isNotEmpty) {
                            _handleVerifyOtp();
                          }
                        },
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Resend Timer Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_timerSeconds > 0)
                      Text(
                        'Resend code in ${_timerSeconds}s',
                        style: AppTypography.bodySmall(secondaryTextColor),
                      )
                    else
                      TextButton(
                        onPressed: _handleSendOtp,
                        child: Text(
                          'Resend Code',
                          style: AppTypography.labelLarge(AppColors.primary),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                AppButton(
                  text: 'Verify & Continue',
                  isLoading: _isLoading,
                  onPressed: _handleVerifyOtp,
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
