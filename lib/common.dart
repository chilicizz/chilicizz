import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';

class NavigationDrawer extends StatelessWidget {
  const NavigationDrawer({
    Key? key,
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
          ListTile(
            title: const Text('AQI Dashboard'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/aqi', ModalRoute.withName('/'));
            },
          ),
          ListTile(
            title: const Text('HKO Warnings'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/hko', ModalRoute.withName('/'));
            },
          ),
          ListTile(
            title: const Text('Bug'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(
                  context, '/bug', ModalRoute.withName('/'));
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
  return Text("last refresh ${formatDate(lastTickTime.toLocal(), [
        D,
        " ",
        dd,
        " ",
        M,
        " ",
        H,
        ":",
        nn
      ])}");
}

Text buildIssued(DateTime lastTickTime) {
  return Text("Issued at ${formatDate(lastTickTime.toLocal(), [
    D,
    " ",
    dd,
    " ",
    M,
    " ",
    H,
    ":",
    nn
  ])}");
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
