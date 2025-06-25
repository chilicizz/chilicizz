import 'dart:async';
import 'dart:convert';

import 'package:chilicizz/AQI/aqi_common.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class AqiDataModel extends ChangeNotifier {
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
}

class AQIProvider {
  final Uri _chatUrl;
  final Future<SharedPreferences> _instanceFuture = SharedPreferences.getInstance();
  ValueNotifier<List<String>?> aqiLocations = ValueNotifier(null);
  AqiDataModel aqiDataModel = AqiDataModel();

  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  final Map<String, Completer> _waitingResponse = {};

  AQIProvider(this._chatUrl) {
    var loadLocations = getAQILocations();
    loadLocations.then((locations) {
      aqiLocations.value = locations;
    }).catchError((error) {
      debugPrint('Error loading AQI locations: $error');
    });
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

  Future<dynamic> sendRequestOverSocket(String searchString) {
    Completer<dynamic> completer = Completer();
    _waitingResponse[searchString] = completer;
    searchString = searchString.toLowerCase().replaceAll('/', '');
    _channel?.sink.add(
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
