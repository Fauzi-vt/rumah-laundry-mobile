import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/app_theme.dart';
import 'core/app_colors.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'ui/screens/auth/login_screen.dart';
import 'ui/screens/auth/register_screen.dart';
import 'ui/screens/dashboard/dashboard_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
      ],
      child: const RumahLaundryApp(),
    ),
  );
}

class RumahLaundryApp extends StatelessWidget {
  const RumahLaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rumah Laundry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AuthGate(),
      routes: {
        '/login':    (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/home':     (_) => const DashboardShell(),
      },
    );
  }
}

// ── Auth Gate ──────────────────────────────────────────────────────────────────
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  Future<void> _checkSession() async {
    final auth = context.read<AuthProvider>();
    await auth.restoreSession();
    if (!mounted) return;
    if (auth.status == AuthStatus.authenticated) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: _SplashContent()),
    );
  }
}

// ── Splash ─────────────────────────────────────────────────────────────────────
class _SplashContent extends StatelessWidget {
  const _SplashContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 32),
        const SizedBox(
          width: 28, height: 28,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: AppColors.primaryGreen),
        ),
      ],
    );
  }
}
