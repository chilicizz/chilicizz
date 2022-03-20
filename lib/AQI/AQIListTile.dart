import 'dart:async';

import 'package:flutter/material.dart';

import '../common.dart';
import 'AQIAutoComplete.dart';
import 'AQICommon.dart';
import 'ForecastChart.dart';

class AQIListTile extends StatefulWidget {
  final String location;
  final Function(String) removeLocationCallback;
  final Function(String, String) updateLocationCallback;

  AQIListTile(
      {Key? key,
      required this.location,
      required this.removeLocationCallback,
      required this.updateLocationCallback})
      : super(key: key);

  @override
  State<AQIListTile> createState() => _AQIListTileState();

  void deleteMe() {
    removeLocationCallback(location);
  }

  void updateLocation(String newLocation) {
    if (newLocation != location) {
      updateLocationCallback(location, newLocation);
    }
  }
}

class _AQIListTileState extends State<AQIListTile> {
  static const Duration tickTime = Duration(minutes: 10);
  late Timer timer;

  late TextEditingController textController;
  bool editingLocation = false;

  AQIData? data;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return ListTile(
        leading: const FittedBox(child: CircularProgressIndicator()),
        title: Text(widget.location),
        trailing: IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () {
            widget.deleteMe();
          },
        ),
      );
    } else {
      return editingLocation
          ? ListTile(
              leading: IconButton(
                icon: const Icon(Icons.cancel),
                onPressed: () {
                  setState(() {
                    editingLocation = false;
                  });
                },
              ),
              title: AQILocationAutocomplete(
                  selectionCallback: (value) => {
                        widget.updateLocation(value),
                        editingLocation = false,
                      },
                  initialValue: textController.value.text,
                  autofocus: editingLocation),
              trailing: ElevatedButton(
                onPressed: () {
                  setState(() {
                    widget.updateLocation(textController.value.text);
                    editingLocation = false;
                  });
                },
                child: const Icon(Icons.check),
              ),
            )
          : Dismissible(
              key: Key(widget.location),
              direction: DismissDirection.startToEnd,
              onDismissed: (direction) {
                widget.deleteMe();
              },
              confirmDismiss: (DismissDirection direction) async {
                return await confirmDismiss(context);
              },
              background: Container(
                alignment: Alignment.centerLeft,
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.delete),
                ),
                color: Colors.red,
              ),
              child: GestureDetector(
                onLongPress: () {
                  setState(() {
                    editingLocation = true;
                  });
                },
                child: ExpansionTile(
                  leading: Tooltip(
                    message: data!.getLevel().name,
                    child: CircleAvatar(
                      child: Text("${data?.aqi}"),
                      backgroundColor: data?.getLevel().color,
                    ),
                  ),
                  title: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                        isSmallDevice()
                            ? data!.getShortCityName()
                            : data!.cityName,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  subtitle: buildLastUpdatedText(data?.lastUpdatedTime),
                  initiallyExpanded: !isSmallDevice(),
                  children: [
                    ListTile(
                      title: Wrap(
                        alignment: WrapAlignment.spaceEvenly,
                        runSpacing: 1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: data!.iaqiData.entries.map((entry) {
                          return _buildAQIChip(entry.key, entry.value);
                        }).toList(),
                      ),
                    ),
                    ListTile(
                      title: SizedBox(
                        height: 200,
                        child: ForecastChart.fromMap(data?.iaqiForecast),
                      ),
                    ),
                    ListTile(
                      title: Text(data!.getLevel().name),
                      subtitle: Text(data!.getLevel().longDescription()),
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

  Future<bool?> confirmDismiss(BuildContext context) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Confirm"),
          content: const Text("Are you sure you wish to delete this item?"),
          actions: <Widget>[
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("DELETE")),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("CANCEL"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAQIChip(final IAQIRecord record, double value) {
    return Tooltip(
      message: record.label,
      child: Chip(
          avatar: CircleAvatar(
            backgroundColor: record.getColour(value),
            foregroundColor: Colors.white.withAlpha(200),
            child: Padding(
              padding: const EdgeInsets.all(1.0),
              child: FittedBox(child: record.getIcon()),
            ),
          ),
          label: Text("$value ${record.unit ?? ''}")),
    );
  }

  Widget buildTitleTile(
      BuildContext context, String? title, DateTime? lastUpdate) {
    if (editingLocation || title == null) {
      textController.selection = TextSelection(
          baseOffset: 0, extentOffset: textController.text.length);
      return ListTile(
        leading: IconButton(
          icon: const Icon(Icons.cancel),
          onPressed: () {
            setState(() {
              editingLocation = false;
            });
          },
        ),
        title: AQILocationAutocomplete(
            selectionCallback: (value) => {
                  widget.updateLocation(value),
                  editingLocation = false,
                },
            initialValue: textController.value.text,
            autofocus: editingLocation),
        trailing: ElevatedButton(
          onPressed: () {
            setState(() {
              editingLocation = false;
              widget.updateLocation(textController.value.text);
            });
          },
          child: const Icon(Icons.check),
        ),
      );
    } else {
      return Tooltip(
        message: "Click to update the location",
        child: ListTile(
          title: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child:
                Text(title, style: Theme.of(context).textTheme.headlineSmall),
          ),
          subtitle: buildLastUpdatedText(lastUpdate),
          onTap: () => {
            setState(() {
              editingLocation = true;
            })
          },
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
    timer = Timer.periodic(tickTime, (Timer t) => _tick(t));
    textController.text = widget.location;
    _tick(null);
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  Future<void> _tick(Timer? t) async {
    var fetchedData = await fetchAQIData(widget.location);
    setState(() {
      data = fetchedData;
    });
  }
}
