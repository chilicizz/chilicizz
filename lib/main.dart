import 'package:chilicizz/AQI/live_aqi_tab.dart';
import 'package:chilicizz/Chat/chat.dart';
import 'package:chilicizz/HKO/typhoon/hko_typhoon_tab.dart';
import 'package:chilicizz/HKO/warnings/live_hko_warnings.dart';
import 'package:chilicizz/rss_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'AQI/aqi_tab.dart';
import 'common.dart';

const String appEnv = String.fromEnvironment('ENV', defaultValue: "pdn");

final List<NavRoute> routes = [
  NavRoute(
      path: '/dashboard',
      label: "Dashboard",
      buildFunction: (context) => const Dashboard(),
      subRoutes: [
        NavRoute(
            path: '/aqi',
            label: "Air Quality",
            buildFunction: (context) => const Dashboard(initial: 0)),
        NavRoute(
            path: '/hko',
            label: "HKO Warnings",
            buildFunction: (context) => const Dashboard(initial: 1)),
        NavRoute(
            path: '/typhoon',
            label: "HKO Typhoon",
            buildFunction: (context) => const Dashboard(initial: 2)),
      ]),
  NavRoute(
    path: '/chat',
    label: "Chat",
    buildFunction: (context) => const ChatExample(title: "WebSocket Chat"),
  ),
  NavRoute(
    path: '/rss',
    label: "RSS Reader",
    buildFunction: (context) => const RSSReader(),
  ),
];

Future<void> main() async {
  await dotenv.load(fileName: "assets/config/$appEnv.properties");
  debugPrint("Starting environment: $appEnv");
  runApp(ChangeNotifierProvider(
    child: const MyApp(),
    create: (BuildContext context) {},
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Map<String, Widget Function(BuildContext)> appRoutes = {};
    for (var route in routes) {
      appRoutes.addAll(route.getRoutes());
    }
    return MaterialApp(
      title: 'app.cyrilng.com',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.deepPurple, brightness: Brightness.light),
      ),
      initialRoute: '/dashboard',
      routes: appRoutes,
    );
  }
}

class Dashboard extends StatefulWidget {
  final int initial;

  const Dashboard({Key? key, this.initial = 0}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: widget.initial,
      length: 4,
      child: Scaffold(
        drawer: NavDrawer(routes: routes),
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Text("AIR QUALITY")),
              Tab(icon: Text("WARNINGS")),
              Tab(icon: Text("TYPHOON")),
              Tab(icon: Text("(🚧)")),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) {
                  final qrController = TextEditingController();
                  qrController.text  = 'https://app.cyrilng.com/';
                  final ValueNotifier<String> textValue =
                      ValueNotifier<String>(qrController.text);
                  return AlertDialog(
                    title: TextField(
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      textAlign: TextAlign.center,
                      controller: qrController,
                      onChanged: (value) => {textValue.notifyListeners()},
                    ),
                    content: ValueListenableBuilder(
                      valueListenable: textValue,
                      builder:
                          (BuildContext context, String value, Widget? child) {
                        return SizedBox(
                          height: 300,
                          width: 300,
                          child: QrImageView(
                            data: qrController.value.text,
                            version: QrVersions.auto,
                            embeddedImage: const AssetImage('assets/cn.png'),
                          ),
                        );
                      },
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.pop(context, 'Close'),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              ),
            )
          ],
        ),
        body: const TabBarView(
          children: [
            AQITab(),
            LiveHKOWarnings(),
            HKOTyphoonTab(),
            AQIPreferenceLoader(),
          ],
        ),
      ),
    );
  }
}

class User {
  String username;
  String firstName;
  String lastName;

  User(this.username, this.firstName, this.lastName);
}

class Auth extends ChangeNotifier {
  // https://docs.flutter.dev/development/data-and-backend/state-mgmt/simple
  // Consumer<Auth>()
  User? _loggedInUser;

  bool isLoggedIn() {
    return _loggedInUser != null;
  }

  void logIn(User user) {
    _loggedInUser = user;
    notifyListeners();
  }

  void logOut() {
    _loggedInUser = null;
    notifyListeners();
  }
}
