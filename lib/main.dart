import 'package:flutter/material.dart';
import 'package:test_app/network.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicTacToe',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyGamePage(
        title: 'TicTacToe',
        net: TicTacToeNetwork(
          WebSocketChannel.connect(Uri.parse("ws://fl-ttt-mini.glitch.me/ws")),
        ),
      ),
    );
  }
}

class MyGamePage extends StatefulWidget {
  const MyGamePage({Key? key, required this.title, required this.net})
      : super(key: key);

  final String title;
  final TicTacToeNetwork net;

  @override
  State<MyGamePage> createState() => _MyGamePageState();
}

class _MyGamePageState extends State<MyGamePage> {
  int _localPlayer = 0;
  int _turnCounter = 1;
  int _currentUser = 1;
  bool _gameOver = false;
  final List<int> _board = List.filled(9, 0);
  final List<List<int>> _winLines = [
    // rows
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    // columns
    [0, 3, 6], [1, 4, 7], [2, 7, 8],
    //diagonals
    [0, 4, 8], [2, 4, 6]
  ];

  void _setBoardPositionTo(int position, int player, bool shouldBuild) {
    print(player);
    print(_turnCounter);

    if (position < 0 || position > 8 || _gameOver || _currentUser != player) {
      return;
    }

    if (player == _localPlayer) {
      widget.net.sendMessage("#PI:$player:$position");
    }

    _turnCounter++;

    if (shouldBuild) {
      setState(() {
        _board[position] = player;
        _checkPlayerWin(player);
        _advanceTurn();
      });
    } else {
      _board[position] = player;
      _checkPlayerWin(player);
      _advanceTurn();
    }
  }

  void _checkPlayerWin(int player) {
    for (var win in _winLines) {
      int sum = _board[win[0]] + _board[win[1]] + _board[win[2]];
      if (sum == player * 3) {
        _gameOver = true;
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var screen = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
          textScaleFactor: 1.5,
        ),
      ),
      body: StreamBuilder<dynamic>(
        stream: widget.net.channel.stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircularProgressIndicator();
          }
          _handleNetworkMessage(snapshot.data);
          return kIsWeb ? _webBody(screen) : _mobileBody();
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.greenAccent,
        child: Text(
          _gameOver ? _showGameOverCredit() : "Turn: $_turnCounter",
          textAlign: TextAlign.center,
          textScaleFactor: 2,
        ),
      ),
    );
  }

  Widget _mobileBody() {
    return GridView.count(
      padding: const EdgeInsets.only(top: 100),
      crossAxisCount: 3,
      children: List.generate(9, (index) {
        return Center(
          child: TicTacToeWidget(
            index: index,
            ownedBy: _board[index],
            setPosition: _setBoardPositionTo,
            clickedBy: _localPlayer,
          ),
        );
      }),
    );
  }

  Widget _webBody(Size screen) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(50),
        width: screen.width * 0.4,
        child: GridView.count(
          crossAxisCount: 3,
          children: List.generate(9, (index) {
            return Center(
              child: TicTacToeWidget(
                index: index,
                ownedBy: _board[index],
                setPosition: _setBoardPositionTo,
                clickedBy: _localPlayer,
              ),
            );
          }),
        ),
      ),
    );
  }

  String _showGameOverCredit() {
    int player = _turnCounter % 2;
    return "Player $player won!";
  }

  void _handleNetworkMessage(data) {
    var res = data.toString().split(":");
    print(res);
    switch (res[0]) {
      case "#UN":
        _localPlayer = int.parse(res[1]);
        break;
      case "#PI":
        int player = int.parse(res[1]);
        int position = int.parse(res[2]);
        _setBoardPositionTo(position, player, false);
        break;
    }
  }

  void _advanceTurn() {
    if (_currentUser == 1) {
      _currentUser == 2;
    } else {
      _currentUser == 1;
    }
  }
}

class TicTacToeWidget extends StatelessWidget {
  const TicTacToeWidget(
      {super.key,
      required this.index,
      required this.ownedBy,
      required this.setPosition,
      this.clickedBy});

  final int ownedBy;
  final int index;
  final Function setPosition;
  final int? clickedBy;

  @override
  Widget build(BuildContext context) {
    if (ownedBy == 1) {
      return const IconButton(
        icon: Icon(Icons.close, color: Colors.red),
        onPressed: null,
        iconSize: kIsWeb ? 195 : 95,
      );
    } else if (ownedBy == 2) {
      return const IconButton(
        icon: Icon(
          Icons.panorama_fish_eye,
          color: Colors.blue,
        ),
        onPressed: null,
        iconSize: kIsWeb ? 185 : 85,
      );
    } else {
      return IconButton(
        onPressed: () => setPosition(index, clickedBy, true),
        icon: const Icon(Icons.edit),
        iconSize: kIsWeb ? 200 : 100,
      );
    }
  }
}
