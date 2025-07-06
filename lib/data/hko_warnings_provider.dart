import 'dart:convert';

import 'package:chilicizz/HKO/warnings_model.dart';
import 'package:chilicizz/HKO/typhoon_model.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class TyphoonTrackNotifier extends ChangeNotifier {
  final Map<String, TyphoonTrack?> _typhoonTracks = {};

  TyphoonTrack? getTyphoonTrack(String typhoonId) {
    return _typhoonTracks[typhoonId];
  }

  void addTyphoonTrack(String typhoonId, TyphoonTrack? track) {
    _typhoonTracks[typhoonId] = track;
    notifyListeners();
  }
}

// Extracts warnings from the HKO feed JSON
class HKOWarningsProvider {
  final ValueNotifier<List<WarningInformation>?> hkoWeatherWarnings = ValueNotifier(null);
  final ValueNotifier<List<Typhoon>?> hkoTyphoons = ValueNotifier(null);
  final TyphoonTrackNotifier typhoonTracks = TyphoonTrackNotifier();
  final TyphoonHttpClientJson typhoonHttpClient;
  final String? mapTileUrl = dotenv.env['mapTileUrl'];

  // Last time the WebSocket received a message
  DateTime lastTick = DateTime.now();

  final Uri hkoWarningsURL;
  final String hkoTyphoonURL;
  final String typhoonBaseUrl;

  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  HKOWarningsProvider(this.hkoWarningsURL, this.hkoTyphoonURL, this.typhoonBaseUrl)
      : typhoonHttpClient = TyphoonHttpClientJson(typhoonBaseUrl) {
    _connect();
    refreshTyphoons();
  }

  void _connect() {
    if (_disposed) return;
    debugPrint('HkoWarningsProvider connecting to WebSocket...');
    try {
      _channel = WebSocketChannel.connect(hkoWarningsURL);
      _channel!.stream.listen(
        (message) {
          debugPrint('HkoWarningsProvider Received message: $message');
          lastTick = DateTime.now();
          // Parse the JSON message and extract warnings
          var hkoFeed = jsonDecode(message);
          var weatherWarnings = extractWarnings(hkoFeed);
          hkoWeatherWarnings.value = weatherWarnings;
        },
        onError: (error) {
          debugPrint('HkoWarningsProvider Error receiving message: $error');
          _reconnect();
        },
        onDone: () {
          debugPrint('HkoWarningsProvider WebSocket connection closed');
          _reconnect();
        },
        cancelOnError: true,
      );
      _reconnectAttempts = 0;
      debugPrint('HkoWarningsProvider WebSocket connection established');
    } catch (error) {
      debugPrint('HkoWarningsProvider Error connecting to WebSocket: $error');
      _reconnect();
    }
  }

  void _reconnect() {
    if (_disposed) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    debugPrint('HkoWarningsProvider attempting to reconnect in ${delay.inSeconds} seconds...');
    Future.delayed(delay, () {
      if (!_disposed) {
        _connect();
      }
    });
  }

  void triggerRefresh() {
    _channel?.sink.add("Refresh");
  }

  void refreshTyphoonTrack(String typhoonId) {
    // Fetch the typhoon track for a specific typhoon ID
    typhoonHttpClient.fetchTyphoonTrack(typhoonId).then((track) {
      if (track != null) {
        typhoonTracks.addTyphoonTrack(typhoonId.toString(), track);
      } else {
        debugPrint('HkoWarningsProvider No track data for typhoon $typhoonId');
      }
    });
  }

  void refreshTyphoons() {
    // Fetch typhoon data
    typhoonHttpClient.fetchTyphoonFeed().then((typhoons) {
      hkoTyphoons.value = typhoons;
      for (var typhoon in typhoons) {
        debugPrint('HkoWarningsProvider Fetching track for typhoon ${typhoon.id}');
        typhoonHttpClient.fetchTyphoonTrack("${typhoon.id}").then((track) {
          if (track != null) {
            typhoonTracks.addTyphoonTrack(typhoon.id.toString(), track);
          } else {
            debugPrint('HkoWarningsProvider No track data for typhoon ${typhoon.id}');
          }
        });
      }
    }).catchError((error) {
      debugPrint('HkoWarningsProvider Error fetching typhoons: $error');
    });
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
    hkoWeatherWarnings.dispose();
  }
}
