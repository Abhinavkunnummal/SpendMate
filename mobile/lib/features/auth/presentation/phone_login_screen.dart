import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/auth/auth_session_manager.dart';
import '../../../core/services/app_sound_service.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  int _loginMode = 0; // 0: Password Login, 1: Phone OTP Login

  // Password Login State
  final _loginIdentifierController = TextEditingController(text: '9876543210');
  final _passwordController = TextEditingController(text: 'SpendMate@2026');
  final _nameController = TextEditingController();
  bool _obscurePassword = true;

  // OTP Login State
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
    _loginIdentifierController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
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

  void _handlePasswordLogin() async {
    final identifier = _loginIdentifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number or email')),
      );
      return;
    }

    if (password.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 4 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final resolvedName = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'User ${identifier.length >= 4 ? identifier.substring(identifier.length - 4) : identifier}';

    await AuthSessionManager.instance.loginSuccess(
      token: 'pwd_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'pwd_refresh_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      userName: resolvedName,
      phoneNumber: identifier,
    );

    AppSoundService.playIncomeChime();

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Welcome back, $resolvedName! Session saved.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/dashboard');
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
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

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signed in with Google as $name ($email)! Session saved.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.go('/dashboard');
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
    Future.delayed(const Duration(milliseconds: 300), () {
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

  void _handleVerifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all 6 digits of the OTP code')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();

    await AuthSessionManager.instance.loginSuccess(
      token: 'otp_token_${DateTime.now().millisecondsSinceEpoch}',
      refreshToken: 'otp_refresh_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'usr_otp_${DateTime.now().millisecondsSinceEpoch}',
      userName: 'Member ${phone.length >= 4 ? phone.substring(phone.length - 4) : phone}',
      phoneNumber: phone,
    );

    AppSoundService.playIncomeChime();

    if (!mounted) return;
    setState(() => _isLoading = false);
    context.go('/dashboard');
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // SpendMate Branding Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16A878), Color(0xFF0F766E)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.wallet_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 18),

              Text('Sign in to SpendMate', style: AppTypography.displayMedium(primaryTextColor).copyWith(fontSize: 26)),
              const SizedBox(height: 6),
              Text('Access your personal finances, group trips, and smart splits.', style: AppTypography.bodySmall(secondaryTextColor)),
              const SizedBox(height: 20),

              // Login Mode Toggle
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    _modeTab('Password Login', 0, isDark),
                    _modeTab('Phone OTP', 1, isDark),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_loginMode == 0) ...[
                // PASSWORD LOGIN FORM
                Text('PHONE NUMBER OR EMAIL', style: AppTypography.labelSmall(secondaryTextColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: _loginIdentifierController,
                  decoration: InputDecoration(
                    hintText: 'e.g. 9876543210 or user@example.com',
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),

                Text('PASSWORD', style: AppTypography.labelSmall(secondaryTextColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'Enter your account password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),

                Text('NAME (FOR DISPLAY & TRIPS)', style: AppTypography.labelSmall(secondaryTextColor)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Abhinav K',
                    prefixIcon: const Icon(Icons.badge_outlined),
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 24),

                AppButton(
                  text: 'Sign In with Password',
                  isLoading: _isLoading,
                  onPressed: _handlePasswordLogin,
                ),
              ] else ...[
                // OTP LOGIN FORM
                if (!_isOtpSent) ...[
                  Text('MOBILE PHONE NUMBER', style: AppTypography.labelSmall(secondaryTextColor)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      prefixText: '+91 ',
                      prefixStyle: TextStyle(fontWeight: FontWeight.w700, color: primaryTextColor),
                      prefixIcon: const Icon(Icons.phone_iphone_rounded),
                      filled: true,
                      fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Get 6-Digit Verification Code',
                    isLoading: _isLoading,
                    onPressed: _handleSendOtp,
                  ),
                ] else ...[
                  Text('ENTER 6-DIGIT OTP', style: AppTypography.labelSmall(secondaryTextColor)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return SizedBox(
                        width: 46,
                        height: 52,
                        child: TextField(
                          controller: _otpControllers[i],
                          focusNode: _focusNodes[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            if (val.isNotEmpty && i < 5) {
                              _focusNodes[i + 1].requestFocus();
                            } else if (val.isEmpty && i > 0) {
                              _focusNodes[i - 1].requestFocus();
                            }
                          },
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Verify & Enter SpendMate',
                    isLoading: _isLoading,
                    onPressed: _handleVerifyOtp,
                  ),
                ],
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text('OR', style: AppTypography.labelSmall(secondaryTextColor)),
                  ),
                  Expanded(child: Divider(color: isDark ? AppColors.borderDark : AppColors.borderLight)),
                ],
              ),
              const SizedBox(height: 18),

              // Official Google Sign-In Card
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _handleGoogleSignIn,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    side: BorderSide(color: isDark ? AppColors.borderDark : Colors.grey.shade300, width: 1.2),
                    backgroundColor: isDark ? AppColors.cardDark : Colors.white,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFF4285F4),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: primaryTextColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeTab(String title, int mode, bool isDark) {
    final isSelected = _loginMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          AppSoundService.playSuccess();
          setState(() => _loginMode = mode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
