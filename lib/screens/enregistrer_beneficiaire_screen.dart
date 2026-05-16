import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../l10n/translations.dart';
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

  String _checkType = '';
  Map<String, dynamic>? _checkData;
  int? _beneficiaireId;

  bool _success = false;
  String? _error;

  static const _genres = ['homme', 'femme', 'autre'];
  static const _categories = [
    'individu', 'famille', 'enfant', 'femme_chef_menage', 'deplacement_interne'
  ];

  Map<String, String> get _genreLabels => {
    'homme': tr('male'),
    'femme': tr('female'),
    'autre': tr('other'),
  };

  Map<String, String> get _categorieLabels => {
    'individu': tr('individual'),
    'famille': tr('family'),
    'enfant': tr('child'),
    'femme_chef_menage': tr('female_head'),
    'deplacement_interne': tr('idp'),
  };

  @override
  void initState() {
    super.initState();
    localeNotifier.addListener(_onLocaleChange);
  }

  void _onLocaleChange() => setState(() {});

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
      final data = res['data'] as Map<String, dynamic>;
      setState(() {
        if (data['found'] == false) {
          _checkType = 'new';
        } else if (data['doublon'] != null) {
          _checkType = 'duplicate';
          _checkData = data['doublon'] as Map<String, dynamic>;
          _beneficiaireId = (data['beneficiaire'] as Map<String, dynamic>?)?['id'] as int?;
        } else {
          _checkType = 'exists';
          _checkData = {'ong': ''};
          _beneficiaireId = (data['beneficiaire'] as Map<String, dynamic>?)?['id'] as int?;
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
      setState(() => _error = tr('required_fields'));
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
      setState(() => _error = e.response?.data?['message'] ?? tr('server_error'));
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
      locale: localeNotifier.value,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        title: Text(tr('register_ben_title'), style: const TextStyle(fontSize: 16)),
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
          _buildSectionTitle(tr('identity')),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildInput(_prenomCtrl, tr('first_name'), onBlur: _checkIdentity)),
              const SizedBox(width: 12),
              Expanded(child: _buildInput(_nomCtrl, tr('last_name'), onBlur: _checkIdentity)),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickDate,
            child: AbsorbPointer(
              child: _buildInput(_dateCtrl, tr('birth_date'), suffixIcon: Icons.calendar_today),
            ),
          ),

          if (_checking) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6))),
                const SizedBox(width: 8),
                Text(tr('checking'), style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ],
          if (!_checking && _checkType.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildCheckBadge(),
          ],

          const SizedBox(height: 20),

          _buildSectionTitle(tr('profile')),
          const SizedBox(height: 12),
          _buildDropdown(tr('gender'), _genres, _genre, (v) => setState(() => _genre = v!),
            labels: _genreLabels),
          const SizedBox(height: 12),
          _buildDropdown(tr('category'), _categories, _categorie, (v) => setState(() => _categorie = v!),
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
                  : Text(tr('register_btn'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
          if (_checkType == 'duplicate')
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(tr('dup_blocked_msg'), textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
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
            Text(tr('ben_registered'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
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
                child: Text(tr('distribute_arrow'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('back_dashboard'), style: const TextStyle(color: Color(0xFF64748B))),
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
          text: tr('new_beneficiary'));
    }
    if (_checkType == 'exists') {
      return _buildBadge(color: const Color(0xFFFFFBEB), border: const Color(0xFFFDE68A),
          icon: Icons.info_outline, iconColor: const Color(0xFFD97706),
          text: tr('already_registered'));
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
            Row(children: [
              const Icon(Icons.block, color: Color(0xFFDC2626), size: 18),
              const SizedBox(width: 8),
              Text(tr('duplicate_active'), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626), fontSize: 13)),
            ]),
            const SizedBox(height: 6),
            Text(
              '${tr('duplicate_detail')} ${_checkData?['aide'] ?? ''} '
              '${tr('by_org')} ${_checkData?['ong'] ?? ''}, '
              '${tr('valid_until')} ${_checkData?['expiration'] ?? ''}.',
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
    localeNotifier.removeListener(_onLocaleChange);
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }
}
