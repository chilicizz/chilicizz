import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class AppConfig {
  static final AppConfig _singleton = AppConfig._internal();
  late final String corsProxy;
  late final String hkoWarningsUrl;
  late final String hkoTyphoonUrl;
  late final String mapTileUrl;
  late final List<String> mapTileSubDomains = [];
  late final String _aqiFeedTemplate;
  late final String _aqiLocationSearchTemplate;

  factory AppConfig() {
    return _singleton;
  }

  AppConfig._internal();

  Future<void> init() async {
    // load the json file
    final contents = await rootBundle.loadString('assets/config/config.json');
    // decode our json
    dynamic json = jsonDecode(contents);
    corsProxy = json["corsProxy"];
    hkoWarningsUrl = json["hkoWarningsUrl"];
    hkoTyphoonUrl = json["hkoTyphoonUrl"];
    mapTileUrl = json["mapTileUrl"];
    for (dynamic entry in json["mapTileSubDomains"]) {
      mapTileSubDomains.add(entry.toString());
    }
    _aqiLocationSearchTemplate = json["aqiLocationSearchTemplate"];
    _aqiFeedTemplate = json["aqiFeedTemplate"];
    return;
  }

  String aqiFeedUrl(String location, String token) {
    return _aqiFeedTemplate
        .replaceAll("#LOCATION#", location)
        .replaceAll("#TOKEN#", token);
  }

  String aqiLocationSearchUrl(String location, String token) {
    return _aqiLocationSearchTemplate
        .replaceAll("#LOCATION#", location)
        .replaceAll("#TOKEN#", token);
  }
}
