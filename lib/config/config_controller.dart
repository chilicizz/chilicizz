import 'package:chilicizz/config/config_store.dart';
import 'package:flutter/foundation.dart';

import 'local_storage_config_store.dart';

class ConfigController {
  final ConfigStore _store;

  final ValueNotifier<String?> userName = ValueNotifier(null);

  final ValueNotifier<String?> sessionId = ValueNotifier(null);

  /// Creates a new instance of [ConfigController] backed by [store].
  ///
  /// By default, settings are persisted using [ConfigLocalStorage]
  /// (i.e. NSUserDefaults on iOS, SharedPreferences on Android or
  /// local storage on the web).
  ConfigController({ConfigStore? store}) : _store = store ?? ConfigLocalStorage() {
    _loadStateFromPersistence();
  }

  void setUserName(String userName) {
    this.userName.value = userName;
    _store.saveUserName(userName);
  }

  /// Sets the session ID and persists it.
  void setSessionId(String sessionId) {
    this.sessionId.value = sessionId;
    _store.setSessionId(sessionId);
  }

  /// Asynchronously loads values from the injected persistence store.
  Future<void> _loadStateFromPersistence() async {
    final loadedValues = await Future.wait([
      _store.getSessionId().then((value) => sessionId.value = value),
      _store.getUserName().then((value) => userName.value = value),
    ]);
    debugPrint('Loaded state from persistence: $loadedValues');
  }
}
