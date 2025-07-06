import 'dart:convert';
import 'dart:io';

import 'package:chilicizz/HKO/typhoon/dummy_typhoon.dart';
import 'package:chilicizz/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

class Typhoon {
  final int id;
  final String englishName;
  final String chineseName;
  final String url;

  Typhoon(
      {required this.id, required this.chineseName, required this.englishName, required this.url});

  @Deprecated("to remove")
  Uri getTrackUrl() {
    Uri uri = Uri.parse(dotenv.env["corsProxy"]! + url);
    return uri;
  }

  @Deprecated("to remove")
  Uri getTrackUrlId() {
    Uri uri = Uri.parse(dotenv.env["hkoTyphoonTrack"]! + id.toString());
    return uri;
  }

  @Deprecated("to remove")
  Future<TyphoonTrack?> getTyphoonTrack() async {
    return TyphoonHttpClient.fetchTyphoonTrack(this);
  }
}

class TyphoonTrack {
  final TyphoonBulletin bulletin;
  final List<TyphoonPosition> past;
  final List<TyphoonPosition> forecast;
  final TyphoonPosition current;

  TyphoonTrack(this.bulletin, this.current, this.past, this.forecast);

  factory TyphoonTrack.fromXML(String xmlString) {
    final document = XmlDocument.parse(xmlString);
    final bulletinElement = document.findAllElements('BulletinHeader').single;

    TyphoonBulletin bulletin = TyphoonBulletin.fromXmlElement(bulletinElement);
    final analysisElement = document.findAllElements('AnalysisInformation').single;
    TyphoonPosition currentAnalysis = parseEntry(analysisElement)!;

    final pastInformationElements = document.findAllElements('PastInformation');
    List<TyphoonPosition> past =
        pastInformationElements.map(parseEntry).whereType<TyphoonPosition>().toList();

    final forecastInformationElements = document.findAllElements('ForecastInformation');
    List<TyphoonPosition> forecast =
        forecastInformationElements.map(parseEntry).whereType<TyphoonPosition>().toList();
    forecast.sort((a, b) {
      return a.index.compareTo(b.index);
    });
    // oldest first
    past.sort((a, b) {
      return a.index.compareTo(b.index);
    });
    past.add(currentAnalysis); // add latest for easy reference
    return TyphoonTrack(bulletin, currentAnalysis, past, forecast);
  }

  factory TyphoonTrack.fromJson(dynamic json) {
    final TyphoonBulletin bulletin;
    final List<TyphoonPosition> past = [];
    final List<TyphoonPosition> forecast = [];
    TyphoonPosition? current;

    String name = json['bulletinName'] ?? '';
    String provider = json['bulletinProvider'] ?? '';
    DateTime time = DateTime.tryParse(json['bulletinTime']) ?? DateTime.now();
    bulletin = TyphoonBulletin(name, provider, time);

    if (json['track'] is List) {
      for (dynamic entry in json['track']) {
        try {
          TyphoonPosition position = TyphoonPosition.fromJson(entry);
          switch (position.timePeriod) {
            case TimePeriod.past:
              past.add(position);
              break;
            case TimePeriod.current:
              current = position;
              break;
            case TimePeriod.forecast:
              forecast.add(position);
              break;
            default:
              debugPrint(
                  "Unknown time period for position: ${position.index}, ${position.latitude}, ${position.longitude}");
          }
        } catch (e) {
          debugPrint("Failed to parse position entry: $entry, error: $e");
          continue; // skip invalid entries
        }
      }
    } else {
      throw Exception("Invalid track data format");
    }

    forecast.sort((a, b) {
      return a.index.compareTo(b.index);
    });
    // oldest first
    past.sort((a, b) {
      return a.index.compareTo(b.index);
    });
    if (current == null) {
      throw Exception("Current position not found in track data");
    }
    past.add(current); // add latest for easy reference
    return TyphoonTrack(bulletin, current, past, forecast);
  }
}

enum TimePeriod {
  past,
  current,
  forecast;

  String get name {
    switch (this) {
      case TimePeriod.past:
        return "PAST";
      case TimePeriod.current:
        return "CURRENT";
      case TimePeriod.forecast:
        return "FORECAST";
    }
  }

  static TimePeriod? fromString(String? value) {
    if (value == null) return null;
    switch (value.toLowerCase().trim()) {
      case 'past':
        return TimePeriod.past;
      case 'current':
        return TimePeriod.current;
      case 'forecast':
        return TimePeriod.forecast;
      default:
        return null;
    }
  }
}

class TyphoonPosition {
  final int index;
  final String? intensity;
  final double? maximumWind; // km/h
  final DateTime? time; // if no time then interpolated position
  final double latitude; // N
  final double longitude; // E
  final TyphoonClass typhoonClass;
  final TimePeriod? timePeriod;

  TyphoonPosition(
    this.index,
    this.intensity,
    this.maximumWind,
    this.time,
    this.latitude,
    this.longitude,
    this.typhoonClass,
    this.timePeriod, // optional
  );

  factory TyphoonPosition.fromXMLElement(XmlElement element) {
    int index = 0;
    String? intensity;
    double? maximumWind; // km/h
    DateTime? time; // if no time then interpolated position
    double latitude = double.nan; // N
    double longitude = double.nan; // E
    for (var child in element.childElements) {
      try {
        if (child.name.local == 'Intensity') {
          intensity = child.innerText;
        } else if (child.name.local == 'Latitude') {
          latitude = double.tryParse(removeNonNumeric(child.innerText)) ?? double.nan;
        } else if (child.name.local == 'Longitude') {
          longitude = double.tryParse(removeNonNumeric(child.innerText)) ?? double.nan;
        } else if (child.name.local == 'Time') {
          time = DateTime.parse(child.innerText);
        } else if (child.name.local == 'MaximumWind') {
          maximumWind = double.tryParse(removeNonNumeric(child.innerText)) ?? double.nan;
        } else if (child.name.local == 'Index') {
          index = int.tryParse(removeNonNumeric(child.innerText)) ?? 0;
        }
      } catch (e) {
        debugPrint("Error parsing $child");
      }
    }
    TyphoonClass typhoonClass = TyphoonClass.fromMaximumWind(maximumWind);
    if (latitude.isNaN || longitude.isNaN) {
      throw Exception("Failed to parse position $element");
    }
    return TyphoonPosition(
        index, intensity, maximumWind, time, latitude, longitude, typhoonClass, null);
  }

  factory TyphoonPosition.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      double latitude =
          double.tryParse(removeNonNumeric(json['latitude'] ?? '')) ?? double.nan; // N
      double longitude =
          double.tryParse(removeNonNumeric(json['longitude'] ?? '')) ?? double.nan; // E
      double? maximumWind =
          double.tryParse(removeNonNumeric(json["maximumWind"] ?? '')) ?? double.nan; // km/h
      int index = json['index'] is int ? json["index"] : int.tryParse(json['index']) ?? 0;
      if (latitude.isNaN || longitude.isNaN) {
        throw Exception("Failed to parse position $json");
      }
      TyphoonClass typhoonClass = TyphoonClass.fromMaximumWind(maximumWind);
      TimePeriod? timePeriod = TimePeriod.fromString(json["timePeriod"]);
      DateTime? time = json['time'] != null ? DateTime.tryParse(json['time']) : null;
      String? intensity = json['intensity'] is String ? json['intensity'] : null;
      return TyphoonPosition(
          index, intensity, maximumWind, time, latitude, longitude, typhoonClass, timePeriod);
    }
    throw Exception("Failed to parse position $json");
  }

  LatLng getLatLng({latitudeOffset = 0, longitudeOffset = 0}) {
    return LatLng(latitude + latitudeOffset, longitude + longitudeOffset);
  }
}

class TyphoonClass {
  final String name;
  final double minWind;
  final double maxWind;
  final Color color;

  TyphoonClass(
    this.name,
    this.minWind,
    this.maxWind,
    this.color,
  );

  bool within(double speed) {
    return speed >= minWind && speed < maxWind;
  }

  static TyphoonClass unknownClass = TyphoonClass("unknown", -1, -1, Colors.grey);

  static List<TyphoonClass> typhoonClasses = [
    TyphoonClass("Extratropical Low", 0, 41, Colors.blue),
    TyphoonClass("Tropical Depression", 41, 62, Colors.lightGreen),
    TyphoonClass("Tropical Storm", 62, 87, Colors.amber),
    TyphoonClass("Severe Tropical Storm", 87, 117, Colors.orange),
    TyphoonClass("Typhoon", 117, 149, Colors.red),
    TyphoonClass("Severe Typhoon", 149, 184, Colors.deepPurple),
    TyphoonClass("Super Typhoon", 184, double.maxFinite, Colors.black),
  ];

  static TyphoonClass fromMaximumWind(double? maximumWind) {
    for (var referenceClass in TyphoonClass.typhoonClasses) {
      double speed = maximumWind ?? -1;
      if (referenceClass.within(speed)) {
        return referenceClass;
      }
    }
    return unknownClass;
  }
}

class TyphoonBulletin {
  final String name;
  final String provider;
  final DateTime time;

  TyphoonBulletin(
    this.name,
    this.provider,
    this.time,
  );

  factory TyphoonBulletin.fromXmlElement(XmlElement bulletinElement) {
    String? name = "";
    String? provider = "";
    DateTime time = DateTime.now();
    for (var element in bulletinElement.childElements) {
      if (element.name.local == 'BulletinName') {
        name = element.innerText;
      } else if (element.name.local == 'BulletinProvider') {
        provider = element.innerText;
      } else if (element.name.local == 'BulletinTime') {
        time = DateTime.parse(element.innerText);
      }
    }
    return TyphoonBulletin(name!, provider!, time);
  }

  factory TyphoonBulletin.fromJson(dynamic json) {
    if (json is! Map<String, dynamic>) {
      throw Exception("Invalid JSON format for TyphoonBulletin");
    }
    String name = json['bulletinName'] ?? '';
    String provider = json['bulletinProvider'] ?? '';
    DateTime time = DateTime.tryParse(json['bulletinTime']) ?? DateTime.now();
    return TyphoonBulletin(name, provider, time);
  }
}

List<Typhoon> parseTyphoonFeed(String xmlString) {
  try {
    final document = XmlDocument.parse(xmlString);
    final titles = document.findAllElements('TropicalCyclone');
    return titles.map((element) {
      return Typhoon(
        id: int.parse(element.findElements("TropicalCycloneID").first.innerText),
        chineseName: element.findElements("TropicalCycloneChineseName").first.innerText,
        englishName: element.findElements("TropicalCycloneEnglishName").first.innerText,
        url: element
            .findElements("TropicalCycloneURL")
            .first
            .innerText
            .replaceAll("http://", "https://"),
      );
    }).toList();
  } catch (e) {
    debugPrint(xmlString.replaceAll('\n', ''));
    debugPrint("Failed to parse typhoon feed $e");
    return [];
  }
}

TyphoonTrack? parseTyphoonTrack(String xmlString) {
  try {
    return TyphoonTrack.fromXML(xmlString);
  } catch (e) {
    debugPrint(xmlString.replaceAll('\n', ''));
    debugPrint("Failed to parse typhoon track data $e");
    return null;
  }
}

TyphoonPosition? parseEntry(XmlElement element) {
  try {
    return TyphoonPosition.fromXMLElement(element);
  } catch (e) {
    debugPrint("Failed to parse typhoon position data $e");
    return null;
  }
}

@Deprecated("Use TyphoonHttpClientJson instead")
class TyphoonHttpClient {
  static Future<List<Typhoon>> dummyTyphoonList() async {
    return [dummyTyphoon()];
  }

  static Future<List<Typhoon>> fetchTyphoonFeed(String hkoTyphoonUrl) async {
    try {
      var path = Uri.parse(hkoTyphoonUrl);
      var response = await http.get(path, headers: {
        HttpHeaders.contentTypeHeader: 'application/xml',
        HttpHeaders.accessControlAllowOriginHeader: '*',
        HttpHeaders.accessControlAllowMethodsHeader: 'GET,HEAD,POST,OPTIONS',
        HttpHeaders.accessControlAllowHeadersHeader: '*',
      });
      if (response.statusCode == 200) {
        String xmlString = const Utf8Decoder().convert(response.bodyBytes);
        var typhoonFeed = parseTyphoonFeed(xmlString);
        return typhoonFeed;
      } else {
        throw Exception('Feed returned ${response.body}');
      }
    } catch (e) {
      debugPrint("Failed to fetch typhoon data $e");
      rethrow;
    }
  }

  static Future<TyphoonTrack?> fetchTyphoonTrack(Typhoon typhoon) async {
    try {
      Uri uri = typhoon.getTrackUrlId();
      var response = await http.get(uri, headers: {
        HttpHeaders.contentTypeHeader: 'application/xml',
        HttpHeaders.accessControlAllowOriginHeader: '*',
        HttpHeaders.accessControlAllowMethodsHeader: 'GET,HEAD,POST,OPTIONS',
        HttpHeaders.accessControlAllowHeadersHeader: '*',
      });
      if (response.statusCode == 200) {
        String xmlDoc = const Utf8Decoder().convert(response.bodyBytes);
        var typhoonTrack = parseTyphoonTrack(xmlDoc);
        return typhoonTrack;
      }
    } catch (e) {
      debugPrint("Error $e falling back to proxy");
      Uri uri = typhoon.getTrackUrl();
      var response = await http.get(uri, headers: {
        HttpHeaders.contentTypeHeader: 'application/xml',
        HttpHeaders.accessControlAllowOriginHeader: '*',
        HttpHeaders.accessControlAllowMethodsHeader: 'GET,HEAD,POST,OPTIONS',
        HttpHeaders.accessControlAllowHeadersHeader: '*',
      });
      if (response.statusCode == 200) {
        String xmlDoc = const Utf8Decoder().convert(response.bodyBytes);
        var typhoonTrack = parseTyphoonTrack(xmlDoc);
        return typhoonTrack;
      }
      debugPrint("Failed to fetch typhoon data $e");
    }
    return null;
  }
}

class TyphoonHttpClientJson {
  static const typhoonListPath = "/typhoon-json/list";
  static const typhoonTrackPath = "/typhoon-json/track/";

  final String baseUrl;

  TyphoonHttpClientJson(this.baseUrl);

  static Future<List<Typhoon>> dummyTyphoonList() async {
    return [dummyTyphoon()];
  }

  Future<List<Typhoon>> fetchTyphoonFeed() async {
    try {
      var path = Uri.parse(baseUrl + typhoonListPath);
      var response = await http.get(path, headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.accessControlAllowOriginHeader: '*',
        HttpHeaders.accessControlAllowMethodsHeader: 'GET,HEAD,POST,OPTIONS',
        HttpHeaders.accessControlAllowHeadersHeader: '*',
      });
      if (response.statusCode == 200) {
        String payload = const Utf8Decoder().convert(response.bodyBytes);
        dynamic json = jsonDecode(payload);
        if (json is List) {
          return json.map<Typhoon>((item) {
            return Typhoon(
              id: int.parse(item['id'] ?? item['TropicalCycloneID']),
              chineseName: item['chineseName'] ?? item['TropicalCycloneChineseName'] ?? '',
              englishName: item['englishName'] ?? item['TropicalCycloneEnglishName'] ?? '',
              url: (item['url'] ?? item['TropicalCycloneURL'] ?? '')
                  .replaceAll("http://", "https://"),
            );
          }).toList();
        } else {
          throw Exception('Unexpected JSON format: $payload');
        }
      } else {
        throw Exception('Feed returned ${response.body}');
      }
    } catch (e) {
      debugPrint("Failed to fetch typhoon data $e");
      rethrow;
    }
  }

  Future<TyphoonTrack?> fetchTyphoonTrack(String typhoonId) async {
    try {
      Uri uri = Uri.parse("$baseUrl$typhoonTrackPath$typhoonId");
      var response = await http.get(uri, headers: {
        HttpHeaders.contentTypeHeader: 'application/json',
        HttpHeaders.accessControlAllowOriginHeader: '*',
        HttpHeaders.accessControlAllowMethodsHeader: 'GET,HEAD,POST,OPTIONS',
        HttpHeaders.accessControlAllowHeadersHeader: '*',
      });
      if (response.statusCode == 200) {
        String payload = const Utf8Decoder().convert(response.bodyBytes);
        dynamic json = jsonDecode(payload);
        if (json is Map<String, dynamic>) {
          if (json.isNotEmpty) {
            return TyphoonTrack.fromJson(json);
          } else {
            throw Exception('No data found in response');
          }
        } else {
          throw Exception('Unexpected JSON format: $payload');
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch typhoon track data $e");
    }
    return null;
  }
}
