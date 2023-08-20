import 'dart:async';

import 'package:chilicizz/AQI/aqi_common.dart';
import 'package:chilicizz/AQI/aqi_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'aqi_auto_complete.dart';

const String aqiLocationsPreferenceLabel = 'aqi_locations';

class AQITab extends StatefulWidget {
  const AQITab({Key? key}) : super(key: key);

  @override
  State<AQITab> createState() => _AQITabState();
}

class _AQITabState extends State<AQITab> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  late AQILocationSearch aqiLocationSearch;
  List<String> locations = [];
  late Future<List<String>> _locations;
  bool _displayInput = false;

  @override
  void initState() {
    super.initState();
    _locations = _prefs.then(
      (SharedPreferences prefs) {
        return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
      },
    );
    // aqiLocationSearch = HTTPAQILocationSearch(dotenv.env['aqiLocationSearchTemplate']!);
    aqiLocationSearch = SocketAQILocationSearch(Uri.parse(dotenv.env['aqiUrl']!));
  }

  @override
  void dispose() {
    aqiLocationSearch.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
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
            ? _buildAutoCompleteListView(context)
            : Center(
                child: FutureBuilder(
                  future: _locations,
                  builder: (BuildContext context,
                      AsyncSnapshot<List<String>> snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.waiting:
                        return const CircularProgressIndicator();
                      default:
                        if (snapshot.hasError) {
                          locations = [];
                        } else {
                          locations = snapshot.data ?? [];
                        }
                        return locations.isNotEmpty
                            ? ListView.builder(
                                scrollDirection: Axis.vertical,
                                itemCount: locations.length,
                                itemBuilder: (context, index) {
                                  return AQIListTile(
                                    location: locations[index],
                                    removeLocationCallback: _removeLocation,
                                    updateLocationCallback: _updateLocation,
                                    aqiFeedTemplate:
                                        dotenv.env['aqiFeedTemplate']!,
                                  );
                                })
                            : _buildAutoCompleteListView(context);
                    }
                  },
                ),
              ),
      ),
    );
  }

  ListView _buildAutoCompleteListView(BuildContext context) {
    return ListView(children: [_buildAutocompleteTile(context)]);
  }

  ListTile _buildAutocompleteTile(BuildContext context) {
    return ListTile(
      title: AQILocationAutocomplete(
        selectionCallback: _addLocation,
        autofocus: true,
        aqiLocationSearch: aqiLocationSearch,
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        OutlinedButton(
          child: const Icon(Icons.cancel_outlined),
          onPressed: () {
            setState(() {
              _addLocation("");
            });
          },
        ),
      ]),
    );
  }

  Future<void> _addLocation(String location) async {
    final SharedPreferences prefs = await _prefs;
    if (locations.contains(location)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location $location already exists')),
      );
      return;
    }
    setState(() {
      _displayInput = false;
      if (location.isEmpty) {
        return;
      }
      locations.add(location);
      prefs.setStringList(aqiLocationsPreferenceLabel, locations).then(
            (bool success) => {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added new tile for $location')),
              )
            },
          );
    });
  }

  Future<void> _removeLocation(String location) async {
    final SharedPreferences prefs = await _prefs;
    if (!locations.contains(location)) {
      return;
    }
    setState(() {
      locations.remove(location);
      prefs.setStringList(aqiLocationsPreferenceLabel, locations).then(
            (bool success) => {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Removed tile for $location')))
            },
          );
      _locations = _prefs.then(
        (SharedPreferences prefs) {
          return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
        },
      );
    });
  }

  Future<void> _updateLocation(String original, String newLocation) async {
    final SharedPreferences prefs = await _prefs;
    if (!locations.contains(original)) {
      return;
    }
    setState(() {
      int index = locations.indexOf(original);
      locations[index] = newLocation;
      prefs.setStringList(aqiLocationsPreferenceLabel, locations).then(
            (bool success) => {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Updated tile $original to $newLocation')))
            },
          );
      _locations = _prefs.then(
        (SharedPreferences prefs) {
          return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
        },
      );
    });
  }

  Future<void> refresh() async {
    setState(() {
      _locations = _prefs.then(
        (SharedPreferences prefs) {
          return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
        },
      );
    });
  }
}
