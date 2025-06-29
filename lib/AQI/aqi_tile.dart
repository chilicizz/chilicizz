import 'dart:async';

import 'package:flutter/material.dart';

import '../common.dart';
import 'aqi_model.dart';
import 'forecast_chart.dart';

/// A stateless widget that displays the AQI data for a location as a ListTile
class AQIStatelessListTile extends StatelessWidget {
  final String location;
  final AQIData? data;
  final Function(String) _removeLocationCallback;
  final Function(String, String) _updateLocationCallback;

  const AQIStatelessListTile(
      {super.key,
      required this.location,
      this.data,
      required dynamic Function(String) removeLocationCallback,
      required dynamic Function(String, String) updateLocationCallback})
      : _updateLocationCallback = updateLocationCallback,
        _removeLocationCallback = removeLocationCallback;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return ListTile(
        leading: const FittedBox(child: CircularProgressIndicator()),
        title: Text(location),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: deleteMe,
        ),
      );
    } else {
      return Dismissible(
        key: Key(location),
        direction: DismissDirection.startToEnd,
        onDismissed: (direction) {
          deleteMe();
        },
        confirmDismiss: (DismissDirection direction) async {
          return await confirmDismiss(context);
        },
        background: Container(
          alignment: Alignment.centerLeft,
          color: Colors.red,
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.delete),
          ),
        ),
        child: GestureDetector(
          onLongPress: () {},
          child: ExpansionTile(
            //initiallyExpanded: !isSmallDevice(),
            leading: Tooltip(
              message: data!.level.name,
              child: CircleAvatar(
                backgroundColor: data?.level.color,
                child: Text(
                  "${data?.aqi}",
                  style: const TextStyle(color: Colors.black),
                ),
              ),
            ),
            title: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(isSmallScreen(context) ? data!.getShortCityName() : data!.cityName,
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
            subtitle: buildLastUpdatedText(data?.lastUpdatedTime),
            children: [
              ListTile(
                title: Wrap(
                  alignment: WrapAlignment.spaceEvenly,
                  runSpacing: 1,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: data!.iaqiData.entries.map((entry) {
                    return AQIChip(record: entry.key, value: entry.value);
                  }).toList(),
                ),
              ),
              ListTile(
                title: SizedBox(
                  height: 200,
                  child: ForecastChart(data: data!.iaqiForecast),
                ),
              ),
              ListTile(
                title: Text(data!.level.name),
                subtitle: Text(data!.level.longDescription()),
              ),
              for (Attribution attribution in data!.attributions)
                ListTile(
                  title: Text(attribution.name),
                  subtitle: Text(attribution.url),
                ),
            ],
          ),
        ),
      );
    }
  }

  void deleteMe() {
    _removeLocationCallback(location);
  }

  void updateLocation(String newLocation) {
    if (newLocation != location) {
      _updateLocationCallback(location, newLocation);
    }
  }

  Future<bool?> confirmDismiss(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you wish to delete this item?"),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CANCEL"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("DELETE"),
            ),
          ],
        );
      },
    );
  }
}
