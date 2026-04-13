import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum ToastType { success, error, info, warning }

class Toast {
  static void show(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    final cfg = _config(type);
    Flushbar(
      title: title ?? cfg.title,
      message: message,
      duration: duration,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(14),
      backgroundColor: cfg.bg,
      icon: Icon(cfg.icon, color: Colors.white, size: 22),
      titleColor: Colors.white,
      messageColor: Colors.white.withValues(alpha: 0.9),
      titleSize: 14,
      messageSize: 13,
      flushbarPosition: FlushbarPosition.TOP,
      boxShadows: [
        BoxShadow(color: cfg.bg.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    ).show(context);
  }

  static void success(BuildContext context, String message, {String? title}) =>
      show(context, message, type: ToastType.success, title: title);

  static void error(BuildContext context, String message, {String? title}) =>
      show(context, message, type: ToastType.error, title: title, duration: const Duration(seconds: 4));

  static void info(BuildContext context, String message, {String? title}) =>
      show(context, message, type: ToastType.info, title: title);

  static void warning(BuildContext context, String message, {String? title}) =>
      show(context, message, type: ToastType.warning, title: title);
}

class _ToastConfig {
  final Color bg;
  final IconData icon;
  final String title;
  const _ToastConfig({required this.bg, required this.icon, required this.title});
}

_ToastConfig _config(ToastType type) {
  switch (type) {
    case ToastType.success:
      return const _ToastConfig(bg: Color(0xFF16A34A), icon: Icons.check_circle_rounded, title: 'Success');
    case ToastType.error:
      return const _ToastConfig(bg: Color(0xFFDC2626), icon: Icons.error_rounded, title: 'Error');
    case ToastType.warning:
      return const _ToastConfig(bg: Color(0xFFD97706), icon: Icons.warning_rounded, title: 'Warning');
    case ToastType.info:
      return _ToastConfig(bg: AppColors.primary, icon: Icons.info_rounded, title: 'Info');
  }
}
