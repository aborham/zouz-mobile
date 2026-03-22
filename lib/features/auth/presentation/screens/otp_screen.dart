import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:zouz_mobile/features/auth/providers/auth_provider.dart';
import 'package:zouz_mobile/core/theme/colors.dart';
import 'package:pinput/pinput.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final _pinFocusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _pinFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isRtl = context.locale.languageCode == 'ar';

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.status == AuthStatus.authenticated) {
        context.go('/dashboard');
      } else if (next.status == AuthStatus.needsProfile) {
        context.push('/complete-profile');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 64,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            isRtl ? Icons.arrow_forward_ios_rounded : Icons.arrow_back_ios_new_rounded,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              final newLocale = isRtl ? const Locale('en') : const Locale('ar');
              context.setLocale(newLocale);
            },
            child: Text(
              isRtl ? 'English' : 'العربية',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'auth.otp_title'.tr(),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 12),
              Text(
                'auth.otp_subtitle'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: isRtl ? TextAlign.right : TextAlign.left,
              ),
              const SizedBox(height: 48),
              // OTP Input using Pinput for premium feel
              Center(
                child: Directionality(
                  textDirection: ui.TextDirection.ltr,
                  child: Pinput(
                    length: 6,
                    controller: _otpController,
                    focusNode: _pinFocusNode,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyWith(
                      decoration: defaultPinTheme.decoration!.copyWith(
                        color: Colors.white,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onCompleted: (pin) {
                      ref.read(authNotifierProvider.notifier).verifyOtp(pin);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Timer and Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time_rounded, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'auth.resend_timer'.tr(args: ['01:30']),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'auth.didnt_receive'.tr(),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              // Verify Button
              ElevatedButton(
                onPressed: authState.status == AuthStatus.loading
                    ? null
                    : () {
                        if (_otpController.text.length == 6) {
                          ref.read(authNotifierProvider.notifier).verifyOtp(_otpController.text);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'auth.verify_otp'.tr(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
