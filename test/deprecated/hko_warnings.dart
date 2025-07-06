import 'dart:async';
import 'dart:convert';

import 'package:chilicizz/HKO/typhoon/hko_typhoon_tab.dart';
import 'package:chilicizz/HKO/typhoon/hko_typhoon_track.dart';
import 'package:chilicizz/HKO/typhoon_model.dart';
import 'package:chilicizz/HKO/warnings/hko_warnings_list.dart';
import 'package:chilicizz/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import 'package:chilicizz/HKO/warnings_model.dart';
import 'package:latlong2/latlong.dart';

@Deprecated("Use LiveHKOWarnings instead")
class HKOWarnings extends StatefulWidget {
  const HKOWarnings({super.key});

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
        .map((key) => WarningInformation(key, null, ["This is an example warning"], DateTime.now()))
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
            builder: (BuildContext context, AsyncSnapshot<List<WarningInformation>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return const LoadingListView();
                default:
                  if (snapshot.hasError) {
                    return ErrorListView(message: "${snapshot.error}");
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
                                title: const Text("No weather warnings in force"),
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

@Deprecated("Use TyphoonTab prefer fetching data from HKOWarningsProvider")
class HKOTyphoonTab extends StatefulWidget {
  const HKOTyphoonTab({super.key});

  @override
  State<HKOTyphoonTab> createState() => _HKOTyphoonTabState();
}

class _HKOTyphoonTabState extends State<HKOTyphoonTab> {
  late Future<List<Typhoon>> futureTyphoons;
  DateTime lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    refresh();
  }

  Future<void> refresh({Timer? t}) async {
    setState(() {
      futureTyphoons = TyphoonHttpClient.fetchTyphoonFeed(dotenv.env['hkoTyphoonUrl']!);
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
}

@Deprecated("Prefer to use TyphoonListTile instead")
class TyphoonTile extends StatelessWidget {
  final Typhoon typhoon;
  final DateTime lastTick;
  final bool expanded;

  const TyphoonTile(
      {super.key, required this.typhoon, required this.lastTick, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      initialData: null,
      future: typhoon.getTyphoonTrack(),
      builder: (BuildContext context, AsyncSnapshot<TyphoonTrack?> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return ListTile(
              leading: const CircularProgressIndicator(),
              title: FittedBox(
                alignment: Alignment.centerLeft,
                fit: BoxFit.scaleDown,
                child: Text(
                  "${typhoon.englishName} (${typhoon.chineseName})",
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              subtitle: buildLastTick(lastTick),
            );
          default:
            if (snapshot.hasError) {
              return ErrorListView(message: "${snapshot.error}");
            } else {
              if (snapshot.data != null) {
                final TyphoonTrack track = snapshot.data!;
                final double distKm =
                    haversineCalc.as(LengthUnit.Kilometer, hkLatLng, track.current.getLatLng());
                final String currentDistance = !distKm.isNaN ? '| distance $distKm km' : "";
                final String maxWindSpeed = !track.current.maximumWind!.isNaN
                    ? '| max winds up to ${track.current.maximumWind} km/h'
                    : "";
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).focusColor,
                    child: Icon(
                      Icons.storm,
                      color: track.current.typhoonClass.color,
                    ),
                  ),
                  title: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${track.current.intensity} ${typhoon.englishName} (${typhoon.chineseName})",
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                  subtitle: Text(
                      "${shortDateFormat(track.bulletin.time)} $currentDistance $maxWindSpeed"),
                  initiallyExpanded: expanded,
                  children: [
                    SizedBox(
                      height: 500,
                      child: HKOTyphoonTrackWidget(snapshot.data!, dotenv.env['mapTileUrl']),
                    ),
                    ListTile(
                      subtitle: Center(
                        child: Text(
                          "${snapshot.data!.bulletin.provider} - ${snapshot.data!.bulletin.name}",
                        ),
                      ),
                      title: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        runSpacing: 1,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: TyphoonClass.typhoonClasses.map((typhoonClass) {
                          return Chip(
                            label: Tooltip(
                              message:
                                  "Maximum winds ${typhoonClass.minWind}${typhoonClass.maxWind != double.maxFinite ? "-${typhoonClass.maxWind}" : "+"} km/h",
                              child: !isSmallScreen(context)
                                  ? Text(
                                      "${typhoonClass.name} ${typhoonClass.minWind}${typhoonClass.maxWind != double.maxFinite ? "-${typhoonClass.maxWind}" : "+"} km/h",
                                    )
                                  : Text(typhoonClass.name),
                            ),
                            avatar: CircleAvatar(
                              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                              child: Icon(Icons.storm, color: typhoonClass.color),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                );
              } else {
                debugPrint(snapshot.error?.toString());
                return ListTile(
                  leading: Tooltip(
                    message: "Failed to load typhoon track data: ${snapshot.error?.toString()}",
                    child: const CircleAvatar(
                      child: Icon(Icons.error_outline),
                    ),
                  ),
                  title: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "${typhoon.englishName} (${typhoon.chineseName})",
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  subtitle: buildLastTick(lastTick),
                );
              }
            }
        }
      },
    );
  }
}
