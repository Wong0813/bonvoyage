import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'utils/app_theme.dart';

void main() {
  runApp(const BonVoyageApp());
}

class BonVoyageApp extends StatelessWidget {
  const BonVoyageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BonVoyage',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppTheme.primary,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppTheme.bg,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
