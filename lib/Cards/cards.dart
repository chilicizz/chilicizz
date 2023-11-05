import 'package:flutter/widgets.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../common.dart';

class LiveCardTab extends StatefulWidget {
  final Uri socketURL;

  const LiveCardTab({super.key, required this.socketURL});

  @override
  State<LiveCardTab> createState() => _LiveCardTabState();
}

class _LiveCardTabState extends State<LiveCardTab> {
  late WebSocketChannel _channel;
  int _failures = 0;

  @override
  void initState() {
    super.initState();
    _channel = WebSocketChannel.connect(widget.socketURL);
  }

  @override
  void dispose() {
    debugPrint("Closing LiveCardTab websocket");
    _channel.sink.close();
    super.dispose();
  }

  void _reconnect() {
    if (_failures < 10) {
      Future.delayed(Duration(milliseconds: 100 * _failures), () {
        setState(() {
          debugPrint(
              "Reconnecting LiveCardTab websocket. Times failed: $_failures");
          _channel = WebSocketChannel.connect(widget.socketURL);
        });
      });
      _failures++;
    } else {
      debugPrint("Too many failures, not reconnecting");
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _channel.ready,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const LoadingListView();
            default:
              if (snapshot.hasError) {
                debugPrint("Error: ${snapshot.error}");
              }
          }
          return StreamBuilder(
            stream: _channel.stream,
            builder: (context, snapshot) {
              return const Placeholder();
            },
          );
        });
  }
}
