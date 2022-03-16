import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

const String infoUrl =
    "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warningInfo&lang=en";
const String typhoonUrl =
    "https://www.weather.gov.hk/wxinfo/currwx/tc_list.xml";

class WarningInformation {
  String warningStatementCode;
  String? subType;
  List<String> contents;
  DateTime updateTime;

  WarningInformation(this.warningStatementCode, this.subType, this.contents, this.updateTime);

  String getDescription() {
    return warningStringMap[subType ?? warningStatementCode] ??
        subType ??
        warningStatementCode;
  }

  CircleAvatar getCircleAvatar() {
    return warningIconMap[subType ?? warningStatementCode] ??
        CircleAvatar(
            child: FittedBox(child: Text(subType ?? warningStatementCode)));
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
  "T8NE": "No.8 North East Gale or Storm",
  "T8SE": "No.8 South East Gale or Storm",
  "T8SW": "No.8 South West Gale or Storm",
  "T8NW": "No.8 North West Gale or Storm",
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
      child: Icon(Icons.local_fire_department, color: Colors.black),
      backgroundColor: Colors.yellow),
  "WFIRER": CircleAvatar(
      child: Icon(Icons.local_fire_department, color: Colors.black),
      backgroundColor: Colors.red),
  "WRAINA": CircleAvatar(child: Text('🌧'), backgroundColor: Colors.amber),
  "WRAINR": CircleAvatar(child: Text('🌧'), backgroundColor: Colors.red),
  "WRAINB": CircleAvatar(child: Text('🌧'), backgroundColor: Colors.black),
  "TC1": CircleAvatar(child: Text("T1"), backgroundColor: Colors.amber),
  "TC3": CircleAvatar(child: Text("T3"), backgroundColor: Colors.amber),
  "T8NE": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
  "T8SE": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
  "T8SW": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
  "T8NW": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
  "TC9": CircleAvatar(child: Text("T9"), backgroundColor: Colors.amber),
  "TC10": CircleAvatar(child: Text("T10"), backgroundColor: Colors.amber),

  "WFROST": CircleAvatar(
      child: Icon(Icons.ac_unit, color: Colors.white),
      backgroundColor: Colors.blue),
  "WHOT": CircleAvatar(
      child: Icon(Icons.thermostat, color: Colors.red),
      backgroundColor: Colors.white54),
  "WCOLD": CircleAvatar(
      child: Icon(Icons.thermostat, color: Colors.blue),
      backgroundColor: Colors.white54),
  "WMSGNL": CircleAvatar(
      child: Icon(Icons.air, color: Colors.white),
      backgroundColor: Colors.blue),
  "WFNTSA": CircleAvatar(
      child: Icon(Icons.water, color: Colors.green),
      backgroundColor: Colors.white54),
  "WL": CircleAvatar(
      child: Icon(Icons.report_problem, color: Colors.yellow),
      backgroundColor: Colors.brown),
  "WTMW": CircleAvatar(child: Text("🌊"), backgroundColor: Colors.amber),
  "WTS": CircleAvatar(
      child: Icon(Icons.bolt, color: Colors.yellow),
      backgroundColor: Colors.black),
};

Future<List<Typhoon>> fetchTyphoonFeed() async {
  try {
    var path = Uri.parse(typhoonUrl);
    var response = await http.get(path, headers: {
      HttpHeaders.contentTypeHeader: 'application/xml',
      HttpHeaders.accessControlAllowOriginHeader: '*',
      HttpHeaders.accessControlAllowHeadersHeader: '*',
      HttpHeaders.accessControlAllowMethodsHeader: "POST,GET,DELETE,PUT,OPTIONS"
    });
    if (response.statusCode == 200) {
      var typhoonFeed = parseTyphoonFeed(response.body);
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
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var typhoonTrack = parseTyphoonTrack(response.body);
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
  TyphoonPosition current;

  TyphoonTrack(this.bulletin, this.current, this.past);
}

class TyphoonPosition {
  late String intensity;
  late double? maximumWind; // km/h
  late DateTime? time; // if no time then interpolated position
  late double latitude; // N
  late double longitude; // E

  TyphoonPosition();
}

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
        url: element.findElements("TropicalCycloneURL").single.text,
      );
    }).toList();
  } catch (e) {
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
    return TyphoonTrack(bulletin, currentAnalysis, past);
  } catch (e) {
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
      }
    }
    return entry;
  } catch (e) {
    debugPrint("Failed to parse typhoon position data $e");
    return null;
  }
}
