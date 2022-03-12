import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'aqi_types.dart';
import 'common.dart';

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

  AQIData? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      _tick(null);
      return Card(
        elevation: 3,
        margin: const EdgeInsets.all(7.0),
        child: Column(
          children: [
            buildTitleTile(context, data?.cityName, data?.lastUpdatedTime),
            const Divider(),
            const FittedBox(child: CircularProgressIndicator()),
          ],
        ),
      );
    } else {
      return Card(
        semanticContainer: true,
        elevation: 3,
        margin: const EdgeInsets.all(7.0),
        child: PageView(
          controller: pageController,
          children: [
            Column(
              children: [
                buildTitleTile(context, data?.cityName, data?.lastUpdatedTime),
                const Divider(),
                ListTile(
                  onTap: () {
                    pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut);
                  },
                  leading: CircleAvatar(
                    child: Text("${data?.aqi}"),
                    backgroundColor: data?.getLevel().color,
                  ),
                  title: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(data!.getLevel().name),
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
                    children: data!.iaqiData.entries.map((entry) {
                      return _buildAQIChip(entry.key, entry.value);
                    }).toList(),
                  ),
                ),
              ],
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  buildTitleTile(
                      context, data?.cityName, data?.lastUpdatedTime),
                  const Divider(),
                  ListTile(
                    leading: CircleAvatar(
                      child: Text("${data?.aqi}"),
                      backgroundColor: data!.getLevel().color,
                    ),
                    title: FittedBox(
                      alignment: Alignment.centerLeft,
                      fit: BoxFit.scaleDown,
                      child: Text(data!.getLevel().name),
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
                  ListTile(title: Text(data!.getLevel().detail)),
                  data!.getLevel().advice != null
                      ? ListTile(title: Text(data!.getLevel().advice ?? ""))
                      : const SizedBox.shrink(),
                  for (Attribution attribution in data!.attributions)
                    ListTile(
                      title: Text(attribution.name),
                      subtitle: Text(attribution.url),
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
  }

  Widget _buildAQIChip(final IAQIRecord record, double value) {
    return Tooltip(
      message: record.label,
      child: Chip(
          avatar: CircleAvatar(
            backgroundColor: record.getColour(value),
            foregroundColor: Colors.white.withAlpha(200),
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: FittedBox(child: record.getIcon()),
            ),
          ),
          label: Text("$value ${record.unit ?? ''}")),
    );
  }

  Widget buildTitleTile(
      BuildContext context, String? title, DateTime? lastUpdate) {
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
        title: AQILocationAutocomplete(
            selectionCallback: (value) => {
                  widget.updateLocation(value),
                  editingLocation = false,
                },
            initialValue: textController.value.text,
            autofocus: editingLocation),
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
          subtitle: buildLastUpdatedText(lastUpdate),
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
    var fetchedData = await fetchAQIData(widget.location);
    setState(() {
      data = fetchedData;
    });
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
        debugPrint("Failed to fetch data");
      }
    }
  } catch (e) {
    debugPrint("Failed to fetch data $e");
  }
  return null;
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

class AQILocationAutocomplete extends StatelessWidget {
  Function(String value) selectionCallback;
  String? initialValue;
  bool autofocus;

  AQILocationAutocomplete(
      {Key? key,
      required this.selectionCallback,
      this.autofocus = false,
      this.initialValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildAQILocationAutocomplete(context, selectionCallback,
        initial: initialValue, autofocus: autofocus);
  }
}

Autocomplete<AQILocation> buildAQILocationAutocomplete(
    BuildContext context, Function(String value) selectionCallback,
    {String? initial, bool autofocus = false}) {
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
        autofocus: autofocus,
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
