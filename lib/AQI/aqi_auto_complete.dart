import 'package:chilicizz/data/aqi_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'aqi_model.dart';

/// Autocomplete for AQI locations
class AQILocationAutocomplete extends StatelessWidget {
  final Function(String value) _selectionCallback;
  final String? _initialValue;
  final bool _autofocus;

  const AQILocationAutocomplete({
    super.key,
    required dynamic Function(String) selectionCallback,
    bool autofocus = false,
    String? initialValue,
  })  : _selectionCallback = selectionCallback,
        _initialValue = initialValue,
        _autofocus = autofocus;

  @override
  Widget build(BuildContext context) {
    AQIProvider aqiProvider = context.read<AQIProvider>();
    return Autocomplete<AQILocation>(
      fieldViewBuilder: (BuildContext context, TextEditingController textEditingController,
          FocusNode focusNode, VoidCallback onFieldSubmitted) {
        if (_initialValue != null) {
          textEditingController.text = _initialValue!;
        }
        textEditingController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: textEditingController.text.length,
        );
        return TextField(
          autofocus: _autofocus,
          focusNode: focusNode,
          controller: textEditingController,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: "enter the name of a city to add a new tile",
          ),
          onSubmitted: (value) {
            onFieldSubmitted();
          },
        );
      },
      displayStringForOption: (location) {
        return "${location.name}\n(${location.url})";
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isNotEmpty && textEditingValue.text.length > 3) {
          return aqiProvider.queryLocation(textEditingValue.text.trim());
        }
        return const Iterable<AQILocation>.empty();
      },
      onSelected: (AQILocation selection) {
        _selectionCallback(selection.url);
      },
    );
  }
}
