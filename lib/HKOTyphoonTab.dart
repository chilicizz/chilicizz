import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'common.dart';
import 'dummyTyphoon.dart';
import 'hko_types.dart';

class HKOTyphoonTab extends StatefulWidget {
  const HKOTyphoonTab({Key? key}) : super(key: key);

  @override
  State<HKOTyphoonTab> createState() => _HKOTyphoonTabState();
}

class _HKOTyphoonTabState extends State<HKOTyphoonTab> {
  static const Duration tickInterval = Duration(minutes: 10);

  late Timer timer;
  late List<Typhoon> typhoons;

  DateTime lastTick = DateTime.now();

  @override
  void initState() {
    super.initState();
    typhoons = [];
    timer = Timer.periodic(tickInterval, (Timer t) => _tick(t: t));
    _tick();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _tick({Timer? t}) async {
    try {
      var fetchedTyphoons = await fetchTyphoonFeed();
      lastTick = DateTime.now();
      setState(() {
        typhoons = fetchedTyphoons;
      });
    } catch (e) {
      lastTick = DateTime.now();
      setState(() {
        typhoons = [
          Typhoon(
              id: -1,
              chineseName: '$e',
              englishName: "Failed to fetch typhoon data",
              url: "")
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ElevatedButton(
            onPressed: _tick,
            child: buildLastTick(lastTick),
            onLongPress: () {
              setState(() {
                typhoons.add(dummyTyphoon());
              });
            },
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _tick,
          child: typhoons.isNotEmpty
              ? ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: typhoons.length,
                  itemBuilder: (BuildContext context, int index) {
                    var typhoon = typhoons[index];
                    return FutureBuilder(
                      initialData: null,
                      future: typhoon.getTyphoonTrack(),
                      builder: (BuildContext context,
                          AsyncSnapshot<TyphoonTrack?> snapshot) {
                        switch (snapshot.connectionState) {
                          case ConnectionState.waiting:
                            return ListTile(
                              trailing: const CircularProgressIndicator(),
                              title: FittedBox(
                                alignment: Alignment.centerLeft,
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    "${typhoon.englishName} (${typhoon.chineseName})",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium),
                              ),
                              subtitle: buildLastTick(lastTick),
                            );
                          default:
                            if (snapshot.hasError) {
                              return Text(
                                  "Error: ${snapshot.error.toString()}");
                            } else {
                              if (snapshot.data != null) {
                                TyphoonTrack track = snapshot.data!;
                                return ExpansionTile(
                                  leading: CircleAvatar(
                                    child: const Icon(Icons.storm),
                                    backgroundColor:
                                        track.current.getTyphoonClass().color,
                                  ),
                                  title: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                        "${track.current.intensity} ${typhoon.englishName} (${typhoon.chineseName})",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                  ),
                                  subtitle: Text(
                                      "${shortDateFormat(track.bulletin.time)} ${!track.current.maximumWind!.isNaN ? '${track.current.maximumWind} km/h' : ""}"),
                                  initiallyExpanded: !isSmallDevice(),
                                  children: [
                                    SizedBox(
                                      height: 500,
                                      child:
                                          HKOTyphoonTrackWidget(snapshot.data!),
                                    ),
                                  ],
                                );
                              } else {
                                return ListTile(
                                  trailing: const Tooltip(
                                    child: Icon(Icons.error),
                                    message:
                                        "Failed to load typhoon track data",
                                  ),
                                  title: FittedBox(
                                    alignment: Alignment.centerLeft,
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                        "${typhoon.englishName} (${typhoon.chineseName})",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium),
                                  ),
                                  subtitle: buildLastTick(lastTick),
                                );
                              }
                            }
                        }
                      },
                    );
                  },
                )
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    ListTile(
                      title: const Text("No current typhoon warnings"),
                      subtitle: buildLastTick(lastTick),
                    )
                  ],
                ),
        ),
      ),
    );
  }
}

class HKOTyphoonTrackWidget extends StatelessWidget {
  final TyphoonTrack track;
  static final LatLng hkLatitudeLongitude = LatLng(22.3453, 114.1372);

  const HKOTyphoonTrackWidget(this.track, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Polyline> trackLines = [];
    TyphoonClass lastClass = track.past.first.getTyphoonClass();
    List<LatLng> allPositions = [];
    List<LatLng> currentSection = [];
    // iterate through track
    for (int i = 0; i < track.past.length; i++) {
      TyphoonPosition position = track.past[i];
      allPositions.add(position.getLatLng());
      currentSection.add(position.getLatLng());
      // when it changes typhoon class
      TyphoonClass currentIteration = position.getTyphoonClass();
      if (currentIteration != lastClass) {
        trackLines.add(
          Polyline(
            points: currentSection,
            color: lastClass.color,
            strokeWidth: 3,
          ),
        );
        currentSection = [position.getLatLng()];
        // update
        lastClass = currentIteration;
      }
    }
    // make sure we add the last bit
    trackLines.add(
      Polyline(
        points: currentSection,
        color: track.past.last.getTyphoonClass().color,
        strokeWidth: 3,
      ),
    );
    // middle of the typhoon and hk
    LatLng mid = LatLng(
        (hkLatitudeLongitude.latitude + track.current.getLatLng().latitude) / 2,
        (hkLatitudeLongitude.longitude + track.current.getLatLng().longitude) /
            2);
    return SizedBox(
      height: 500,
      child: FlutterMap(
        options: MapOptions(
          center: mid,
          zoom: 5.0,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            //"http://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
            attributionBuilder: (_) {
              return Text("© OpenStreetMap / ${track.bulletin.provider}");
            },
          ),
          PolylineLayerOptions(
            polylineCulling: true,
            polylines: trackLines,
          ),
          MarkerLayerOptions(
            markers: [
              Marker(
                width: 20.0,
                height: 20.0,
                point: hkLatitudeLongitude,
                builder: (ctx) =>
                    const Icon(Icons.location_pin, color: Colors.red),
              ),
              Marker(
                width: 20.0,
                height: 20.0,
                point: track.current.getLatLng(),
                builder: (ctx) => Icon(Icons.storm,
                    color: track.current.getTyphoonClass().color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
