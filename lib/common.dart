import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';

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
            title: const Text('AQI Dashboard'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/aqi', ModalRoute.withName('/login'));

            },
          ),
          ListTile(
            title: const Text('HKO Warnings'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/hko', ModalRoute.withName('/login'));
            },
          ),
          ListTile(
            title: const Text('Bug'),
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, '/bug', ModalRoute.withName('/login'));
            },
          ),
        ],
      ),
    );
  }
}

Text buildLastUpdatedText(DateTime lastUpdateTime) {
  return Text("last updated ${formatDate(lastUpdateTime.toLocal(), [
    D,
    " ",
    H,
    ":",
    nn
  ])}");
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