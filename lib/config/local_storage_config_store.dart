import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config_store.dart';

class ConfigLocalStorage extends ConfigStore {
  final Future<SharedPreferences> instanceFuture = SharedPreferences.getInstance();

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
  Future<String> getSessionId() async {
    final prefs = await instanceFuture;
    return prefs.getString('device_id') ?? UniqueKey().hashCode.toString();
  }

  @override
  Future<void> setSessionId(String value) async {
    final prefs = await instanceFuture;
    await prefs.setString('device_id', value);
  }
}
