import 'package:chilicizz/HKO/hko_typhoon_tab.dart';
import 'package:chilicizz/rss_reader.dart';
import 'package:chilicizz/signin_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'AQI/aqi_tab.dart';
import 'HKO/hko_warnings.dart';
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
            label: "AQI",
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
    path: '/login',
    label: "Login",
    buildFunction: (context) => const SignInHttpDemo(),
  ),
  NavRoute(
    path: '/rss',
    label: "RSS Reader",
    buildFunction: (context) => const RSSReader(),
  ),
];

Future<void> main() async {
  await dotenv.load(fileName: "assets/config/$appEnv.properties");
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
      title: 'chilicizz.github.io',
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
      length: 3,
      child: Scaffold(
        drawer: NavigationDrawer(routes: routes),
        appBar: AppBar(
          title: const Text('Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Text("AQI")),
              Tab(icon: Text("WARNINGS")),
              Tab(icon: Text("TYPHOON")),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Under construction'),
                  content: const Text('...'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'OK'),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        body: const TabBarView(
          children: [
            AQITab(),
            HKOWarnings(),
            HKOTyphoonTab(),
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
