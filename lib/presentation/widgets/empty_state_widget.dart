import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

// ─── Empty State Widget ───────────────────────────────────────────────────────
// Beautiful animated empty states for lists/screens.
// Uses CustomPainter-based illustrations + flutter_animate.

enum EmptyStateType {
  noFaculty,
  noQueue,
  noEvents,
  noTodos,
  noSearch,
  noNotifications,
  general,
}

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateType type;
  final String? title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    this.type = EmptyStateType.general,
    this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final config = _emptyConfig(type);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated illustration
            _AnimatedIllustration(
              type: type,
              color: config.color,
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: 28),

            // Title
            Text(
              title ?? config.title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 150.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut),

            const SizedBox(height: 8),

            // Subtitle
            Text(
              subtitle ?? config.subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            )
                .animate(delay: 220.ms)
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut),

            if (onAction != null) ...[
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: onAction,
                icon: Icon(config.actionIcon, size: 16),
                label: Text(actionLabel ?? config.actionLabel ?? 'Retry'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: AppColors.primaryLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              )
                  .animate(delay: 320.ms)
                  .fadeIn(duration: 400.ms)
                  .scale(
                    begin: const Offset(0.9, 0.9),
                    end: const Offset(1.0, 1.0),
                    duration: 400.ms,
                    curve: Curves.easeOut,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Config ───────────────────────────────────────────────────────────────────
class _Config {
  final String title;
  final String subtitle;
  final Color color;
  final String? actionLabel;
  final IconData actionIcon;

  const _Config({
    required this.title,
    required this.subtitle,
    required this.color,
    this.actionLabel,
    this.actionIcon = Icons.refresh_rounded,
  });
}

_Config _emptyConfig(EmptyStateType type) {
  switch (type) {
    case EmptyStateType.noFaculty:
      return const _Config(
        title: 'No Faculty Found',
        subtitle: 'Faculty members will appear here once they are added to the system.',
        color: AppColors.primary,
        actionLabel: 'Refresh',
        actionIcon: Icons.refresh_rounded,
      );
    case EmptyStateType.noQueue:
      return const _Config(
        title: 'Queue is Empty',
        subtitle: 'No students are currently waiting. The queue will populate as students join.',
        color: AppColors.success,
        actionLabel: 'Refresh',
        actionIcon: Icons.refresh_rounded,
      );
    case EmptyStateType.noEvents:
      return const _Config(
        title: 'No Events Yet',
        subtitle: 'Academic events and announcements will show up here.',
        color: AppColors.secondary,
        actionLabel: 'Add Event',
        actionIcon: Icons.add_rounded,
      );
    case EmptyStateType.noTodos:
      return const _Config(
        title: 'All Clear!',
        subtitle: 'You have no pending tasks. Add a to-do to stay organized.',
        color: AppColors.warning,
        actionLabel: 'Add Task',
        actionIcon: Icons.add_rounded,
      );
    case EmptyStateType.noSearch:
      return const _Config(
        title: 'No Results',
        subtitle: 'Try a different search term or check the spelling.',
        color: AppColors.textMuted,
        actionLabel: 'Clear Search',
        actionIcon: Icons.clear_rounded,
      );
    case EmptyStateType.noNotifications:
      return const _Config(
        title: 'No Notifications',
        subtitle: 'You\'re all caught up. Subscribe to faculty to get alerts.',
        color: AppColors.info,
      );
    case EmptyStateType.general:
      return const _Config(
        title: 'Nothing Here',
        subtitle: 'Check back later for updates.',
        color: AppColors.primary,
        actionLabel: 'Retry',
        actionIcon: Icons.refresh_rounded,
      );
  }
}

// ─── Animated illustration ────────────────────────────────────────────────────
class _AnimatedIllustration extends StatefulWidget {
  final EmptyStateType type;
  final Color color;

  const _AnimatedIllustration({required this.type, required this.color});

  @override
  State<_AnimatedIllustration> createState() => _AnimatedIllustrationState();
}

class _AnimatedIllustrationState extends State<_AnimatedIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _float.value),
        child: child,
      ),
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(72, 72),
            painter: _IllustrationPainter(
              type: widget.type,
              color: widget.color,
              progress: _ctrl.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  final EmptyStateType type;
  final Color color;
  final double progress;

  const _IllustrationPainter({
    required this.type,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    switch (type) {
      case EmptyStateType.noFaculty:
      case EmptyStateType.general:
        _drawPerson(canvas, size, center, paint, fillPaint);
        break;
      case EmptyStateType.noQueue:
        _drawQueue(canvas, size, center, paint, fillPaint);
        break;
      case EmptyStateType.noEvents:
        _drawCalendar(canvas, size, center, paint, fillPaint);
        break;
      case EmptyStateType.noTodos:
        _drawCheckCircle(canvas, size, center, paint, fillPaint);
        break;
      case EmptyStateType.noSearch:
        _drawSearch(canvas, size, center, paint, fillPaint);
        break;
      case EmptyStateType.noNotifications:
        _drawBell(canvas, size, center, paint, fillPaint);
        break;
    }
  }

  void _drawPerson(Canvas canvas, Size s, Offset c, Paint p, Paint f) {
    // Head
    canvas.drawCircle(Offset(c.dx, c.dy - 14), 11, f);
    canvas.drawCircle(Offset(c.dx, c.dy - 14), 11, p);
    // Body
    final bodyPath = Path()
      ..moveTo(c.dx - 16, c.dy + 22)
      ..quadraticBezierTo(c.dx - 16, c.dy + 2, c.dx, c.dy + 2)
      ..quadraticBezierTo(c.dx + 16, c.dy + 2, c.dx + 16, c.dy + 22);
    canvas.drawPath(bodyPath, p);
    // Plus sign (empty indicator)
    canvas.drawLine(Offset(c.dx - 5, c.dy + 8), Offset(c.dx + 5, c.dy + 8), p);
    canvas.drawLine(Offset(c.dx, c.dy + 3), Offset(c.dx, c.dy + 13), p);
  }

  void _drawQueue(Canvas canvas, Size s, Offset c, Paint p, Paint f) {
    // Three small people outlines staggered
    for (int i = 0; i < 3; i++) {
      final x = c.dx - 18 + i * 18.0;
      final y = c.dy + 10.0;
      final opacity = 1.0 - i * 0.25;
      final rp = Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      canvas.drawCircle(Offset(x, y - 14), 7, rp);
      final bodyPath = Path()
        ..moveTo(x - 9, y + 10)
        ..quadraticBezierTo(x - 9, y, x, y)
        ..quadraticBezierTo(x + 9, y, x + 9, y + 10);
      canvas.drawPath(bodyPath, rp);
    }
  }

  void _drawCalendar(Canvas canvas, Size s, Offset c, Paint p, Paint f) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: c, width: 44, height: 40),
      const Radius.circular(8),
    );
    canvas.drawRRect(rect, f);
    canvas.drawRRect(rect, p);
    // Header strip
    final headerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(c.dx - 22, c.dy - 20, 44, 14),
      const Radius.circular(8),
    );
    canvas.drawRRect(headerRect, p..color = color.withValues(alpha: 0.4));
    p.color = color;
    // Bind posts
    canvas.drawLine(Offset(c.dx - 10, c.dy - 24), Offset(c.dx - 10, c.dy - 14), p);
    canvas.drawLine(Offset(c.dx + 10, c.dy - 24), Offset(c.dx + 10, c.dy - 14), p);
    // Grid dots
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 4; col++) {
        canvas.drawCircle(
          Offset(c.dx - 15 + col * 10.0, c.dy + 2 + row * 10.0),
          1.5,
          p..style = PaintingStyle.fill,
        );
      }
    }
    p.style = PaintingStyle.stroke;
  }

  void _drawCheckCircle(Canvas canvas, Size s, Offset c, Paint p, Paint f) {
    canvas.drawCircle(c, 24, f);
    canvas.drawCircle(c, 24, p);
    // Checkmark
    final path = Path()
      ..moveTo(c.dx - 10, c.dy)
      ..lineTo(c.dx - 2, c.dy + 9)
      ..lineTo(c.dx + 12, c.dy - 8);
    canvas.drawPath(path, p..strokeWidth = 3.0);
    p.strokeWidth = 2.5;
  }

  void _drawSearch(Canvas canvas, Size s, Offset c, Paint p, Paint f) {
    canvas.drawCircle(Offset(c.dx - 4, c.dy - 4), 18, f);
    canvas.drawCircle(Offset(c.dx - 4, c.dy - 4), 18, p);
    // Handle
    final angle = math.pi / 4;
    canvas.drawLine(
      Offset(c.dx - 4 + 14 * math.cos(angle), c.dy - 4 + 14 * math.sin(angle)),
      Offset(c.dx - 4 + 24 * math.cos(angle), c.dy - 4 + 24 * math.sin(angle)),
      p..strokeWidth = 3.5,
    );
    p.strokeWidth = 2.5;
  }

  void _drawBell(Canvas canvas, Size s, Offset c, Paint p, Paint f) {
    // Bell body
    final path = Path()
      ..moveTo(c.dx, c.dy - 22)
      ..cubicTo(c.dx + 20, c.dy - 22, c.dx + 20, c.dy - 5, c.dx + 22, c.dy + 8)
      ..lineTo(c.dx - 22, c.dy + 8)
      ..cubicTo(c.dx - 20, c.dy - 5, c.dx - 20, c.dy - 22, c.dx, c.dy - 22);
    canvas.drawPath(path, f);
    canvas.drawPath(path, p);
    // Clapper
    canvas.drawArc(
      Rect.fromCenter(center: Offset(c.dx, c.dy + 11), width: 12, height: 8),
      0, math.pi, false, p,
    );
    // Top hook
    canvas.drawLine(Offset(c.dx, c.dy - 22), Offset(c.dx, c.dy - 26), p);
  }

  @override
  bool shouldRepaint(covariant _IllustrationPainter old) =>
      old.progress != progress || old.color != color;
}

extension _DurationInt on int {
  Duration get ms => Duration(milliseconds: this);
}
