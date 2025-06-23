import 'package:test/test.dart';
import 'dart:io';

import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  late WebSocketChannel channel;
  setUp(() {
    channel = WebSocketChannel.connect(Uri.parse('ws://localhost:8080/chat/all/anon'));
    // Uri.parse('wss://spark.cyrilng.com/chat/all/anon'));
  });

  test('Connects', () async {
    await channel.ready;
    expect(channel.ready, completes);
  });

  test('WebSocketChannel can send and receive messages', () async {
    await channel.ready;
    channel.sink.add('Hello, WebSocket!');
    channel.stream.listen((message) {
      //sleep(Duration(seconds: 100));

      stdout.write("$message\n");
      // Check if the message is received correctly
      // expect(message, equals('Hello, WebSocket!\n'));
    });
    // Allow time for the message to be processed
    await Future.delayed(Duration(seconds: 3));
  });

  test('WebSocketChannel can send and receive messages', () async {
    try {
      await channel.ready;
    } on SocketException catch (e) {
      print(e.message);
      // Handle the exception.
    } on WebSocketChannelException catch (e) {
      // Handle the exception.
      print(e.message);
    }

    channel.stream.listen((message) {
      //sleep(Duration(seconds: 100));

      print("$message\n");
      // Check if the message is received correctly
      expect(message, equals('Hello, WebSocket!\n'));
    }, onError: (error) {
      // Handle any errors that occur during message reception
      print('Error receiving message: $error');
    }, onDone: () {
      // Handle the completion of the stream
      print('WebSocket connection closed');
    });

    // Send a message to the WebSocket server
    channel.sink.add('Hello, WebSocket!');

    // Allow time for the message to be processed
    await Future.delayed(Duration(seconds: 3));
  });

  tearDown(() async {
    await channel.sink.close();
  });
}
