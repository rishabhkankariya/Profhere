import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import '../navigation/app_router.dart';

// ─── Splash Screen ────────────────────────────────────────────────────────────
// Sequence:
//  0ms   → background fades in
//  200ms → logo scales up + fades in with glow
//  700ms → "ProfHere" assembles letter by letter
// 1200ms → tagline fades in
// 1600ms → thin progress line sweeps across
// 2400ms → navigate (or call onComplete if provided)

class SplashScreen extends ConsumerStatefulWidget {
  /// When used as a standalone route, leave null — it navigates automatically.
  /// When used in MaterialApp.router builder, pass a callback to signal done.
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
  late final Animation<double> _logoBlur;

  // Glow pulse
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  // Text assembling
  late final AnimationController _textCtrl;
  late final Animation<double> _textReveal; // 0→1 drives letter reveal
  late final Animation<double> _textFade;

  // Tagline
  late final AnimationController _tagCtrl;
  late final Animation<double> _tagFade;
  late final Animation<Offset> _tagSlide;

  // Progress line
  late final AnimationController _lineCtrl;
  late final Animation<double> _lineWidth;
  late final Animation<double> _lineFade;

  static const _appName = 'ProfHere';

  @override
  void initState() {
    super.initState();

    // Background
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _bgFade = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeOut);

    // Logo
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.7, curve: Curves.easeOut)));
    _logoBlur = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));

    // Glow
    _glowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Text assembling
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _textReveal = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOut));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textCtrl, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)));

    // Tagline
    _tagCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _tagFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut));
    _tagSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOutCubic));

    // Progress line
    _lineCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _lineWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineCtrl, curve: Curves.easeInOut));
    _lineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _lineCtrl, curve: const Interval(0.0, 0.3, curve: Curves.easeOut)));

    _runSequence();
    _init();
  }

  Future<void> _runSequence() async {
    // Background
    _bgCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Logo
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Text assembling
    _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // Tagline
    _tagCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    // Progress line
    _lineCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _logoCtrl.dispose();
    _glowCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _lineCtrl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2600)),
      ref.read(authStateProvider.future),
    ]).catchError((_) => <dynamic>[null, null]);
    if (!mounted) return;

    // If used in builder mode, just call the callback — main.dart handles navigation
    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    // Standalone route mode — navigate directly
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
        child: Stack(
          children: [

            // ── Ambient glow behind logo ──────────────────────────────────
            AnimatedBuilder(
              animation: _glowAnim,
              builder: (_, __) => Center(
                child: Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF4F46E5).withValues(alpha: 0.18 * _glowAnim.value),
                          const Color(0xFF7C3AED).withValues(alpha: 0.06 * _glowAnim.value),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Main content ──────────────────────────────────────────────
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
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF4F46E5)
                                    .withValues(alpha: 0.5 * _glowAnim.value),
                                blurRadius: 40,
                                spreadRadius: -4,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(26),
                            child: Image.asset(
                              'assets/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.school_rounded, size: 44, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App name — letter-by-letter reveal
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
                          return AnimatedOpacity(
                            opacity: progress,
                            duration: Duration.zero,
                            child: Transform.translate(
                              offset: Offset(0, 8 * (1.0 - progress)),
                              child: Text(
                                _appName[i],
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),

                  const SizedBox(height: 10),

                  // Tagline
                  SlideTransition(
                    position: _tagSlide,
                    child: FadeTransition(
                      opacity: _tagFade,
                      child: Text(
                        'Faculty Availability Platform',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.35),
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Progress line
                  AnimatedBuilder(
                    animation: _lineCtrl,
                    builder: (_, __) => Opacity(
                      opacity: _lineFade.value,
                      child: SizedBox(
                        width: 120,
                        height: 1.5,
                        child: Stack(
                          children: [
                            // Track
                            Container(
                              width: 120,
                              height: 1.5,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                            // Fill
                            Container(
                              width: 120 * _lineWidth.value,
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color(0xFF4F46E5).withValues(alpha: 0.8),
                                    const Color(0xFF7C3AED),
                                  ],
                                ),
                              ),
                            ),
                            // Shimmer dot at tip
                            if (_lineWidth.value > 0.02)
                              Positioned(
                                left: (120 * _lineWidth.value) - 3,
                                top: -1,
                                child: Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.9),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF7C3AED).withValues(alpha: 0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Corner grid lines (subtle) ────────────────────────────────
            FadeTransition(
              opacity: _tagFade,
              child: CustomPaint(
                size: Size(size.width, size.height),
                painter: _CornerLinePainter(),
              ),
            ),

            // ── Version tag ───────────────────────────────────────────────
            Positioned(
              bottom: 32,
              left: 0, right: 0,
              child: FadeTransition(
                opacity: _tagFade,
                child: Center(
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withValues(alpha: 0.15),
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Corner accent lines ──────────────────────────────────────────────────────
// Draws 4 small L-shaped corner marks — very subtle, adds depth without noise.

class _CornerLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const len = 24.0;
    const margin = 28.0;

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
