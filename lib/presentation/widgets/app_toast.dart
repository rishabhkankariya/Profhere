import 'package:flutter/material.dart';

enum AppToastType { success, error, info }

abstract final class AppToast {
  static void success(BuildContext context, String message) {
    _show(context, message: message, type: AppToastType.success);
  }

  static void error(BuildContext context, String message) {
    _show(context, message: message, type: AppToastType.error);
  }

  static void info(BuildContext context, String message) {
    _show(context, message: message, type: AppToastType.info);
  }

  static void _show(
    BuildContext context, {
    required String message,
    required AppToastType type,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (backgroundColor, foregroundColor, icon) = switch (type) {
      AppToastType.success => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
        Icons.check_circle_rounded,
      ),
      AppToastType.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.error_rounded,
      ),
      AppToastType.info => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
        Icons.info_rounded,
      ),
    };

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: backgroundColor,
          elevation: 10,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          content: Row(
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foregroundColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }
}
