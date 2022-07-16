import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

// https://www.hko.gov.hk/en/abouthko/opendata_intro.htm
// https://data.weather.gov.hk/weatherAPI/doc/HKO_Open_Data_API_Documentation.pdf
const String infoUrl =
    "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warningInfo&lang=en";
const String typhoonUrl =
    "https://www.weather.gov.hk/wxinfo/currwx/tc_list.xml";
const String corsProxyPrefix =
    "https://proxy.chilicizz.workers.dev/corsproxy/?apiurl=";

class WarningInformation {
  String warningStatementCode;
  String? subType;
  List<String> contents;
  DateTime updateTime;

  WarningInformation(
      this.warningStatementCode, this.subType, this.contents, this.updateTime);

  String getDescription() {
    return warningStringMap[subType ?? warningStatementCode] ??
        subType ??
        warningStatementCode;
  }

  CircleAvatar getCircleAvatar() {
    return warningIconMap[subType ?? warningStatementCode] ??
        CircleAvatar(
          child: FittedBox(
            child: Text(subType ?? warningStatementCode),
          ),
        );
  }
}

List<WarningInformation> extractWarnings(dynamic json) {
  List<WarningInformation> result = [];
  if (json == null || json?["details"] == null) {
    return [];
  }
  for (dynamic entry in json?["details"]) {
    try {
      String warningStatementCode = entry?["warningStatementCode"];
      String? subType = entry?["subtype"];
      var updateTime = DateTime.parse("${entry?["updateTime"]}");
      List<String> contents = [for (var i in entry?["contents"]) '$i'];
      result.add(WarningInformation(
          warningStatementCode, subType, contents, updateTime));
    } catch (e) {
      debugPrint(e.toString());
    }
  }
  return result;
}

const Map<String, String> warningStringMap = {
  "WFIREY": "Yellow Fire Danger Warning",
  "WFIRER": "Red Fire Danger Warning",
  "WRAINA": "Amber Rainstorm Warning",
  "WRAINR": "Red Rainstorm Warning",
  "WRAINB": "Black Rainstorm Warning",
  "TC1": "Standby Signal No.1",
  "TC3": "Strong Wind Signal No.3",
  "TC8NE": "No.8 North East Gale or Storm",
  "TC8SE": "No.8 South East Gale or Storm",
  "TC8SW": "No.8 South West Gale or Storm",
  "TC8NW": "No.8 North West Gale or Storm",
  "TC9": "Increasing Gale or Storm No.9",
  "TC10": "Hurricane Signal No.10",
  "WFROST": "Frost Warning",
  "WHOT": "Very Hot Weather Warning",
  "WCOLD": "Cold Weather Warning",
  "WMSGNL": "Strong Monsoon",
  "WFNTSA": "Flooding in the Northern New Territories",
  "WL": "Landslip Warning",
  "WTMW": "Tsunami Warning",
  "WTS": "Thunderstorm Warning",
};

const Map<String, CircleAvatar> warningIconMap = {
  // Fetch icons from https://www.hko.gov.hk/textonly/v2/explain/intro.htm
  "WFIREY": CircleAvatar(
      backgroundColor: Colors.yellow,
      child: Icon(Icons.local_fire_department, color: Colors.black)),
  "WFIRER": CircleAvatar(
      backgroundColor: Colors.red,
      child: Icon(Icons.local_fire_department, color: Colors.black)),
  "WRAINA": CircleAvatar(backgroundColor: Colors.amber, child: Text('🌧')),
  "WRAINR": CircleAvatar(backgroundColor: Colors.red, child: Text('🌧')),
  "WRAINB": CircleAvatar(backgroundColor: Colors.black, child: Text('🌧')),
  "TC1": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T1",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC3": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T3",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8NE": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T8",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8SE": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T8",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8SW": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T8",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8NW": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T8",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC9": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T9",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC10": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T10",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "WFROST": CircleAvatar(
      backgroundColor: Colors.blue,
      child: Icon(Icons.ac_unit, color: Colors.white)),
  "WHOT": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Icon(Icons.thermostat, color: Colors.red)),
  "WCOLD": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Icon(Icons.thermostat, color: Colors.blue)),
  "WMSGNL": CircleAvatar(
      backgroundColor: Colors.cyan,
      child: Icon(Icons.air, color: Colors.white)),
  "WFNTSA": CircleAvatar(
      backgroundColor: Colors.cyan,
      child: Icon(Icons.water, color: Colors.lime)),
  "WL": CircleAvatar(
      backgroundColor: Colors.brown,
      child: Icon(Icons.report_problem, color: Colors.yellow)),
  "WTMW": CircleAvatar(backgroundColor: Colors.amberAccent, child: Text("🌊")),
  "WTS": CircleAvatar(
      backgroundColor: Colors.black,
      child: Icon(Icons.bolt, color: Colors.yellow)),
};

Future<List<Typhoon>> fetchTyphoonFeed() async {
  try {
    var path = Uri.parse(corsProxyPrefix + typhoonUrl);
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

class Typhoon {
  int id;
  String englishName;
  String chineseName;
  String url;

  Typhoon(
      {required this.id,
      required this.chineseName,
      required this.englishName,
      required this.url});

  Future<TyphoonTrack?> getTyphoonTrack() async {
    try {
      Uri uri = Uri.parse(corsProxyPrefix + url);
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
      debugPrint("Failed to fetch typhoon data $e");
    }
    return null;
  }
}

class TyphoonTrack {
  TyphoonBulletin bulletin;
  List<TyphoonPosition> past;
  List<TyphoonPosition> forecast;
  TyphoonPosition current;

  TyphoonTrack(this.bulletin, this.current, this.past, this.forecast);
}

class TyphoonPosition {
  late int index;
  String? intensity;
  double? maximumWind; // km/h
  DateTime? time; // if no time then interpolated position
  late double latitude; // N
  late double longitude; // E
  TyphoonClass _class = unknownClass;

  TyphoonPosition();

  LatLng getLatLng({latitudeOffset = 0, longitudeOffset = 0}) {
    return LatLng(latitude + latitudeOffset, longitude + longitudeOffset);
  }

  TyphoonClass getTyphoonClass() {
    if (_class == unknownClass) {
      double speed = maximumWind ?? 0;
      for (var typhoonClass in typhoonClasses) {
        if (typhoonClass.within(speed)) {
          _class = typhoonClass;
          return typhoonClass;
        }
      }
    }
    return _class;
  }
}

class TyphoonClass {
  String name;
  double minWind;
  double maxWind;
  Color color;

  TyphoonClass(this.name, this.minWind, this.maxWind, this.color);

  bool within(double speed) {
    return speed >= minWind && speed < maxWind;
  }
}

TyphoonClass unknownClass = TyphoonClass("unknown", -1, -1, Colors.grey);

List<TyphoonClass> typhoonClasses = [
  TyphoonClass("Extratropical Low", double.minPositive, 41, Colors.blue),
  TyphoonClass("Tropical Depression", 41, 62, Colors.lightGreen),
  TyphoonClass("Tropical Storm", 62, 87, Colors.yellow),
  TyphoonClass("Severe Tropical Storm", 87, 117, Colors.orange),
  TyphoonClass("Typhoon", 117, 149, Colors.red),
  TyphoonClass("Severe Typhoon", 149, 184, Colors.deepPurple),
  TyphoonClass("Super Typhoon", 184, double.maxFinite, Colors.black),
];

class TyphoonBulletin {
  late String name;
  late String provider;
  late DateTime time;

  TyphoonBulletin();
}

List<Typhoon> parseTyphoonFeed(String xmlString) {
  try {
    final document = XmlDocument.parse(xmlString);
    final titles = document.findAllElements('TropicalCyclone');
    return titles.map((element) {
      return Typhoon(
        id: int.parse(element.findElements("TropicalCycloneID").single.text),
        chineseName:
            element.findElements("TropicalCycloneChineseName").single.text,
        englishName:
            element.findElements("TropicalCycloneEnglishName").single.text,
        url: element
            .findElements("TropicalCycloneURL")
            .single
            .text
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
    final document = XmlDocument.parse(xmlString);
    final bulletinElement = document.findAllElements('BulletinHeader').single;

    TyphoonBulletin bulletin = TyphoonBulletin();
    for (var element in bulletinElement.childElements) {
      if (element.name.local == 'BulletinName') {
        bulletin.name = element.text;
      } else if (element.name.local == 'BulletinProvider') {
        bulletin.provider = element.text;
      } else if (element.name.local == 'BulletinTime') {
        bulletin.time = DateTime.parse(element.text);
      }
    }
    final analysisElement =
        document.findAllElements('AnalysisInformation').single;
    TyphoonPosition currentAnalysis = parseEntry(analysisElement)!;

    final pastInformationElements = document.findAllElements('PastInformation');
    List<TyphoonPosition> past = pastInformationElements
        .map(parseEntry)
        .whereType<TyphoonPosition>()
        .toList();

    final forecastInformationElements =
        document.findAllElements('ForecastInformation');
    List<TyphoonPosition> forecast = forecastInformationElements
        .map(parseEntry)
        .whereType<TyphoonPosition>()
        .toList();
    forecast.sort((a, b) {
      return a.index.compareTo(b.index);
    });
    // oldest first
    past.sort((a, b) {
      return a.index.compareTo(b.index);
    });
    past.add(currentAnalysis); // add latest for easy reference
    return TyphoonTrack(bulletin, currentAnalysis, past, forecast);
  } catch (e) {
    debugPrint(xmlString.replaceAll('\n', ''));
    debugPrint("Failed to parse typhoon track data $e");
    return null;
  }
}

String removeNonNumeric(String entry) {
  return entry.replaceAll(RegExp(r"[^\d.]"), "");
}

TyphoonPosition? parseEntry(XmlElement element) {
  try {
    TyphoonPosition entry = TyphoonPosition();
    for (var child in element.childElements) {
      if (child.name.local == 'Intensity') {
        entry.intensity = child.text;
      } else if (child.name.local == 'Latitude') {
        entry.latitude =
            double.tryParse(removeNonNumeric(child.text)) ?? double.nan;
      } else if (child.name.local == 'Longitude') {
        entry.longitude =
            double.tryParse(removeNonNumeric(child.text)) ?? double.nan;
      } else if (child.name.local == 'Time') {
        entry.time = DateTime.parse(child.text);
      } else if (child.name.local == 'MaximumWind') {
        entry.maximumWind =
            double.tryParse(removeNonNumeric(child.text)) ?? double.nan;
      } else if (child.name.local == 'Index') {
        entry.index = int.tryParse(removeNonNumeric(child.text)) ?? 0;
      }
    }
    return entry;
  } catch (e) {
    debugPrint("Failed to parse typhoon position data $e");
    return null;
  }
}
