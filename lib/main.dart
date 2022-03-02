import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:adaptive_breakpoints/adaptive_breakpoints.dart';
import 'package:http/http.dart' as http;
import 'package:date_format/date_format.dart';

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
                accentColor: Colors.pinkAccent.shade100,
                brightness: Brightness.dark,
                errorColor: Colors.red,
                cardColor: Colors.deepPurple.shade700)),
        initialRoute: '/',
        routes: {
          '/': (context) => const Dashboard(),
          '/feature': (context) => const Dashboard(),
          '/bug': (context) => const MyHomePage(title: "demo"),
        });
  }
}

class AQI extends StatefulWidget {
  String location;

  AQI({Key? key, required this.location}) : super(key: key);

  @override
  State<AQI> createState() => _AQIState();

  void _updateLocation(String location) {
    this.location = location;
  }
}

class _AQIState extends State<AQI> {
  String token = const String.fromEnvironment('AQI_TOKEN');
  Duration tickTime = const Duration(minutes: 10);
  Timer? timer;
  String aqiString = '';
  dynamic jsonResult;
  double aqi = 0.0;
  bool editingLocation = false;
  var textController = TextEditingController();
  DateTime lastUpdateTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    Color aqiColour;
    String tooltip;
    String warning;
    if (aqi > 300) {
      aqiColour = Colors.black;
      tooltip = "Hazardous";
      warning = "Everyone should avoid all outdoor exertion";
    } else if (aqi > 200) {
      aqiColour = Colors.deepPurple;
      tooltip = "Very Unhealthy";
      warning =
      "Active children and adults, and people with respiratory disease, such as asthma, should avoid all outdoor exertion; everyone else, especially children, should limit outdoor exertion.";
    } else if (aqi > 150) {
      aqiColour = Colors.red;
      tooltip = "Unhealthy";
      warning =
      "Active children and adults, and people with respiratory disease, such as asthma, should avoid prolonged outdoor exertion; everyone else, especially children, should limit prolonged outdoor exertion";
    } else if (aqi > 100) {
      aqiColour = Colors.orange;
      tooltip = "Unhealthy for Sensitive Groups";
      warning =
      "Active children and adults, and people with respiratory disease, such as asthma, should limit prolonged outdoor exertion.";
    } else if (aqi > 50) {
      aqiColour = Colors.amber;
      tooltip = "Moderate";
      warning =
      "Active children and adults, and people with respiratory disease, such as asthma, should limit prolonged outdoor exertion.";
    } else {
      aqiColour = Colors.lightGreen;
      tooltip = "Good";
      warning = "";
    }
    return Card(
        elevation: 3,
        margin: const EdgeInsets.all(5.0),
        child: Column(
          children: [
            editingLocation
                ? ListTile(
              title: TextField(
                controller: textController,
                onEditingComplete: () {
                  setState(() {
                    widget._updateLocation(textController.value.text);
                    editingLocation = false;
                    _tick(null);
                  });
                },
              ),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget._updateLocation(textController.value.text);
                    editingLocation = false;
                    _tick(null);
                  });
                },
                child: const Icon(Icons.check),
              ),
            )
                : ListTile(
              leading: Tooltip(
                message: tooltip,
                child: CircleAvatar(
                  child: Text("$aqi"),
                  backgroundColor: aqiColour,
                ),
              ),
              title: Text("${jsonResult?["city"]?["name"]}",
                  style: Theme
                      .of(context)
                      .textTheme
                      .headlineSmall),
              subtitle: Text(
                  "last updated ${formatDate(
                      lastUpdateTime.toLocal(), [D, " ", H, ":", nn])}"
              ),
              onTap: () =>
              {
                setState(() {
                  editingLocation = true;
                  textController.text = widget.location;
                })
              },
            ),
            const Divider(),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: const Icon(Icons.thermostat),
                  label: Text("${jsonResult?["iaqi"]?["t"]?["v"]} °C"),
                ),
                Chip(
                  avatar: const Icon(Icons.water_drop),
                  label: Text("${jsonResult?["iaqi"]?["h"]?["v"]} %"),
                ),
                Chip(
                  avatar: const Icon(Icons.air),
                  label: Text("${jsonResult?["iaqi"]?["w"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("bar"),
                  label: Text("${jsonResult?["iaqi"]?["p"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("uvi"),
                  label: Text("${jsonResult?["iaqi"]?["uvi"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("pm2.5", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["pm25"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("pm10", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["pm10"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("no2", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["no2"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("o3", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["o3"]?["v"]}"),
                ),
                Chip(
                  avatar: const Text("so2", style: TextStyle(fontSize: 8)),
                  label: Text("${jsonResult?["iaqi"]?["so2"]?["v"]}"),
                ),
              ],
            ),
            ExpansionTile(
              leading: Text("$aqi"),
              title: Text(tooltip),
              children: [
                ListTile(
                  title: Text(warning),
                ),
              ],
            ),
          ],
        ));
  }

  @override
  void initState() {
    super.initState();
    _tick(timer);
    timer = Timer.periodic(tickTime, (Timer t) => _tick(t));
  }

  Future<void> _tick(Timer? t) async {
    var response = await _fetchData();
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var aqiFeed = jsonDecode(response.body);
      if (aqiFeed?["status"]?.contains("ok")) {
        setState(() {
          jsonResult = aqiFeed?["data"];
          aqi = double.parse("${aqiFeed?["data"]?["aqi"]}");
          lastUpdateTime =
              DateTime.parse("${aqiFeed?["data"]?["time"]?["iso"]}");
        });
      }
    }
  }

  Future<http.Response> _fetchData() {
    return http.get(Uri.parse(
        'https://api.waqi.info/feed/${widget.location}/?token=$token'));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      drawer: const NavigationDrawer(),
      body: Center(
        child: Column(
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme
                  .of(context)
                  .textTheme
                  .headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      // Add a ListView to the drawer. This ensures the user can scroll
      // through the options in the drawer if there isn't enough vertical
      // space to fit everything.
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Center(
                child: Column(
                  children: const <Widget>[
                    Icon(
                      Icons.account_circle,
                      size: 64,
                    ),
                    Divider(),
                    Text('Cyril NG LUNG KIT'),
                  ],
                )),
          ),
          ListTile(
            title: const Text('Feature'),
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
          ),
          ListTile(
            title: const Text('Bug'),
            onTap: () {
              // Update the state of the app
              // ...
              // Then close the drawer
              Navigator.pushNamed(context, '/bug');
            },
          ),
        ],
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int crossAxisCount = getWindowType(context) <= AdaptiveWindowType.small
        ? 1
        : getWindowType(context) <= AdaptiveWindowType.medium
        ? 2
        : 3;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      drawer: const NavigationDrawer(),
      body: Center(
        child: GridView.count(
          crossAxisCount: crossAxisCount,
          children: [
            AQI(location: 'hongkong/sha-tin'),
            AQI(location: 'hongkong/central'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(context: context,
              builder: (context) {
                return const Dialog(
                  child: Text("Popup"),
                );
              });
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
