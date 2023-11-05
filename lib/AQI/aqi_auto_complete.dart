import 'package:flutter/material.dart';

import 'aqi_common.dart';

/// Autocomplete for AQI locations
class AQILocationAutocomplete extends StatelessWidget {
  final Function(String value) selectionCallback;
  final String? initialValue;
  final bool autofocus;
  final AQILocationSearch aqiLocationSearch;

  const AQILocationAutocomplete(
      {super.key,
      required this.selectionCallback,
      this.autofocus = false,
      this.initialValue,
      required this.aqiLocationSearch});

  @override
  Widget build(BuildContext context) {
    return Autocomplete<AQILocation>(
      fieldViewBuilder: (BuildContext context,
          TextEditingController textEditingController,
          FocusNode focusNode,
          VoidCallback onFieldSubmitted) {
        if (initialValue != null) {
          textEditingController.text = initialValue!;
        }
        textEditingController.selection = TextSelection(
            baseOffset: 0, extentOffset: textEditingController.text.length);
        return TextField(
          autofocus: autofocus,
          focusNode: focusNode,
          controller: textEditingController,
          decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: "enter the name of a city to add a new tile"),
          onSubmitted: (value) {
            onFieldSubmitted();
          },
        );
      },
      displayStringForOption: (location) {
        return "${location.name}\n(${location.url})";
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isNotEmpty &&
            textEditingValue.text.length > 3) {
          return aqiLocationSearch.locationQuery(textEditingValue.text.trim());
        }
        return const Iterable<AQILocation>.empty();
      },
      onSelected: (AQILocation selection) {
        selectionCallback(selection.url);
      },
    );
  }
}
