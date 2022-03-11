import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'common.dart';

class HKO extends StatefulWidget {
  const HKO({Key? key}) : super(key: key);

  @override
  State<HKO> createState() => _HKOState();
}

class _HKOState extends State<HKO> {
  static const String infoUrl =
      "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warningInfo&lang=en";
  static const Duration tickInterval = Duration(minutes: 10);

  static const Map<String, String> warningStringMap = {
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

  static const Map<String, CircleAvatar> warningIconMap = {
    // Fetch icons from https://www.hko.gov.hk/textonly/v2/explain/intro.htm
    "WFIREY": CircleAvatar(
        child: Icon(Icons.local_fire_department, color: Colors.black),
        backgroundColor: Colors.yellow),
    "WFIRER": CircleAvatar(
        child: Icon(Icons.local_fire_department, color: Colors.black),
        backgroundColor: Colors.red),
    "WRAINA": CircleAvatar(
        child: Icon(Icons.water, color: Colors.black),
        backgroundColor: Colors.amber),
    "WRAINR": CircleAvatar(
        child: Icon(Icons.water, color: Colors.black),
        backgroundColor: Colors.red),
    "WRAINB": CircleAvatar(
        child: Icon(Icons.water, color: Colors.black),
        backgroundColor: Colors.black),
    "TC1": CircleAvatar(child: Text("T1"), backgroundColor: Colors.amber),
    "TC3": CircleAvatar(child: Text("T3"), backgroundColor: Colors.amber),
    "T8NE": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
    "T8SE": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
    "T8SW": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
    "T8NW": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
    "TC9": CircleAvatar(child: Text("T8"), backgroundColor: Colors.amber),
    "TC10": CircleAvatar(child: Text("T10"), backgroundColor: Colors.amber),

    "WFROST": CircleAvatar(child: Icon(Icons.ac_unit, color: Colors.white), backgroundColor: Colors.blue),
    "WHOT": CircleAvatar(child: Icon(Icons.wb_sunny, color: Colors.red), backgroundColor: Colors.amber),
    "WCOLD": CircleAvatar(child: Icon(Icons.ac_unit, color: Colors.blue), backgroundColor: Colors.amber),
    "WMSGNL":
        CircleAvatar(child: Icon(Icons.air, color: Colors.black), backgroundColor: Colors.amber),
    "WFNTSA":
        CircleAvatar(child: Icon(Icons.water, color: Colors.black), backgroundColor: Colors.amber),
    "WL": CircleAvatar(child: Icon(Icons.report_problem, color: Colors.black), backgroundColor: Colors.amber),
    "WTMW": CircleAvatar(child: Text("🌊"), backgroundColor: Colors.amber),
    "WTS": CircleAvatar(child: Icon(Icons.bolt, color: Colors.black), backgroundColor: Colors.amber),
  };

  late Timer timer;
  late List<WarningInformation> warnings;

  dynamic jsonResult;
  DateTime lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    warnings = [];
    timer = Timer.periodic(tickInterval, (Timer t) => _tick(t: t));
    _tick();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _tick({Timer? t}) async {
    try {
      var response = await _fetchData();
      if (response.statusCode == 200) {
        var hkoFeed = jsonDecode(response.body);
        setState(() {
          jsonResult = hkoFeed;
          warnings = extractWarnings(hkoFeed);
          lastTick = DateTime.now();
        });
      }
    } catch (e) {
      debugPrint("Failed to fetch data $e");
    }
  }

  Future<http.Response> _fetchData() {
    return http.get(Uri.parse(infoUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HKO Warnings'),
      ),
      drawer: const NavigationDrawer(),
      floatingActionButton: ElevatedButton(
        child: buildLastTick(lastTick),
        onPressed: () {
          _tick();
        },
      ),
      body: Center(
          child: warnings.isNotEmpty
              ? ListView.builder(
                  itemCount: warnings.length,
                  itemBuilder: (BuildContext context, int index) {
                    var warning = warnings[index];
                    CircleAvatar icon = warningIconMap[
                            warning.subType ?? warning.warningStatementCode] ??
                        CircleAvatar(
                            child: FittedBox(
                                child: Text(warning.subType ??
                                    warning.warningStatementCode)));
                    return ExpansionTile(
                      leading: icon,
                      title: Text(warningStringMap[warning.subType ??
                              warning.warningStatementCode] ??
                          warning.subType ??
                          warning.warningStatementCode),
                      subtitle: buildIssued(warning.updateTime),
                      initiallyExpanded: true,
                      children: [
                        for (var s in warning.contents)
                          ListTile(
                            title: Text(s),
                          )
                      ],
                    );
                  },
                )
              : ListTile(
                  title: const Text("No active warnings"),
                  subtitle: buildLastTick(lastTick))),
    );
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

class WarningInformation {
  String warningStatementCode;
  String? subType;
  List<String> contents;
  DateTime updateTime;

  WarningInformation(
      this.warningStatementCode, this.subType, this.contents, this.updateTime);
}
