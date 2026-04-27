import 'package:chilicizz/data/aqi_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'aqi_model.dart';

/// Autocomplete for AQI locations
class AQILocationAutocomplete extends StatefulWidget {
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
  State<AQILocationAutocomplete> createState() => _AQILocationAutocompleteState();
}

class _AQILocationAutocompleteState extends State<AQILocationAutocomplete> {
  late AQIProvider aqiProvider;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    aqiProvider = context.read<AQIProvider>();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<AQILocation>(
      fieldViewBuilder: (BuildContext context, TextEditingController textEditingController,
          FocusNode focusNode, VoidCallback onFieldSubmitted) {
        if (widget._initialValue != null && textEditingController.text.isEmpty) {
          textEditingController.text = widget._initialValue!;
        }
        textEditingController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: textEditingController.text.length,
        );
        return TextField(
          autofocus: widget._autofocus,
          focusNode: focusNode,
          controller: textEditingController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: "enter the name of a city to add a new tile",
            suffixIcon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: (value) {
            setState(() {
              _isLoading = value.length > 3;
            });
          },
          onSubmitted: (value) {
            setState(() {
              _isLoading = false;
            });
            onFieldSubmitted();
          },
        );
      },
      displayStringForOption: (location) {
        return "${location.name} (${location.url})";
      },
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty || textEditingValue.text.length <= 3) {
          return const Iterable<AQILocation>.empty();
        }
        return aqiProvider.queryLocation(textEditingValue.text.trim()).then((results) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return results;
        }).catchError((error) {
          debugPrint('AQILocationAutocomplete Error: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
          return <AQILocation>[];
        });
      },
      onSelected: (AQILocation selection) {
        setState(() {
          _isLoading = false;
        });
        widget._selectionCallback(selection.url);
      },
    );
  }
}
