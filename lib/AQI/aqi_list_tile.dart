import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../common.dart';
import 'aqi_auto_complete.dart';
import 'aqi_common.dart';
import 'forecast_chart.dart';

class AQIListTile extends StatefulWidget {
  final String location;
  final Function(String) removeLocationCallback;
  final Function(String, String) updateLocationCallback;
  final String aqiFeedTemplate;

  const AQIListTile(
      {super.key,
      required this.location,
      required this.removeLocationCallback,
      required this.updateLocationCallback,
      required this.aqiFeedTemplate});

  @override
  State<AQIListTile> createState() => _AQIListTileState();

  void deleteMe() {
    removeLocationCallback(location);
  }

  void updateLocation(String newLocation) {
    if (newLocation != location) {
      updateLocationCallback(location, newLocation);
    }
  }
}

class _AQIListTileState extends State<AQIListTile> {
  late TextEditingController textController;
  late AQILocationSearch aqiLocationSearch;
  bool editingLocation = false;

  AQIData? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return ListTile(
        leading: const FittedBox(child: CircularProgressIndicator()),
        title: Text(widget.location),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            widget.deleteMe();
          },
        ),
      );
    } else {
      return editingLocation
          ? ListTile(
              title: AQILocationAutocomplete(
                  aqiLocationSearch: aqiLocationSearch,
                  selectionCallback: (value) => {
                        widget.updateLocation(value),
                        editingLocation = false,
                      },
                  initialValue: textController.value.text,
                  autofocus: editingLocation),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OutlinedButton(
                    child: const Icon(Icons.cancel_outlined),
                    onPressed: () {
                      setState(() {
                        editingLocation = false;
                      });
                    },
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        widget.updateLocation(textController.value.text);
                        editingLocation = false;
                      });
                    },
                    child: const Icon(Icons.check),
                  ),
                ],
              ),
            )
          : Dismissible(
              key: Key(widget.location),
              direction: DismissDirection.startToEnd,
              onDismissed: (direction) {
                widget.deleteMe();
              },
              confirmDismiss: (DismissDirection direction) async {
                return await confirmDismiss(context);
              },
              background: Container(
                alignment: Alignment.centerLeft,
                color: Colors.red,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.delete),
                ),
              ),
              child: GestureDetector(
                onLongPress: () {
                  setState(() {
                    editingLocation = true;
                  });
                },
                child: ExpansionTile(
                  //initiallyExpanded: !isSmallDevice(),
                  leading: Tooltip(
                    message: data!.level.name,
                    child: CircleAvatar(
                      backgroundColor: data?.level.color,
                      child: Text(
                        "${data?.aqi}",
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  title: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                        isSmallDevice()
                            ? data!.getShortCityName()
                            : data!.cityName,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  subtitle: buildLastUpdatedText(data?.lastUpdatedTime),
                  children: [
                    ListTile(
                      title: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        runSpacing: 1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: data!.iaqiData.entries.map((entry) {
                          return AQIChip(record: entry.key, value: entry.value);
                        }).toList(),
                      ),
                    ),
                    ListTile(
                      title: SizedBox(
                        height: 200,
                        child: ForecastChart(data: data!.iaqiForecast),
                      ),
                    ),
                    ListTile(
                      title: Text(data!.level.name),
                      subtitle: Text(data!.level.longDescription()),
                    ),
                    for (Attribution attribution in data!.attributions)
                      ListTile(
                        title: Text(attribution.name),
                        subtitle: Text(attribution.url),
                      ),
                  ],
                ),
              ),
            );
    }
  }

  Future<bool?> confirmDismiss(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you wish to delete this item?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("DELETE"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    textController.text = widget.location;
    aqiLocationSearch = HTTPAQILocationSearch(dotenv.env['aqiLocationSearchTemplate']!);
    // aqiLocationSearch = SocketAQILocationSearch(Uri.parse(dotenv.env['aqiUrl']!));
    refresh();
  }

  @override
  void dispose() {
    aqiLocationSearch.close();
    textController.dispose();
    super.dispose();
  }

  Future<void> refresh({Timer? t}) async {
    var fetchedData = await _fetchAQIData(widget.location);
    setState(() {
      data = fetchedData;
    });
  }

  String _getAqiFeedUrl(String location, String token) {
    return widget.aqiFeedTemplate
        .replaceAll("_LOCATION_", location)
        .replaceAll("_TOKEN_", token);
  }

  Future<AQIData?> _fetchAQIData(String location) async {
    try {
      var aqiFeedUrl = _getAqiFeedUrl(location, aqiToken);
      var response = await http.get(Uri.parse(aqiFeedUrl));
      if (response.statusCode == 200) {
        var aqiFeed = jsonDecode(response.body);
        if (aqiFeed?["status"]?.contains("ok")) {
          return AQIData.fromJSON(aqiFeed?["data"]);
        } else {
          debugPrint("AQI Feed returned error $location ${response.body}");
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch data $location $e");
    }
    return null;
  }
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
            child: FittedBox(child: record.getIcon()),
          ),
        ),
        label: Text(
            "${value.toStringAsFixed(value > 50 ? 0 : 1)} ${record.unit ?? ''}"),
      ),
    );
  }
}
