import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';
import '../services/sync_service.dart';
import 'login_screen.dart';
import 'enregistrer_beneficiaire_screen.dart';
import 'distribuer_aide_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _userName = '';
  String _ongNom = '';
  bool _isOnline = true;
  int _pendingCount = 0;
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _listenConnectivity();
  }

  Future<void> _loadData() async {
    final name = await AuthService.getUserName();
    final ong = await AuthService.getOngNom();
    final pending = await DbService.countPending();
    if (mounted) setState(() { _userName = name; _ongNom = ong; _pendingCount = pending; });
  }

  void _listenConnectivity() {
    Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((r) => r != ConnectivityResult.none);
      setState(() => _isOnline = online);
      if (online && _pendingCount > 0) _syncNow();
    });
  }

  Future<void> _syncNow() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final result = await SyncService.syncPending();
    final pending = await DbService.countPending();
    if (!mounted) return;
    setState(() { _pendingCount = pending; _syncing = false; });
    if (result.synced > 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${result.synced} distribution(s) synchronisée(s)'),
        backgroundColor: const Color(0xFF16A34A),
      ));
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _openEnregistrerBeneficiaire() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => const EnregistrerBeneficiaireScreen(),
    ));
    _loadData();
  }

  void _openDistribuerAide() async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => const DistribuerAideScreen(),
    ));
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AideChain', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            if (_ongNom.isNotEmpty)
              Text(_ongNom, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF94A3B8)),
            onPressed: _logout,
            tooltip: 'Déconnexion',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            // Banière offline
            if (!_isOnline)
              _buildBanner(
                color: const Color(0xFFFFF7ED),
                border: const Color(0xFFFB923C),
                icon: Icons.wifi_off,
                iconColor: const Color(0xFFF97316),
                text: 'Mode hors ligne — les distributions seront synchronisées au retour du réseau.',
              ),

            // Banière sync en attente
            if (_pendingCount > 0) ...[
              if (!_isOnline) const SizedBox(height: 10),
              _buildBanner(
                color: const Color(0xFFFEFCE8),
                border: const Color(0xFFEAB308),
                icon: Icons.sync,
                iconColor: const Color(0xFFCA8A04),
                text: '$_pendingCount distribution(s) en attente de synchronisation.',
                action: _isOnline
                    ? TextButton(
                        onPressed: _syncing ? null : _syncNow,
                        child: _syncing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFCA8A04)))
                            : const Text('Synchroniser', style: TextStyle(color: Color(0xFFCA8A04), fontWeight: FontWeight.w600)),
                      )
                    : null,
              ),
            ],

            const SizedBox(height: 24),

            // Bonjour
            Text(
              'Bonjour, $_userName',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Que souhaitez-vous faire ?',
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 24),

            // Actions
            _buildActionCard(
              onTap: _openEnregistrerBeneficiaire,
              color: const Color(0xFFEFF6FF),
              border: const Color(0xFFBFDBFE),
              iconBg: const Color(0xFF3B82F6),
              icon: Icons.person_add_outlined,
              title: 'Enregistrer un bénéficiaire',
              subtitle: 'Vérification doublon automatique',
            ),
            const SizedBox(height: 14),
            _buildActionCard(
              onTap: _openDistribuerAide,
              color: const Color(0xFFF0FDF4),
              border: const Color(0xFFBBF7D0),
              iconBg: const Color(0xFF16A34A),
              icon: Icons.check_circle_outline,
              title: 'Distribuer une aide',
              subtitle: 'Sélectionner parmi les projets actifs',
            ),

            const SizedBox(height: 32),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 16),
            const Text(
              'Pour créer des projets ou gérer votre ONG, connectez-vous via l\'interface web.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBanner({
    required Color color,
    required Color border,
    required IconData icon,
    required Color iconColor,
    required String text,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: iconColor))),
          if (action != null) action,
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required VoidCallback onTap,
    required Color color,
    required Color border,
    required Color iconBg,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
