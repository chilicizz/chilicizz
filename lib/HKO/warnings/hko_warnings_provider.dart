import 'dart:convert';

import 'package:chilicizz/HKO/hko_types.dart';
import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HKOWarningsProvider {
  ValueNotifier<List<WarningInformation>?> hkoWeatherWarnings =
      ValueNotifier(null);
  DateTime lastTick = DateTime.now();

  final Uri hkoWarningsURL;
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  HKOWarningsProvider(this.hkoWarningsURL) {
    _connect();
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

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
    hkoWeatherWarnings.dispose();
  }
}
