import 'package:flutter/material.dart';

class CustomToast {
  static void show(
    BuildContext context,
    String message, {
    bool isSuccess = false,
    bool isError = false,
    bool isWarning = false,
  }) {
    Color primaryColor = const Color(0xFF1A237E); // Default deep blue
    IconData icon = Icons.info_outline_rounded;

    if (isSuccess) {
      primaryColor = const Color(0xFF2E7D32); // Modern green
      icon = Icons.check_circle_outline_rounded;
    } else if (isError) {
      primaryColor = const Color(0xFFC62828); // Modern red
      icon = Icons.error_outline_rounded;
    } else if (isWarning) {
      primaryColor = const Color(0xFFEF6C00); // Modern orange
      icon = Icons.warning_amber_rounded;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        padding: EdgeInsets.zero,
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: const Duration(seconds: 3),
        content: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.95),
                primaryColor.withAlpha(220),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
