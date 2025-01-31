// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:chilicizz/config/config_store.dart';
import 'package:flutter/foundation.dart';

import 'local_storage_config_store.dart';

class ConfigController {
  final ConfigStore _store;

  /// The player's name. Used for things like high score lists.
  ValueNotifier<String> userName = ValueNotifier('anon');

  ValueNotifier<List<String>> aqiLocations = ValueNotifier(<String>[]);

  ValueNotifier<String> sessionId = ValueNotifier('');

  /// Creates a new instance of [ConfigController] backed by [store].
  ///
  /// By default, settings are persisted using [ConfigLocalStorage]
  /// (i.e. NSUserDefaults on iOS, SharedPreferences on Android or
  /// local storage on the web).
  ConfigController({ConfigStore? store})
      : _store = store ?? ConfigLocalStorage() {
    _loadStateFromPersistence();
  }

  void setUserName(String userName) {
    this.userName.value = userName;
    _store.saveUserName(userName);
  }

  void setAQILocations(List<String> aqiLocations) {
    this.aqiLocations.value = aqiLocations;
    _store.saveAQILocations(aqiLocations);
  }

  void addAQILocation(String location) {
    List<String> locations = aqiLocations.value;
    locations.add(location);
    aqiLocations.value = locations;
    setAQILocations(locations);
  }

  void updateAQILocation(String originalLocation, String newLocation) {
    List<String> locations = aqiLocations.value;
    locations.remove(originalLocation);
    locations.add(newLocation);
    aqiLocations.value = locations;
    setAQILocations(locations);
  }

  void removeAQILocation(String originalLocation) {
    List<String> locations = aqiLocations.value;
    locations.remove(originalLocation);
    aqiLocations.value = locations;
    setAQILocations(locations);
  }

  /// Asynchronously loads values from the injected persistence store.
  Future<void> _loadStateFromPersistence() async {
    final loadedValues = await Future.wait([
      _store.getSessionId().then((value) => sessionId.value = value),
      _store.getUserName().then((value) => userName.value = value),
      _store.getAQILocations().then((value) => aqiLocations.value = value),
    ]);
    debugPrint('Loaded state from persistence: $loadedValues');
  }
}
