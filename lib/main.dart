import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase_config.dart';
import 'admin/screens/admin_dashboard_screen.dart';
import 'admin/screens/admin_login_screen.dart';
import 'admin/screens/admin_order_detail_screen.dart';
import 'admin/screens/admin_orders_screen.dart';
import 'admin/screens/admin_product_form_screen.dart';
import 'admin/screens/admin_products_screen.dart';
import 'admin/screens/admin_voucher_form_screen.dart';
import 'admin/screens/admin_vouchers_screen.dart';
import 'admin/widgets/admin_auth_gate.dart';
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
    final initialPath = Uri.base.fragment.isNotEmpty
        ? Uri.base.fragment
        : Uri.base.path;

    final adminHome = switch (initialPath) {
      '/admin' => const AdminLoginScreen(),
      '/admin/dashboard' => const AdminAuthGate(child: AdminDashboardScreen()),
      '/admin/products' => const AdminAuthGate(child: AdminProductsScreen()),
      '/admin/products/form' => const AdminAuthGate(child: AdminProductFormScreen()),
      '/admin/orders' => const AdminAuthGate(child: AdminOrdersScreen()),
      '/admin/orders/detail' => const AdminAuthGate(child: AdminOrderDetailScreen()),
      '/admin/vouchers' => const AdminAuthGate(child: AdminVouchersScreen()),
      '/admin/vouchers/form' => const AdminAuthGate(child: AdminVoucherFormScreen()),
      _ => null,
    };

    final Widget home;
    if (adminHome != null) {
      home = adminHome;
    } else if (!databaseConfigured) {
      home = const DatabaseSetupScreen();
    } else {
      final session = Supabase.instance.client.auth.currentSession;
      home = session != null ? const MainScreen() : const LoginScreen();
    }

    return MaterialApp(
      title: 'Daisy Shop',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: home,
      routes: {
        '/login': (_) => const LoginScreen(),
        '/admin': (_) => const AdminLoginScreen(),
        '/admin/dashboard': (_) => const AdminAuthGate(child: AdminDashboardScreen()),
        '/admin/products': (_) => const AdminAuthGate(child: AdminProductsScreen()),
        '/admin/products/form': (_) => const AdminAuthGate(child: AdminProductFormScreen()),
        '/admin/orders': (_) => const AdminAuthGate(child: AdminOrdersScreen()),
        '/admin/orders/detail': (_) => const AdminAuthGate(child: AdminOrderDetailScreen()),
        '/admin/vouchers': (_) => const AdminAuthGate(child: AdminVouchersScreen()),
        '/admin/vouchers/form': (_) => const AdminAuthGate(child: AdminVoucherFormScreen()),
      },
      onUnknownRoute: (_) => MaterialPageRoute(
        builder: (_) => const AdminDashboardScreen(),
      ),
    );
  }
}
