import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'common.dart';
import 'hko_types.dart';

const String infoUrl =
    "https://data.weather.gov.hk/weatherAPI/opendata/weather.php?dataType=warningInfo&lang=en";
const String typhoonUrl =
    "https://www.weather.gov.hk/wxinfo/currwx/tc_list.xml";

class HKO extends StatefulWidget {
  const HKO({Key? key}) : super(key: key);

  @override
  State<HKO> createState() => _HKOState();
}

class _HKOState extends State<HKO> {
  static const Duration tickInterval = Duration(minutes: 10);

  late Timer timer;
  late List<WarningInformation> warnings;

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
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      warnings.addAll(warningStringMap.keys
                          .map((key) => WarningInformation(
                              key, null, ["Dummy description"], DateTime.now()))
                          .toList());
                    });
                  },
                  child: buildLastTick(lastTick)),
            ),
          )
        ],
      ),
      drawer: const NavigationDrawer(),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
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
                  CircleAvatar icon = warning.getCircleAvatar();
                  return ExpansionTile(
                    leading: icon,
                    title: Text(warning.getDescription()),
                    subtitle: buildIssued(warning.updateTime),
                    initiallyExpanded: !isSmallDevice(),
                    children: [
                      for (var s in warning.contents)
                        ListTile(
                          title: Text(s),
                        )
                    ],
                  );
                },
              )
            : ListView(
                children: [
                  ListTile(
                      title: const Text("No active warnings"),
                      subtitle: buildLastTick(lastTick))
                ],
              ),
      ),
    );
  }
}
