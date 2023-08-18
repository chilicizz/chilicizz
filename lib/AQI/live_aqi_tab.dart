import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../common.dart';
import 'aqi_common.dart';
import 'aqi_list_tile.dart';
import 'forecast_chart.dart';

const String aqiLocationsPreferenceLabel = 'aqi_locations';

/// Loads preferences and then loads the AQI tab
class AQIPreferenceLoader extends StatefulWidget {
  const AQIPreferenceLoader({super.key});

  @override
  State<AQIPreferenceLoader> createState() => _AQIPreferenceLoaderState();
}

class _AQIPreferenceLoaderState extends State<AQIPreferenceLoader> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late Future<List<String>> _loadingLocations;
  List<String> locationsLoaded = [];

  @override
  void initState() {
    super.initState();
    _loadingLocations = _prefs.then(
      (SharedPreferences prefs) {
        return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadingLocations,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const LoadingListView();
          default:
            locationsLoaded =
                snapshot.hasError ? [] : snapshot.data as List<String>;
            return LiveAQITab(
                locations: locationsLoaded.toSet(),
                removeLocationCallback: _removeLocation,
                updateLocationCallback: _updateLocation);
        }
      },
    );
  }

  Future<void> _removeLocation(String location) async {
    final SharedPreferences prefs = await _prefs;
    if (!locationsLoaded.contains(location)) {
      return;
    }
    setState(
      () {
        locationsLoaded.remove(location);
        prefs.setStringList(aqiLocationsPreferenceLabel, locationsLoaded).then(
              (bool success) => {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed tile for $location')))
              },
            );
        _loadingLocations = _prefs.then(
          (SharedPreferences prefs) {
            return prefs.getStringList(aqiLocationsPreferenceLabel) ??
                <String>[];
          },
        );
      },
    );
  }

  Future<void> _updateLocation(String original, String newLocation) async {
    final SharedPreferences prefs = await _prefs;
    if (!locationsLoaded.contains(original)) {
      return;
    }
    setState(
      () {
        int index = locationsLoaded.indexOf(original);
        locationsLoaded[index] = newLocation;
        prefs.setStringList(aqiLocationsPreferenceLabel, locationsLoaded).then(
              (bool success) => {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Updated tile $original to $newLocation')))
              },
            );
        _loadingLocations = _prefs.then(
          (SharedPreferences prefs) {
            return prefs.getStringList(aqiLocationsPreferenceLabel) ??
                <String>[];
          },
        );
      },
    );
  }
}

class LiveAQITab extends StatefulWidget {
  final Set<String> locations;
  final Function(String) removeLocationCallback;
  final Function(String, String) updateLocationCallback;

  const LiveAQITab(
      {Key? key,
      required this.locations,
      required this.removeLocationCallback,
      required this.updateLocationCallback})
      : super(key: key);

  @override
  State<LiveAQITab> createState() => _AQITabState();
}

class _AQITabState extends State<LiveAQITab> {
  final socketURL = Uri.parse(dotenv.env['aqiUrl']!);
  late WebSocketChannel _channel = WebSocketChannel.connect(socketURL);
  final Map<String, AQIData?> locationDataMap = {};

  bool _displayInput = false;

  @override
  void initState() {
    super.initState();
    for (var element in widget.locations) {
      locationDataMap[element] = null;
    }
  }

  void _connect() {
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        debugPrint("Reconnecting websocket");
        _channel = WebSocketChannel.connect(socketURL);
      });
    });
  }

  void locationSearch(String searchString) {
    _channel.sink.add(
      jsonEncode({
        "id": searchString,
        "type": "AQI_SEARCH_REQUEST",
        "payload": searchString
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _channel.ready,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return const LoadingListView();
          default:
            if (snapshot.hasError) {
              debugPrint("Error: ${snapshot.error}");
            }
        }
        return RefreshIndicator(
          onRefresh: () async {
            for (var element in widget.locations) {
              debugPrint("Requesting location $element");
              _channel.sink.add(
                jsonEncode({
                  "id": element,
                  "type": "AQI_FEED_REQUEST",
                  "payload": element
                }),
              );
            }
          },
          child: Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _displayInput = true;
                });
              },
              child: const Icon(Icons.add),
            ),
            body: _displayInput
                ? const Text("Autocomplete")
                : StreamBuilder<dynamic>(
                    stream: _channel.stream,
                    builder: (context, snapshot) {
                      switch (snapshot.connectionState) {
                        case ConnectionState.waiting:
                          return const LoadingListView();
                        case ConnectionState.done:
                          _connect();
                          return ErrorListView(
                              message:
                                  "Connection closed ${_channel.closeReason}");
                        case ConnectionState.none:
                          _connect();
                          return ErrorListView(
                              message: "No connection ${_channel.closeReason}");
                        default:
                          if (snapshot.hasError) {
                            debugPrint("Error: ${snapshot.error}");
                          }
                      }
                      if (snapshot.hasData) {
                        var event = snapshot.data;
                        var message = jsonDecode(event);
                        var type = message["type"];
                        var payload = message["payload"];
                        var location = message["id"];
                        if (type == "AQI_FEED_RESPONSE") {
                          debugPrint("Received message for location $location");
                          AQIData data =
                              AQIData.fromJSON(jsonDecode(payload)["data"]);
                          locationDataMap[location] = data;
                        } else if (type == "AQI_SEARCH_RESPONSE") {
                          debugPrint("Received search response $payload");
                        } else {
                          debugPrint("Received unknown message $event");
                        }
                      }
                      return ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: locationDataMap.length,
                        itemBuilder: (context, index) {
                          var entry = locationDataMap.entries.elementAt(index);
                          var location = entry.key;
                          var aqiData = entry.value;
                          if (aqiData == null) {
                            debugPrint("Requesting location $location");
                            _channel.sink.add(
                              jsonEncode({
                                "id": location,
                                "type": "AQI_FEED_REQUEST",
                                "payload": location
                              }),
                            );
                          }
                          return AQIStatelessListTile(
                            location: location,
                            data: aqiData,
                            removeLocationCallback:
                                widget.removeLocationCallback,
                            updateLocationCallback:
                                widget.updateLocationCallback,
                          );
                        },
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    debugPrint("Closing websocket");
    _channel.sink.close();
    super.dispose();
  }
}

/// A stateless widget that displays the AQI data for a location as a ListTile
class AQIStatelessListTile extends StatelessWidget {
  final String location;
  final AQIData? data;
  final Function(String) removeLocationCallback;
  final Function(String, String) updateLocationCallback;

  const AQIStatelessListTile(
      {super.key,
      required this.location,
      this.data,
      required this.removeLocationCallback,
      required this.updateLocationCallback});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return ListTile(
        leading: const FittedBox(child: CircularProgressIndicator()),
        title: Text(location),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            deleteMe();
          },
        ),
      );
    } else {
      return Dismissible(
        key: Key(location),
        direction: DismissDirection.startToEnd,
        onDismissed: (direction) {
          deleteMe();
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
          onLongPress: () {},
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
                  isSmallDevice() ? data!.getShortCityName() : data!.cityName,
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

  void deleteMe() {
    removeLocationCallback(location);
  }

  void updateLocation(String newLocation) {
    if (newLocation != location) {
      updateLocationCallback(location, newLocation);
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
}