import 'dart:async';
import 'dart:convert';

import 'package:date_format/date_format.dart';
import 'package:flutter/cupertino.dart';
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

  AQI({Key? key,
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

  late PageController pageController;
  late TextEditingController textController;
  late FocusNode titleFocus;
  bool editingLocation = false;

  dynamic jsonResult;
  DateTime lastUpdateTime = DateTime.now();
  int aqi = 0;
  AQILevel level = getLevel(0);

  @override
  Widget build(BuildContext context) {
    if (jsonResult == null) {
      textController.text = widget.location;
      _tick(null);
      return Card(
        child: Column(
          children: [
            buildTitleTileEditing(),
            const Divider(),
            const FittedBox(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    level = getLevel(aqi);
    return Card(
      semanticContainer: true,
      elevation: 3,
      margin: const EdgeInsets.all(7.0),
      child: PageView(
        controller: pageController,
        children: [
          Column(
            children: [
              editingLocation
                  ? buildTitleTileEditing()
                  : buildTitleTile(context),
              const Divider(),
              ListTile(
                onTap: () {
                  pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut);
                },
                leading: CircleAvatar(
                  child: Text("$aqi"),
                  backgroundColor: level.color,
                ),
                title: Text(level.name),
                trailing: IconButton(
                    icon: const Icon(Icons.arrow_right),
                    onPressed: () {
                      pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    }),
              ),
              ListTile(
                title: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  runSpacing: 3,
                  children: [
                    buildAqiChip(const Icon(Icons.thermostat),
                        jsonResult?["iaqi"]?["t"]?["v"], "°C"),
                    buildAqiChip(const Icon(Icons.water_drop),
                        jsonResult?["iaqi"]?["h"]?["v"], "%"),
                    buildAqiChip(
                        const Icon(Icons.air), jsonResult?["iaqi"]?["w"]?["v"]),
                    buildAqiChip(
                        const Text("bar"), jsonResult?["iaqi"]?["p"]?["v"]),
                    buildAqiChip(
                        const Text("uvi"), jsonResult?["iaqi"]?["uvi"]?["v"]),
                  ],
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                ListTile(
                  leading: CircleAvatar(
                    child: Text("$aqi"),
                    backgroundColor: level.color,
                  ),
                  title: SizedBox(
                    height: 40,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        child: Text(level.name,
                            style: Theme
                                .of(context)
                                .textTheme
                                .headlineSmall),
                      ),
                    ),
                  ),
                  subtitle: buildLastUpdatedText(),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () {
                      pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  title: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 3,
                    children: [
                      buildAqiChip(
                          const Text("pm2.5", style: TextStyle(fontSize: 8)),
                          jsonResult?["iaqi"]?["pm25"]?["v"]),
                      buildAqiChip(
                          const Text("pm10", style: TextStyle(fontSize: 8)),
                          jsonResult?["iaqi"]?["pm10"]?["v"]),
                      buildAqiChip(
                          const Text("no2", style: TextStyle(fontSize: 8)),
                          jsonResult?["iaqi"]?["no2"]?["v"]),
                      buildAqiChip(
                          const Text("o3", style: TextStyle(fontSize: 8)),
                          jsonResult?["iaqi"]?["o3"]?["v"]),
                      buildAqiChip(
                          const Text("so2", style: TextStyle(fontSize: 8)),
                          jsonResult?["iaqi"]?["so2"]?["v"]),
                    ],
                  ),
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
          )
        ],
      ),
    );
  }

  Widget buildAqiChip(final Widget icon, dynamic value, [String? suffix]) {
    if (value != null) {
      return Chip(avatar: icon, label: Text("$value ${suffix ?? ''}"));
    } else {
      return const SizedBox.shrink();
    }
  }

  Tooltip buildTitleTile(BuildContext context) {
    return Tooltip(
      message: "Click to update the location",
      child: ListTile(
        title: SizedBox(
          height: 40,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Text("${jsonResult?["city"]?["name"]}",
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall),
            ),
          ),
        ),
        subtitle: buildLastUpdatedText(),
        onTap: () =>
        {
          setState(() {
            editingLocation = true;
            textController.text = widget.location;
            titleFocus.requestFocus();
            textController.selection = TextSelection(
                baseOffset: 0, extentOffset: textController.text.length);
          })
        },
      ),
    );
  }

  Text buildLastUpdatedText() {
    return Text("last updated ${formatDate(lastUpdateTime.toLocal(), [
      D,
      " ",
      H,
      ":",
      nn
    ])}");
  }

  ListTile buildTitleTileEditing() {
    return ListTile(
      leading: Tooltip(
        message: "Delete this tile",
        child: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            editingLocation = false;
            widget.deleteMe();
          },
        ),
      ),
      title: TextField(
        controller: textController,
        focusNode: titleFocus,
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
    );
  }

  @override
  void initState() {
    super.initState();
    titleFocus = FocusNode();
    textController = TextEditingController();
    pageController = PageController();
    timer = Timer.periodic(tickTime, (Timer t) => _tick(t));
    _tick(null);
  }

  @override
  void dispose() {
    titleFocus.dispose();
    textController.dispose();
    pageController.dispose();
    super.dispose();
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

class AQILevel {
  final Color color;
  final String name;
  final String detail;
  final String? advice;
  final int upperThreshold;

  const AQILevel(this.color, this.name, this.detail, this.advice,
      this.upperThreshold);

  bool within(int value) {
    return value <= upperThreshold;
  }
}
