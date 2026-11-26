import 'package:flutter/material.dart';

import 'package:app/core/router/app_router.dart';
import 'package:app/features/auth/data/repositories/auth_service.dart';
import 'package:app/core/widgets/mobile_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pulihkan session login dari SharedPreferences sebelum UI dirender
  await AuthService.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Museum Brawijaya',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue.shade800),
        useMaterial3: true,
      ),
      routerConfig: AppRouter.router,
      builder: (context, child) => MobileFrame(
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
