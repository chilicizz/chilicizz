import 'dart:async';
import 'dart:convert';

import 'package:chilicizz/HKO/live_hko_warnings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../common.dart';
import 'hko_types.dart';

class HKOWarnings extends StatefulWidget {
  const HKOWarnings({Key? key}) : super(key: key);

  @override
  State<HKOWarnings> createState() => _HKOWarningsState();
}

class _HKOWarningsState extends State<HKOWarnings> {
  late Future<List<WarningInformation>> futureWarnings;
  DateTime lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> refresh({Timer? t}) async {
    setState(() {
      futureWarnings = getWarnings();
      lastTick = DateTime.now();
    });
  }

  Future<List<WarningInformation>> getWarnings() async {
    try {
      var response = await http.get(Uri.parse(dotenv.env['hkoWarningsUrl']!));
      if (response.statusCode == 200) {
        var hkoFeed = jsonDecode(response.body);
        return extractWarnings(hkoFeed);
      }
    } catch (e) {
      debugPrint("Failed to fetch data $e");
    }
    return [];
  }

  Future<List<WarningInformation>> dummyWarnings() async {
    List<WarningInformation> warnings = [];
    warnings.addAll(warningStringMap.keys
        .map((key) => WarningInformation(
            key, null, ["This is an example warning"], DateTime.now()))
        .toList());
    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            child: ElevatedButton(
              onPressed: refresh,
              child: buildLastTick(lastTick),
            ),
            onLongPress: () async {
              setState(() {
                futureWarnings = dummyWarnings();
              });
              await Future.delayed(const Duration(seconds: 30));
              refresh();
            },
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: FutureBuilder<List<WarningInformation>>(
            future: futureWarnings,
            initialData: const [],
            builder: (BuildContext context,
                AsyncSnapshot<List<WarningInformation>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return loadingListView();
                default:
                  if (snapshot.hasError) {
                    return hasErrorListView(snapshot);
                  } else {
                    var warnings = snapshot.data ?? [];
                    return warnings.isNotEmpty
                        ? HKOWarningsList(warnings: warnings)
                        : ListView(
                            children: [
                              ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.done),
                                ),
                                title:
                                    const Text("No weather warnings in force"),
                                subtitle: buildLastTick(lastTick),
                              ),
                            ],
                          );
                  }
              }
            },
          ),
        ),
      ),
    );
  }
}
