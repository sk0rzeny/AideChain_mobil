import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/translations.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await loadSavedLocale();
  runApp(const AideChainApp());
}

class AideChainApp extends StatelessWidget {
  const AideChainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, _) {
        return MaterialApp(
          title: 'AideChain',
          debugShowCheckedModeBanner: false,
          locale: locale,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
            useMaterial3: true,
          ),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('fr', 'FR'),
            Locale('en', 'US'),
            Locale('ar', 'SA'),
          ],
          home: const SplashScreen(),
        );
      },
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icon.png', width: 96, height: 96),
            const SizedBox(height: 16),
            const Text('AideChain', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text(tr('app_subtitle'), style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
