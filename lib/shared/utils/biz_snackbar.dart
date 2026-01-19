import 'package:flutter/material.dart';

class BizSnackbar {
  static void showSuccess(BuildContext context, String message) {
    _show(
      context,
      message,
      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
      const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)], // Emerald Green
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  static void showError(BuildContext context, String message) {
    _show(
      context,
      message,
      const Icon(Icons.error_outline_rounded, color: Colors.white, size: 28),
      const LinearGradient(
        colors: [Color(0xFFDC2626), Color(0xFFEF4444)], // Red
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  static void showInfo(BuildContext context, String message) {
    _show(
      context,
      message,
      const Icon(Icons.info_outline_rounded, color: Colors.white, size: 28),
      LinearGradient(
        colors: [Theme.of(context).primaryColor, Theme.of(context).primaryColor.withValues(alpha: 0.8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );
  }

  static void _show(
    BuildContext context,
    String message,
    Widget icon,
    Gradient backgroundGradient,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: icon,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        padding: EdgeInsets.zero,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        animation: CurvedAnimation(
          parent: const AlwaysStoppedAnimation(1),
          curve: Curves.easeOutBack,
        ),
      ),
    );

    // We can't easily style the SnackBar background itself with a gradient
    // So we use a little hack or just rely on the content container if we want full gradient.
    // Actually, to get a gradient SnackBar, we usually wrap the content in a Container with decoration
    // and make the SnackBar background transparent.
    
    // Let's re-invoke with the correct structure for gradient:
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          decoration: BoxDecoration(
            gradient: backgroundGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: icon,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
