abstract class ConfigStore {
  Future<String?> getUserName();

  Future<void> saveUserName(String value);

  Future<void> setSessionId(String value);

  Future<String> getSessionId();
}
