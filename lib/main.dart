import 'package:chilicizz/HKOTyphoonTab.dart';
import 'package:flutter/material.dart';

import 'AQI/AQITab.dart';
import 'HKOWarnings.dart';
import 'common.dart';
import 'counter.dart';

final List<NavRoute> routes = [
  NavRoute(
      path: '/',
      label: "Dashboard",
      buildFunction: (context) => const Dashboard()),
  NavRoute(
      path: '/dashboard/aqi',
      label: "AQI",
      buildFunction: (context) => const Dashboard(initial: 0)),
  NavRoute(
      path: '/dashboard/hko',
      label: "HKO Warnings",
      buildFunction: (context) => const Dashboard(initial: 1)),
  NavRoute(
      path: '/dashboard/typhoon',
      label: "HKO Typhoon",
      buildFunction: (context) => const Dashboard(initial: 2)),
  NavRoute(
      path: '/counter',
      label: "Counter",
      buildFunction: (context) => const MyHomePage(title: "demo")),
];

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
            primarySwatch: Colors.deepPurple, brightness: Brightness.light),
      ),
      initialRoute: '/',
      routes: {for (var e in routes) e.path: e.buildFunction},
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
          actions: [],
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
