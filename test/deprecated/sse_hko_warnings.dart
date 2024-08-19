import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sse/client/sse_client.dart';

import 'package:chilicizz/common.dart';
import 'package:chilicizz/HKO/hko_types.dart';
import 'package:chilicizz/HKO/warnings/live_hko_warnings.dart';

/// SSE Does not currently seem to be working for Web
/// Connects OK but no data is returned
class SSEHKOWarnings extends StatefulWidget {
  const SSEHKOWarnings({super.key});

  @override
  State<SSEHKOWarnings> createState() => _SSEHKOWarningsState();
}

class _SSEHKOWarningsState extends State<SSEHKOWarnings> {
  List<WarningInformation>? weatherWarnings;
  DateTime lastTick = DateTime.now();
  bool displayDummy = false;
  late SseClient sseClient;

  @override
  void initState() {
    super.initState();
    sseClient = SseClient("http://localhost:8080/warnings_sse");
  }

  @override
  void dispose() {
    debugPrint("Closing SSEHKOWarnings");
    sseClient.close();
    super.dispose();
  }

  List<WarningInformation> dummyWarnings() {
    List<WarningInformation> warnings = [];
    warnings.addAll(warningStringMap.keys
        .map((key) => WarningInformation(
            key, null, ["This is an example warning"], DateTime.now()))
        .toList());
    return warnings;
  }

  @override
  Widget build(BuildContext context) {
    if (displayDummy) {
      return Scaffold(
        body: Center(child: HKOWarningsList(warnings: dummyWarnings())),
      );
    }

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            child: ElevatedButton(
              onPressed: () {},
              child: buildLastTick(lastTick),
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
        child: StreamBuilder<dynamic>(
          stream: sseClient.stream,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const LoadingListView();
              case ConnectionState.done:
                debugPrint("HKO socket closed: ${snapshot.error.toString()}");
                return ErrorListView(
                    message: "Connection closed ${snapshot.error.toString()}");
              case ConnectionState.none:
                return ErrorListView(
                    message: "No connection ${snapshot.error.toString()}");
              default:
                if (snapshot.hasError) {
                  debugPrint("Error: ${snapshot.error.toString()}");
                }
            }
            if (snapshot.hasData) {
              var hkoFeed = jsonDecode(snapshot.data);
              lastTick = DateTime.now();
              debugPrint("Updated HKO Warnings: $lastTick");
              weatherWarnings = extractWarnings(hkoFeed);
              return weatherWarnings!.isNotEmpty
                  ? HKOWarningsList(warnings: weatherWarnings!)
                  : NoWarningsList(lastTick: lastTick);
            } else {
              return const LoadingListView();
            }
          },
        ),
      ),
    );
  }
}
