import 'dart:async';
import 'dart:convert';

import 'package:chilicizz/AQI/aqi_common.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AqiDataModel extends ChangeNotifier {
  final List<String> locations = [];
  final Map<String, AQIData> locationDataMap = {};

  /// Returns the AQIData for a given location, or null if not available.
  AQIData? getAQIData(String location) {
    return locationDataMap[location];
  }

  /// Returns a list of all locations with available AQIData.
  List<String> getAvailableLocations() {
    return locationDataMap.keys.toList();
  }

  void addAQIData(String location, AQIData data) {
    locationDataMap[location] = data;
    notifyListeners();
  }

  void addLocation(String location) {
    if (!locations.contains(location)) {
      locations.add(location);
      notifyListeners();
    }
  }

  void removeLocation(String location) {
    if (locations.contains(location)) {
      locations.remove(location);
      locationDataMap.remove(location);
      notifyListeners();
    }
  }

  void updateLocation(String oldLocation, String newLocation) {
    if (locations.contains(oldLocation)) {
      int index = locations.indexOf(oldLocation);
      locations[index] = newLocation;
      var data = locationDataMap.remove(oldLocation);
      if (data != null) {
        locationDataMap[newLocation] = data;
      }
      notifyListeners();
    }
  }
}

class AQIProvider {
  final Uri _chatUrl;
  final Future<SharedPreferences> _instanceFuture = SharedPreferences.getInstance();
  ValueNotifier<List<String>?> aqiLocations = ValueNotifier(null);
  AqiDataModel aqiDataModel = AqiDataModel();

  final Map<String, List<AQILocation>> searchCache = {};
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  final Map<String, Completer> _waitingResponse = {};

  AQIProvider(this._chatUrl) {
    debugPrint('AQIProvider initialized with URL: $_chatUrl');
    _loadStateFromPersistence();
    _connect();
  }

  Future<void> _loadStateFromPersistence() async {
    final loadedValues = await Future.wait([
      getAQILocations().then((value) => aqiLocations.value = value),
    ]);
    debugPrint('Loaded state from persistence: $loadedValues');
  }

  Future<List<String>> getAQILocations() async {
    final prefs = await _instanceFuture;
    return prefs.getStringList('aqi_locations') ?? <String>[];
  }

  Future<void> saveAQILocations(List<String> locations) async {
    final prefs = await _instanceFuture;
    await prefs.setStringList('aqi_locations', locations);
  }

  void _connect() {
    if (_disposed) return;
    debugPrint('AQIProvider connecting to WebSocket...');
    try {
      _channel = WebSocketChannel.connect(_chatUrl);
      _channel!.stream.listen(
        (message) {
          debugPrint('AQIProvider Received message: $message');
          handleSocketMessages(message);
        },
        onError: (error) {
          debugPrint('AQIProvider Error receiving message: $error');
          _reconnect();
        },
        onDone: () {
          debugPrint('AQIProvider WebSocket connection closed');
          _reconnect();
        },
        cancelOnError: true,
      );
      _reconnectAttempts = 0;
      debugPrint('AQIProvider WebSocket connection established');
    } catch (error) {
      debugPrint('AQIProvider Error connecting to WebSocket: $error');
      _reconnect();
    }
  }

  Future<List<AQILocation>> queryLocation(String searchString) async {
    searchString = searchString.toLowerCase().replaceAll('/', '');
    String additionalQueryString = searchString.contains(" ")
        ? searchString.substring(searchString.indexOf(" ") + 1, searchString.length)
        : "";
    if (searchCache.containsKey(searchString)) {
      return searchCache[searchString]!;
    }
    debugPrint("Sending search request for $searchString");
    dynamic payload = await _sendRequestOverSocket(searchString);
    List<AQILocation> list = parseLocationSearchResponse(payload);
    if (additionalQueryString.isNotEmpty) {
      list = list
          .where((element) => element.name.toLowerCase().contains(additionalQueryString))
          .toList();
    }
    searchCache[searchString] = list;
    return list;
  }

  Future<dynamic> _sendRequestOverSocket(String searchString) {
    Completer<dynamic> completer = Completer();
    _waitingResponse[searchString] = completer;
    searchString = searchString.toLowerCase().replaceAll('/', '');
    _channel!.sink.add(
      jsonEncode({"id": searchString, "type": "AQI_SEARCH_REQUEST", "payload": searchString}),
    );
    return completer.future;
  }

  void handleSocketMessages(dynamic event) {
    var message = jsonDecode(event);
    var type = message["type"];
    var payload = message["payload"];
    var location = message["id"];
    if (type == "AQI_FEED_RESPONSE") {
      debugPrint("Received AQIData for location: $location");
      AQIData data = AQIData.fromJSON(jsonDecode(payload)["data"]);
      aqiDataModel.addAQIData(location, data);
    } else if (type == "AQI_SEARCH_RESPONSE") {
      debugPrint("Received search response for: $location");
      var completer = _waitingResponse.remove(location);
      completer?.complete(payload);
    } else {
      debugPrint("Received unknown message: $message");
    }
  }

  void _reconnect() {
    if (_disposed) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    debugPrint('AQIProvider attempting to reconnect in ${delay.inSeconds} seconds...');
    Future.delayed(delay, () {
      if (!_disposed) {
        _connect();
      }
    });
  }

  void sendMessage(String message) {
    if (_disposed || _channel == null) {
      debugPrint('AQIProvider cannot send message, WebSocket is not connected');
      return;
    }
    try {
      debugPrint('AQIProvider Sending message: $message');
      _channel!.sink.add(message);
    } catch (error) {
      debugPrint('AQIProvider Error sending message: $error');
      _reconnect();
    }
  }

  void requestLocation(String element) {
    debugPrint("Requesting AQI location $element");
    _channel!.sink.add(
      jsonEncode({"id": element, "type": "AQI_FEED_REQUEST", "payload": element}),
    );
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
  }
}
