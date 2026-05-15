import 'package:shared_preferences/shared_preferences.dart';

const String kApiUrlKey = 'api_base_url';
const String kApiDefaultUrl = 'http://192.168.1.1:8000';

Future<String> getApiBaseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(kApiUrlKey) ?? kApiDefaultUrl;
}

Future<void> saveApiBaseUrl(String url) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kApiUrlKey, url.trimRight().replaceAll(RegExp(r'/$'), ''));
}
