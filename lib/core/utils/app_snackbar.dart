import 'package:another_flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppSnackBar {
  /// Show Success Flushbar
  static void showSuccess(
    BuildContext context, {
    required String message,
    String title = 'Success',
    Duration duration = const Duration(seconds: 3),
    FlushbarPosition position = FlushbarPosition.TOP,
  }) {
    _showFlushbar(
      context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFF10B981), // Green
      icon: const Icon(
        Icons.check_circle_rounded,
        color: Colors.white,
        size: 28,
      ),
      duration: duration,
      position: position,
    );
  }

  /// Show Error Flushbar
  static void showError(
    BuildContext context, {
    required String message,
    String title = 'Error',
    Duration duration = const Duration(seconds: 4),
    FlushbarPosition position = FlushbarPosition.TOP,
  }) {
    _showFlushbar(
      context,
      title: title,
      message: message,
      backgroundColor: const Color(0xFFEF4444), // Red
      icon: const Icon(
        Icons.error_rounded,
        color: Colors.white,
        size: 28,
      ),
      duration: duration,
      position: position,
    );
  }

  /// Show Alert / Warning Flushbar
  static void showAlert(
    BuildContext context, {
    required String message,
    String title = 'Warning',
    Duration duration = const Duration(seconds: 3),
    FlushbarPosition position = FlushbarPosition.TOP,
  }) {
    _showFlushbar(
      context,
      title: title,
      message: message,
      backgroundColor: AppColors.primary, // Orange Brand Color
      icon: const Icon(
        Icons.warning_amber_rounded,
        color: Colors.white,
        size: 28,
      ),
      duration: duration,
      position: position,
    );
  }

  /// Show Info Flushbar
  static void showInfo(
    BuildContext context, {
    required String message,
    String title = 'Notice',
    Duration duration = const Duration(seconds: 3),
    FlushbarPosition position = FlushbarPosition.TOP,
  }) {
    _showFlushbar(
      context,
      title: title,
      message: message,
      backgroundColor: AppColors.secondary, // Dark Blue Brand Color
      icon: const Icon(
        Icons.info_rounded,
        color: Colors.white,
        size: 28,
      ),
      duration: duration,
      position: position,
    );
  }

  /// Internal builder method for another_flushbar
  static void _showFlushbar(
    BuildContext context, {
    required String title,
    required String message,
    required Color backgroundColor,
    required Widget icon,
    required Duration duration,
    required FlushbarPosition position,
  }) {
    Flushbar(
      titleText: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      messageText: Text(
        message,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
      icon: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: icon,
      ),
      duration: duration,
      flushbarPosition: position,
      flushbarStyle: FlushbarStyle.FLOATING,
      margin: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: backgroundColor,
      boxShadows: [
        BoxShadow(
          color: backgroundColor.withValues(alpha: 0.4),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ],
      dismissDirection: FlushbarDismissDirection.HORIZONTAL,
      forwardAnimationCurve: Curves.easeOutBack,
    ).show(context);
  }
}
