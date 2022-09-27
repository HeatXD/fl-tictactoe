import 'package:web_socket_channel/web_socket_channel.dart';

class TicTacToeNetwork {
  final WebSocketChannel channel;

  TicTacToeNetwork(this.channel);

  void closeNetwork() {
    channel.sink.close();
  }

  void sendMessage(dynamic message) {
    channel.sink.add(message);
  }
}
