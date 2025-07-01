import 'dart:convert';
import 'dart:io';

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
}

class TyphoonPosition {
  final int index;
  final String? intensity;
  final double? maximumWind; // km/h
  final DateTime? time; // if no time then interpolated position
  final double latitude; // N
  final double longitude; // E
  final TyphoonClass typhoonClass;

  TyphoonPosition(
    this.index,
    this.intensity,
    this.maximumWind,
    this.time,
    this.latitude,
    this.longitude,
    this.typhoonClass,
  );

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
    for (var referenceClass in typhoonClasses) {
      double speed = maximumWind ?? -1;
      if (referenceClass.within(speed)) {
        typhoonClass = referenceClass;
      }
    }
    if (latitude.isNaN || longitude.isNaN) {
      throw Exception("Failed to parse position $element");
    }
    return TyphoonPosition(index, intensity, maximumWind, time, latitude, longitude, typhoonClass);
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
