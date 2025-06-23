import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../common.dart';
import '../hko_types.dart';
import './hko_warnings_list.dart';

class LiveHKOWarnings extends StatefulWidget {
  const LiveHKOWarnings({super.key});

  @override
  State<LiveHKOWarnings> createState() => _LiveHKOWarningsState();
}

class _LiveHKOWarningsState extends State<LiveHKOWarnings> {
  final socketURL = Uri.parse(dotenv.env['warningsUrl']!);
  List<WarningInformation>? weatherWarnings;
  late WebSocketChannel _channel;
  DateTime lastTick = DateTime.now();
  int _failures = 0;
  bool displayDummy = false;

  void _reconnect() {
    debugPrint("Reconnecting websocket: $_failures");
    if (_failures < 10) {
      Future.delayed(Duration(milliseconds: 100 * _failures), () {
        setState(() {
          debugPrint("Reconnecting websocket times $_failures");
          _channel = WebSocketChannel.connect(socketURL);
        });
      });
      _failures++;
    } else {
      debugPrint("Too many failures, not reconnecting");
    }
  }

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(socketURL);
  }

  @override
  void dispose() {
    debugPrint("Closing websocket");
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (displayDummy) {
      return Scaffold(
        body: Center(
          child: HKOWarningsList(warnings: dummyWarnings()),
        ),
      );
    }

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            child: ElevatedButton(
              onPressed: () {
                triggerRefresh();
              },
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
        child: FutureBuilder(
          future: _channel.ready,
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return const LoadingListView();
              default:
                if (snapshot.hasError) {
                  debugPrint("Error: ${snapshot.error}");
                }
            }
            return StreamBuilder<dynamic>(
              stream: _channel.stream,
              builder: (context, snapshot) {
                switch (snapshot.connectionState) {
                  case ConnectionState.waiting:
                    return const LoadingListView();
                  case ConnectionState.done:
                    debugPrint("HKO socket closed: ${snapshot.error}");
                    _reconnect();
                    return ErrorListView(
                      message: "Connection closed ${_channel.closeReason}",
                    );
                  case ConnectionState.none:
                    _reconnect();
                    return ErrorListView(
                      message: "No connection ${_channel.closeReason}",
                    );
                  default:
                    if (snapshot.hasError) {
                      debugPrint("Error: ${snapshot.error}");
                    }
                }
                _failures = 0; // reset failures
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
            );
          },
        ),
      ),
    );
  }

  void triggerRefresh() {
    _channel.sink.add("Refresh");
  }
}
