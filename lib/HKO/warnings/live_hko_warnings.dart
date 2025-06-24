import 'package:chilicizz/HKO/warnings/hko_warnings_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common.dart';
import '../hko_types.dart';
import './hko_warnings_list.dart';

class LiveHKOWarnings extends StatefulWidget {
  const LiveHKOWarnings({super.key});

  @override
  State<LiveHKOWarnings> createState() => _LiveHKOWarningsState();
}

class _LiveHKOWarningsState extends State<LiveHKOWarnings> {
  bool displayDummy = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (displayDummy) {
      return Scaffold(
        body: Center(
          child: HKOWarningsList(warnings: dummyWarnings()),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              displayDummy = false;
            });
          },
          child: const Icon(Icons.navigate_before),
        ),
      );
    }

    var provider = context.watch<HKOWarningsProvider>();
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            child: ElevatedButton(
              onPressed: () {
                provider.triggerRefresh();
              },
              child: buildLastTick(provider.lastTick),
            ),
            onLongPress: () async {
              setState(() {
                displayDummy = true;
              });
            },
          ),
        ],
      ),
      body: Center(
        child: ValueListenableBuilder<List<WarningInformation>>(
          valueListenable: provider.hkoWeatherWarnings,
          builder: (context, warnings, child) {
            if (warnings.isEmpty) {
              return NoWarningsList(lastTick: provider.lastTick);
            } else {
              return HKOWarningsList(warnings: warnings);
            }
          },
        ),
      ),
    );
  }
}
