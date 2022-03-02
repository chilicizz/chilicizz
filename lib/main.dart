import 'package:flutter/material.dart';
import 'package:adaptive_breakpoints/adaptive_breakpoints.dart';

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
                brightness: Brightness.light
            )),
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
  TextEditingController textController = TextEditingController();
  List<Widget> widgets = [
    AQI(location: 'hongkong/sha-tin'),
    AQI(location: 'hongkong/central'),
  ];

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
          children: widgets,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Enter a location"),
                  content: TextField(
                    autofocus: true,
                    controller: textController,
                    decoration: const InputDecoration(hintText: "enter a city"),
                    onEditingComplete: () {
                      addNewWidget(AQI(location: textController.value.text));
                      textController.clear();
                      Navigator.pop(context);
                    }
                  ),
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
        tooltip: 'Add new widget',
        child: const Icon(Icons.add),
      ),
    );
  }

  void addNewWidget(Widget widget) {
    setState(() {
      widgets.add(widget);
    });
  }
}
