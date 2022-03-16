import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const String token = String.fromEnvironment('AQI_TOKEN');

AQIData marshalJSON(dynamic jsonResult) {
  num aqi = double.tryParse("${jsonResult["aqi"]}") ?? -1;
  DateTime feedUpdate =
      DateTime.tryParse("${jsonResult?["time"]?["iso"]}") ?? DateTime.now();
  AQIData data =
      AQIData(jsonResult?["city"]?["name"], (aqi).floor(), feedUpdate);
  for (dynamic attribution in jsonResult?["attributions"]) {
    data.attributions
        .add(Attribution("${attribution?["name"]}", "${attribution?["url"]}"));
  }
  for (IAQIRecord entry in iqiEntries) {
    if (jsonResult?["iaqi"]?[entry.code]?["v"] != null) {
      data.iaqiData[entry] = jsonResult?["iaqi"]?[entry.code]?["v"];
    }
  }
  return data;
}

class AQILocation {
  final String name;
  final String url;

  AQILocation(this.name, this.url);

  @override
  String toString() {
    return name;
  }
}

Future<http.Response> locationQueryHttp(location) {
  return http.get(Uri.parse(
      'https://api.waqi.info/search/?keyword=$location&token=$token'));
}

Future<List<AQILocation>> locationQuery(String location) async {
  var response = await locationQueryHttp(location.replaceAll('/', ''));
  if (response.statusCode == 200) {
    var aqiFeed = jsonDecode(response.body);
    if (aqiFeed?["status"]?.contains("ok")) {
      List<AQILocation> list = [];
      dynamic jsonResult = aqiFeed?["data"];
      for (dynamic entry in jsonResult) {
        // entry["aqi"];
        list.add(
            AQILocation(entry["station"]?["name"], entry["station"]?["url"]));
      }
      list.sort((a, b) => a.url.compareTo(b.url));
      return list;
    } else {
      debugPrint("Failed to fetch data $location");
      return [];
    }
  } else {
    debugPrint("Failed to fetch data $location");
    return [];
  }
}

Future<AQIData?> fetchAQIData(String location) async {
  try {
    var response = await http
        .get(Uri.parse('https://api.waqi.info/feed/$location/?token=$token'));
    if (response.statusCode == 200) {
      var aqiFeed = jsonDecode(response.body);
      if (aqiFeed?["status"]?.contains("ok")) {
        return marshalJSON(aqiFeed?["data"]);
      } else {
        debugPrint("AQI Feed returned error $location ${response.body}");
      }
    }
  } catch (e) {
    debugPrint("Failed to fetch data $location $e");
  }
  return null;
}

class AQIData {
  String cityName;
  DateTime lastUpdatedTime;
  int aqi;
  Map<IAQIRecord, double> iaqiData = {};
  List<Attribution> attributions = [];

  AQIData(this.cityName, this.aqi, this.lastUpdatedTime);

  AQILevel getLevel() {
    for (final level in AQIThresholds) {
      if (level.within(aqi)) {
        return level;
      }
    }
    return AQIThresholds.last;
  }

  // Remove the parenthesis
  String getShortCityName() {
    return cityName.replaceAll(RegExp('\\(.*?\\)'), '');
  }
}

class Attribution {
  String name;
  String url;

  Attribution(this.name, this.url);
}

class AQILevel {
  final Color color;
  final String name;
  final String detail;
  final String? advice;
  final int upperThreshold;

  const AQILevel(
      this.color, this.name, this.detail, this.advice, this.upperThreshold);

  bool within(int value) {
    return value <= upperThreshold;
  }

  String longDescription() {
    return detail + (advice != null ? "\n$advice" : '');
  }
}

class IAQIRecord {
  String code;
  String label;
  String? unit;
  IconData? iconData;
  Color Function(double)? colourFunction;

  IAQIRecord(this.code, this.label,
      {this.unit, this.iconData, this.colourFunction});

  Widget getIcon() {
    return iconData != null ? Icon(iconData) : Text(code);
  }

  Color getColour(double value) {
    return (colourFunction != null
        ? colourFunction!(value)
        : Colors.blueAccent);
  }
}

const AQIThresholds = [
  AQILevel(
      Colors.grey,
      "Unavailable",
      "Air Quality data is unavailable for this location at this time.",
      null,
      -1),
  AQILevel(
      Colors.lightGreen,
      "Good",
      "Air quality is considered satisfactory and air pollution poses little or no risk.",
      null,
      50),
  AQILevel(
      Colors.yellow,
      "Moderate",
      "Air quality is acceptable; however, for some pollutants there may be a moderate health concern for a very small number of people who are unusually sensitive to air pollution.",
      "Active children and adults, and people with respiratory disease, such as asthma, should limit prolonged outdoor exertion.",
      100),
  AQILevel(
      Colors.orange,
      "Unhealthy for Sensitive Groups",
      "Members of sensitive groups may experience health effects. The general public is not likely to be affected.",
      "Active children and adults, and people with respiratory disease, such as asthma, should limit prolonged outdoor exertion.",
      150),
  AQILevel(
      Colors.red,
      "Unhealthy",
      "Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects",
      "Active children and adults, and people with respiratory disease, such as asthma, should avoid prolonged outdoor exertion; everyone else, especially children, should limit prolonged outdoor exertion",
      200),
  AQILevel(
      Colors.deepPurple,
      "Very Unhealthy",
      "Health warnings of emergency conditions. The entire population is more likely to be affected.",
      "Active children and adults, and people with respiratory disease, such as asthma, should avoid all outdoor exertion; everyone else, especially children, should limit outdoor exertion.",
      300),
  AQILevel(
      Colors.black,
      "Hazardous",
      "Health alert: everyone may experience more serious health effects",
      "Everyone should avoid all outdoor exertion",
      0x7fffffff), // 32 bit max
];

List<IAQIRecord> iqiEntries = [
  IAQIRecord("t", "Temperature", unit: "°C", iconData: Icons.thermostat,
      colourFunction: (value) {
        Color? bgColour;
    if (value < 27) {
      bgColour = Color.lerp(Colors.lightBlue, Colors.yellow, value / 27);
    } else if (value < 40) {
      bgColour = Color.lerp(Colors.yellow, Colors.red, (value - 27) / 15);
    } else {
      bgColour = Colors.red;
    }
    return bgColour ?? Colors.grey.shade800;
  }),
  IAQIRecord("h", "Humidity", unit: "%", iconData: Icons.water_drop),
  IAQIRecord("w", "Wind Speed", unit: "m/s", iconData: Icons.air),
  IAQIRecord("p", "Pressure", unit: "bar", iconData: Icons.storm),
  IAQIRecord("uvi", "UV index", iconData: Icons.wb_sunny,
      colourFunction: (value) {
    Color? bgColour;
    if (value < 5) {
      bgColour = Color.lerp(Colors.green, Colors.amber, value / 5);
    } else if (value < 11) {
      bgColour = Color.lerp(Colors.amber, Colors.red, (value - 5) / 6);
    } else {
      bgColour = Colors.deepPurple;
    }
    return bgColour ?? Colors.blueAccent;
  }),
  IAQIRecord("pm25", "PM 2.5"),
  IAQIRecord("pm10", "PM 10"),
  IAQIRecord("no2", "Nitrogen dioxide"),
  IAQIRecord("o3", "Ozone"),
  IAQIRecord("so2", "Sulphur dioxide"),
];
