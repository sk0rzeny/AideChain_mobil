import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'distribuer_aide_screen.dart';

class EnregistrerBeneficiaireScreen extends StatefulWidget {
  const EnregistrerBeneficiaireScreen({super.key});

  @override
  State<EnregistrerBeneficiaireScreen> createState() => _State();
}

class _State extends State<EnregistrerBeneficiaireScreen> {
  final _prenomCtrl = TextEditingController();
  final _nomCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  String _genre = '';
  String _categorie = '';
  bool _loading = false;
  bool _checking = false;

  // Résultat du check identité
  String _checkType = ''; // 'new' | 'exists' | 'duplicate' | ''
  Map<String, dynamic>? _checkData;
  int? _beneficiaireId;

  bool _success = false;
  String? _error;

  static const _genres = ['homme', 'femme', 'autre'];
  static const _categories = [
    'individu', 'famille', 'enfant', 'femme_chef_menage', 'deplacement_interne'
  ];
  static const _categorieLabels = {
    'individu': 'Individu',
    'famille': 'Famille',
    'enfant': 'Enfant',
    'femme_chef_menage': 'Femme chef de ménage',
    'deplacement_interne': 'Déplacé interne',
  };

  Future<void> _checkIdentity() async {
    if (_prenomCtrl.text.isEmpty || _nomCtrl.text.isEmpty || _dateCtrl.text.isEmpty) return;
    setState(() { _checking = true; _checkType = ''; _checkData = null; _beneficiaireId = null; });

    try {
      final res = await ApiService.checkBeneficiaire(
        prenom: _prenomCtrl.text.trim(),
        nom: _nomCtrl.text.trim(),
        dateNaissance: _dateCtrl.text,
      );

      if (!mounted) return;
      setState(() {
        if (res['found'] == false) {
          _checkType = 'new';
        } else if (res['doublon'] != null) {
          _checkType = 'duplicate';
          _checkData = res['doublon'] as Map<String, dynamic>;
          _beneficiaireId = res['beneficiaire_id'] as int?;
        } else {
          _checkType = 'exists';
          _checkData = {'ong': res['beneficiaire']?['ong']?['nom'] ?? ''};
          _beneficiaireId = res['beneficiaire_id'] as int?;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _checkType = '');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _enregistrer() async {
    if (_prenomCtrl.text.isEmpty || _nomCtrl.text.isEmpty || _dateCtrl.text.isEmpty ||
        _genre.isEmpty || _categorie.isEmpty) {
      setState(() => _error = 'Tous les champs sont obligatoires.');
      return;
    }
    setState(() { _loading = true; _error = null; });

    try {
      final res = await ApiService.storeBeneficiaire(
        prenom: _prenomCtrl.text.trim(),
        nom: _nomCtrl.text.trim(),
        dateNaissance: _dateCtrl.text,
        genre: _genre,
        categorie: _categorie,
      );
      final bene = res['data']['beneficiaire'] as Map<String, dynamic>;
      if (!mounted) return;
      setState(() { _success = true; _beneficiaireId = bene['id'] as int; });
    } on DioException catch (e) {
      setState(() => _error = e.response?.data?['message'] ?? 'Erreur serveur.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 1)),
      locale: const Locale('fr', 'FR'),
    );
    if (date != null && mounted) {
      setState(() {
        _dateCtrl.text = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      });
      _checkIdentity();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: const Text('Enregistrer un bénéficiaire', style: TextStyle(fontSize: 16)),
        elevation: 0,
      ),
      body: _success ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section identité
          _buildSectionTitle('Identité'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInput(_prenomCtrl, 'Prénom', onBlur: _checkIdentity)),
              const SizedBox(width: 12),
              Expanded(child: _buildInput(_nomCtrl, 'Nom', onBlur: _checkIdentity)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: _buildInput(_dateCtrl, 'Date de naissance (AAAA-MM-JJ)', suffixIcon: Icons.calendar_today),
            ),
          ),

          // Indicateur check
          if (_checking) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6))),
                SizedBox(width: 8),
                Text('Vérification en cours...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],
          if (!_checking && _checkType.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCheckBadge(),
          ],

          const SizedBox(height: 20),

          // Section profil
          _buildSectionTitle('Profil'),
          const SizedBox(height: 12),
          _buildDropdown('Genre', _genres, _genre, (v) => setState(() => _genre = v!),
            labels: {'homme': 'Homme', 'femme': 'Femme', 'autre': 'Autre'}),
          const SizedBox(height: 12),
          _buildDropdown('Catégorie', _categories, _categorie, (v) => setState(() => _categorie = v!),
            labels: _categorieLabels),

          if (_error != null) ...[
            const SizedBox(height: 14),
            _buildErrorBox(_error!),
          ],

          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _loading || _checkType == 'duplicate' ? null : _enregistrer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF94A3B8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          if (_checkType == 'duplicate')
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Enregistrement bloqué — doublon actif détecté.', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(36)),
              child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Bénéficiaire enregistré', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('${_prenomCtrl.text} ${_nomCtrl.text}', style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => DistribuerAideScreen(beneficiaireId: _beneficiaireId, beneficiaireNom: '${_prenomCtrl.text} ${_nomCtrl.text}')),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Distribuer une aide →', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retour au tableau de bord', style: TextStyle(color: Color(0xFF64748B))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckBadge() {
    if (_checkType == 'new') {
      return _buildBadge(color: const Color(0xFFF0FDF4), border: const Color(0xFF86EFAC),
          icon: Icons.fiber_new, iconColor: const Color(0xFF16A34A),
          text: 'Nouveau bénéficiaire — sera ajouté au registre.');
    }
    if (_checkType == 'exists') {
      return _buildBadge(color: const Color(0xFFFFFBEB), border: const Color(0xFFFDE68A),
          icon: Icons.info_outline, iconColor: const Color(0xFFD97706),
          text: 'Déjà enregistré par ${_checkData?['ong'] ?? ''}. L\'aide sera liée au dossier existant.');
    }
    if (_checkType == 'duplicate') {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFCA5A5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(children: [
              Icon(Icons.block, color: Color(0xFFDC2626), size: 18),
              SizedBox(width: 8),
              Text('DOUBLON ACTIF — Distribution bloquée', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Text(
              'Ce bénéficiaire reçoit déjà une aide ${_checkData?['aide'] ?? ''} '
              'distribuée par ${_checkData?['ong'] ?? ''}, '
              'valide jusqu\'au ${_checkData?['expiration'] ?? ''}.',
              style: const TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBadge({required Color color, required Color border, required IconData icon, required Color iconColor, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: iconColor))),
      ]),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569), letterSpacing: 0.5));
  }

  Widget _buildInput(TextEditingController ctrl, String label, {IconData? suffixIcon, VoidCallback? onBlur}) {
    return Focus(
      onFocusChange: (hasFocus) { if (!hasFocus && onBlur != null) onBlur(); },
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: Color(0xFF0F172A)),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: const Color(0xFF94A3B8), size: 18) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> values, String current, ValueChanged<String?> onChanged, {Map<String, String>? labels}) {
    return DropdownButtonFormField<String>(
      value: current.isEmpty ? null : current,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: values.map((v) => DropdownMenuItem(value: v, child: Text(labels?[v] ?? v, style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14)))).toList(),
      onChanged: onChanged,
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
