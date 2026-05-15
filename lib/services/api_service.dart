import 'package:dio/dio.dart';
import '../config/api.dart';
import 'auth_service.dart';

class ApiService {
  static Future<Dio> _client() async {
    final baseUrl = await getApiBaseUrl();
    final token = await AuthService.getToken();
    final dio = Dio(BaseOptions(
      baseUrl: '$baseUrl/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ));
    return dio;
  }

  // Auth
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final dio = await _client();
    final res = await dio.post('/login', data: {'email': email, 'password': password});
    return res.data as Map<String, dynamic>;
  }

  static Future<void> logout() async {
    try {
      final dio = await _client();
      await dio.post('/logout');
    } catch (_) {}
  }

  // Projets
  static Future<List<Map<String, dynamic>>> getProjets() async {
    final dio = await _client();
    final res = await dio.get('/projets');
    final data = res.data['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  // Bénéficiaires
  static Future<Map<String, dynamic>> checkBeneficiaire({
    required String prenom,
    required String nom,
    required String dateNaissance,
  }) async {
    final dio = await _client();
    final res = await dio.get('/beneficiaires/check', queryParameters: {
      'prenom': prenom,
      'nom': nom,
      'date_naissance': dateNaissance,
    });
    return res.data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> storeBeneficiaire({
    required String prenom,
    required String nom,
    required String dateNaissance,
    required String genre,
    required String categorie,
  }) async {
    final dio = await _client();
    final res = await dio.post('/beneficiaires', data: {
      'prenom': prenom,
      'nom': nom,
      'date_naissance': dateNaissance,
      'genre': genre,
      'categorie': categorie,
    });
    return res.data as Map<String, dynamic>;
  }

  // Aides
  static Future<Map<String, dynamic>> distribuerAide({
    required int beneficiaireId,
    required int projetAideId,
    String? notes,
  }) async {
    final dio = await _client();
    final res = await dio.post('/aides', data: {
      'beneficiaire_id': beneficiaireId,
      'projet_aide_id': projetAideId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return res.data as Map<String, dynamic>;
  }
}
