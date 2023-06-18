import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:xml/xml.dart';

// https://www.hko.gov.hk/en/abouthko/opendata_intro.htm
// https://data.weather.gov.hk/weatherAPI/doc/HKO_Open_Data_API_Documentation.pdf
class WarningInformation {
  final String warningStatementCode;
  final String? subType;
  final List<String> contents;
  final DateTime updateTime;

  WarningInformation(
      this.warningStatementCode, this.subType, this.contents, this.updateTime);

  factory WarningInformation.fromJSON(dynamic entry) {
    String warningStatementCode = entry?["warningStatementCode"];
    String? subType = entry?["subtype"];
    var updateTime = DateTime.parse("${entry?["updateTime"]}");
    List<String> contents = [for (var i in entry?["contents"]) '$i'];
    return WarningInformation(
        warningStatementCode, subType, contents, updateTime);
  }

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
      result.add(WarningInformation.fromJSON(entry));
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
  "WTCPRE8": "Pre-8 Tropical Cyclone Special Announcement",
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
  "WTCPRE8": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Icon(Icons.alarm, color: Colors.black)),
  "TC8NE": CircleAvatar(
      backgroundColor: Colors.amber,
      child: Text("T8",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8SE": CircleAvatar(
      backgroundColor: Colors.amber,
      child: Text("T8",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8SW": CircleAvatar(
      backgroundColor: Colors.amber,
      child: Text("T8",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8NW": CircleAvatar(
      backgroundColor: Colors.amber,
      child: Text("T8",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC9": CircleAvatar(
      backgroundColor: Colors.orange,
      child: Text("T9",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC10": CircleAvatar(
      backgroundColor: Colors.redAccent,
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

class Typhoon {
  final int id;
  final String englishName;
  final String chineseName;
  final String url;

  Typhoon(
      {required this.id,
      required this.chineseName,
      required this.englishName,
      required this.url});

  Uri getTrackUrl() {
    Uri uri = Uri.parse(dotenv.env["corsProxy"]! + url);
    return uri;
  }

  Uri getTrackUrlId() {
    Uri uri = Uri.parse(dotenv.env["hkoTyphoonTrack"]! + id.toString());
    return uri;
  }

  Future<TyphoonTrack?> getTyphoonTrack() async {
    try {
      Uri uri = getTrackUrlId();
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
      Uri uri = getTrackUrl();
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

  TyphoonPosition(this.index, this.intensity, this.maximumWind, this.time,
      this.latitude, this.longitude, this.typhoonClass);

  factory TyphoonPosition.fromXMLElement(XmlElement element) {
    int index = 0;
    String? intensity;
    double? maximumWind; // km/h
    DateTime? time; // if no time then interpolated position
    double latitude = double.nan; // N
    double longitude = double.nan; // E
    TyphoonClass typhoonClass = unknownClass;
    for (var child in element.childElements) {
      try {
        if (child.name.local == 'Intensity') {
          intensity = child.value;
        } else if (child.name.local == 'Latitude') {
          latitude =
              double.tryParse(removeNonNumeric(child.value!)) ?? double.nan;
        } else if (child.name.local == 'Longitude') {
          longitude =
              double.tryParse(removeNonNumeric(child.value!)) ?? double.nan;
        } else if (child.name.local == 'Time') {
          time = DateTime.parse(child.value!);
        } else if (child.name.local == 'MaximumWind') {
          maximumWind =
              double.tryParse(removeNonNumeric(child.value!)) ?? double.nan;
        } else if (child.name.local == 'Index') {
          index = int.tryParse(removeNonNumeric(child.value!)) ?? 0;
        }
      } catch (e) {
        debugPrint("Error parsing $child");
      }
    }
    for (var referenceClass in typhoonClasses) {
      double speed = maximumWind ?? -1;
      if (referenceClass.within(speed)) {
        typhoonClass = referenceClass;
      }
    }
    if (latitude.isNaN || longitude.isNaN) {
      throw Exception("Failed to parse position $element");
    }
    return TyphoonPosition(
        index, intensity, maximumWind, time, latitude, longitude, typhoonClass);
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

  TyphoonClass(this.name, this.minWind, this.maxWind, this.color);

  bool within(double speed) {
    return speed >= minWind && speed < maxWind;
  }
}

TyphoonClass unknownClass = TyphoonClass("unknown", -1, -1, Colors.grey);

List<TyphoonClass> typhoonClasses = [
  TyphoonClass("Extratropical Low", 0, 41, Colors.blue),
  TyphoonClass("Tropical Depression", 41, 62, Colors.lightGreen),
  TyphoonClass("Tropical Storm", 62, 87, Colors.amber),
  TyphoonClass("Severe Tropical Storm", 87, 117, Colors.orange),
  TyphoonClass("Typhoon", 117, 149, Colors.red),
  TyphoonClass("Severe Typhoon", 149, 184, Colors.deepPurple),
  TyphoonClass("Super Typhoon", 184, double.maxFinite, Colors.black),
];

class TyphoonBulletin {
  final String name;
  final String provider;
  final DateTime time;

  TyphoonBulletin(this.name, this.provider, this.time);

  factory TyphoonBulletin.fromXmlElement(XmlElement bulletinElement) {
    String? name = "";
    String? provider = "";
    DateTime time = DateTime.now();
    for (var element in bulletinElement.childElements) {
      if (element.name.local == 'BulletinName') {
        name = element.value;
      } else if (element.name.local == 'BulletinProvider') {
        provider = element.value;
      } else if (element.name.local == 'BulletinTime') {
        time = DateTime.parse(element.value != null ? element.value! : "");
      }
    }
    return TyphoonBulletin(name!, provider!, time);
  }
}

List<Typhoon> parseTyphoonFeed(String xmlString) {
  try {
    final document = XmlDocument.parse(xmlString);
    final titles = document.findAllElements('TropicalCyclone');
    return titles.map((element) {
      return Typhoon(
        id: int.parse(element.findElements("TropicalCycloneID").single.value!),
        chineseName:
            element.findElements("TropicalCycloneChineseName").single.value!,
        englishName:
            element.findElements("TropicalCycloneEnglishName").single.value!,
        url: element
            .findElements("TropicalCycloneURL")
            .single
            .value
            .toString()
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

String removeNonNumeric(String entry) {
  return entry.replaceAll(RegExp(r"[^\d.]"), "");
}

TyphoonPosition? parseEntry(XmlElement element) {
  try {
    return TyphoonPosition.fromXMLElement(element);
  } catch (e) {
    debugPrint("Failed to parse typhoon position data $e");
    return null;
  }
}
