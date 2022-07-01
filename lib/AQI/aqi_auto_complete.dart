import 'package:flutter/material.dart';

import 'aqi_common.dart';

class AQILocationAutocomplete extends StatelessWidget {
  final Function(String value) selectionCallback;
  final String? initialValue;
  final bool autofocus;

  const AQILocationAutocomplete(
      {Key? key,
      required this.selectionCallback,
      this.autofocus = false,
      this.initialValue})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildAQILocationAutocomplete(context, selectionCallback,
        initial: initialValue, autofocus: autofocus);
  }
}

Autocomplete<AQILocation> buildAQILocationAutocomplete(
    BuildContext context, Function(String value) selectionCallback,
    {String? initial, bool autofocus = false}) {
  return Autocomplete<AQILocation>(
    fieldViewBuilder: (BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted) {
      if (initial != null) {
        textEditingController.text = initial;
      }
      textEditingController.selection = TextSelection(
          baseOffset: 0, extentOffset: textEditingController.text.length);
      return TextField(
        autofocus: autofocus,
        focusNode: focusNode,
        controller: textEditingController,
        decoration: const InputDecoration(hintText: "enter the name of a city"),
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
        return locationQuery(textEditingValue.text.trim());
      }
      return const Iterable<AQILocation>.empty();
    },
    onSelected: (AQILocation selection) {
      selectionCallback(selection.url);
    },
  );
}
