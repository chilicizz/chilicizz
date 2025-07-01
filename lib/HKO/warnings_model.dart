import 'package:flutter/material.dart';

// https://www.hko.gov.hk/en/abouthko/opendata_intro.htm
// https://data.weather.gov.hk/weatherAPI/doc/HKO_Open_Data_API_Documentation.pdf
class WarningInformation {
  final String warningStatementCode;
  final String? subType;
  final List<String> contents;
  final DateTime updateTime;

  WarningInformation(
    this.warningStatementCode,
    this.subType,
    this.contents,
    this.updateTime,
  );

  factory WarningInformation.fromJSON(dynamic entry) {
    String warningStatementCode = entry?["warningStatementCode"];
    String? subType = entry?["subtype"];
    var updateTime = DateTime.parse("${entry?["updateTime"]}");
    List<String> contents = [for (var i in entry?["contents"]) '$i'];
    return WarningInformation(
      warningStatementCode,
      subType,
      contents,
      updateTime,
    );
  }

  String getDescription() {
    return warningStringMap[subType ?? warningStatementCode] ?? subType ?? warningStatementCode;
  }

  CircleAvatar getCircleAvatar() {
    return warningIconMap[subType ?? warningStatementCode] ??
        CircleAvatar(
          child: FittedBox(
            child: Text(
              subType ?? warningStatementCode,
            ),
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
      result.add(
        WarningInformation.fromJSON(entry),
      );
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
  "WTCSGNL": "Tropical Cyclone Signals Cancelled",
  "CANCEL": "All Signals Cancelled",
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
      backgroundColor: Colors.red, child: Icon(Icons.local_fire_department, color: Colors.black)),
  "WRAINA": CircleAvatar(backgroundColor: Colors.amber, child: Text('🌧')),
  "WRAINR": CircleAvatar(backgroundColor: Colors.red, child: Text('🌧')),
  "WRAINB": CircleAvatar(backgroundColor: Colors.black, child: Text('🌧')),
  "TC1": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T1", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC3": CircleAvatar(
      backgroundColor: Colors.amberAccent,
      child: Text("T3", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "WTCPRE8": CircleAvatar(
      backgroundColor: Colors.amberAccent, child: Icon(Icons.alarm, color: Colors.black)),
  "TC8NE": CircleAvatar(
      backgroundColor: Colors.amber,
      child: Text("T8", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8SE": CircleAvatar(
      backgroundColor: Colors.amber,
      child: Text("T8", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8SW": CircleAvatar(
      backgroundColor: Colors.amber,
      child: Text("T8", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC8NW": CircleAvatar(
      backgroundColor: Colors.amber,
      child: Text("T8", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC9": CircleAvatar(
      backgroundColor: Colors.orange,
      child: Text("T9", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "TC10": CircleAvatar(
      backgroundColor: Colors.redAccent,
      child: Text("T10", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
  "WTCSGNL": CircleAvatar(
      backgroundColor: Colors.white, child: Icon(Icons.check_circle_outline, color: Colors.green)),
  "CANCEL": CircleAvatar(
      backgroundColor: Colors.white, child: Icon(Icons.check_circle_outline, color: Colors.green)),
  "WFROST":
      CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.ac_unit, color: Colors.white)),
  "WHOT": CircleAvatar(
      backgroundColor: Colors.amberAccent, child: Icon(Icons.thermostat, color: Colors.red)),
  "WCOLD": CircleAvatar(
      backgroundColor: Colors.amberAccent, child: Icon(Icons.thermostat, color: Colors.blue)),
  "WMSGNL": CircleAvatar(backgroundColor: Colors.cyan, child: Icon(Icons.air, color: Colors.white)),
  "WFNTSA":
      CircleAvatar(backgroundColor: Colors.cyan, child: Icon(Icons.water, color: Colors.lime)),
  "WL": CircleAvatar(
      backgroundColor: Colors.brown, child: Icon(Icons.report_problem, color: Colors.yellow)),
  "WTMW": CircleAvatar(backgroundColor: Colors.amberAccent, child: Text("🌊")),
  "WTS": CircleAvatar(backgroundColor: Colors.black, child: Icon(Icons.bolt, color: Colors.yellow)),
};

List<WarningInformation> dummyWarnings() {
  List<WarningInformation> warnings = [];
  warnings.addAll(
    warningStringMap.keys
        .map(
          (key) => WarningInformation(
            key,
            null,
            ["This is an example warning"],
            DateTime.now(),
          ),
        )
        .toList(),
  );
  return warnings;
}
