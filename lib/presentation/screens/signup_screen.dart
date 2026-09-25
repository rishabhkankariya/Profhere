import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/app_user.dart';
import '../providers/auth_provider.dart';
import '../widgets/adaptive_back_button.dart';
import '../widgets/app_toast.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.student;
  bool _isSubmitting = false;
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBase,
      appBar: AppBar(
        leading: const AdaptiveBackButton(),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            right: -100,
            child: _GlowOrb(
              size: 400,
              color: AppTheme.vibrantTeal.withValues(alpha: 0.1),
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
                        'Join ProfHere',
                        style: Theme.of(
                          context,
                        ).textTheme.displayLarge?.copyWith(fontSize: 32),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Connect with your campus community',
                        style: GoogleFonts.inter(
                          color: AppTheme.softGrey.withValues(alpha: 0.5),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Form Card
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
                              _buildFieldLabel('FULL NAME'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  hintText: 'John Doe',
                                  prefixIcon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 20,
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.trim().isEmpty
                                    ? 'Name is required'
                                    : null,
                              ),
                              const SizedBox(height: 20),

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
                              const SizedBox(height: 20),

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
                              const SizedBox(height: 20),

                              _buildFieldLabel('PRIMARY ROLE'),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.obsidianLayer1,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButtonFormField<UserRole>(
                                    initialValue: _selectedRole,
                                    dropdownColor: AppTheme.obsidianLayer2,
                                    icon: const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                    ),
                                    decoration: const InputDecoration(
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    items: UserRole.values
                                        .map(
                                          (role) => DropdownMenuItem(
                                            value: role,
                                            child: Text(
                                              role.value[0].toUpperCase() + 
                                              role.value.substring(1),
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (value) {
                                      if (value != null)
                                        setState(() => _selectedRole = value);
                                    },
                                  ),
                                ),
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
                                    : const Text('Create Account'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: GoogleFonts.inter(
                                color: AppTheme.softGrey.withValues(alpha: 0.4),
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: const Text(
                                "Sign In",
                                style: TextStyle(
                                  color: AppTheme.vibrantTeal,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
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

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    if (!value.contains('@')) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'At least 6 characters';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (ref.read(authServiceProvider) == null) {
      AppToast.error(context, 'Supabase is not configured.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
          );

      if (mounted) {
        Navigator.of(
          context,
        ).pop('Account created. Confirm your email if required.');
      }
    } catch (error) {
      if (mounted) AppToast.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
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
