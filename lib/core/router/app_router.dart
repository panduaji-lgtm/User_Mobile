import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/data/services/auth_service.dart';
import 'package:app/views/screens/ai/museum_ai_chat_screen.dart';
import 'package:app/views/screens/auth/forgot_password_screen.dart';
import 'package:app/views/screens/auth/login_screen.dart';
import 'package:app/views/screens/auth/register_screen.dart';
import 'package:app/views/screens/auth/reset_password_screen.dart';
import 'package:app/views/screens/main_navigation.dart';
import 'package:app/views/screens/profile/edit_profile_screen.dart';

/// Konfigurasi Rute Aplikasi dan Auth Guard
class AppRouter {
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNav');

  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: AuthService.authNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final isLoggedIn = AuthService.isLoggedIn;
      var location = state.matchedLocation;

      // Normalisasi trailing slash (misal /tiket/ -> /tiket)
      if (location.length > 1 && location.endsWith('/')) {
        location = location.substring(0, location.length - 1);
      }

      // Rute autentikasi publik (tidak memerlukan status login)
      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location.startsWith('/reset-password');

      // Auth Guard: Jika belum login dan mengakses rute selain auth, arahkan ke /login
      if (!isLoggedIn) {
        return isAuthRoute ? null : '/login';
      }

      // Auth Guard: Jika sudah login tetapi mencoba membuka login/register, arahkan ke beranda
      final isLoginOrRegister = location == '/login' || location == '/register';
      if (isLoggedIn && isLoginOrRegister) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          final email = state.uri.queryParameters['email'] ?? '';
          return ResetPasswordScreen(token: token, email: email);
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const MainNavigation(initialIndex: 0),
      ),
      GoRoute(
        path: '/koleksi',
        builder: (context, state) => const MainNavigation(initialIndex: 1),
      ),
      GoRoute(
        path: '/tiket',
        builder: (context, state) => const MainNavigation(initialIndex: 2),
      ),
      GoRoute(
        path: '/tentang',
        builder: (context, state) => const MainNavigation(initialIndex: 3),
      ),
      GoRoute(
        path: '/profil',
        builder: (context, state) => const MainNavigation(initialIndex: 4),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/asisten-ai',
        builder: (context, state) {
          final prompt = state.uri.queryParameters['prompt'] ??
              (state.extra is String ? state.extra as String : null);
          return MuseumAiChatScreen(initialPrompt: prompt);
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Halaman Tidak Ditemukan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Rute "${state.uri}" tidak tersedia.',
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => context.go('/'),
                child: const Text('Kembali ke Beranda'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
