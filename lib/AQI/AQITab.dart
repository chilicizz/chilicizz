import 'dart:async';

import 'package:chilicizz/AQI/AQIListTile.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AQIAutoComplete.dart';

class AQITab extends StatefulWidget {
  const AQITab({Key? key}) : super(key: key);

  @override
  State<AQITab> createState() => _AQITabState();
}

class _AQITabState extends State<AQITab> {
  static const String aqiLocations = 'aqi_locations';
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  List<String> locations = [];
  late Future<List<String>> _locations;

  @override
  void initState() {
    super.initState();
    _locations = _prefs.then((SharedPreferences prefs) {
      return prefs.getStringList(aqiLocations) ?? <String>[];
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
          tooltip: 'Add a new tile',
          child: const Icon(Icons.add),
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) {
                  return buildAQILocationDialog(context);
                });
          },
        ),
        body: Center(
          child: FutureBuilder(
            future: _locations,
            builder:
                (BuildContext context, AsyncSnapshot<List<String>> snapshot) {
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
                              removeLocationCallback: removeLocation,
                              updateLocationCallback: updateLocation,
                            );
                          })
                      : const Text("No locations added");
              }
            },
          ),
        ),
      ),
    );
  }

  AlertDialog buildAQILocationDialog(BuildContext context) {
    return AlertDialog(
      title: const Text("Add new tile"),
      content: AQILocationAutocomplete(
          selectionCallback: (value) {
            addLocation(value);
            Navigator.pop(context);
          },
          autofocus: true),
      actions: [
        Tooltip(
          message: "Current Location",
          child: IconButton(
            onPressed: () {
              addLocation('here');
              Navigator.pop(context);
            },
            icon: const Icon(Icons.my_location),
          ),
        ),
        TextButton(
          child: const Text('CANCEL'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ],
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
      locations.add(location);
      prefs.setStringList(aqiLocations, locations).then((bool success) => {
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
      prefs.setStringList(aqiLocations, locations).then((bool success) => {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Removed tile for $location')))
          });
      _locations = _prefs.then((SharedPreferences prefs) {
        return prefs.getStringList(aqiLocations) ?? <String>[];
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
      prefs.setStringList(aqiLocations, locations).then((bool success) => {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Updated tile $original to $newLocation')))
          });
      _locations = _prefs.then((SharedPreferences prefs) {
        return prefs.getStringList(aqiLocations) ?? <String>[];
      });
    });
  }

  Future<void> refresh() async {
    setState(() {
      _locations = _prefs.then((SharedPreferences prefs) {
        return prefs.getStringList(aqiLocations) ?? <String>[];
      });
    });
  }
}
