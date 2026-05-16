import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../l10n/translations.dart';
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
  final _passCtrl  = TextEditingController();
  final _urlCtrl   = TextEditingController();
  bool _loading      = false;
  bool _showUrlField = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUrl();
    localeNotifier.addListener(_onLocaleChange);
  }

  void _onLocaleChange() => setState(() {});

  Future<void> _loadUrl() async {
    _urlCtrl.text = await getApiBaseUrl();
  }

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    if (_showUrlField && _urlCtrl.text.trim().isNotEmpty) {
      await saveApiBaseUrl(_urlCtrl.text);
    }
    setState(() { _loading = true; _error = null; });

    try {
      final res  = await ApiService.login(_emailCtrl.text.trim(), _passCtrl.text);
      final inner = res['data'] as Map<String, dynamic>;
      final token = inner['token'] as String;
      final user  = inner['user']  as Map<String, dynamic>;
      final ong   = inner['ong']   as Map<String, dynamic>?;

      await AuthService.saveSession(
        token:    token,
        userName: user['name'] as String,
        ongNom:   ong?['nom'] as String? ?? '',
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
    } on DioException catch (e) {
      setState(() {
        if (e.response?.statusCode == 401) {
          _error = tr('wrong_credentials');
        } else if (e.response != null) {
          _error = '${tr('server_error')} ${e.response!.statusCode}.';
        } else if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
          _error = tr('timeout_error');
        } else if (e.type == DioExceptionType.connectionError) {
          _error = '${tr('connection_error')}\n${e.error?.toString() ?? ''}';
        } else {
          _error = e.message;
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sélecteur de langue
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _langBtn('fr', 'FR'),
                    const SizedBox(width: 8),
                    _langBtn('en', 'EN'),
                    const SizedBox(width: 8),
                    _langBtn('ar', 'AR'),
                  ],
                ),
                const SizedBox(height: 28),

                // Logo
                Image.asset('assets/icon.png', width: 80, height: 80),
                const SizedBox(height: 16),
                const Text('AideChain', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(tr('field_interface'), textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                const SizedBox(height: 40),

                _buildField(controller: _emailCtrl, label: tr('email'), keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildField(controller: _passCtrl, label: tr('password'), obscure: true),
                const SizedBox(height: 24),

                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
                  ),
                  const SizedBox(height: 16),
                ],

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
                        : Text(tr('login_btn'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () => setState(() => _showUrlField = !_showUrlField),
                  child: Text(_showUrlField ? tr('hide_url') : tr('configure_url'),
                    style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                ),
                if (_showUrlField) ...[
                  const SizedBox(height: 8),
                  _buildField(controller: _urlCtrl, label: tr('api_url_label')),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      await saveApiBaseUrl(_urlCtrl.text);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(tr('url_saved')), backgroundColor: const Color(0xFF16A34A)));
                        setState(() => _showUrlField = false);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(tr('save_url')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _langBtn(String code, String label) {
    final active = localeNotifier.value.languageCode == code;
    return GestureDetector(
      onTap: () => setLocale(code),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF3B82F6) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF64748B),
          )),
      ),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, bool obscure = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
      ),
    );
  }

  @override
  void dispose() {
    localeNotifier.removeListener(_onLocaleChange);
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }
}
