import 'dart:async';
import 'dart:convert';

import 'package:chilicizz/AQI/aqi_provider.dart';
import 'package:chilicizz/config/config_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../common.dart';
import 'aqi_auto_complete.dart';
import 'aqi_common.dart';
import 'package:provider/provider.dart';
import './aqi_tile.dart';

const String aqiLocationsPreferenceLabel = 'aqi_locations';
Map<String, List<AQILocation>> searchCache = {};
Map<String, Completer> waitingResponse = {};

class AQITabLoader extends StatelessWidget {
  const AQITabLoader({super.key});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();
    final aqiProvider = Provider.of<AQIProvider>(context, listen: true);
    return ListenableBuilder(
      listenable: aqiProvider.aqiLocations,
      builder: (context, child) {
        debugPrint("loading LiveAQITab with ${aqiProvider.aqiLocations}");
        return LiveAQITab(
          socketURL: Uri.parse(dotenv.env['aqiUrl']!),
          locations: aqiProvider.aqiLocations.value!.toSet(),
          removeLocationCallback: (location) => config.removeAQILocation(location),
          updateLocationCallback: (original, updated) =>
              config.updateAQILocation(original, updated),
          addLocationCallback: (location) => config.addAQILocation(location),
        );
      },
    );
  }
}

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
            debugPrint("Loading AQI locations...");
            return const LoadingListView();
          default:
            locationsLoaded = snapshot.hasError ? [] : snapshot.data as List<String>;
            debugPrint("Locations loaded: $locationsLoaded");
            return LiveAQITab(
              socketURL: Uri.parse(dotenv.env['aqiUrl']!),
              locations: locationsLoaded.toSet(),
              removeLocationCallback: _removeLocation,
              updateLocationCallback: _updateLocation,
              addLocationCallback: _addLocation,
            );
        }
      },
    );
  }

  Future<void> _addLocation(String location) async {
    final SharedPreferences prefs = await _prefs;
    if (location.isEmpty) {
      return;
    }
    if (locationsLoaded.contains(location)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AQI Location $location already exists')),
      );
      return;
    }
    setState(() {
      locationsLoaded.add(location);
      _loadingLocations =
          prefs.setStringList(aqiLocationsPreferenceLabel, locationsLoaded).then((bool success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added new AQI tile for $location')),
        );
        return locationsLoaded;
      });
    });
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
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Removed AQI tile for $location')))
              },
            );
        _loadingLocations = _prefs.then(
          (SharedPreferences prefs) {
            return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
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
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Updated AQI tile $original to $newLocation')))
              },
            );
        _loadingLocations = _prefs.then(
          (SharedPreferences prefs) {
            return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
          },
        );
      },
    );
  }
}

class LiveAQITab extends StatefulWidget {
  final Uri socketURL;
  final Set<String> locations;
  final Function(String) removeLocationCallback;
  final Function(String, String) updateLocationCallback;
  final Function(String) addLocationCallback;

  const LiveAQITab(
      {super.key,
      required this.locations,
      required this.removeLocationCallback,
      required this.updateLocationCallback,
      required this.socketURL,
      required this.addLocationCallback});

  @override
  State<LiveAQITab> createState() => _AQITabState();
}

class _AQITabState extends State<LiveAQITab> {
  late WebSocketChannel _channel;
  int _failures = 0;
  final Map<String, AQIData?> locationDataMap = {};
  bool _displayInput = false;

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(widget.socketURL);
    for (var element in widget.locations) {
      locationDataMap[element] = null;
    }
    if (widget.locations.isEmpty) {
      _displayInput = true;
    }
  }

  void _reconnect() {
    if (_failures < 10) {
      Future.delayed(Duration(milliseconds: 100 * _failures), () {
        setState(() {
          debugPrint("Reconnecting websocket. Times failed: $_failures");
          _channel = WebSocketChannel.connect(widget.socketURL);
        });
      });
      _failures++;
    } else {
      debugPrint("Too many failures, not reconnecting");
    }
  }

  void refreshAll() {
    for (var element in widget.locations) {
      requestLocation(element);
    }
  }

  void requestLocation(String element) {
    debugPrint("Requesting AQI location $element");
    _channel.sink.add(
      jsonEncode({"id": element, "type": "AQI_FEED_REQUEST", "payload": element}),
    );
  }

  Future<dynamic> sendRequestOverSocket(String searchString) {
    Completer<dynamic> completer = Completer();
    waitingResponse[searchString] = completer;
    searchString = searchString.toLowerCase().replaceAll('/', '');
    _channel.sink.add(
      jsonEncode({"id": searchString, "type": "AQI_SEARCH_REQUEST", "payload": searchString}),
    );
    return completer.future;
  }

  Future<List<AQILocation>> queryLocation(String searchString) async {
    searchString = searchString.toLowerCase().replaceAll('/', '');
    String additionalQueryString = searchString.contains(" ")
        ? searchString.substring(searchString.indexOf(" ") + 1, searchString.length)
        : "";
    if (searchCache.containsKey(searchString)) {
      return searchCache[searchString]!;
    }
    debugPrint("Sending search request for $searchString");
    dynamic payload = await sendRequestOverSocket(searchString);
    List<AQILocation> list = parseLocationSearchResponse(payload);
    if (additionalQueryString.isNotEmpty) {
      list = list
          .where((element) => element.name.toLowerCase().contains(additionalQueryString))
          .toList();
    }
    searchCache[searchString] = list;
    return list;
  }

  void handleSocketMessages(dynamic event) {
    var message = jsonDecode(event);
    var type = message["type"];
    var payload = message["payload"];
    var location = message["id"];
    if (type == "AQI_FEED_RESPONSE") {
      debugPrint("Received AQIData for location: $location");
      AQIData data = AQIData.fromJSON(jsonDecode(payload)["data"]);
      locationDataMap[location] = data;
    } else if (type == "AQI_SEARCH_RESPONSE") {
      debugPrint("Received search response for: $location");
      if (waitingResponse.containsKey(location)) {
        waitingResponse[location]!.complete(payload);
        waitingResponse.remove(location);
      }
    } else {
      debugPrint("Received unknown message: $message");
    }
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
            debugPrint("Websocket connection ready");
        }
        // request data from socket
        refreshAll();
        return RefreshIndicator(
          onRefresh: () async {
            refreshAll();
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
            body: StreamBuilder<dynamic>(
              stream: _channel.stream,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return _displayInput
                        ? ListTile(
                            title: AQILocationAutocomplete(
                              autofocus: true,
                              selectionCallback: (value) {
                                setState(() {
                                  widget.addLocationCallback(value);
                                  _displayInput = false;
                                });
                              },
                            ),
                            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                              OutlinedButton(
                                child: const Icon(Icons.cancel_outlined),
                                onPressed: () {
                                  setState(() {
                                    widget.addLocationCallback("");
                                    _displayInput = false;
                                  });
                                },
                              ),
                            ]),
                          )
                        : const LoadingListView();
                  case ConnectionState.done:
                    _reconnect();
                    return ErrorListView(
                      message: "Connection closed ${_channel.closeReason}",
                    );
                  case ConnectionState.none:
                    _reconnect();
                    return ErrorListView(
                      message: "No connection ${_channel.closeReason}",
                    );
                  default:
                    if (snapshot.hasError) {
                      debugPrint("Error: ${snapshot.error}");
                    }
                }
                _failures = 0; // reset failures
                if (snapshot.hasData) {
                  var event = snapshot.data;
                  handleSocketMessages(event);
                }
                return _displayInput
                    ? ListTile(
                        title: AQILocationAutocomplete(
                          autofocus: true,
                          selectionCallback: (value) {
                            setState(() {
                              widget.addLocationCallback(value);
                              _displayInput = false;
                            });
                          },
                        ),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          OutlinedButton(
                            child: const Icon(Icons.cancel_outlined),
                            onPressed: () {
                              setState(() {
                                widget.addLocationCallback("");
                                _displayInput = false;
                              });
                            },
                          ),
                          // ElevatedButton(
                          //   onPressed: () {
                          //     widget.addLocationCallback('here');
                          //     _displayInput = false;
                          //   },
                          //   child: const Tooltip(
                          //     message: "Current Location",
                          //     child: Icon(Icons.my_location),
                          //   ),
                          // ),
                        ]),
                      )
                    : ListView.builder(
                        scrollDirection: Axis.vertical,
                        itemCount: locationDataMap.length,
                        itemBuilder: (context, index) {
                          var entry = locationDataMap.entries.elementAt(index);
                          var location = entry.key;
                          var aqiData = entry.value;
                          if (aqiData == null) {
                            requestLocation(location);
                          }
                          return AQIStatelessListTile(
                            location: location,
                            data: aqiData,
                            removeLocationCallback: widget.removeLocationCallback,
                            updateLocationCallback: widget.updateLocationCallback,
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
    debugPrint("Closing AQI websocket");
    _channel.sink.close();
    super.dispose();
  }
}
