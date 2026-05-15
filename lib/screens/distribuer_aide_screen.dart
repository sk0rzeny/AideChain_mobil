import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import '../services/db_service.dart';

class DistribuerAideScreen extends StatefulWidget {
  final int? beneficiaireId;
  final String? beneficiaireNom;

  const DistribuerAideScreen({super.key, this.beneficiaireId, this.beneficiaireNom});

  @override
  State<DistribuerAideScreen> createState() => _State();
}

class _State extends State<DistribuerAideScreen> {
  // Étape 1 — recherche bénéficiaire
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  bool _searching = false;
  String? _searchError;

  // Bénéficiaire trouvé
  int? _beneficiaireId;
  String _beneficiaireNom = '';
  Map<String, dynamic>? _doublonInfo;

  // Étape 2 — projets
  List<Map<String, dynamic>> _projets = [];
  bool _loadingProjets = false;
  int? _selectedProjetId;
  String _notesText = '';

  // Soumission
  bool _submitting = false;
  bool _savedOffline = false;
  String? _submitError;

  int _step = 1; // 1=recherche, 2=projet, 3=succès

  @override
  void initState() {
    super.initState();
    // Si bénéficiaire passé depuis EnregistrerBeneficiaireScreen
    if (widget.beneficiaireId != null) {
      _beneficiaireId = widget.beneficiaireId;
      _beneficiaireNom = widget.beneficiaireNom ?? '';
      _step = 2;
      _loadProjets();
    }
  }

  Future<void> _searchBeneficiaire() async {
    if (_prenomCtrl.text.isEmpty || _nomCtrl.text.isEmpty || _dateCtrl.text.isEmpty) return;
    setState(() { _searching = true; _searchError = null; _doublonInfo = null; });

    try {
      final res = await ApiService.checkBeneficiaire(
        prenom: _prenomCtrl.text.trim(),
        nom: _nomCtrl.text.trim(),
        dateNaissance: _dateCtrl.text,
      );

      if (!mounted) return;

      if (res['found'] == false) {
        setState(() => _searchError = 'Bénéficiaire introuvable. Enregistrez-le d\'abord.');
        return;
      }

      if (res['doublon'] != null) {
        setState(() => _doublonInfo = res['doublon'] as Map<String, dynamic>);
      }

      setState(() {
        _beneficiaireId = res['beneficiaire_id'] as int?;
        _beneficiaireNom = '${_prenomCtrl.text.trim()} ${_nomCtrl.text.trim()}';
        _step = 2;
      });
      _loadProjets();
    } catch (_) {
      if (mounted) setState(() => _searchError = 'Impossible de contacter le serveur.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _loadProjets() async {
    setState(() => _loadingProjets = true);
    try {
      final projets = await ApiService.getProjets();
      if (mounted) setState(() => _projets = projets);
    } catch (_) {
      if (mounted) setState(() => _projets = []);
    } finally {
      if (mounted) setState(() => _loadingProjets = false);
    }
  }

  Future<void> _distribuer() async {
    if (_selectedProjetId == null) {
      setState(() => _submitError = 'Sélectionnez un projet.');
      return;
    }
    setState(() { _submitting = true; _submitError = null; });

    // Vérifier la connectivité
    final connectivity = await Connectivity().checkConnectivity();
    final isOnline = connectivity.any((r) => r != ConnectivityResult.none);

    if (!isOnline) {
      // Sauvegarder offline
      await DbService.saveDistribution(
        beneficiaireId: _beneficiaireId!,
        projetAideId: _selectedProjetId!,
        notes: _notesText.isNotEmpty ? _notesText : null,
      );
      if (mounted) setState(() { _savedOffline = true; _submitting = false; _step = 3; });
      return;
    }

    try {
      await ApiService.distribuerAide(
        beneficiaireId: _beneficiaireId!,
        projetAideId: _selectedProjetId!,
        notes: _notesText.isNotEmpty ? _notesText : null,
      );
      if (mounted) setState(() { _savedOffline = false; _step = 3; });
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        final doublon = e.response?.data?['doublon'] as Map<String, dynamic>?;
        setState(() => _submitError =
          'DOUBLON ACTIF — Ce bénéficiaire reçoit déjà une aide "${doublon?['type'] ?? ''}" '
          'de ${doublon?['ong'] ?? ''}, valide jusqu\'au ${doublon?['expiration'] ?? ''}.');
      } else {
        setState(() => _submitError = e.response?.data?['message'] ?? 'Erreur serveur.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
    );
    if (date != null && mounted) {
      setState(() {
        _dateCtrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Distribuer une aide', style: TextStyle(fontSize: 16)),
        elevation: 0,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _step == 1
            ? _buildStepRecherche()
            : _step == 2
                ? _buildStepProjet()
                : _buildSuccess(),
      ),
    );
  }

  Widget _buildStepRecherche() {
    return SingleChildScrollView(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Identifier le bénéficiaire', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 4),
          const Text('Saisissez l\'identité exacte telle qu\'elle a été enregistrée.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(child: _buildInput(_prenomCtrl, 'Prénom')),
              const SizedBox(width: 12),
              Expanded(child: _buildInput(_nomCtrl, 'Nom')),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: _buildInput(_dateCtrl, 'Date de naissance', suffixIcon: Icons.calendar_today),
            ),
          ),

          if (_searchError != null) ...[
            const SizedBox(height: 12),
            _buildErrorBox(_searchError!),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _searching ? null : _searchBeneficiaire,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _searching
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Rechercher', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepProjet() {
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Carte bénéficiaire
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person, color: Color(0xFF64748B), size: 20),
                const SizedBox(width: 10),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bénéficiaire', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                    Text(_beneficiaireNom, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  ],
                )),
                TextButton(onPressed: () => setState(() { _step = 1; _doublonInfo = null; }), child: const Text('Changer', style: TextStyle(fontSize: 12))),
              ],
            ),
          ),

          // Alerte doublon existant
          if (_doublonInfo != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Row(children: [
                  Icon(Icons.warning_amber, color: Color(0xFFDC2626), size: 16),
                  SizedBox(width: 6),
                  Text('Aide active détectée', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 13)),
                ]),
                const SizedBox(height: 4),
                Text(
                  '${_doublonInfo!['aide']} — ${_doublonInfo!['ong']} — exp. ${_doublonInfo!['expiration']}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
                ),
              ]),
            ),
          ],

          const SizedBox(height: 20),
          const Text('Sélectionner le projet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 16),

          if (_loadingProjets)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          else if (_projets.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFFDE68A))),
              child: const Text('Aucun projet actif. Demandez au représentant de créer un projet via l\'interface web.', style: TextStyle(fontSize: 13, color: Color(0xFFD97706))),
            )
          else
            ..._projets.map((p) => _buildProjetCard(p)),

          const SizedBox(height: 16),

          // Notes
          TextField(
            onChanged: (v) => _notesText = v,
            maxLines: 2,
            style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Notes (optionnel)',
              labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          if (_submitError != null) ...[
            const SizedBox(height: 12),
            _buildErrorBox(_submitError!),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _submitting || _projets.isEmpty ? null : _distribuer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Confirmer la distribution', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjetCard(Map<String, dynamic> projet) {
    final selected = _selectedProjetId == projet['id'];
    return GestureDetector(
      onTap: () => setState(() { _selectedProjetId = projet['id'] as int; _submitError = null; }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FDF4) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(projet['nom'] as String, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: selected ? const Color(0xFF15803D) : const Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(
                    '${projet['type_aide']}${projet['zone_cible'] != null ? ' · ${projet['zone_cible']}' : ''} · exp. ${(projet['date_expiration'] as String).substring(0, 10)}',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      key: const ValueKey(3),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _savedOffline ? const Color(0xFFFFFBEB) : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(36),
              ),
              child: Icon(
                _savedOffline ? Icons.schedule : Icons.check,
                color: _savedOffline ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _savedOffline ? 'Sauvegardé hors ligne' : 'Aide enregistrée',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              _savedOffline
                  ? 'La distribution sera synchronisée automatiquement au retour du réseau.'
                  : 'La distribution a été enregistrée avec succès dans le registre partagé.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: const Text('Retour au tableau de bord', style: TextStyle(color: Color(0xFF475569))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label, {IconData? suffixIcon}) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Color(0xFF0F172A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true, fillColor: Colors.white,
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF94A3B8), size: 18) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildErrorBox(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(msg, style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13)),
    );
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }
}
