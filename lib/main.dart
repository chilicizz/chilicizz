import 'package:chilicizz/HKOTyphoonTab.dart';
import 'package:flutter/material.dart';

import 'AQI/AQITab.dart';
import 'HKOWarnings.dart';
import 'common.dart';
import 'counter.dart';

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
    Map<String, Widget Function(BuildContext)> appRoutes = {};
    for (var e in routes) {
      appRoutes.addAll(e.getRoutes());
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
          actions: const [],
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
