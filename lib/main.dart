import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/admin_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/category_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/order_provider.dart';
import 'providers/product_provider.dart';
import 'providers/user_management_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/category_service.dart';
import 'services/cart_service.dart';
import 'services/coupon_service.dart';
import 'services/order_service.dart';
import 'services/product_service.dart';
import 'services/user_service.dart';
import 'supabase_client.dart';
import 'ui/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khoi tao ket noi Supabase truoc khi build app.
  // URL/ANON KEY duoc lay tu AppConfig (dart-define).
  if (AppConfig.isConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }

  runApp(const ShopApp());
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Neu chua cau hinh Supabase thi chan app tai man hinh huong dan.
    if (!AppConfig.isConfigured) {
      return const MaterialApp(home: MissingConfigScreen());
    }

    // Tao service 1 lan tai root de cac Provider su dung lai.
    // Luong tong quat: Screen -> Provider -> Service -> Supabase.
    final authService = AuthService();
    final productService = ProductService();
    final cartService = CartService();
    final couponService = CouponService();
    final orderService = OrderService();
    final categoryService = CategoryService();
    final userService = UserService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        ChangeNotifierProvider(create: (_) => ProductProvider(productService)),
        ChangeNotifierProvider(
          create: (_) => CategoryProvider(categoryService),
        ),
        ChangeNotifierProvider(create: (_) => CartProvider(cartService)),
        ChangeNotifierProvider(
          create: (_) => OrderProvider(orderService, couponService),
        ),
        ChangeNotifierProvider(
          create: (_) => AdminProvider(orderService, couponService),
        ),
        ChangeNotifierProvider(
          create: (_) => UserManagementProvider(userService),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mobile Device Shop',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // Theo doi trang thai dang nhap tu AuthProvider.
    // Co session thi vao Home, khong thi ve Login.
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;
    return isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}

class MissingConfigScreen extends StatelessWidget {
  const MissingConfigScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Supabase config is missing.\n\nRun with:\n'
            'flutter run --dart-define=SUPABASE_URL=YOUR_URL '
            '--dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
