import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'common.dart';

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

const String token = String.fromEnvironment('AQI_TOKEN');

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
  static const Duration tickTime = Duration(minutes: 10);
  late Timer timer;

  late PageController pageController;
  late TextEditingController textController;
  bool editingLocation = false;

  dynamic jsonResult;
  DateTime lastUpdateTime = DateTime.now();
  int aqi = 0;
  AQILevel level = getLevel(0);

  @override
  Widget build(BuildContext context) {
    if (jsonResult == null) {
      _tick(null);
      return Card(
        elevation: 3,
        margin: const EdgeInsets.all(7.0),
        child: Column(
          children: [
            buildTitleTile(context, jsonResult?["city"]?["name"]),
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
              buildTitleTile(context, jsonResult?["city"]?["name"]),
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
                title: FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(level.name),
                ),
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
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 2,
                  children: [
                    buildAqiChip(const Icon(Icons.thermostat),
                        jsonResult?["iaqi"]?["t"]?["v"],
                        suffix: "°C", label: "Temp"),
                    buildAqiChip(const Icon(Icons.water_drop),
                        jsonResult?["iaqi"]?["h"]?["v"],
                        suffix: "%", label: "Humidity"),
                    buildAqiChip(
                        const Icon(Icons.air), jsonResult?["iaqi"]?["w"]?["v"],
                        label: "Wind"),
                    buildAqiChip(
                        const Text("bar"), jsonResult?["iaqi"]?["p"]?["v"],
                        label: "Pressure"),
                    buildAqiChip(
                        const Text("uvi"), jsonResult?["iaqi"]?["uvi"]?["v"],
                        label: "UV Index"),
                    buildAqiChip(
                        const Text("pm2.5"), jsonResult?["iaqi"]?["pm25"]?["v"],
                        label: "PM 2.5"),
                    buildAqiChip(
                        const Text("pm10"), jsonResult?["iaqi"]?["pm10"]?["v"],
                        label: "PM 10"),
                    buildAqiChip(
                        const Text("no2"), jsonResult?["iaqi"]?["no2"]?["v"],
                        label: "NO2"),
                    buildAqiChip(
                        const Text("o3"), jsonResult?["iaqi"]?["o3"]?["v"],
                        label: "O3"),
                    buildAqiChip(
                        const Text("so2"), jsonResult?["iaqi"]?["so2"]?["v"],
                        label: "SO2"),
                  ],
                ),
              ),
            ],
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                buildTitleTile(context, jsonResult?["city"]?["name"]),
                const Divider(),
                ListTile(
                  leading: CircleAvatar(
                    child: Text("$aqi"),
                    backgroundColor: level.color,
                  ),
                  title: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(level.name),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_left),
                    onPressed: () {
                      pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut);
                    },
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
                ListTile(
                  title: Text("Delete this tile",
                      style: Theme.of(context).textTheme.bodySmall),
                  leading: Tooltip(
                    message: "Delete this tile",
                    child: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        setState(() {
                          widget.deleteMe();
                          editingLocation = false;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget buildAqiChip(final Widget icon, dynamic value,
      {String? suffix, String? label}) {
    if (value != null) {
      return Tooltip(
        message: label ?? '',
        child: Chip(
            avatar: CircleAvatar(
                child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: FittedBox(child: icon),
            )),
            label: Text("$value ${suffix ?? ''}")),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget buildTitleTile(BuildContext context, String? title) {
    if (editingLocation || title == null) {
      textController.selection = TextSelection(
          baseOffset: 0, extentOffset: textController.text.length);
      return ListTile(
        leading: IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () {
            setState(() {
              editingLocation = false;
            });
          },
        ),
        title: buildAQILocationAutocomplete(
            context,
            (value) => {
                  widget.updateLocation(value),
                  editingLocation = false,
                },
            initial: textController.value.text,
            editing: editingLocation),
        trailing: ElevatedButton(
          onPressed: () {
            setState(() {
              editingLocation = false;
              widget.updateLocation(textController.value.text);
            });
          },
          child: const Icon(Icons.check),
        ),
      );
    } else {
      return Tooltip(
        message: "Click to update the location",
        child: ListTile(
          title: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child:
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          subtitle: buildLastUpdatedText(lastUpdateTime),
          onTap: () => {
            setState(() {
              editingLocation = true;
            })
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    pageController = PageController();
    timer = Timer.periodic(tickTime, (Timer t) => _tick(t));
    textController.text = widget.location;
    _tick(null);
  }

  @override
  void dispose() {
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

  const AQILevel(
      this.color, this.name, this.detail, this.advice, this.upperThreshold);

  bool within(int value) {
    return value <= upperThreshold;
  }
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
      debugPrint("Failed to fetch data");
      return [];
    }
  } else {
    return [];
  }
}

Autocomplete<AQILocation> buildAQILocationAutocomplete(
    BuildContext context, Function(String value) selectionCallback,
    {String? initial, bool editing = false}) {
  return Autocomplete<AQILocation>(
    fieldViewBuilder: (BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted) {
      if (initial != null) {
        textEditingController.text = initial;
      }
      textEditingController.selection = TextSelection(
          baseOffset: 0, extentOffset: textEditingController.text.length);
      return TextField(
        autofocus: editing,
        focusNode: focusNode,
        controller: textEditingController,
        decoration: const InputDecoration(hintText: "enter the name of a city"),
        onSubmitted: (value) {
          selectionCallback(value);
        },
      );
    },
    displayStringForOption: (location) {
      return "${location.name}\n(${location.url})";
    },
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isNotEmpty &&
          textEditingValue.text.length > 3) {
        return locationQuery(textEditingValue.text);
      }
      return const Iterable<AQILocation>.empty();
    },
    onSelected: (AQILocation selection) {
      selectionCallback(selection.url);
    },
  );
}
