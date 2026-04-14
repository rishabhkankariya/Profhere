import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.user != null) {
        switch (next.user!.role.name) {
          case 'admin':   context.go(AppRoutes.admin);
          case 'faculty': context.go(AppRoutes.facultyDashboard);
          default:        context.go(AppRoutes.faculties);
        }
      }
      if (next.error != null) {
        Toast.error(context, next.error!, title: 'Sign In Failed');
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 56),
            // Header
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Icon(Icons.school_rounded, size: 26, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('Welcome back',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('Sign in to your ProfHere account',
                style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
            const SizedBox(height: 36),

            // Form
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email address',
                    prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
              ]),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPassword(context),
                child: const Text('Forgot password?',
                    style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _login,
                child: auth.isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Sign In'),
              ),
            ),

            const SizedBox(height: 28),
            _buildDivider('quick access'),
            const SizedBox(height: 16),
            // Quick access buttons for demo
            Row(children: [
              Expanded(child: _QuickBtn(label: 'Admin',   icon: Icons.shield_outlined,  color: AppColors.error,
                  onTap: () { _emailCtrl.text = 'admin@profhere.com'; _passCtrl.text = 'admin123'; })),
              const SizedBox(width: 10),
              Expanded(child: _QuickBtn(label: 'Faculty', icon: Icons.person_outlined,  color: AppColors.primary,
                  onTap: () { _emailCtrl.text = 'sarah.mitchell@profhere.com'; _passCtrl.text = 'faculty123'; })),
              const SizedBox(width: 10),
              Expanded(child: _QuickBtn(label: 'Student', icon: Icons.school_outlined,  color: AppColors.info,
                  onTap: () { _emailCtrl.text = 'alex.thompson@student.profhere.com'; _passCtrl.text = 'student123'; })),
            ]),

            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text("Don't have an account? ",
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              GestureDetector(
                onTap: () => context.go(AppRoutes.register),
                child: const Text('Sign up',
                    style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  Widget _buildDivider(String label) {
    return Row(children: [
      const Expanded(child: Divider()),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ),
      const Expanded(child: Divider()),
    ]);
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter your email and we\'ll send a reset link.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier).sendPasswordReset(ctrl.text.trim());
              if (context.mounted) Toast.success(context, 'Reset email sent. Check your inbox.');
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
