import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'screens/database_setup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');

  if (SupabaseConfig.isValid) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  }

  runApp(DaisyShopApp(databaseConfigured: SupabaseConfig.isValid));
}

class DaisyShopApp extends StatelessWidget {
  final bool databaseConfigured;

  const DaisyShopApp({super.key, required this.databaseConfigured});

  @override
  Widget build(BuildContext context) {
    final session = databaseConfigured
        ? Supabase.instance.client.auth.currentSession
        : null;

    return MaterialApp(
      title: 'Daisy Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: !databaseConfigured
          ? const DatabaseSetupScreen()
          : session != null
          ? const MainScreen()
          : const LoginScreen(),
      routes: {'/login': (_) => const LoginScreen()},
    );
  }
}
