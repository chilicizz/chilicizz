import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'aqi_common.dart';

const Map<String, List<AQILocation>> cache = {};

class AQILocationAutocomplete extends StatelessWidget {
  final Function(String value) selectionCallback;
  final String? initialValue;
  final bool autofocus;
  final String aqiLocationSearchTemplate;

  const AQILocationAutocomplete(
      {Key? key,
      required this.selectionCallback,
      this.autofocus = false,
      this.initialValue,
      required this.aqiLocationSearchTemplate})
      : super(key: key);

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
          return locationQuery(textEditingValue.text.trim());
        }
        return const Iterable<AQILocation>.empty();
      },
      onSelected: (AQILocation selection) {
        selectionCallback(selection.url);
      },
    );
  }

  String aqiLocationSearchUrl(String location, String token) {
    return aqiLocationSearchTemplate
        .replaceAll("_LOCATION_", location)
        .replaceAll("_TOKEN_", token);
  }

  Future<http.Response> locationQueryHttp(location) {
    var locationSearchUrl = aqiLocationSearchUrl(location, aqiToken);
    return http.get(Uri.parse(locationSearchUrl));
  }

  Future<List<AQILocation>> locationQuery(String location) async {
    location = location.toLowerCase().replaceAll('/', '');
    String additional = location.contains(" ")
        ? location.substring(location.indexOf(" ") + 1, location.length)
        : "";
    if (cache.containsKey(location)) {
      return cache[location]!;
    }
    var response = await locationQueryHttp(location);
    if (response.statusCode == 200) {
      var aqiFeed = jsonDecode(response.body);
      if (aqiFeed?["status"]?.contains("ok")) {
        List<AQILocation> list = [];
        dynamic jsonResult = aqiFeed?["data"];
        for (dynamic entry in jsonResult) {
          // entry["aqi"];
          list.add(
              AQILocation(entry["station"]?["name"], entry["station"]?["url"]));
        }
        list.sort((a, b) => a.url.compareTo(b.url));
        if (additional.isNotEmpty) {
          list = list
              .where(
                  (element) => element.name.toLowerCase().contains(additional))
              .toList();
        }
        cache[location] = list;
        return list;
      } else {
        debugPrint("Failed to fetch data $location");
        return [];
      }
    } else {
      debugPrint("Failed to fetch data $location");
      return [];
    }
  }
}
