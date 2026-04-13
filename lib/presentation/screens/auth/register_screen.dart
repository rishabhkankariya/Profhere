import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _emailCtrl  = TextEditingController();
  final _codeCtrl   = TextEditingController();
  final _phoneCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  final _confirmCtrl= TextEditingController();

  bool _obscure  = true;
  bool _obscureC = true;
  bool _humanChecked = false; // simple captcha checkbox
  int? _selectedYear;

  static const _years = [1, 2, 3, 4, 5];

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _codeCtrl, _phoneCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_humanChecked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please confirm you are not a robot'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    await ref.read(authNotifierProvider.notifier).register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
      studentCode: _codeCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      yearOfStudy: _selectedYear,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.emailVerificationSent) {
        _showVerificationDialog();
      }
      if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ));
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 4),
            const Text('Create account',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('Join ProfHere as a student',
                style: TextStyle(fontSize: 15, color: AppColors.textMuted)),
            const SizedBox(height: 28),

            Form(
              key: _formKey,
              child: Column(children: [
                // Full name
                _tf(_nameCtrl, 'Full name', Icons.person_outline_rounded,
                    caps: TextCapitalization.words,
                    validator: (v) => (v == null || v.isEmpty) ? 'Enter your name' : null),
                const SizedBox(height: 12),

                // Email
                _tf(_emailCtrl, 'Email address', Icons.alternate_email_rounded,
                    type: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter your email';
                      if (!RegExp(r'^[\w.]+@[\w.]+\.\w+$').hasMatch(v)) return 'Enter a valid email';
                      return null;
                    }),
                const SizedBox(height: 12),

                // Roll No
                _tf(_codeCtrl, 'Roll No / Enrollment Number', Icons.badge_outlined,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Enter your Roll No / Enrollment Number' : null),
                const SizedBox(height: 12),

                // Phone number
                _tf(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                    type: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Enter your phone number';
                      if (v.trim().length < 10) return 'Enter a valid phone number';
                      return null;
                    }),
                const SizedBox(height: 12),

                // Year of study
                DropdownButtonFormField<int>(
                  value: _selectedYear,
                  decoration: const InputDecoration(
                    labelText: 'Year of Study',
                    prefixIcon: Icon(Icons.school_outlined, size: 18),
                  ),
                  items: _years.map((y) => DropdownMenuItem(
                    value: y,
                    child: Text('Year $y'),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedYear = v),
                  validator: (v) => v == null ? 'Select your year of study' : null,
                ),
                const SizedBox(height: 12),

                // Password
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
                    if (v == null || v.isEmpty) return 'Enter a password';
                    if (v.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Confirm password
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureC,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureC ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                      onPressed: () => setState(() => _obscureC = !_obscureC),
                    ),
                  ),
                  validator: (v) => v != _passCtrl.text ? 'Passwords do not match' : null,
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Simple captcha checkbox ──────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _humanChecked ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
                ),
              ),
              child: Row(children: [
                Checkbox(
                  value: _humanChecked,
                  activeColor: AppColors.success,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (v) => setState(() => _humanChecked = v ?? false),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('I am not a robot',
                      style: TextStyle(fontSize: 14, color: AppColors.textPrimary, fontWeight: FontWeight.w500)),
                ),
                Icon(Icons.security_rounded,
                    color: _humanChecked ? AppColors.success : AppColors.textMuted, size: 20),
              ]),
            ),

            const SizedBox(height: 20),

            // Create account button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _register,
                child: auth.isLoading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Account'),
              ),
            ),

            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Already have an account? ', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              GestureDetector(
                onTap: () => context.go(AppRoutes.login),
                child: const Text('Sign in', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.mark_email_read_rounded, color: AppColors.primary),
          SizedBox(width: 10),
          Text('Verify your email'),
        ]),
        content: Text(
          'A verification link has been sent to ${_emailCtrl.text.trim()}.\n\nPlease check your inbox and click the link to activate your account.',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.login);
            },
            child: const Text('Go to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _tf(TextEditingController ctrl, String label, IconData icon, {
    TextInputType type = TextInputType.text,
    TextCapitalization caps = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      textCapitalization: caps,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 18)),
      validator: validator,
    );
  }
}
