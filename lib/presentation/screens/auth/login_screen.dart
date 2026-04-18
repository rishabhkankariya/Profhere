import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/toast.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/app_router.dart';

// ─── Role model ───────────────────────────────────────────────────────────────

class _Role {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _Role(this.label, this.subtitle, this.icon, this.color);
}

const _roles = [
  _Role('Admin',   'Full system access',     Icons.shield_rounded,  AppColors.error),
  _Role('Faculty', 'Manage your profile',    Icons.person_rounded,  AppColors.primary),
  _Role('Student', 'Find & consult faculty', Icons.school_rounded,  AppColors.info),
];

// ─── Screen ───────────────────────────────────────────────────────────────────

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  int  _role    = 2; // 0=Admin 1=Faculty 2=Student

  late final AnimationController _fadeCtrl;
  late final Animation<double>   _fade;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))..forward();
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authNotifierProvider.notifier)
        .login(_emailCtrl.text.trim(), _passCtrl.text);
  }

  Future<void> _googleSignIn() async {
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
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
        child: FadeTransition(
          opacity: _fade,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 48),

                // ── Logo ─────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 64, height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.school_rounded, size: 30, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // ── Role selector ────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: List.generate(_roles.length, (i) {
                      final r      = _roles[i];
                      final active = _role == i;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _role = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: active ? AppColors.surface : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: active ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4, offset: const Offset(0, 1),
                                ),
                              ] : null,
                            ),
                            child: Column(children: [
                              Icon(r.icon, size: 17,
                                  color: active ? r.color : AppColors.textMuted),
                              const SizedBox(height: 4),
                              Text(r.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    color: active ? r.color : AppColors.textMuted,
                                  )),
                            ]),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Form ─────────────────────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(children: [
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.alternate_email_rounded, size: 17),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Enter your email';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 17),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 17,
                          ),
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

                // ── Forgot password ──────────────────────────────────────
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _showForgotPassword(context),
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8)),
                    child: const Text('Forgot password?',
                        style: TextStyle(
                          color: AppColors.primary, fontSize: 13,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ),

                // ── Sign In ──────────────────────────────────────────────
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: auth.isLoading
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : Text('Sign In as ${_roles[_role].label}',
                            style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700,
                              color: Colors.white,
                            )),
                  ),
                ),

                // ── Google — students only ───────────────────────────────
                if (_role == 2) ...[
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ]),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: auth.isLoading ? null : _googleSignIn,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        backgroundColor: AppColors.surface,
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        SizedBox(width: 20, height: 20,
                            child: CustomPaint(painter: _GooglePainter())),
                        const SizedBox(width: 10),
                        const Text('Continue with Google',
                            style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            )),
                      ]),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Sign up ──────────────────────────────────────────────
                if (_role == 2)
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text("Don't have an account? ",
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    GestureDetector(
                      onTap: () => context.go(AppRoutes.register),
                      child: const Text('Sign up',
                          style: TextStyle(
                            color: AppColors.primary, fontSize: 13,
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
    );
  }

  void _showForgotPassword(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset password'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Enter your email and we\'ll send a reset link.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
          const SizedBox(height: 16),
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 17),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              Navigator.pop(context);
              await ref.read(authNotifierProvider.notifier)
                  .sendPasswordReset(ctrl.text.trim());
              if (context.mounted) {
                Toast.success(context, 'Reset email sent. Check your inbox.');
              }
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }
}

// ─── Google icon painter ──────────────────────────────────────────────────────

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = size.width * 0.46;
    final sw = size.width * 0.19;

    Paint p(Color c) => Paint()
      ..color = c
      ..strokeWidth = sw
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);
    canvas.drawArc(rect, -math.pi / 2,  math.pi * 0.55, false, p(const Color(0xFFEA4335)));
    canvas.drawArc(rect,  math.pi * 0.05, math.pi * 0.55, false, p(const Color(0xFFFBBC05)));
    canvas.drawArc(rect,  math.pi * 0.6,  math.pi * 0.4,  false, p(const Color(0xFF34A853)));
    canvas.drawArc(rect,  math.pi,         math.pi * 0.6,  false, p(const Color(0xFF4285F4)));
    canvas.drawLine(
      Offset(cx, cy), Offset(cx + r * 0.9, cy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = sw
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_GooglePainter _) => false;
}
