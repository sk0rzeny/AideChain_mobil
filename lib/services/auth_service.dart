import 'package:shared_preferences/shared_preferences.dart';

const String _kToken = 'auth_token';
const String _kUserName = 'user_name';
const String _kOngNom = 'ong_nom';

class AuthService {
  static Future<void> saveSession({
    required String token,
    required String userName,
    required String ongNom,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kToken, token);
    await prefs.setString(_kUserName, userName);
    await prefs.setString(_kOngNom, ongNom);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kToken);
  }

  static Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kUserName) ?? '';
  }

  static Future<String> getOngNom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kOngNom) ?? '';
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kToken);
    await prefs.remove(_kUserName);
    await prefs.remove(_kOngNom);
  }
}
