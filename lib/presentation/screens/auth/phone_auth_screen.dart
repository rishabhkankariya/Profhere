import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

class PhoneAuthScreen extends ConsumerStatefulWidget {
  const PhoneAuthScreen({super.key});
  @override
  ConsumerState<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends ConsumerState<PhoneAuthScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl   = TextEditingController();

  String? _verificationId;
  bool _codeSent  = false;
  bool _loading   = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      Toast.error(context, 'Enter a valid phone number with country code.\nExample: +91 9876543210');
      return;
    }
    setState(() => _loading = true);

    await ref.read(authNotifierProvider.notifier).verifyPhoneNumber(
      phoneNumber: phone,
      onCodeSent: (id) {
        setState(() { _verificationId = id; _codeSent = true; _loading = false; });
        Toast.success(context, 'OTP sent to $phone', title: 'Code Sent');
      },
      onFailed: (err) {
        setState(() => _loading = false);
        Toast.error(context, err, title: 'Verification Failed');
      },
    );
  }

  Future<void> _verifyCode() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) {
      Toast.warning(context, 'Enter the 6-digit OTP from your SMS.');
      return;
    }
    setState(() => _loading = true);
    await ref.read(authNotifierProvider.notifier).signInWithPhoneOtp(
      verificationId: _verificationId!,
      smsCode: code,
    );
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.user != null) {
        Toast.success(context, 'Signed in successfully!');
        context.go(AppRoutes.faculties);
      }
      if (next.error != null) {
        Toast.error(context, next.error!, title: 'Sign In Failed');
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 16),
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.phone_android_rounded, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              _codeSent ? 'Enter OTP' : 'Phone Sign In',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              _codeSent
                  ? 'Enter the 6-digit code sent to ${_phoneCtrl.text.trim()}'
                  : 'Enter your phone number with country code to receive an OTP.',
              style: const TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
            ),
            const SizedBox(height: 32),

            if (!_codeSent) ...[
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '+91 9876543210',
                  prefixIcon: Icon(Icons.phone_outlined, size: 18),
                ),
              ),
              const SizedBox(height: 8),
              // Demo hint
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Demo: Use +1 650-555-3434 with code 123456',
                    style: TextStyle(fontSize: 12, color: AppColors.primary),
                  )),
                ]),
              ),
            ] else ...[
              // OTP input boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => _OtpBox(
                  index: i,
                  controller: _otpCtrl,
                  onChanged: (val) {
                    if (_otpCtrl.text.length == 6) _verifyCode();
                  },
                )),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _loading ? null : () => setState(() { _codeSent = false; _otpCtrl.clear(); }),
                child: const Text('Change phone number',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ),
            ],

            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : (_codeSent ? _verifyCode : _sendCode),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_codeSent ? 'Verify OTP' : 'Send OTP'),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final void Function(String) onChanged;
  const _OtpBox({required this.index, required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, height: 52,
      child: TextField(
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onChanged: (v) {
          // Build full OTP string from individual boxes
          if (v.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          }
          onChanged(v);
        },
      ),
    );
  }
}
