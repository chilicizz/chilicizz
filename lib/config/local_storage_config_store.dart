import 'package:shared_preferences/shared_preferences.dart';

import 'config_store.dart';

class ConfigLocalStorage extends ConfigStore {
  final Future<SharedPreferences> instanceFuture =
      SharedPreferences.getInstance();

  @override
  Future<String> getUserName() async {
    final prefs = await instanceFuture;
    return prefs.getString('user_name') ?? 'anon';
  }

  @override
  Future<void> saveUserName(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('user_name', value);
  }

  @override
  Future<List<String>> getAQILocations() async {
    final prefs = await instanceFuture;
    return prefs.getStringList('aqi_locations') ?? <String>[];
  }

  @override
  Future<void> saveAQILocations(List<String> locations) async {
    final prefs = await instanceFuture;
    await prefs.setStringList('aqi_locations', locations);
  }
}
