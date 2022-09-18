import 'dart:async';

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
  List<String> locations = [];
  late Future<List<String>> _locations;
  bool _displayInput = false;

  @override
  void initState() {
    super.initState();
    _locations = _prefs.then((SharedPreferences prefs) {
      return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        return refresh();
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
            ? buildAutoCompleteListView(context)
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
                                // add one for autocomplete
                                itemBuilder: (context, index) {
                                  return AQIListTile(
                                    location: locations[index],
                                    removeLocationCallback: removeLocation,
                                    updateLocationCallback: updateLocation,
                                    aqiFeedTemplate:
                                        dotenv.env['aqiFeedTemplate']!,
                                  );
                                })
                            : buildAutoCompleteListView(context);
                    }
                  },
                ),
              ),
      ),
    );
  }

  ListView buildAutoCompleteListView(BuildContext context) {
    return ListView(children: [buildAutocompleteTile(context)]);
  }

  ListTile buildAutocompleteTile(BuildContext context) {
    return ListTile(
      title: AQILocationAutocomplete(
        selectionCallback: addLocation,
        autofocus: true,
        aqiLocationSearchTemplate: dotenv.env['aqiLocationSearchTemplate']!,
      ),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        OutlinedButton(
          child: const Icon(Icons.cancel_outlined),
          onPressed: () {
            setState(() {
              addLocation("");
            });
          },
        ),
        ElevatedButton(
          onPressed: () {
            addLocation('here');
          },
          child: const Tooltip(
            message: "Current Location",
            child: Icon(Icons.my_location),
          ),
        ),
      ]),
    );
  }

  Future<void> addLocation(String location) async {
    final SharedPreferences prefs = await _prefs;
    if (locations.contains(location)) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location $location already exists')));
      return;
    }
    setState(() {
      _displayInput = false;
      if (location.isEmpty) {
        return;
      }
      locations.add(location);
      prefs
          .setStringList(aqiLocationsPreferenceLabel, locations)
          .then((bool success) => {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added new tile for $location')))
              });
    });
  }

  Future<void> removeLocation(String location) async {
    final SharedPreferences prefs = await _prefs;
    if (!locations.contains(location)) {
      return;
    }
    setState(() {
      locations.remove(location);
      prefs
          .setStringList(aqiLocationsPreferenceLabel, locations)
          .then((bool success) => {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Removed tile for $location')))
              });
      _locations = _prefs.then((SharedPreferences prefs) {
        return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
      });
    });
  }

  Future<void> updateLocation(String original, String newLocation) async {
    final SharedPreferences prefs = await _prefs;
    if (!locations.contains(original)) {
      return;
    }
    setState(() {
      int index = locations.indexOf(original);
      locations[index] = newLocation;
      prefs
          .setStringList(aqiLocationsPreferenceLabel, locations)
          .then((bool success) => {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Updated tile $original to $newLocation')))
              });
      _locations = _prefs.then((SharedPreferences prefs) {
        return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
      });
    });
  }

  Future<void> refresh() async {
    setState(() {
      _locations = _prefs.then((SharedPreferences prefs) {
        return prefs.getStringList(aqiLocationsPreferenceLabel) ?? <String>[];
      });
    });
  }
}
