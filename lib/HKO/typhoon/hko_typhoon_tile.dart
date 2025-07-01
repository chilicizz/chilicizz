import 'package:chilicizz/HKO/typhoon_model.dart';
import 'package:chilicizz/data/hko_warnings_provider.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../common.dart';
import './hko_typhoon_track.dart';

class TyphoonListTile extends StatelessWidget {
  final Typhoon typhoon;
  final DateTime lastTick;
  final bool initiallyExpanded;

  const TyphoonListTile(
      {super.key, required this.typhoon, required this.lastTick, this.initiallyExpanded = false});

  @override
  Widget build(BuildContext context) {
    var provider = context.watch<HKOWarningsProvider>();
    TyphoonTrack? typhoonTrack = provider.typhoonTracks.getTyphoonTrack(typhoon.id.toString());
    return ListenableBuilder(
      listenable: provider.typhoonTracks,
      builder: (context, child) {
        if (typhoonTrack == null) {
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
        } else {
          final TyphoonTrack track = typhoonTrack;
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
            subtitle:
                Text("${shortDateFormat(track.bulletin.time)} $currentDistance $maxWindSpeed"),
            initiallyExpanded: initiallyExpanded,
            children: [
              SizedBox(
                height: 500,
                child: HKOTyphoonTrackWidget(track),
              ),
              ListTile(
                subtitle: Center(
                  child: Text(
                    "${track.bulletin.provider} - ${track.bulletin.name}",
                  ),
                ),
                title: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  runSpacing: 1,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: typhoonClasses.map((typhoonClass) {
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
        }
      },
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
                      child: HKOTyphoonTrackWidget(snapshot.data!),
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
                        children: typhoonClasses.map((typhoonClass) {
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
