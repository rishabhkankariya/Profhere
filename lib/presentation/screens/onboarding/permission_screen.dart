import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/permission_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onDone;
  const PermissionScreen({super.key, required this.onDone});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with SingleTickerProviderStateMixin {
  bool _notifGranted = false;
  bool _loading = false;
  late final AnimationController _anim;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _checkExisting();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _checkExisting() async {
    final notif = await PermissionService.hasNotificationPermission();
    if (mounted) setState(() => _notifGranted = notif);
  }

  Future<void> _requestAll() async {
    setState(() => _loading = true);
    
    // Add a small delay to ensure the UI is ready for the system dialog
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Request notification permission if not already granted
    if (!_notifGranted) {
      final g = await PermissionService.requestNotifications();
      if (mounted) setState(() => _notifGranted = g);
    }
    
    if (mounted) setState(() => _loading = false);
    
    // Wait a moment to show the updated UI with the granted status
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Only proceed if mounted and user is still on this screen
    if (mounted) {
      widget.onDone();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),

                  // Icon
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    'One permission\nto get started',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.8,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'We only ask for what\'s needed. Nothing more.',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Notification card
                  _PermCard(
                    icon: Icons.notifications_rounded,
                    color: AppColors.primary,
                    title: 'Notifications',
                    subtitle:
                        'Get alerted when a subscribed faculty becomes available or someone mentions you in chat.',
                    granted: _notifGranted,
                  ),

                  const SizedBox(height: 16),

                  // Future hint card (read-only, no request)
                  _FutureCard(
                    icon: Icons.wifi_rounded,
                    color: AppColors.textMuted,
                    title: 'Network access',
                    subtitle:
                        'Will be used in a future update to detect faculty availability via campus Wi-Fi.',
                  ),

                  const Spacer(),

                  // CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _requestAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Allow & Continue',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _loading ? null : widget.onDone,
                      child: const Text('Skip for now',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool granted;

  const _PermCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: granted
              ? AppColors.success.withValues(alpha: 0.5)
              : AppColors.border,
          width: granted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (granted ? AppColors.success : color)
                .withValues(alpha: granted ? 0.08 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: (granted ? AppColors.success : color)
                .withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            granted ? Icons.check_rounded : icon,
            color: granted ? AppColors.success : color,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: granted
                        ? Container(
                            key: const ValueKey('granted'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.successBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Granted',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.success)),
                          )
                        : Container(
                            key: const ValueKey('needed'),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Needed',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary)),
                          ),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                        height: 1.4)),
              ]),
        ),
      ]),
    );
  }
}

class _FutureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FutureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary
                              .withValues(alpha: 0.5))),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHigh,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Coming soon',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted)),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted.withValues(alpha: 0.7),
                        height: 1.4)),
              ]),
        ),
      ]),
    );
  }
}
