import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../common.dart';
import 'dummy_typhoon.dart';
import 'hko_types.dart';

final LatLng hkLatLng = LatLng(22.3453, 114.1372);
const Distance haversineCalc = Distance(calculator: Haversine());

class HKOTyphoonTab extends StatefulWidget {
  const HKOTyphoonTab({Key? key}) : super(key: key);

  @override
  State<HKOTyphoonTab> createState() => _HKOTyphoonTabState();
}

class _HKOTyphoonTabState extends State<HKOTyphoonTab> {
  static const Duration tickInterval = Duration(minutes: 10);

  late Timer timer;
  late Future<List<Typhoon>> futureTyphoons;
  DateTime lastTick = DateTime.now();

  Future<List<Typhoon>> dummyTyphoonList() async {
    return [dummyTyphoon()];
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(tickInterval, (Timer t) => _tick(t: t));
    _tick();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _tick({Timer? t}) async {
    setState(() {
      futureTyphoons = fetchTyphoonFeed();
      lastTick = DateTime.now();
    });
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
                futureTyphoons = dummyTyphoonList();
              });
            },
          ),
        ],
      ),
      body: Center(
        child: RefreshIndicator(
          onRefresh: _tick,
          child: FutureBuilder(
            future: futureTyphoons,
            builder:
                (BuildContext context, AsyncSnapshot<List<Typhoon>> snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                  return loadingListView();
                default:
                  List<Typhoon> typhoons;
                  if (snapshot.hasError) {
                    return hasErrorListView(snapshot);
                  } else {
                    typhoons = snapshot.data ?? [];
                  }
                  return typhoons.isNotEmpty
                      ? ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: typhoons.length,
                          itemBuilder: (BuildContext context, int index) {
                            var typhoon = typhoons[index];
                            return buildTyphoonTile(typhoon);
                          },
                        )
                      : buildNoCurrentTyphoons();
              }
            },
          ),
        ),
      ),
    );
  }

  ListView buildNoCurrentTyphoons() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        ListTile(
          leading: const CircleAvatar(
            child: Icon(Icons.done),
          ),
          title: const Text("No active typhoon warnings"),
          subtitle: buildLastTick(lastTick),
        )
      ],
    );
  }

  FutureBuilder<TyphoonTrack?> buildTyphoonTile(Typhoon typhoon) {
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
                child: Text("${typhoon.englishName} (${typhoon.chineseName})",
                    style: Theme.of(context).textTheme.headlineMedium),
              ),
              subtitle: buildLastTick(lastTick),
            );
          default:
            if (snapshot.hasError) {
              return hasErrorListView(snapshot);
            } else {
              if (snapshot.data != null) {
                final TyphoonTrack track = snapshot.data!;
                final double distKm = haversineCalc.as(
                    LengthUnit.Kilometer, hkLatLng, track.current.getLatLng());
                final String currentDistance =
                    !distKm.isNaN ? '($distKm km)' : "";
                final String maxWindSpeed = !track.current.maximumWind!.isNaN
                    ? '<${track.current.maximumWind} km/h'
                    : "";
                return ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: track.current.getTyphoonClass().color,
                    child: const Icon(Icons.storm, color: Colors.black),
                  ),
                  title: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                        "${track.current.intensity} ${typhoon.englishName} (${typhoon.chineseName})",
                        style: Theme.of(context).textTheme.headlineMedium),
                  ),
                  subtitle: Text(
                      "${shortDateFormat(track.bulletin.time)} $currentDistance $maxWindSpeed"),
                  initiallyExpanded: !isSmallDevice(),
                  children: [
                    SizedBox(
                      height: 500,
                      child: HKOTyphoonTrackWidget(snapshot.data!),
                    ),
                  ],
                );
              } else {
                debugPrint(snapshot.error?.toString());
                return ListTile(
                  leading: Tooltip(
                    message:
                        "Failed to load typhoon track data: ${snapshot.error?.toString()}",
                    child: const CircleAvatar(
                      child: Icon(Icons.error_outline),
                    ),
                  ),
                  title: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                        "${typhoon.englishName} (${typhoon.chineseName})",
                        style: Theme.of(context).textTheme.headlineMedium),
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

class HKOTyphoonTrackWidget extends StatelessWidget {
  final TyphoonTrack track;

  const HKOTyphoonTrackWidget(this.track, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double minDistance = double.infinity;
    TyphoonPosition? closestPosition;
    List<Polyline> trackLines = [];
    TyphoonClass lastClass = track.past.first.getTyphoonClass();
    List<LatLng> allPositions = [];
    List<LatLng> currentSection = [];
    // iterate through track
    for (int i = 0; i < track.past.length; i++) {
      final TyphoonPosition position = track.past[i];
      // update if closer
      final double distKm = haversineCalc.as(
          LengthUnit.Kilometer, hkLatLng, position.getLatLng());
      if (closestPosition == null || distKm < minDistance) {
        closestPosition = position;
        minDistance = distKm;
      }

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
    // make sure we add the currentSection
    trackLines.add(
      Polyline(
        points: currentSection,
        color: track.current.getTyphoonClass().color,
        strokeWidth: 3,
      ),
    );
    lastClass = track.current.getTyphoonClass();
    // plot the forecast
    List<TyphoonPosition> dates = [];
    for (int i = 0; i < track.forecast.length; i++) {
      final TyphoonPosition position = track.forecast[i];
      // update if closer
      final double distKm = haversineCalc.as(
          LengthUnit.Kilometer, hkLatLng, position.getLatLng());
      if (closestPosition == null || distKm < minDistance) {
        closestPosition = position;
        minDistance = distKm;
      }
      if (position.time != null) {
        dates.add(position);
      }

      allPositions.add(position.getLatLng());
      currentSection.add(position.getLatLng());
      // when it changes typhoon class
      TyphoonClass currentIteration = position.getTyphoonClass();
      if (currentIteration != lastClass && currentIteration != unknownClass) {
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
    // centre the map at the middle of the typhoon and hk
    final LatLng mid = LatLng(
        (hkLatLng.latitude + track.current.getLatLng().latitude) / 2,
        (hkLatLng.longitude + track.current.getLatLng().longitude) / 2);

    // calculate the minimum expected distance
    trackLines.add(Polyline(
      points: [hkLatLng, closestPosition!.getLatLng()],
      color: Colors.deepPurple,
      strokeWidth: 1,
      isDotted: false,
    ));
    // marker
    final Marker closestDistance = Marker(
      height: 30,
      width: 60,
      point: LatLng(
          (hkLatLng.latitude + closestPosition.getLatLng().latitude) / 2,
          (hkLatLng.longitude + closestPosition.getLatLng().longitude) / 2),
      builder: (ctx) => FittedBox(
        child: Text(
          "$minDistance km",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
    );
    return SizedBox(
      height: 500,
      child: FlutterMap(
        options: MapOptions(
          center: mid,
          zoom: 5.0,
          minZoom: 5.0,
          maxZoom: 10.0,
          interactiveFlags: InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom,
        ),
        nonRotatedChildren: [
          AttributionWidget.defaultWidget(
            source: "OpenStreetMap / ${track.bulletin.provider}",
          )
        ],
        layers: [
          TileLayerOptions(
            //https://wiki.openstreetmap.org/wiki/Tiles
            urlTemplate:
                //"https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                "https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png",
            subdomains: ['a', 'b'],
          ),
          PolylineLayerOptions(
            polylineCulling: true,
            polylines: trackLines,
          ),
          MarkerLayerOptions(
            markers: [
              Marker(
                width: 30.0,
                height: 30.0,
                point: hkLatLng,
                builder: (ctx) =>
                    const Icon(Icons.location_pin, color: Colors.red),
              ),
              Marker(
                width: 50.0,
                height: 50.0,
                point: track.current.getLatLng(),
                builder: (ctx) => Icon(Icons.storm,
                    color: track.current.getTyphoonClass().color),
              ),
              // Draw dates for forecast
              for (var position in dates)
                Marker(
                  point: position.getLatLng(longitudeOffset: 0.2),
                  builder: (ctx) => Text(
                    dayMonthFormat(position.time),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              closestDistance,
            ],
          ),
        ],
      ),
    );
  }
}
