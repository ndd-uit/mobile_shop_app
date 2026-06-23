import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DaisyShopApp());
}

class DaisyShopApp extends StatelessWidget {
  const DaisyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daisy Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/login',
      routes: {'/login': (_) => const LoginScreen()},
    );
  }
}
