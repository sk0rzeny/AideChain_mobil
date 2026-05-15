import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../config/api.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _loading = false;
  bool _showUrlField = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    _urlCtrl.text = await getApiBaseUrl();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    setState(() { _loading = true; _error = null; });

    try {
      final res = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
      final inner = res['data'] as Map<String, dynamic>;
      final token = inner['token'] as String;
      final user = inner['user'] as Map<String, dynamic>;
      final ong = inner['ong'] as Map<String, dynamic>?;

      await AuthService.saveSession(
        token: token,
        userName: user['name'] as String,
        ongNom: ong?['nom'] as String? ?? '',
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } on DioException catch (e) {
      setState(() {
        _error = e.response?.statusCode == 401
            ? 'Email ou mot de passe incorrect.'
            : 'Impossible de contacter le serveur. Vérifiez l\'URL API.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo
                const Icon(Icons.shield_outlined, size: 64, color: Color(0xFF3B82F6)),
                const SizedBox(height: 16),
                const Text(
                  'AideChain',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Interface agent terrain',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                ),
                const SizedBox(height: 40),

                // Champ email
                _buildField(
                  controller: _emailCtrl,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 14),

                // Champ mot de passe
                _buildField(
                  controller: _passCtrl,
                  label: 'Mot de passe',
                  obscure: true,
                ),
                const SizedBox(height: 24),

                // Erreur
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7F1D1D).withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.5)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

                // Bouton login
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Se connecter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 20),

                // Config URL
                TextButton(
                  onPressed: () => setState(() => _showUrlField = !_showUrlField),
                  child: Text(
                    _showUrlField ? 'Masquer la configuration' : 'Configurer l\'URL du serveur',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                ),
                if (_showUrlField) ...[
                  const SizedBox(height: 8),
                  _buildField(controller: _urlCtrl, label: 'URL API (ex: http://192.168.1.5:8000)'),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      await saveApiBaseUrl(_urlCtrl.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('URL enregistrée'), backgroundColor: Color(0xFF16A34A)),
                        );
                        setState(() => _showUrlField = false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF94A3B8),
                      side: const BorderSide(color: Color(0xFF334155)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Enregistrer l\'URL'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }
}
