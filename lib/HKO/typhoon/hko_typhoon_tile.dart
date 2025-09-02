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
    return ListenableBuilder(
      listenable: provider.typhoonTracks,
      builder: (context, child) {
        TyphoonTrack? typhoonTrack = provider.typhoonTracks.getTyphoonTrack("${typhoon.id}");
        if (typhoonTrack == null) {
          // provider.refreshTyphoonTrack("${typhoon.id}");
          return ListTile(
            leading: const CircularProgressIndicator(),
            title: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                "${typhoon.englishName} (${typhoon.chineseName})",
                // style: Theme.of(context).textTheme.headlineSmall,
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
          final String typhoonTitle =
              "${track.current.intensity} ${typhoon.englishName} (${typhoon.chineseName})";
          final String subtitle =
              "${shortDateFormat(track.bulletin.time)} $currentDistance $maxWindSpeed";
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
                typhoonTitle,
                // style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            subtitle: Text(subtitle),
            initiallyExpanded: initiallyExpanded,
            children: [
              SizedBox(
                height: 500,
                child: HKOTyphoonTrackWidget(track, provider.mapTileUrl),
              ),
              ListTile(
                title: TyphoonClassLegendWrap(),
                subtitle: Center(
                  child: Text(
                    "${track.bulletin.provider} - ${track.bulletin.name}",
                  ),
                ),
              ),
            ],
          );
        }
      },
    );
  }
}

class TyphoonClassLegendWrap extends StatelessWidget {
  const TyphoonClassLegendWrap({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      runSpacing: 1,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: TyphoonClass.typhoonClasses.map((typhoonClass) {
        final String windRange =
            "${typhoonClass.minWind}${typhoonClass.maxWind != double.maxFinite ? "-${typhoonClass.maxWind}" : "+"} km/h";
        final tooltip = "Maximum winds $windRange";
        final String label = "${typhoonClass.name} $windRange";
        return Chip(
          label: Tooltip(
            message: tooltip,
            child: !isSmallScreen(context) ? Text(label) : Text(typhoonClass.name),
          ),
          avatar: CircleAvatar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            child: Icon(Icons.storm, color: typhoonClass.color),
          ),
        );
      }).toList(),
    );
  }
}

class NoTyphoonsTile extends StatelessWidget {
  const NoTyphoonsTile({
    super.key,
    required this.lastTick,
  });

  final DateTime lastTick;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
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
    );
  }
}
