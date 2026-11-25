import 'package:flutter/material.dart';
import 'package:app/features/auth/presentation/views/login_screen.dart';
import 'package:app/features/navigation/presentation/views/main_navigation.dart';
import 'package:app/features/auth/data/repositories/auth_service.dart';
import 'package:app/core/widgets/mobile_frame.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Museum Brawijaya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800),
        useMaterial3: true,
      ),
      builder: (context, child) => MobileFrame(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  late final Future<UserModel?> _sessionFuture;

  @override
  void initState() {
    super.initState();
    _sessionFuture = AuthService.restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel?>(
      future: _sessionFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFFF7F3EA),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF3F5243)),
            ),
          );
        }
        if (snapshot.data != null) {
          return const MainNavigation();
        }
        return const LoginScreen();
      },
    );
  }
}