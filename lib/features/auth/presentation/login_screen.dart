import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinput/pinput.dart';
import 'package:gap/gap.dart';
import '../providers/auth_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/app_snackbar.dart';
import '../../home/presentation/main_dashboard_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool _validateAndSendOtp() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      AppSnackBar.showError(context, title: 'Missing Number', message: 'Please enter your mobile number.');
      return false;
    }
    if (phone.length != 10) {
      AppSnackBar.showError(context, title: 'Invalid Length', message: 'Mobile number must be exactly 10 digits.');
      return false;
    }
    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(phone)) {
      AppSnackBar.showError(context, title: 'Invalid Number', message: 'Please enter a valid Indian mobile number starting with 6-9.');
      return false;
    }
    return true;
  }

  bool _validateOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      AppSnackBar.showError(context, title: 'Invalid OTP', message: 'Please enter the complete 6-digit OTP code.');
      return false;
    }
    return true;
  }

  Future<void> _handleOtpVerification(String pin) async {
    if (!_validateOtp()) return;
    final success = await ref.read(authProvider.notifier).verifyOtp(pin);
    if (!mounted) return;
    if (success) {
      final user = ref.read(authProvider).user;
      // If user is new (isNewUser == true), go to Profile Setup.
      // If user already exists (isNewUser == false), go directly to Main Dashboard (Home).
      if (user?.isNewUser == true) {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const ProfileSetupScreen()), (route) => false);
      } else {
        Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const MainDashboardScreen()), (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Custom Pinput Theme
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 54,
      textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        border: Border.all(color: AppColors.primary, width: 2),
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 8, offset: const Offset(0, 2))],
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration!.copyWith(
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.primary),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(20),

              // Brand Logo Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: AppColors.secondary.withValues(alpha: 0.08), blurRadius: 20, spreadRadius: 4)],
                  ),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 70,
                        width: 70,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.two_wheeler, size: 40, color: Colors.white),
                      );
                    },
                  ),
                ),
              ),

              const Gap(32),

              // Welcome Title
              Text(
                _otpSent ? 'Enter OTP Code' : 'Get Started with Ridonova',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textPrimary, letterSpacing: -0.5),
              ),
              const Gap(8),
              Text(
                _otpSent
                    ? 'Enter the 6-digit code sent to +91 ${_phoneController.text}'
                    : 'Enter your mobile number to log in or create an account',
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),

              const Gap(32),

              if (!_otpSent) ...[
                // Phone Number Input Card
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      // Country Code Tile
                      Row(
                        children: [
                          const Text('🇮🇳', style: TextStyle(fontSize: 20)),
                          const Gap(8),
                          const Text(
                            '+91',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Gap(12),
                          Container(height: 24, width: 1, color: Colors.grey.shade400),
                          const Gap(12),
                        ],
                      ),
                      // Mobile Field
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textPrimary),
                          decoration: const InputDecoration(
                            hintText: 'Enter Mobile Number',
                            hintStyle: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.normal, letterSpacing: 0),
                            counterText: '',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Gap(24),

                // Get OTP Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: authState.isLoading
                        ? null
                        : () async {
                            if (_validateAndSendOtp()) {
                              final success = await ref.read(authProvider.notifier).sendOtp(_phoneController.text);
                              if (success) {
                                final msg = ref.read(authProvider).successMessage;
                                if (!context.mounted) return;
                                setState(() {
                                  _otpSent = true;
                                });
                                if (msg != null) {
                                  AppSnackBar.showSuccess(context, title: 'OTP Sent', message: msg);
                                }
                              }
                            }
                          },
                    child: authState.isLoading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),
              ] else ...[
                // OTP Input Pinput Widget
                Center(
                  child: Pinput(
                    controller: _otpController,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: focusedPinTheme,
                    submittedPinTheme: submittedPinTheme,
                    showCursor: true,
                    onCompleted: _handleOtpVerification,
                  ),
                ),

                const Gap(28),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: authState.isLoading ? null : () => _handleOtpVerification(_otpController.text),
                    child: authState.isLoading
                        ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Verify & Proceed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ),
                ),

                const Gap(16),

                // Actions: Resend OTP / Change Number
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.refresh, size: 18, color: AppColors.secondary),
                      label: const Text(
                        'Resend OTP',
                        style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold),
                      ),
                      onPressed: authState.isLoading
                          ? null
                          : () async {
                              final success = await ref.read(authProvider.notifier).resendOtp();
                              if (success) {
                                if (!context.mounted) return;
                                AppSnackBar.showSuccess(
                                  context,
                                  title: 'OTP Resent',
                                  message: 'A new 6-digit OTP has been sent to +91 ${_phoneController.text}',
                                );
                              }
                            },
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                      label: const Text(
                        'Edit Number',
                        style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        setState(() {
                          _otpSent = false;
                          _otpController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ],

              if (authState.errorMessage != null) ...[
                const Gap(20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          authState.errorMessage!,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Gap(40),

              // Footer / Terms & Privacy
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    'By continuing, you agree to Ridonova\'s Terms of Service & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
