import 'package:flutter/material.dart';

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
            child: FittedBox(child: Text(subType ?? warningStatementCode)));
  }
}

List<WarningInformation> extractWarnings(dynamic json) {
  List<WarningInformation> result = [];
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
  "WRAINA": CircleAvatar(
      child: Text('🌧'),
      backgroundColor: Colors.amber),
  "WRAINR": CircleAvatar(
      child: Text('🌧'),
      backgroundColor: Colors.red),
  "WRAINB": CircleAvatar(
      child: Text('🌧'),
      backgroundColor: Colors.black),
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