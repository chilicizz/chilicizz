import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:date_format/date_format.dart';

const AQIThresholds = [
  AQILevel(Colors.lightGreen, "Good",
      "Air quality is considered satisfactory and air pollution poses little or no risk.",
      "Enjoy the outdoors.", 50),
  AQILevel(Colors.yellow, "Moderate",
      "Air quality is acceptable; however, for some pollutants there may be a moderate health concern for a very small number of people who are unusually sensitive to air pollution.",
      "Active children and adults, and people with respiratory disease, such as asthma, should limit prolonged outdoor exertion.",
      100),
  AQILevel(Colors.orange, "Unhealthy for Sensitive Groups",
      "Members of sensitive groups may experience health effects. The general public is not likely to be affected.",
      "Active children and adults, and people with respiratory disease, such as asthma, should limit prolonged outdoor exertion.",
      150),
  AQILevel(Colors.red, "Unhealthy",
      "Everyone may begin to experience health effects; members of sensitive groups may experience more serious health effects",
      "Active children and adults, and people with respiratory disease, such as asthma, should avoid prolonged outdoor exertion; everyone else, especially children, should limit prolonged outdoor exertion",
      200),
  AQILevel(Colors.deepPurple, "Very Unhealthy",
      "Health warnings of emergency conditions. The entire population is more likely to be affected.",
      "Active children and adults, and people with respiratory disease, such as asthma, should avoid all outdoor exertion; everyone else, especially children, should limit outdoor exertion.",
      300),
  AQILevel(Colors.black, "Hazardous",
      "Health alert: everyone may experience more serious health effects",
      "Everyone should avoid all outdoor exertion", 0x7fffffff), // 32 bit max
];

AQILevel getLevel(int value) {
  for (final level in AQIThresholds) {
    if (level.within(value)) {
      return level;
    }
  }
  return AQIThresholds.last;
}

class AQI extends StatefulWidget {
  String location;

  AQI({Key? key, required this.location}) : super(key: key);

  @override
  State<AQI> createState() => _AQIState();

  void _updateLocation(String location) {
    this.location = location;
  }
}

class _AQIState extends State<AQI> {
  final String token = const String.fromEnvironment('AQI_TOKEN');
  final Duration tickTime = const Duration(minutes: 10);
  Timer? timer;

  var textController = TextEditingController();
  bool editingLocation = false;

  dynamic jsonResult;
  DateTime lastUpdateTime = DateTime.now();
  int aqi = 0;

  @override
  Widget build(BuildContext context) {
    level = getLevel(aqi);

    return Card(
        elevation: 3,
        margin: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            editingLocation
                ? ListTile(
              title: TextField(
                autofocus: true,
                controller: textController,
                onEditingComplete: () {
                  setState(() {
                    widget._updateLocation(textController.value.text);
                    _tick(null);
                    editingLocation = false;
                  });
                },
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget._updateLocation(textController.value.text);
                    _tick(null);
                    editingLocation = false;
                  });
                },
                child: const Icon(Icons.check),
              ),
            )
                : ListTile(
              leading: Tooltip(
                message: level.name,
                child: CircleAvatar(
                  child: Text("$aqi"),
                  backgroundColor: level.color,
                ),
              ),
              title: Text("${jsonResult?["city"]?["name"]}",
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall),
              subtitle: Text(
                  "last updated ${formatDate(lastUpdateTime.toLocal(), [
                    D,
                    " ",
                    H,
                    ":",
                    nn
                  ])}"),
              onTap: () =>
              {
                setState(() {
                  editingLocation = true;
                  textController.text = widget.location;
                  textController.selection = TextSelection(
                      baseOffset: 0, extentOffset: textController.text.length);
                })
              },
            ),
            const Divider(),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: const Icon(Icons.thermostat),
                  label: Text("${jsonResult?["iaqi"]?["t"]?["v"]} °C"),
                ),
                Chip(
                  avatar: const Icon(Icons.water_drop),
                  label: Text("${jsonResult?["iaqi"]?["h"]?["v"]} %"),
                ),
                Chip(
                  avatar: const Icon(Icons.air),
                  label: Text("${jsonResult?["iaqi"]?["w"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("bar"),
                  label: Text("${jsonResult?["iaqi"]?["p"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("uvi"),
                  label: Text("${jsonResult?["iaqi"]?["uvi"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("pm2.5", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["pm25"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("pm10", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["pm10"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("no2", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["no2"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("o3", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["o3"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("so2", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["so2"]?["v"]}"),
                ),
              ],
            ),
            ExpansionTile(
              leading: Text("$aqi"),
              title: Text(level.name),
              children: [
                ListTile(
                    title: Text(level.detail)
                ),
                ListTile(
                    title: Text(level.advice)
                ),
                Tooltip(
                  message: "${jsonResult?["attributions"]?[0]?["url"]}",
                  child: ListTile(
                    title: Text("${jsonResult?["attributions"]?[0]?["name"]}"),
                  ),
                )
              ],
            ),
          ],
        ));
  }

  AQILevel level = getLevel(0);

  @override
  void initState() {
    super.initState();
    _tick(timer);
    timer = Timer.periodic(tickTime, (Timer t) => _tick(t));
  }

  Future<void> _tick(Timer? t) async {
    var response = await _fetchData();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var aqiFeed = jsonDecode(response.body);
      if (aqiFeed?["status"]?.contains("ok")) {
        setState(() {
          jsonResult = aqiFeed?["data"];
          aqi = double.parse("${aqiFeed?["data"]?["aqi"]}").floor();
          lastUpdateTime =
              DateTime.parse("${aqiFeed?["data"]?["time"]?["iso"]}");
        });
      } else {
        debugPrint("Failed to fetch data");
      }
    }
  }

  Future<http.Response> _fetchData() {
    return http.get(Uri.parse(
        'https://api.waqi.info/feed/${widget.location}/?token=$token'));
  }
}

class AQILevel {
  final Color color;
  final String name;
  final String detail;
  final String advice;
  final int upperThreshold;

  const AQILevel(this.color, this.name, this.detail, this.advice,
      this.upperThreshold);

  bool within(int value) {
    return value <= upperThreshold;
  }
}
