import 'package:flutter/material.dart';

import 'AQICommon.dart';

class AQILocationAutocomplete extends StatelessWidget {
  Function(String value) selectionCallback;
  String? initialValue;
  bool autofocus;

  AQILocationAutocomplete(
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
          selectionCallback(value);
        },
      );
    },
    displayStringForOption: (location) {
      return "${location.name}\n(${location.url})";
    },
    optionsBuilder: (TextEditingValue textEditingValue) {
      if (textEditingValue.text.isNotEmpty &&
          textEditingValue.text.length > 3) {
        return locationQuery(textEditingValue.text);
      }
      return const Iterable<AQILocation>.empty();
    },
    onSelected: (AQILocation selection) {
      selectionCallback(selection.url);
    },
  );
}
