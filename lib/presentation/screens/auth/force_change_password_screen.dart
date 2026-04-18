import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

class ForceChangePasswordScreen extends ConsumerStatefulWidget {
  const ForceChangePasswordScreen({super.key});
  @override
  ConsumerState<ForceChangePasswordScreen> createState() =>
      _ForceChangePasswordScreenState();
}

class _ForceChangePasswordScreenState
    extends ConsumerState<ForceChangePasswordScreen> {
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading  = false;
  String? _error;

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final newPass = _newCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (newPass.isEmpty) {
      setState(() => _error = 'Enter a new password');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _error = 'Minimum 6 characters');
      return;
    }
    if (newPass != confirm) {
      setState(() => _error = 'Passwords do not match');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final fbUser = fb.FirebaseAuth.instance.currentUser;
      if (fbUser == null) throw Exception('Not signed in');

      // Update Firebase Auth password
      await fbUser.updatePassword(newPass);

      // Clear the mustChangePassword flag in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(fbUser.uid)
          .update({'mustChangePassword': false});

      // Refresh user in state
      final user = ref.read(authNotifierProvider).user;
      if (user != null) {
        ref.read(authNotifierProvider.notifier).hydrateFromRepository(
          user.copyWith(mustChangePassword: false),
        );
      }

      if (!mounted) return;
      // Navigate to faculty dashboard
      context.go(AppRoutes.facultyDashboard);
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 24),

              const Text(
                'Set your password',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your account was created with a temporary password. Please set a new secure password to continue.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: AppColors.primary, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'A password reset link has also been sent to your email. You can use either method.',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          height: 1.4),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // New password
              TextField(
                controller: _newCtrl,
                obscureText: _obscure1,
                decoration: InputDecoration(
                  labelText: 'New password',
                  prefixIcon:
                      const Icon(Icons.lock_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure1
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscure1 = !_obscure1),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Confirm password
              TextField(
                controller: _confirmCtrl,
                obscureText: _obscure2,
                decoration: InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon:
                      const Icon(Icons.lock_rounded, size: 18),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure2
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    onPressed: () =>
                        setState(() => _obscure2 = !_obscure2),
                  ),
                ),
              ),

              if (_error != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                        color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Set Password & Continue'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
