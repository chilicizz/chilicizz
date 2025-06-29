import 'dart:convert';

import 'package:flutter/material.dart';

class AQILocation {
  final String name;
  final String url;

  AQILocation(this.name, this.url);

  @override
  String toString() {
    return name;
  }
}

class AQIData {
  final String cityName;
  final DateTime lastUpdatedTime;
  final int aqi;
  final Map<IAQIRecord, double> iaqiData;
  final List<Attribution> attributions;
  final Map<IAQIRecord, List<ForecastEntry>> iaqiForecast;
  final AQILevel level;

  AQIData(this.cityName, this.lastUpdatedTime, this.aqi, this.iaqiData, this.attributions,
      this.iaqiForecast, this.level);

  factory AQIData.fromJSON(dynamic jsonResult) {
    String cityName = jsonResult?["city"]?["name"];
    Map<IAQIRecord, double> iaqiData = {};
    List<Attribution> attributions = [];
    Map<IAQIRecord, List<ForecastEntry>> iaqiForecast = {};
    int aqi = (double.tryParse("${jsonResult["aqi"]}") ?? -1).floor();
    DateTime lastUpdatedTime =
        DateTime.tryParse("${jsonResult?["time"]?["iso"]}") ?? DateTime.now();
    for (dynamic attribution in jsonResult?["attributions"]) {
      attributions.add(Attribution("${attribution?["name"]}", "${attribution?["url"]}"));
    }
    for (IAQIRecord entry in iqiEntries) {
      if (jsonResult?["iaqi"]?[entry.code]?["v"] != null) {
        iaqiData[entry] = jsonResult?["iaqi"]?[entry.code]?["v"];
      }
    }
    for (IAQIRecord entry in iqiEntries) {
      if (jsonResult?["forecast"]?["daily"]?[entry.code] != null) {
        var cutoff = DateTime.now().subtract(const Duration(days: 1));
        List<ForecastEntry> forecast = [];
        for (dynamic forecastData in jsonResult?["forecast"]?["daily"]?[entry.code]) {
          try {
            ForecastEntry forecastEntryResult = ForecastEntry.fromJSON(forecastData);
            if (forecastEntryResult.date.isAfter(cutoff)) {
              forecast.add(forecastEntryResult);
            }
          } catch (e) {
            debugPrint("Error handling the forecast: $e");
          }
        }
        iaqiForecast[entry] = forecast;
      }
    }
    for (AQILevel thresholdLevel in aqiThresholds) {
      if (thresholdLevel.within(aqi)) {
        return AQIData(
            cityName, lastUpdatedTime, aqi, iaqiData, attributions, iaqiForecast, thresholdLevel);
      }
    }
    return AQIData(
        cityName, lastUpdatedTime, aqi, iaqiData, attributions, iaqiForecast, aqiThresholds.last);
  }

  // Remove the parenthesis
  String getShortCityName() {
    return cityName.replaceAll(RegExp('\\(.*?\\)'), '');
  }
}

class Attribution {
  final String name;
  final String url;

  Attribution(this.name, this.url);
}

class AQILevel {
  final Color color;
  final String name;
  final String detail;
  final String? advice;
  final int upperThreshold;

  const AQILevel(this.color, this.name, this.detail, this.advice, this.upperThreshold);

  bool within(int value) {
    return value <= upperThreshold;
  }

  String longDescription() {
    return detail + (advice != null ? "\n$advice" : '');
  }
}

class IAQIRecord {
  final String code;
  final String label;
  final String? unit;
  final IconData? iconData;
  final Color Function(double)? colourFunction;

  IAQIRecord(this.code, this.label, {this.unit, this.iconData, this.colourFunction});

  Widget getIcon() {
    return iconData != null ? Icon(iconData) : Text(code);
  }

  Color getColour(double value) {
    return (colourFunction != null ? colourFunction!(value) : Colors.blueAccent);
  }
}

class ForecastEntry {
  final int average;
  final int min;
  final int max;
  final DateTime date;

  ForecastEntry({required this.average, required this.min, required this.max, required this.date});

  factory ForecastEntry.fromJSON(dynamic forecastData) {
    DateTime day = DateTime.parse("${forecastData["day"]}");
    return ForecastEntry(
        average: forecastData["avg"],
        min: forecastData["min"],
        max: forecastData["max"],
        date: day);
  }

  @override
  String toString() {
    return 'ForecastEntry{average: $average, min: $min, max: $max, date: $date}';
  }
}

const aqiThresholds = [
  AQILevel(Colors.grey, "Unavailable",
      "Air Quality data is unavailable for this location at this time.", null, -1),
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
      Colors.brown,
      "Hazardous",
      "Health alert: everyone may experience more serious health effects",
      "Everyone should avoid all outdoor exertion",
      0x7fffffff), // 32 bit max
];

List<IAQIRecord> iqiEntries = [
  IAQIRecord("t", "Temperature", unit: "°C", iconData: Icons.thermostat, colourFunction: (value) {
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
  IAQIRecord("uvi", "UV index", iconData: Icons.wb_sunny, colourFunction: (value) {
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

List<AQILocation> parseLocationSearchResponse(dynamic json) {
  var aqiFeed = jsonDecode(json);
  if (aqiFeed?["status"]?.contains("ok")) {
    List<AQILocation> list = [];
    dynamic jsonResult = aqiFeed?["data"];
    for (dynamic entry in jsonResult) {
      // entry["aqi"];
      list.add(
        AQILocation(entry["station"]?["name"], entry["station"]?["url"]),
      );
    }
    list.sort((a, b) => a.url.compareTo(b.url));
    return list;
  }
  debugPrint("Failed to fetch data");
  return [];
}

class AQIChip extends StatelessWidget {
  const AQIChip({
    super.key,
    required this.record,
    required this.value,
  });

  final IAQIRecord record;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: record.label,
      child: Chip(
        avatar: CircleAvatar(
          backgroundColor: record.getColour(value),
          foregroundColor: Colors.white.withAlpha(200),
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: FittedBox(
              child: record.getIcon(),
            ),
          ),
        ),
        label: Text(
          "${value.toStringAsFixed(value > 50 ? 0 : 1)} ${record.unit ?? ''}",
        ),
      ),
    );
  }
}
