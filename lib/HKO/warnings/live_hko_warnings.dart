import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../common.dart';
import '../hko_types.dart';

class LiveHKOWarnings extends StatefulWidget {
  const LiveHKOWarnings({Key? key}) : super(key: key);

  @override
  State<LiveHKOWarnings> createState() => _LiveHKOWarningsState();
}

class _LiveHKOWarningsState extends State<LiveHKOWarnings> {
  List<WarningInformation>? weatherWarnings;
  final socketURL = Uri.parse(dotenv.env['warningsUrl']!);

  late WebSocketChannel _channel;
  DateTime lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _channel = WebSocketChannel.connect(socketURL);
    _channel.stream.listen((event) {
      if (mounted) {
        var hkoFeed = jsonDecode(event);
        setState(() {
          lastTick = DateTime.now();
          debugPrint("Updated HKO Warnings: $lastTick");
          weatherWarnings = extractWarnings(hkoFeed);
        });
      }
    }, onError: (e) {
      if (mounted) {
        debugPrint("HKO stream failed $e");
        _connect();
      }
    }, onDone: () {
      if (mounted) {
        debugPrint("HKO stream closed");
        _connect();
      }
    });
  }


  @override
  void deactivate() {
    super.deactivate();
    debugPrint("Deactivate state");
  }

  @override
  void dispose() {
    debugPrint("Closing websocket");
    _channel.sink.close();
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
                weatherWarnings = dummyWarnings();
              });
            },
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: () {
            return Future(() => triggerRefresh());
          },
          child: weatherWarnings == null
              ? const LoadingListView()
              : weatherWarnings!.isNotEmpty
                  ? HKOWarningsList(warnings: weatherWarnings!)
                  : NoWarningsList(lastTick: lastTick),
        ),
      ),
    );
  }

  void triggerRefresh() {
    _channel.sink.add("Refresh");
  }

  @override
  void activate() {
    super.activate();
    //_connect();
    debugPrint("Activate state");
  }
}

class NoWarningsList extends StatelessWidget {
  const NoWarningsList({
    super.key,
    required this.lastTick,
  });

  final DateTime lastTick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.done),
          ),
          title: const Text("No weather warnings in force"),
          subtitle: buildLastTick(lastTick),
        ),
      ],
    );
  }
}

class HKOWarningsList extends StatelessWidget {
  const HKOWarningsList({
    super.key,
    required this.warnings,
  });

  final List<WarningInformation> warnings;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: warnings.length,
      itemBuilder: (BuildContext context, int index) {
        var warning = warnings[index];
        CircleAvatar icon = warning.getCircleAvatar();
        return ExpansionTile(
          leading: icon,
          title: Text(warning.getDescription()),
          subtitle: buildIssued(warning.updateTime),
          initiallyExpanded: !isSmallDevice() || warnings.length == 1,
          children: [
            for (var s in warning.contents)
              ListTile(
                title: Text(s),
              )
          ],
        );
      },
    );
  }
}
