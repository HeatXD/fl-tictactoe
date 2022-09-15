import 'dart:collection';

import 'package:web_socket_channel/io.dart';

class TicTacToeNetwork {
  static Queue<dynamic>? buffer;
  static IOWebSocketChannel? channel;

  static void setupNetwork() {
    buffer = Queue<dynamic>();
    channel =
        IOWebSocketChannel.connect(Uri.parse('ws://fl-ttt-mini.glitch.me/ws'));
  }

  // returns false if the channel is still null
  static bool startListening() {
    if (channel != null) {
      channel!.stream.listen((message) {
        buffer!.add(message);
      });
      return true;
    }
    return false;
  }

  static void closeNetwork() {
    channel?.sink.close();
  }

  static Queue<dynamic> getLastMessages() {
    if (buffer != null) {
      return buffer!;
    }
    return Queue();
  }

  static void sendMessage(dynamic message) {
    channel!.sink.add(message);
  }
}
