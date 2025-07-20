import 'package:chilicizz/HKO/typhoon_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../common.dart';

const LatLng hkLatLng = LatLng(22.3453, 114.1372);
const Distance haversineCalc = Distance(calculator: Haversine());
const String mapUserAgent = "app.cyrilng.com";

// This widget displays the track of a typhoon on a Flutter Map
// It shows the past, current, and forecast positions of the typhoon
class HKOTyphoonTrackWidget extends StatelessWidget {
  final TyphoonTrack track;
  final String? mapTileUrl;
  const HKOTyphoonTrackWidget(this.track, this.mapTileUrl, {super.key});

  @override
  Widget build(BuildContext context) {
    double minDistance = double.infinity;
    TyphoonPosition? closestPosition;
    List<Polyline> trackLines = [];
    TyphoonClass lastClass = track.past.first.typhoonClass;
    List<LatLng> allPositions = [];
    List<LatLng> currentSection = [];
    // iterate through track
    for (int i = 0; i < track.past.length; i++) {
      final TyphoonPosition position = track.past[i];
      // update if closer
      final double distKm = haversineCalc.as(LengthUnit.Kilometer, hkLatLng, position.getLatLng());
      if (closestPosition == null || distKm < minDistance) {
        closestPosition = position;
        minDistance = distKm;
      }

      allPositions.add(position.getLatLng());
      currentSection.add(position.getLatLng());
      // when it changes typhoon class
      TyphoonClass currentIteration = position.typhoonClass;
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
        color: track.current.typhoonClass.color,
        strokeWidth: 3,
      ),
    );
    lastClass = track.current.typhoonClass;
    // plot the forecast
    List<TyphoonPosition> dates = [];
    for (int i = 0; i < track.forecast.length; i++) {
      final TyphoonPosition position = track.forecast[i];
      // update if closer
      final double distKm = haversineCalc.as(LengthUnit.Kilometer, hkLatLng, position.getLatLng());
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
      TyphoonClass currentIteration = position.typhoonClass;
      if (currentIteration != lastClass && currentIteration != TyphoonClass.unknownClass) {
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
    // make sure we add the last section
    trackLines.add(
      Polyline(
        points: currentSection,
        color: lastClass.color,
        strokeWidth: 3,
      ),
    );
    // centre the map at the middle of the typhoon and hk
    final LatLng mid = LatLng(
      (hkLatLng.latitude + track.current.getLatLng().latitude) / 2,
      (hkLatLng.longitude + track.current.getLatLng().longitude) / 2,
    );

    // calculate the minimum expected distance
    trackLines.add(
      Polyline(
        points: [hkLatLng, closestPosition!.getLatLng()],
        color: Colors.deepPurple,
        strokeWidth: 1,
        pattern: const StrokePattern.dotted(),
      ),
    );
    // marker
    final Marker closestDistance = Marker(
      height: 30,
      width: 60,
      point: LatLng(
        (hkLatLng.latitude + closestPosition.getLatLng().latitude) / 2,
        (hkLatLng.longitude + closestPosition.getLatLng().longitude) / 2,
      ),
      child: FittedBox(
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
          initialCenter: mid,
          initialZoom: 5.0,
          minZoom: 5.0,
          maxZoom: 10.0,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
          ),
        ),
        children: [
          TileLayer(
            //https://wiki.openstreetmap.org/wiki/Tiles
            urlTemplate: mapTileUrl,
            // subdomains: dotenv.env['mapTileSubDomains']!.split(","),
            userAgentPackageName: mapUserAgent,
            tileProvider: NetworkTileProvider(),
          ),
          PolylineLayer(
            polylines: trackLines,
          ),
          MarkerLayer(
            markers: [
              const Marker(
                width: 30.0,
                height: 30.0,
                point: hkLatLng,
                child: Icon(
                  Icons.location_pin,
                  color: Colors.red,
                ),
              ),
              Marker(
                width: 50.0,
                height: 50.0,
                point: track.current.getLatLng(),
                child: Icon(
                  Icons.storm,
                  color: track.current.typhoonClass.color,
                ),
              ),
              // Draw dates for forecast with an offset
              for (var position in dates)
                Marker(
                  point: position.getLatLng(longitudeOffset: 0.2),
                  child: Text(
                    mapLabelFormat(position.time),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              closestDistance,
            ],
          ),
          const SimpleAttributionWidget(
            source: Text("OpenStreetMap"),
          )
        ],
      ),
    );
  }
}
