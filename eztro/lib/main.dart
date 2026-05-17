import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/constants/app_secrets.dart';
import 'services/auth_service.dart';
import 'views/home/home_screen.dart';
import 'views/home/tenant_home_screen.dart';
import 'views/auth/login_screen.dart';
import 'views/auth/role_selection_screen.dart';
import 'core/constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  MapboxOptions.setAccessToken(AppSecrets.mapboxAccessToken);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'EZTro',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        primaryColor: AppColors.primary,
      ),
      home: const AuthGate(),
    );
  }
}

/// AuthGate mới: Sử dụng AuthService thuần túy bằng Native SharedPreferences.
/// Tốc độ siêu nhẹ (0ms), không bị block khung hình bởi WebView.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Widget _initialScreen = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    final user = await AuthService.getCurrentUser();
    
    if (mounted) {
      if (user != null) {
        if (user.role == 'unassigned') {
          _initialScreen = const RoleSelectionScreen();
        } else if (user.role != 'tenant') {
          _initialScreen = const HomeScreen();
        } else {
          _initialScreen = const TenantHomeScreen();
        }
      } else {
        _initialScreen = const TenantHomeScreen();
      }
      
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Màn hình Splash siêu tốc (chạy chưa tới <0.1s vì đĩa đọc rất nhanh)
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    
    return _initialScreen;
  }
}
