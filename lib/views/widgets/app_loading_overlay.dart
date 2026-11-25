import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/views/screens/main_navigation.dart';

/// Loading Screen saat perpindahan halaman / proses navigasi di aplikasi pengunjung
/// Bertema Museum Klasik Brawijaya (Cream, Forest Green, Gold Accent)
class AppLoadingOverlay extends StatelessWidget {
  final String message;

  const AppLoadingOverlay({
    super.key,
    this.message = 'Memuat Museum Brawijaya...',
  });

  /// Helper untuk menampilkan overlay loading singkat lalu berpindah ke route/screen target
  /// Menggunakan OverlayEntry (bukan showDialog) agar tidak pernah berkonflik dengan stack GoRouter.
  static Future<void> navigateWithLoading(
    BuildContext context, {
    Widget? targetScreen,
    String? targetRoute,
    bool replace = false,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    OverlayEntry? overlayEntry;

    if (overlay != null) {
      overlayEntry = OverlayEntry(
        builder: (_) => Material(
          color: Colors.black.withValues(alpha: 0.45),
          child: const AppLoadingOverlay(),
        ),
      );
      overlay.insert(overlayEntry);
    }

    try {
      await Future.delayed(delay);
    } finally {
      overlayEntry?.remove();
    }

    if (!context.mounted) return;

    if (targetRoute != null) {
      context.go(targetRoute);
    } else if (targetScreen is MainNavigation) {
      context.go('/');
    } else if (targetScreen != null) {
      if (replace) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, _, _) => targetScreen,
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } else {
        Navigator.of(context).push(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, _, _) => targetScreen,
            transitionsBuilder: (_, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgCream = Color(0xFFF7F3EA);
    const Color darkGreen = Color(0xFF3F5243);
    const Color goldAccent = Color(0xFFCBB26A);
    const Color textDark = Color(0xFF2C322B);
    const Color textMuted = Color(0xFF727A71);

    return PopScope(
      canPop: false,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: bgCream,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2DDD5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge Icon Museum Berputar Halus
              Stack(
                alignment: Alignment.center,
                children: [
                  const SizedBox(
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.5,
                      valueColor: AlwaysStoppedAnimation<Color>(goldAccent),
                      backgroundColor: Color(0xFFE2DDD5),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: darkGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance,
                      color: goldAccent,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                'MUSEUM BRAWIJAYA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.3,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
