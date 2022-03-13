import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';

class NavRoute {
  String path;
  String label;
  Widget Function(BuildContext) buildFunction;

  NavRoute(
      {required this.path, required this.label, required this.buildFunction});
}

class NavigationDrawer extends StatelessWidget {
  final List<NavRoute> routes;

  const NavigationDrawer({
    Key? key,
    required this.routes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
              ),
            ),
          ),
          for (var route in routes)
            ListTile(
              title: Text(route.label),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, route.path, ModalRoute.withName('/'));
              },
            ),
        ],
      ),
    );
  }
}

Text buildLastUpdatedText(DateTime? lastUpdateTime) {
  if (lastUpdateTime != null) {
    return Text("last updated ${formatDate(lastUpdateTime.toLocal(), [
          D,
          " ",
          H,
          ":",
          nn
        ])}");
  } else {
    return const Text("");
  }
}

Text buildLastTick(DateTime lastTickTime) {
  return Text(
    "last refresh ${formatDate(
      lastTickTime.toLocal(),
      [
        D,
        " ",
        dd,
        " ",
        M,
        " ",
        H,
        ":",
        nn,
      ],
    )}",
  );
}

Text buildIssued(DateTime lastTickTime) {
  return Text(
    "Issued ${formatDate(lastTickTime.toLocal(), [
          D,
          " ",
          dd,
          " ",
          M,
          " ",
          H,
          ":",
          nn
        ])}",
  );
}

bool isSmallScreen(BuildContext context) {
  // The equivalent of the "smallestWidth" qualifier on Android.
  var shortestSide = MediaQuery.of(context).size.shortestSide;
  // Determine if we should use mobile layout or not, 600 here is
  // a common breakpoint for a typical 7-inch tablet.
  final bool useMobileLayout = shortestSide < 600;
  return useMobileLayout;
}

bool isSmallDevice() {
  final data = MediaQueryData.fromWindow(WidgetsBinding.instance!.window);
  return data.size.shortestSide < 600;
}
