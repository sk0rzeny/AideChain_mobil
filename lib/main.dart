import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AideChainApp());
}

class AideChainApp extends StatelessWidget {
  const AideChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AideChain',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    final loggedIn = await AuthService.isLoggedIn();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => loggedIn ? const DashboardScreen() : const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 72, color: Color(0xFF3B82F6)),
            SizedBox(height: 16),
            Text('AideChain', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 8),
            Text('Registre partagé · Tchad', style: TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
