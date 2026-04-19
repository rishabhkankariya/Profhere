import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../navigation/app_router.dart';

// ─── Splash Screen ─────────────────────────────────────────────────────────────
// Modern dark splash with:
//  • Radial ambient glow + animated ring
//  • Floating particle field (CustomPainter)
//  • Logo scale-in with glow pulse
//  • Letter-by-letter name assembly
//  • Tagline + animated dots loader
//  • Subtle corner frame accent
// Total duration ≈ 2.8s before navigation.

class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback? onComplete;
  const SplashScreen({super.key, this.onComplete});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {

  // Background
  late final AnimationController _bgCtrl;
  late final Animation<double> _bgFade;

  // Logo
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // Glow + ring pulse
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // Ring expand
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringFade;

  // Text
  late final AnimationController _textCtrl;
  late final Animation<double> _textReveal;

  // Tagline
  late final AnimationController _tagCtrl;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagSlide;

  // Dots loader
  late final AnimationController _dotsCtrl;

  // Particles
  late final AnimationController _particleCtrl;

  static const _appName = 'ProfHere';
  final _random = math.Random(42);
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _particles = List.generate(18, (i) => _Particle.random(_random));

    // Background
    _bgCtrl = AnimationController(vsync: this, duration: 700.ms);
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);

    // Logo
    _logoCtrl = AnimationController(vsync: this, duration: 750.ms);
    _logoScale = Tween<double>(begin: 0.55, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOut)));

    // Glow pulse (loops)
    _glowCtrl = AnimationController(vsync: this, duration: 2400.ms)
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Ring expand (one-shot after logo)
    _ringCtrl = AnimationController(vsync: this, duration: 900.ms);
    _ringScale = Tween<double>(begin: 0.6, end: 2.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));
    _ringFade = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _ringCtrl, curve: Curves.easeIn));

    // Text
    _textCtrl = AnimationController(vsync: this, duration: 700.ms);
    _textReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));

    // Tagline
    _tagCtrl = AnimationController(vsync: this, duration: 500.ms);
    _tagFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));
    _tagSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOutCubic));

    // Dots (loops)
    _dotsCtrl = AnimationController(vsync: this, duration: 900.ms)
      ..repeat();

    // Particles (loops)
    _particleCtrl = AnimationController(vsync: this, duration: 8000.ms)
      ..repeat();

    _runSequence();
    _init();
  }

  Future<void> _runSequence() async {
    _bgCtrl.forward();
    await Future.delayed(100.ms);
    if (!mounted) return;

    _logoCtrl.forward();
    await Future.delayed(400.ms);
    if (!mounted) return;

    _ringCtrl.forward();
    await Future.delayed(200.ms);
    if (!mounted) return;

    _textCtrl.forward();
    await Future.delayed(500.ms);
    if (!mounted) return;

    _tagCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _ringCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _dotsCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      Future.delayed(2800.ms),
      ref.read(authStateProvider.future),
    ]).catchError((_) => <dynamic>[null, null]);
    if (!mounted) return;

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    final user = await ref.read(authRepositoryProvider).getCurrentUser();
    if (!mounted) return;
    if (user != null) {
      ref.read(authNotifierProvider.notifier).hydrateFromRepository(user);
      switch (user.role) {
        case UserRole.admin:   context.go(AppRoutes.admin);
        case UserRole.faculty: context.go(AppRoutes.facultyDashboard);
        case UserRole.student: context.go(AppRoutes.faculties);
      }
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF07070F),
      body: FadeTransition(
        opacity: _bgFade,
        child: Stack(children: [

          // ── Particle field ──────────────────────────────────────────────
          AnimatedBuilder(
            animation: _particleCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter: _ParticlePainter(
                particles: _particles,
                progress: _particleCtrl.value,
                screenSize: size,
              ),
            ),
          ),

          // ── Ambient radial glow ─────────────────────────────────────────
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Center(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF4F46E5).withValues(alpha: 0.20 * _glowAnim.value),
                        const Color(0xFF7C3AED).withValues(alpha: 0.08 * _glowAnim.value),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Expanding ring after logo ───────────────────────────────────
          AnimatedBuilder(
            animation: _ringCtrl,
            builder: (_, __) => Center(
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Opacity(
                  opacity: _ringFade.value,
                  child: Transform.scale(
                    scale: _ringScale.value,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Logo
                AnimatedBuilder(
                  animation: Listenable.merge([_logoCtrl, _glowCtrl]),
                  builder: (_, __) => Opacity(
                    opacity: _logoFade.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5B52F0), Color(0xFF7C3AED)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5)
                                  .withValues(alpha: 0.55 * _glowAnim.value),
                              blurRadius: 48,
                              spreadRadius: -4,
                              offset: const Offset(0, 14),
                            ),
                            BoxShadow(
                              color: const Color(0xFF7C3AED)
                                  .withValues(alpha: 0.2 * _glowAnim.value),
                              blurRadius: 80,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Image.asset(
                            'assets/logo.png',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.school_rounded, size: 46, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // App name — letter-by-letter
                AnimatedBuilder(
                  animation: _textReveal,
                  builder: (_, __) {
                    final visibleCount = (_textReveal.value * _appName.length).ceil();
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_appName.length, (i) {
                        final visible = i < visibleCount;
                        final progress = visible
                            ? (((_textReveal.value * _appName.length) - i).clamp(0.0, 1.0))
                            : 0.0;
                        return Opacity(
                          opacity: progress.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, 10 * (1.0 - progress)),
                            child: Text(
                              _appName[i],
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.8,
                                height: 1.0,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Tagline
                SlideTransition(
                  position: _tagSlide,
                  child: FadeTransition(
                    opacity: _tagFade,
                    child: Text(
                      'Smart Campus · Faculty Platform',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.32),
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 56),

                // Animated dots loader
                FadeTransition(
                  opacity: _tagFade,
                  child: _DotsLoader(controller: _dotsCtrl),
                ),
              ],
            ),
          ),

          // ── Corner accent frame ──────────────────────────────────────────
          FadeTransition(
            opacity: _tagFade,
            child: CustomPaint(
              size: Size(size.width, size.height),
              painter: _CornerLinePainter(),
            ),
          ),

          // ── Version ──────────────────────────────────────────────────────
          Positioned(
            bottom: 28,
            left: 0, right: 0,
            child: FadeTransition(
              opacity: _tagFade,
              child: Center(
                child: Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.12),
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Animated Dots Loader ─────────────────────────────────────────────────────
class _DotsLoader extends StatelessWidget {
  final AnimationController controller;
  const _DotsLoader({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot has a phase offset
            final phase = (controller.value - i * 0.25).clamp(0.0, 1.0);
            final t = (math.sin(phase * math.pi * 2) * 0.5 + 0.5);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(
                  alpha: (0.15 + t * 0.65).clamp(0.0, 1.0),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

// ─── Particle Painter ─────────────────────────────────────────────────────────
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });

  factory _Particle.random(math.Random r) {
    return _Particle(
      x: r.nextDouble(),
      y: r.nextDouble(),
      size: r.nextDouble() * 2.0 + 0.8,
      speed: r.nextDouble() * 0.3 + 0.1,
      opacity: r.nextDouble() * 0.25 + 0.05,
      phase: r.nextDouble() * math.pi * 2,
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Size screenSize;

  const _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.screenSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final t = (progress * p.speed + p.phase / (math.pi * 2)) % 1.0;
      // Particles float upward and fade out near top
      final y = ((p.y - t * 0.6) % 1.0) * size.height;
      final x = p.x * size.width + math.sin(t * math.pi * 4 + p.phase) * 20;

      // Fade near top
      final fadeY = 1.0 - (y / size.height) * 0.7;
      final alpha = (p.opacity * fadeY).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = const Color(0xFF818CF8).withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter old) =>
      old.progress != progress;
}

// ─── Corner Accent Lines ──────────────────────────────────────────────────────
class _CornerLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const len = 28.0;
    const margin = 24.0;

    // Top-left
    canvas.drawLine(Offset(margin, margin + len), Offset(margin, margin), paint);
    canvas.drawLine(Offset(margin, margin), Offset(margin + len, margin), paint);

    // Top-right
    canvas.drawLine(Offset(size.width - margin - len, margin), Offset(size.width - margin, margin), paint);
    canvas.drawLine(Offset(size.width - margin, margin), Offset(size.width - margin, margin + len), paint);

    // Bottom-left
    canvas.drawLine(Offset(margin, size.height - margin - len), Offset(margin, size.height - margin), paint);
    canvas.drawLine(Offset(margin, size.height - margin), Offset(margin + len, size.height - margin), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width - margin - len, size.height - margin), Offset(size.width - margin, size.height - margin), paint);
    canvas.drawLine(Offset(size.width - margin, size.height - margin), Offset(size.width - margin, size.height - margin - len), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Duration helpers ─────────────────────────────────────────────────────────
extension _DurationInt on int {
  Duration get ms => Duration(milliseconds: this);
}
