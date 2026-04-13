import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Displays a faculty avatar.
/// If [avatarBase64] is provided and valid → shows the image.
/// Otherwise falls back to [initials] in a gradient rounded square.
class FacultyAvatar extends StatelessWidget {
  final String? avatarBase64;
  final String initials;
  final double size;
  final double borderRadius;
  final bool isCircle;
  final VoidCallback? onTap; // non-null = shows camera overlay

  const FacultyAvatar({
    super.key,
    this.avatarBase64,
    required this.initials,
    this.size = 68,
    this.borderRadius = 20,
    this.isCircle = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = isCircle
        ? BorderRadius.circular(size / 2)
        : BorderRadius.circular(borderRadius);

    Widget avatar;

    if (avatarBase64 != null && avatarBase64!.isNotEmpty) {
      // Show uploaded image
      try {
        final bytes = base64Decode(avatarBase64!);
        avatar = Container(
          width: size, height: size,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: onTap != null
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))]
                : null,
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Image.memory(bytes, fit: BoxFit.cover, width: size, height: size),
          ),
        );
      } catch (_) {
        avatar = _InitialsAvatar(initials: initials, size: size, radius: radius);
      }
    } else {
      avatar = _InitialsAvatar(initials: initials, size: size, radius: radius);
    }

    if (onTap == null) return avatar;

    // Editable — show camera overlay on hover/tap
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          avatar,
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 6)],
              ),
              child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: size * 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String initials;
  final double size;
  final BorderRadius radius;
  const _InitialsAvatar({required this.initials, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: radius,
        boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Center(
        child: Text(initials,
            style: TextStyle(
              fontSize: size * 0.35,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            )),
      ),
    );
  }
}
