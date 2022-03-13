import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'common.dart';
import 'hko_types.dart';

class HKOWarnings extends StatefulWidget {
  const HKOWarnings({Key? key}) : super(key: key);

  @override
  State<HKOWarnings> createState() => _HKOWarningsState();
}

class _HKOWarningsState extends State<HKOWarnings> {
  static const Duration tickInterval = Duration(minutes: 10);

  late Timer timer;
  late List<WarningInformation> warnings;

  DateTime lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    warnings = [];
    timer = Timer.periodic(tickInterval, (Timer t) => _tick(t: t));
    _tick();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _tick({Timer? t}) async {
    var fetchedWarnings = await getWarnings();
    lastTick = DateTime.now();
    setState(() {
      warnings = fetchedWarnings;
    });
  }

  Future<List<WarningInformation>> getWarnings() async {
    try {
      var response = await http.get(Uri.parse(infoUrl));
      if (response.statusCode == 200) {
        var hkoFeed = jsonDecode(response.body);
        return extractWarnings(hkoFeed);
      }
    } catch (e) {
      debugPrint("Failed to fetch data $e");
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            child: ElevatedButton(
              onPressed: _tick,
              child: buildLastTick(lastTick),
            ),
            onLongPress: () async {
              setState(() {
                warnings = [];
                warnings.addAll(warningStringMap.keys
                    .map((key) => WarningInformation(key, null,
                        ["This is an example warning"], DateTime.now()))
                    .toList());
              });
              await Future.delayed(const Duration(seconds: 10));
              _tick();
            },
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _tick,
          child: warnings.isNotEmpty
              ? ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: warnings.length,
                  itemBuilder: (BuildContext context, int index) {
                    var warning = warnings[index];
                    CircleAvatar icon = warning.getCircleAvatar();
                    return ExpansionTile(
                      leading: icon,
                      title: Text(warning.getDescription()),
                      subtitle: buildIssued(warning.updateTime),
                      initiallyExpanded: !isSmallDevice(),
                      children: [
                        for (var s in warning.contents)
                          ListTile(
                            title: Text(s),
                          )
                      ],
                    );
                  },
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ListTile(
                      title: const Text("No active warnings"),
                      subtitle: buildLastTick(lastTick),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}
