import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../screens/admin_login_screen.dart';
import '../services/admin_auth_service.dart';

class AdminAuthGate extends StatelessWidget {
  final Widget child;

  const AdminAuthGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminAuthService.hasAdminSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) return child;
        return const AdminLoginScreen();
      },
    );
  }
}
