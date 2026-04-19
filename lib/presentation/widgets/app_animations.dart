import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ─── FadeSlideIn ─────────────────────────────────────────────────────────────
/// Fades and slides a child into view. Use [delay] for staggering.
class FadeSlideIn extends StatelessWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;

  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 400),
    this.beginOffset = const Offset(0, 24),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay)
        .fadeIn(duration: duration, curve: Curves.easeOutCubic)
        .slideY(
          begin: beginOffset.dy / 100,
          end: 0,
          duration: duration,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─── StaggeredList ───────────────────────────────────────────────────────────
/// Wraps a list of children with staggered FadeSlide animations.
class StaggeredList extends StatelessWidget {
  final List<Widget> children;
  final Duration itemDelay;
  final Duration itemDuration;
  final double slideOffset;

  const StaggeredList({
    super.key,
    required this.children,
    this.itemDelay = const Duration(milliseconds: 60),
    this.itemDuration = const Duration(milliseconds: 350),
    this.slideOffset = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(children.length, (i) {
        return children[i]
            .animate(delay: itemDelay * i)
            .fadeIn(duration: itemDuration, curve: Curves.easeOutCubic)
            .slideY(
              begin: slideOffset / 100,
              end: 0,
              duration: itemDuration,
              curve: Curves.easeOutCubic,
            );
      }),
    );
  }
}

// ─── PulseWidget ─────────────────────────────────────────────────────────────
/// Continuously pulses its child (scale in/out).
class PulseWidget extends StatelessWidget {
  final Widget child;
  final Duration period;
  final double minScale;

  const PulseWidget({
    super.key,
    required this.child,
    this.period = const Duration(seconds: 2),
    this.minScale = 0.95,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: Offset(1.0 + (1.0 - 0.95), 1.0 + (1.0 - 0.95)),
          duration: period,
          curve: Curves.easeInOut,
        );
  }
}

// ─── ScaleTap ─────────────────────────────────────────────────────────────────
/// Scales down when tapped — gives tactile feedback.
class ScaleTap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;

  const ScaleTap({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.96,
  });

  @override
  State<ScaleTap> createState() => _ScaleTapState();
}

class _ScaleTapState extends State<ScaleTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: widget.scale).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// ─── ShimmerBox ───────────────────────────────────────────────────────────────
/// A shimmer placeholder using flutter_animate — no shimmer package needed.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
    )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: const Duration(milliseconds: 1200),
          color: const Color(0xFFF8FAFC),
          angle: 0.1,
        );
  }
}

// ─── StatusDot ────────────────────────────────────────────────────────────────
/// Animated pulsing status dot.
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool animate;

  const StatusDot({
    super.key,
    required this.color,
    this.size = 10,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: size,
            spreadRadius: size * 0.2,
          ),
        ],
      ),
    );

    if (!animate) return dot;

    return dot
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.2, 1.2),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        )
        .fadeOut(
          begin: 0.7,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
        );
  }
}

// ─── CountUpText ──────────────────────────────────────────────────────────────
/// Reveals text with a subtle count-up feel using flipH.
class RevealText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Duration delay;

  const RevealText({
    super.key,
    required this.text,
    this.style,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Text(text, style: style)
        .animate(delay: delay)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

// ─── PageSlideTransition ──────────────────────────────────────────────────────
/// Custom page transition that slides in from the right with a fade.
class PageFadeSlide extends PageRouteBuilder {
  final Widget page;

  PageFadeSlide({required this.page})
      : super(
          transitionDuration: const Duration(milliseconds: 320),
          reverseTransitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, __, ___) => page,
          transitionsBuilder: (_, animation, secondaryAnimation, child) {
            final curve = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curve),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(curve),
                child: child,
              ),
            );
          },
        );
}
