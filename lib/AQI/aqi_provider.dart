import 'dart:async';
import 'dart:convert';

import 'package:chilicizz/AQI/aqi_common.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Storage model for AQI data.
/// This model holds the AQI data for different locations and provides methods to access and manage it
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

/// Represents a user's AQI locations and provides methods to manage them
class UserAQILocations extends ChangeNotifier {
  final List<String> _locations = [];

  List<String> get locations => _locations;

  get length => null;

  set value(List<String> locations) {
    _locations.clear();
    _locations.addAll(locations);
    notifyListeners();
  }

  void addLocation(String location) {
    if (location.isNotEmpty && !_locations.contains(location)) {
      _locations.add(location);
      notifyListeners();
    }
  }

  void removeLocation(String location) {
    if (_locations.contains(location)) {
      _locations.remove(location);
      notifyListeners();
    }
  }

  void updateLocation(String oldLocation, String newLocation) {
    int index = _locations.indexOf(oldLocation);
    if (index != -1) {
      _locations[index] = newLocation;
      notifyListeners();
    }
  }

  bool contains(String location) {
    return _locations.contains(location);
  }
}

class AQIProvider {
  final Uri _chatUrl;
  final Future<SharedPreferences> _instanceFuture = SharedPreferences.getInstance();
  final UserAQILocations aqiLocations = UserAQILocations();
  final AqiDataModel aqiDataModel = AqiDataModel();
  final Map<String, List<AQILocation>> _searchCache = {};

  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  bool _disposed = false;
  final Map<String, Completer> _waitingResponse = {};

  AQIProvider(this._chatUrl) {
    debugPrint('AQIProvider initialized with URL: $_chatUrl');
    _loadStateFromPersistence().then((_) {
      _connect();
    }).catchError((error) {
      debugPrint('AQIProvider Error loading state from persistence: $error');
    });
  }

  Future<void> _loadStateFromPersistence() async {
    final loadedValues = await Future.wait([
      _getAQILocations().then((value) => aqiLocations.value = value),
    ]);
    aqiLocations.addListener(() {
      // Save the locations whenever they change
      debugPrint('Saving AQI locations: ${aqiLocations.locations}');
      _saveAQILocations(aqiLocations.locations);
    });
    debugPrint('Loaded state from persistence: $loadedValues');
  }

  Future<List<String>> _getAQILocations() async {
    final prefs = await _instanceFuture;
    return prefs.getStringList('aqi_locations') ?? <String>[];
  }

  Future<void> _saveAQILocations(List<String> locations) async {
    final prefs = await _instanceFuture;
    await prefs.setStringList('aqi_locations', locations);
  }

  void addLocation(String location) {
    if (!aqiLocations.contains(location)) {
      aqiLocations.addLocation(location);
      requestAQIDataforLocation(location);
    }
  }

  void removeLocation(String location) {
    if (aqiLocations.contains(location)) {
      aqiLocations.removeLocation(location);
    }
  }

  void updateLocation(String oldLocation, String newLocation) {
    if (aqiLocations.contains(oldLocation)) {
      aqiLocations.updateLocation(oldLocation, newLocation);
      requestAQIDataforLocation(newLocation);
    } else {
      debugPrint('AQIProvider: Attempted to update non-existent location: $oldLocation');
      addLocation(newLocation);
    }
  }

  void _connect() {
    if (_disposed) return;
    debugPrint('AQIProvider connecting to WebSocket...');
    try {
      _channel = WebSocketChannel.connect(_chatUrl);
      _channel!.stream.listen(
        (message) {
          _handleSocketMessages(message);
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
      for (var location in aqiLocations._locations) {
        requestAQIDataforLocation(location);
      }
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
    if (_searchCache.containsKey(searchString)) {
      return _searchCache[searchString]!;
    }
    debugPrint("Sending search request for $searchString");
    dynamic payload = await _sendQueryRequest(searchString);
    List<AQILocation> list = parseLocationSearchResponse(payload);
    if (additionalQueryString.isNotEmpty) {
      list = list
          .where((element) => element.name.toLowerCase().contains(additionalQueryString))
          .toList();
    }
    _searchCache[searchString] = list;
    return list;
  }

  Future<dynamic> _sendQueryRequest(String searchString) {
    if (_disposed || _channel == null) {
      debugPrint('AQIProvider cannot send message, WebSocket is not connected');
      return Future.error('WebSocket is not connected');
    }
    Completer<dynamic> completer = Completer();
    _waitingResponse[searchString] = completer;
    searchString = searchString.toLowerCase().replaceAll('/', '');
    var queryRequest = {"id": searchString, "type": "AQI_SEARCH_REQUEST", "payload": searchString};
    _channel!.sink.add(jsonEncode(queryRequest));
    return completer.future;
  }

  void requestAQIDataforLocation(String location) {
    if (_disposed || _channel == null) {
      debugPrint('AQIProvider cannot send message, WebSocket is not connected');
      return;
    }
    try {
      debugPrint("Requesting AQI location $location");
      var request = {"id": location, "type": "AQI_FEED_REQUEST", "payload": location};
      _channel!.sink.add(jsonEncode(request));
    } catch (error) {
      debugPrint('AQIProvider Error sending request: $error');
    }
  }

  void _handleSocketMessages(dynamic event) {
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

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
  }
}
