import 'package:shared_preferences/shared_preferences.dart';

const String kApiUrlKey = 'api_base_url';
const String kApiDefaultUrl = 'https://aidechain.collaborativeteam.site';

Future<String> getApiBaseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(kApiUrlKey);
  // Réinitialise si l'ancienne valeur est une IP locale
  if (stored == null || stored.startsWith('http://192.') || stored.startsWith('http://10.') || stored.startsWith('http://172.')) {
    await prefs.setString(kApiUrlKey, kApiDefaultUrl);
    return kApiDefaultUrl;
  }
  return stored;
}

Future<void> saveApiBaseUrl(String url) async {
  final prefs = await SharedPreferences.getInstance();
  final clean = url.trim().replaceAll(RegExp(r'/$'), '');
  await prefs.setString(kApiUrlKey, clean);
}
