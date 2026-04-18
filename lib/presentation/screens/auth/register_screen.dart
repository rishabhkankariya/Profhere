import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure  = true;
  bool _obscureC = true;

  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _fade  = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _anim.dispose();
    for (final c in [_nameCtrl, _emailCtrl, _passCtrl, _confirmCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier).register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authNotifierProvider);

    ref.listen<AuthState>(authNotifierProvider, (_, next) {
      if (next.user != null) context.go(AppRoutes.faculties);
      if (next.error != null) {
        Toast.error(context, next.error!, title: 'Registration Failed');
        ref.read(authNotifierProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),

                  // Header
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16, offset: const Offset(0, 6),
                      )],
                    ),
                    child: const Icon(Icons.person_add_rounded, size: 26, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Create account',
                    style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary, letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Join your campus community',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(children: [
                      // Name
                      TextFormField(
                        controller: _nameCtrl,
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          hintText: 'Enter your full name',
                          prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Enter your full name' : null,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'Enter your email',
                          prefixIcon: Icon(Icons.alternate_email_rounded, size: 18),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your email';
                          if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Create a password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter a password';
                          if (v.length < 6) return 'Minimum 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm password
                      TextFormField(
                        controller: _confirmCtrl,
                        obscureText: _obscureC,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _register(),
                        decoration: InputDecoration(
                          labelText: 'Confirm password',
                          hintText: 'Re-enter your password',
                          prefixIcon: const Icon(Icons.lock_rounded, size: 18),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureC ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              size: 18,
                            ),
                            onPressed: () => setState(() => _obscureC = !_obscureC),
                          ),
                        ),
                        validator: (v) => v != _passCtrl.text
                            ? 'Passwords do not match' : null,
                      ),
                    ]),
                  ),

                  const SizedBox(height: 32),

                  // Sign up button
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: auth.isLoading ? null : _register,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Create Account', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Already have an account? ',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.login),
                      child: const Text('Sign in',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                  ]),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
