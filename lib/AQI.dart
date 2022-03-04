import 'dart:async';
import 'dart:convert';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const AQIThresholds = [
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

AQILevel getLevel(int value) {
  for (final level in AQIThresholds) {
    if (level.within(value)) {
      return level;
    }
  }
  return AQIThresholds.last;
}

class AQI extends StatefulWidget {
  final String location;
  final Function(String) removeLocationCallback;
  final Function(String, String) updateLocationCallback;

  AQI(
      {Key? key,
      required this.location,
      required this.removeLocationCallback,
      required this.updateLocationCallback})
      : super(key: key);

  @override
  State<AQI> createState() => _AQIState();

  void deleteMe() {
    removeLocationCallback(location);
  }

  void updateLocation(String newLocation) {
    if (newLocation != location) {
      updateLocationCallback(location, newLocation);
    }
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
    if (jsonResult == null) {
      textController.text = widget.location;
      _tick(null);
      return Card(
        child: Column(
          children: [
            ListTile(
              leading: Tooltip(
                message: "Delete this tile",
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    widget.deleteMe();
                  },
                ),
              ),
              title: TextField(
                autofocus: true,
                controller: textController,
                onEditingComplete: () {
                  setState(() {
                    widget.updateLocation(textController.value.text);
                    editingLocation = false;
                  });
                },
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.updateLocation(textController.value.text);
                    editingLocation = false;
                  });
                },
                child: const Icon(Icons.check),
              ),
            ),
            const Divider(),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }
    level = getLevel(aqi);

    return Card(
        semanticContainer: true,
        elevation: 3,
        margin: const EdgeInsets.all(7.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              editingLocation
                  ? ListTile(
                      leading: Tooltip(
                        message: "Delete this tile",
                        child: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            widget.deleteMe();
                          },
                        ),
                      ),
                      title: TextField(
                        autofocus: true,
                        controller: textController,
                        onEditingComplete: () {
                          setState(() {
                            widget.updateLocation(textController.value.text);
                            editingLocation = false;
                          });
                        },
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            widget.updateLocation(textController.value.text);
                            editingLocation = false;
                          });
                        },
                        child: const Icon(Icons.check),
                      ),
                    )
                  : Tooltip(
                      message: "Click to update the location",
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text("$aqi"),
                          backgroundColor: level.color,
                        ),
                        title: SizedBox(
                          height: 40,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text("${jsonResult?["city"]?["name"]}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall),
                            ),
                          ),
                        ),
                        subtitle: Text(
                            "last updated ${formatDate(lastUpdateTime.toLocal(), [
                              D,
                              " ",
                              H,
                              ":",
                              nn
                            ])}"),
                        onTap: () => {
                          setState(() {
                            editingLocation = true;
                            textController.text = widget.location;
                            textController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: textController.text.length);
                          })
                        },
                      ),
                    ),
              const Divider(),
              ListTile(
                title: Wrap(
                  spacing: 2,
                  runSpacing: 2,
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
                      avatar:
                          const Text("pm2.5", style: TextStyle(fontSize: 8)),
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
              ),
              ListTile(
                leading: Text("$aqi"),
                title: Text(level.name),
              ),
              ListTile(title: Text(level.detail)),
              level.advice != null
                  ? ListTile(title: Text(level.advice ?? ""))
                  : const SizedBox.shrink(),
              for (dynamic attribution in jsonResult?["attributions"])
                ListTile(
                  title: Text("${attribution?["name"]}"),
                  subtitle: Text("${attribution?["url"]}"),
                ),
            ],
          ),
        ));
  }

  AQILevel level = getLevel(0);

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(tickTime, (Timer t) => _tick(t));
    _tick(null);
  }

  Future<void> _tick(Timer? t) async {
    try {
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
    } catch (e) {
      debugPrint("Failed to fetch data $e");
    }
  }

  Future<http.Response> _fetchData() {
    return http.get(Uri.parse(
        'https://api.waqi.info/feed/${widget.location}/?token=$token'));
  }
}

class AQIChip extends StatefulWidget {
  AQIChip(Widget avatar, String value, {Key? key}) : super(key: key) {}

  @override
  State<AQIChip> createState() => _AQIChipState();
}

class _AQIChipState extends State<AQIChip> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    throw UnimplementedError();
  }
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
}
