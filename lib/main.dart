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
  TextEditingController textController = TextEditingController();
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
                return AlertDialog(
                  title: const Text("Add a new tile"),
                  content: TextField(
                    autofocus: true,
                    controller: textController,
                    decoration: const InputDecoration(hintText: "enter a city"),
                    onEditingComplete: () {
                      addLocation(textController.value.text);
                      textController.clear();
                      Navigator.pop(context);
                    },
                  ),
                  actions: [
                    Tooltip(
                      message: "Current Location",
                      child: IconButton(
                        onPressed: () {
                          addLocation('here');
                          textController.clear();
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
                    ElevatedButton(
                      child: const Text('SUBMIT'),
                      onPressed: () {
                        addLocation(textController.value.text);
                        textController.clear();
                        Navigator.pop(context);
                      },
                    )
                  ],
                );
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
                  locations = snapshot.data ?? ['hongkong/sha-tin'];
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

  Future<void> updateLocation(String original, String location) async {
    final SharedPreferences prefs = await _prefs;
    if (!locations.contains(original)) {
      return;
    }
    setState(() {
      int index = locations.indexOf(original);
      locations[index] = location;
      prefs.setStringList(aqiLocations, locations).then((bool success) => {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Updated tile $original to $location')))
          });
    });
  }
}
