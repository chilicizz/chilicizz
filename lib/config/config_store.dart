abstract class ConfigStore {
  Future<String> getUserName();

  Future<List<String>> getAQILocations();

  Future<void> saveUserName(String value);

  Future<void> saveAQILocations(List<String> locations);

  Future<void> setSessionId(String value);

  Future<String> getSessionId();
}
