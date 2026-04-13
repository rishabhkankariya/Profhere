import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/permission_service.dart';

class PermissionScreen extends StatefulWidget {
  final VoidCallback onDone;
  const PermissionScreen({super.key, required this.onDone});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _notifGranted  = false;
  bool _cameraGranted = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final notif  = await PermissionService.hasNotificationPermission();
    final camera = await PermissionService.hasCameraPermission();
    if (mounted) setState(() { _notifGranted = notif; _cameraGranted = camera; });
  }

  Future<void> _requestAll() async {
    setState(() => _loading = true);

    if (!_notifGranted) {
      final g = await PermissionService.requestNotifications();
      if (mounted) setState(() => _notifGranted = g);
    }

    if (!_cameraGranted) {
      final g = await PermissionService.requestCamera();
      if (mounted) setState(() => _cameraGranted = g);
    }

    if (mounted) setState(() => _loading = false);
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.lock_open_rounded, color: AppColors.primary, size: 28),
              ),
              const SizedBox(height: 20),
              const Text('A few permissions',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 8),
              const Text('ProfHere needs these to work properly. We only use what\'s necessary.',
                  style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.4)),
              const SizedBox(height: 36),

              _PermCard(
                icon: Icons.notifications_active_rounded,
                color: const Color(0xFF4F46E5),
                title: 'Notifications',
                subtitle: 'Get alerted when subscribed faculty becomes available or someone mentions you.',
                granted: _notifGranted,
              ),
              const SizedBox(height: 12),
              _PermCard(
                icon: Icons.camera_alt_rounded,
                color: const Color(0xFF0EA5E9),
                title: 'Camera & Photos',
                subtitle: 'Used only when you choose to set or update your profile photo.',
                granted: _cameraGranted,
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _requestAll,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Allow & Continue',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: widget.onDone,
                  child: const Text('Skip for now',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                ),
              ),
              const SizedBox(height: 16),
            ],
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
    required this.icon, required this.color,
    required this.title, required this.subtitle,
    required this.granted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: granted ? AppColors.success.withValues(alpha: 0.4) : AppColors.border,
          width: granted ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            if (granted)
              const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.success)
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Required',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: AppColors.warning)),
              ),
          ]),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted, height: 1.4)),
        ])),
      ]),
    );
  }
}
