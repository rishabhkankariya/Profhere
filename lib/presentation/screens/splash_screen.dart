import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.8, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.obsidianBase,
      body: Stack(
        children: [
          // Dynamic Background Glows
          Positioned(
            top: MediaQuery.of(context).size.height * 0.1,
            right: -100,
            child: _GlowOrb(
              size: 400,
              color: AppTheme.electricTeal.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -150,
            left: -50,
            child: _GlowOrb(
              size: 500,
              color: AppTheme.vibrantTeal.withValues(alpha: 0.08),
            ),
          ),

          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Rounded Logo with Premium Shadow and Border
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 180,
                      height: 180,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.vibrantTeal.withValues(alpha: 0.4),
                            AppTheme.electricTeal.withValues(alpha: 0.2),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.electricTeal.withValues(alpha: 0.3),
                            blurRadius: 40,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.obsidianLayer1,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: Stack(
                            children: [
                              Image.asset(
                                'assets/branding/profhere_logo.png.png',
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                  child: Icon(Icons.school_rounded,
                                      color: Colors.white, size: 80),
                                ),
                              ),
                              // Subtle Overlay to ensure blend with dark theme
                              Container(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(alpha: 0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 60),
                
                // Typography with improved spacing and premium feel
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      Text(
                        'PROFHERE',
                        style: GoogleFonts.inter(
                          color: AppTheme.softGrey,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Precision Campus Terminal',
                        style: GoogleFonts.inter(
                          color: AppTheme.softGrey.withValues(alpha: 0.4),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 100),
                
                // Active Loader - Ensures user knows "something is going"
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.vibrantTeal),
                    backgroundColor: AppTheme.obsidianLayer2,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Minimal Status Text
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'INITIALIZING SECURE LINK',
                    style: GoogleFonts.inter(
                      color: AppTheme.softGrey.withValues(alpha: 0.2),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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
          stops: const [0.0, 0.7],
        ),
      ),
    );
  }
}
