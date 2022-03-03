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
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Add a new tile"),
                  content: TextField(
                      autofocus: true,
                      controller: textController,
                      decoration:
                          const InputDecoration(hintText: "enter a city"),
                      onEditingComplete: () {
                        addLocation(textController.value.text);
                        textController.clear();
                        Navigator.pop(context);
                      }),
                  actions: [
                    TextButton(
                      child: const Text('CANCEL'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    ElevatedButton(
                      child: const Text('SUBMIT'),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    )
                  ],
                );
              });
        },
        tooltip: 'Add a new tile',
        child: const Icon(Icons.add),
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
                  addLocation("hongkong/sha-tin");
                } else {
                  locations = snapshot.data ?? [];
                }
                return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 600,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: locations.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(locations[index]),
                        onDismissed: (direction) {
                          removeLocation(locations[index]);
                        },
                        direction: DismissDirection.down,
                        confirmDismiss: (DismissDirection direction) async {
                          return await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Confirm"),
                                content: const Text(
                                    "Are you sure you wish to delete this item?"),
                                actions: <Widget>[
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text("DELETE")),
                                  ElevatedButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text("CANCEL"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: AQI(location: locations[index]),
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
}
