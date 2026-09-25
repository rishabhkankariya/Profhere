import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_toast.dart';
import 'signup_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResendingConfirmation = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBase,
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -150,
            left: -100,
            child: _GlowOrb(
              size: 400,
              color: AppTheme.electricTeal.withValues(alpha: 0.1),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Welcome Back',
                        style: Theme.of(
                          context,
                        ).textTheme.displayLarge?.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Access the smart campus curator',
                        style: GoogleFonts.inter(
                          color: AppTheme.softGrey.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Form Card (Obsidian Glassmorphism)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: AppTheme.obsidianLayer1.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildFieldLabel('EMAIL ADDRESS'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  hintText: 'name@university.edu',
                                  prefixIcon: Icon(
                                    Icons.email_outlined,
                                    size: 20,
                                  ),
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 24),

                              _buildFieldLabel('PASSWORD'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                decoration: InputDecoration(
                                  hintText: '••••••••',
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    size: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(
                                      () => _isPasswordVisible =
                                          !_isPasswordVisible,
                                    ),
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 32),

                              ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                child: _isSubmitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Secondary Actions
                      Center(
                        child: Column(
                          children: [
                            TextButton(
                              onPressed:
                                  _isSubmitting || _isResendingConfirmation
                                  ? null
                                  : _resendConfirmationEmail,
                              child: Text(
                                _isResendingConfirmation
                                    ? 'Sending confirmation...'
                                    : 'Resend confirmation email',
                                style: GoogleFonts.inter(
                                  color: AppTheme.softGrey.withValues(
                                    alpha: 0.4,
                                  ),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "New here? ",
                                  style: GoogleFonts.inter(
                                    color: AppTheme.softGrey.withValues(
                                      alpha: 0.4,
                                    ),
                                    fontSize: 14,
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _isSubmitting
                                      ? null
                                      : () => _navigateToSignup(context),
                                  child: const Text(
                                    "Create an account",
                                    style: TextStyle(
                                      color: AppTheme.vibrantTeal,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(label, style: Theme.of(context).textTheme.labelMedium);
  }

  void _navigateToSignup(BuildContext context) async {
    final message = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const SignupScreen()),
    );

    if (context.mounted && message != null) {
      AppToast.success(context, message);
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!value.contains('@')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'At least 6 characters';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (ref.read(authServiceProvider) == null) {
      AppToast.error(context, 'Supabase is not configured.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signIn(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        AppToast.success(context, 'Logged in successfully.');
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _resendConfirmationEmail() async {
    final email = _emailController.text.trim();
    final emailError = _validateEmail(email);
    if (emailError != null) {
      AppToast.error(context, emailError);
      return;
    }

    setState(() => _isResendingConfirmation = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resendConfirmationEmail(email);
      if (mounted) {
        AppToast.info(context, 'Confirmation email sent. Check your inbox.');
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(context, error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isResendingConfirmation = false);
      }
    }
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 0.8],
        ),
      ),
    );
  }
}
