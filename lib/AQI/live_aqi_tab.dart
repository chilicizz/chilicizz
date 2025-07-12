import 'package:chilicizz/AQI/geolocator.dart';
import 'package:chilicizz/data/aqi_provider.dart';
import 'package:flutter/material.dart';
import 'aqi_auto_complete.dart';
import 'package:provider/provider.dart';
import './aqi_tile.dart';

// This tab displays the live AQI data for multiple locations.
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
        var locationSet = aqiProvider.aqiLocations.locations.toSet();
        debugPrint("loading AQITab with $locationSet locations");
        bool showAutoComplete = _displayInput || locationSet.isEmpty;
        return Scaffold(
          floatingActionButton: !showAutoComplete
              ? FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _displayInput = true;
                    });
                  },
                  child: const Icon(Icons.add),
                )
              : FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      _displayInput = false;
                    });
                  },
                  child: const Icon(Icons.cancel_outlined),
                ),
          body: (showAutoComplete)
              ? ListView(children: [
                  ListTile(
                    title: AQILocationAutocomplete(
                      autofocus: true,
                      selectionCallback: (location) {
                        setState(() {
                          _displayInput = false;
                          aqiProvider.addLocation(location);
                          final snackBar = SnackBar(content: Text('Added new location: $location'));
                          ScaffoldMessenger.of(context).showSnackBar(snackBar);
                        });
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.cancel_outlined),
                      onPressed: () {
                        setState(() {
                          _displayInput = false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: Text("Find your current location (requires location permission)"),
                    leading: IconButton(
                      onPressed: () {
                        determinePosition().then((position) {
                          aqiProvider
                              .queryLocationLatLng(position.latitude, position.longitude)
                              .then((location) {
                            setState(() {
                              _displayInput = false;
                              aqiProvider.addLocation(location.url);
                              final snackBar =
                                  SnackBar(content: Text('Added new location: ${location.url}'));
                              ScaffoldMessenger.of(context).showSnackBar(snackBar);
                            });
                          });
                        }).onError((error, stackTrace) {
                          if (context.mounted) {
                            final snackBar = SnackBar(
                                content: Text('Error fetching location: ${error.toString()}'));
                            ScaffoldMessenger.of(context).showSnackBar(snackBar);
                          }
                        });
                      },
                      icon: Icon(Icons.my_location_outlined),
                    ),
                  )
                ])
              : AQIListView(
                  locations: locationSet,
                  removeLocationCallback: (location) {
                    setState(() {
                      _displayInput = false;
                      aqiProvider.removeLocation(location);
                      final snackBar = SnackBar(content: Text('Removed location: $location'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    });
                  },
                  updateLocationCallback: (original, updated) {
                    setState(() {
                      _displayInput = false;
                      aqiProvider.updateLocation(original, updated);
                      final snackBar =
                          SnackBar(content: Text('Updated location: $original to $updated'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    });
                  },
                  addLocationCallback: (location) {
                    setState(() {
                      _displayInput = false;
                      aqiProvider.addLocation(location);
                      final snackBar = SnackBar(content: Text('Added new location: $location'));
                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    });
                  },
                ),
        );
      },
    );
  }
}

class AQIListView extends StatelessWidget {
  final Set<String> locations;
  final Function(String) removeLocationCallback;
  final Function(String, String) updateLocationCallback;
  final Function(String) addLocationCallback;

  const AQIListView(
      {super.key,
      required this.locations,
      required this.removeLocationCallback,
      required this.updateLocationCallback,
      required this.addLocationCallback});

  @override
  Widget build(BuildContext context) {
    final aqiProvider = Provider.of<AQIProvider>(context, listen: true);
    return ListenableBuilder(
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
