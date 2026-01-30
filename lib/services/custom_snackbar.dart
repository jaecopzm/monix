import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final color = _getColorForType(type);
    final icon = _getIconForType(type);
    
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Image.asset(
                'assets/icons/monixx-icon.png',
                width: 16,
                height: 16,
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        elevation: 8,
      ),
    );
  }

  static Color _getColorForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppTheme.successColor;
      case SnackBarType.error:
        return AppTheme.errorColor;
      case SnackBarType.warning:
        return AppTheme.warningColor;
      case SnackBarType.info:
      default:
        return AppTheme.primaryColor;
    }
  }

  static IconData _getIconForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle;
      case SnackBarType.error:
        return Icons.error;
      case SnackBarType.warning:
        return Icons.warning;
      case SnackBarType.info:
      default:
        return Icons.info;
    }
  }
}

enum SnackBarType {
  success,
  error,
  warning,
  info,
}
