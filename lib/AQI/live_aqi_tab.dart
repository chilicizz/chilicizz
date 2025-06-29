import 'package:chilicizz/AQI/aqi_provider.dart';
import 'package:flutter/material.dart';
import 'aqi_auto_complete.dart';
import 'package:provider/provider.dart';
import './aqi_tile.dart';

class AQITabLoader extends StatefulWidget {
  const AQITabLoader({super.key});

  @override
  State<AQITabLoader> createState() => _AQITabLoaderState();
}

class _AQITabLoaderState extends State<AQITabLoader> {
  bool _displayInput = false;
  @override
  Widget build(BuildContext context) {
    final aqiProvider = Provider.of<AQIProvider>(context, listen: true);
    return ListenableBuilder(
      listenable: aqiProvider.aqiLocations,
      builder: (context, child) {
        debugPrint("loading LiveAQITab with ${aqiProvider.aqiLocations.locations} locations");
        return Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              setState(() {
                _displayInput = true;
              });
            },
            child: const Icon(Icons.add),
          ),
          body: _displayInput
              ? ListTile(
                  title: AQILocationAutocomplete(
                    autofocus: true,
                    selectionCallback: (location) {
                      setState(() {
                        _displayInput = false;
                        aqiProvider.addLocation(location);
                      });
                    },
                  ),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    OutlinedButton(
                      child: const Icon(Icons.cancel_outlined),
                      onPressed: () {
                        setState(() {
                          _displayInput = false;
                        });
                      },
                    ),
                  ]),
                )
              : AQITab(
                  locations: aqiProvider.aqiLocations.locations.toSet(),
                  removeLocationCallback: (location) {
                    setState(() {
                      _displayInput = false;
                      aqiProvider.removeLocation(location);
                    });
                  },
                  updateLocationCallback: (original, updated) {
                    setState(() {
                      _displayInput = false;
                      aqiProvider.updateLocation(original, updated);
                    });
                  },
                  addLocationCallback: (location) {
                    setState(() {
                      _displayInput = false;
                      aqiProvider.addLocation(location);
                    });
                  },
                ),
        );
      },
    );
  }
}

class AQITab extends StatelessWidget {
  final Set<String> locations;
  final Function(String) removeLocationCallback;
  final Function(String, String) updateLocationCallback;
  final Function(String) addLocationCallback;

  const AQITab(
      {super.key,
      required this.locations,
      required this.removeLocationCallback,
      required this.updateLocationCallback,
      required this.addLocationCallback});

  @override
  Widget build(BuildContext context) {
    final aqiProvider = Provider.of<AQIProvider>(context, listen: true);
    return locations.isEmpty
        ? ListTile(
            title: AQILocationAutocomplete(
              autofocus: true,
              selectionCallback: addLocationCallback,
            ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              OutlinedButton(
                child: const Icon(Icons.cancel_outlined),
                onPressed: () {
                  addLocationCallback("");
                },
              ),
            ]),
          )
        : ListenableBuilder(
            listenable: aqiProvider.aqiDataModel,
            builder: (context, child) => ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: locations.length,
              itemBuilder: (context, index) {
                // Get the location and data for the current index
                var locationData = locations.elementAt(index);
                var entry = aqiProvider.aqiDataModel.getAQIData(locationData);
                return AQIStatelessListTile(
                  location: locationData,
                  data: entry,
                  removeLocationCallback: removeLocationCallback,
                  updateLocationCallback: updateLocationCallback,
                );
              },
            ),
          );
  }
}
