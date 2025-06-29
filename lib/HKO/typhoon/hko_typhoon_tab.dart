import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../common.dart';
import 'dummy_typhoon.dart';
import '../hko_types.dart';
import 'hko_typhoon_tile.dart';

class HKOTyphoonTab extends StatefulWidget {
  const HKOTyphoonTab({super.key});

  @override
  State<HKOTyphoonTab> createState() => _HKOTyphoonTabState();
}

class _HKOTyphoonTabState extends State<HKOTyphoonTab> {
  late Future<List<Typhoon>> futureTyphoons;
  DateTime lastTick = DateTime.now();

  Future<List<Typhoon>> dummyTyphoonList() async {
    return [dummyTyphoon()];
  }

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
      futureTyphoons = _fetchTyphoonFeed(dotenv.env['hkoTyphoonUrl']!);
      lastTick = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: RefreshIndicator(
          onRefresh: refresh,
          child: FutureBuilder(
            future: futureTyphoons,
            builder: (BuildContext context, AsyncSnapshot<List<Typhoon>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const LoadingListView();
                default:
                  List<Typhoon> typhoons;
                  if (snapshot.hasError) {
                    return ErrorListView(message: "${snapshot.error}");
                  } else {
                    typhoons = snapshot.data ?? [];
                  }
                  return typhoons.isNotEmpty
                      ? TyphoonsListView(typhoons: typhoons, lastTick: lastTick)
                      : NoTyphoonsListView(lastTick: lastTick);
              }
            },
          ),
        ),
      ),
    );
  }

  Future<List<Typhoon>> _fetchTyphoonFeed(String hkoTyphoonUrl) async {
    try {
      var path = Uri.parse(hkoTyphoonUrl);
      var response = await http.get(path, headers: {
        HttpHeaders.contentTypeHeader: 'application/xml',
        HttpHeaders.accessControlAllowOriginHeader: '*',
        HttpHeaders.accessControlAllowMethodsHeader: 'GET,HEAD,POST,OPTIONS',
        HttpHeaders.accessControlAllowHeadersHeader: '*',
      });
      if (response.statusCode == 200) {
        String xmlString = const Utf8Decoder().convert(response.bodyBytes);
        var typhoonFeed = parseTyphoonFeed(xmlString);
        return typhoonFeed;
      } else {
        throw Exception('Feed returned ${response.body}');
      }
    } catch (e) {
      debugPrint("Failed to fetch typhoon data $e");
      rethrow;
    }
  }
}

class TyphoonsListView extends StatelessWidget {
  const TyphoonsListView({
    super.key,
    required this.typhoons,
    required this.lastTick,
  });

  final List<Typhoon> typhoons;
  final DateTime lastTick;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: typhoons.length,
      itemBuilder: (BuildContext context, int index) {
        return TyphoonTile(
          typhoon: typhoons[index],
          lastTick: lastTick,
          expanded: typhoons.length == 1,
        );
      },
    );
  }
}

class NoTyphoonsListView extends StatelessWidget {
  const NoTyphoonsListView({
    super.key,
    required this.lastTick,
  });

  final DateTime lastTick;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ExpansionTile(
          leading: const CircleAvatar(
            child: Icon(Icons.done),
          ),
          title: const Text("No active typhoon warnings"),
          subtitle: buildLastTick(lastTick),
          children: const [
            ListTile(
              title: Text(
                  "Tropical cyclone track information data provided by Hong Kong Observatory and "
                  "is expected to be updated when a tropical cyclone forms within or enters the area bounded by 7-36N and 100-140E"),
              subtitle: Text(""),
            ),
          ],
        ),
      ],
    );
  }
}
