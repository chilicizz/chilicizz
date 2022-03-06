import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'AQI.dart';
import 'common.dart';
import 'counter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'chilicizz.github.io',
        theme: ThemeData(
            colorScheme: ColorScheme.fromSwatch(
                primarySwatch: Colors.deepPurple,
                brightness: Brightness.light)),
        initialRoute: '/',
        routes: {
          '/': (context) => const Dashboard(),
          '/feature': (context) => const Dashboard(),
          '/bug': (context) => const MyHomePage(title: "demo"),
        });
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const NavigationDrawer(),
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
                return GridView.builder(
                    scrollDirection: Axis.vertical,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 400,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      return AQI(
                        location: locations[index],
                        removeLocationCallback: removeLocation,
                        updateLocationCallback: updateLocation,
                      );
                    });
            }
          },
        ),
      ),
    );
  }

  AlertDialog buildAQILocationDialog(BuildContext context) {
    return AlertDialog(
      title: const Text("Add new tile"),
      content: buildAQILocationAutocomplete(context, (value) {
        addLocation(value);
        Navigator.pop(context);
      }),
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
}
