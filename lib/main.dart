import 'package:flutter/cupertino.dart';
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
          WebSocketChannel.connect(
            Uri.parse("wss://fl-ttt-mini.glitch.me/ws"),
          ),
        ),
      ),
    );
  }
}

class MyGamePage extends StatefulWidget {
  const MyGamePage({
    Key? key,
    required this.title,
    required this.net,
  }) : super(key: key);

  final String title;
  final TicTacToeNetwork net;

  @override
  State<MyGamePage> createState() => _MyGamePageState();
}

class _MyGamePageState extends State<MyGamePage> {
  int _localPlayer = 0;
  int _turnCounter = 1;
  bool _justPlaced = true;
  bool _gameOver = false;
  String _lastNetMsg = "";
  bool _opponentDisconnect = false;
  final List<int> _board = List.filled(9, 0);
  final List<List<int>> _winLines = [
    // rows
    [0, 1, 2], [3, 4, 5], [6, 7, 8],
    // columns
    [0, 3, 6], [1, 4, 7], [2, 5, 8],
    //diagonals
    [0, 4, 8], [2, 4, 6]
  ];

  void _setBoardPositionTo(int position, int player, bool shouldBuild) {
    if (position < 0 ||
        position > 8 ||
        _gameOver ||
        (_localPlayer == player && _justPlaced)) {
      return;
    }

    if (player == _localPlayer) {
      widget.net.sendMessage("#PI:$player:$position");
      _justPlaced = true;
    } else {
      _justPlaced = false;
    }

    if (shouldBuild) {
      setState(() {
        _board[position] = player;
        _checkPlayerWin(player);
        if (!_gameOver) _turnCounter++;
      });
    } else {
      _board[position] = player;
      _checkPlayerWin(player);
      if (!_gameOver) _turnCounter++;
    }

    // stalemate
    if (_turnCounter == 10) {
      _gameOver = true;
      Future.delayed(
        const Duration(seconds: 5),
        () => widget.net.sendMessage("#RQ"),
      );
    }
  }

  void _checkPlayerWin(int player) {
    //print(_board);
    for (var win in _winLines) {
      if (_board[win[0]] == player &&
          _board[win[1]] == player &&
          _board[win[2]] == player) {
        _gameOver = true;
        Future.delayed(
          const Duration(seconds: 5),
          () => widget.net.sendMessage("#RQ"),
        );
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var screen = MediaQuery.of(context).size;
    return StreamBuilder<dynamic>(
      stream: widget.net.channel.stream,
      builder: (context, snapshot) {
        _handleNetworkMessage(snapshot.data);
        var gameOverMsg = _opponentDisconnect
            ? "Opponent disconnected\nLooking for a new one."
            : "Finding a new opponent";
        return Scaffold(
          appBar: AppBar(
            title: Text(
              widget.title,
              textAlign: TextAlign.center,
              textScaleFactor: 1.5,
            ),
          ),
          body: !snapshot.hasData || _gameOver
              ? Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        _gameOver
                            ? "Game Over!\n$gameOverMsg"
                            : "Looking for an opponent!",
                        textScaleFactor: 3,
                      ),
                      SizedBox(
                        height: screen.height / 2,
                        width: screen.width * 0.7,
                        child: const CircularProgressIndicator(
                          strokeWidth: 20,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                )
              : (kIsWeb ? _webBody(screen) : _mobileBody()),
          bottomNavigationBar: BottomAppBar(
            color: Colors.greenAccent,
            child: Text(
              _gameOver
                  ? _showGameOverCredit()
                  : (_justPlaced
                      ? "Opponent Turn ($_turnCounter)"
                      : "Your Turn ($_turnCounter)"),
              textAlign: TextAlign.center,
              textScaleFactor: 2,
            ),
          ),
        );
      },
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
    int won = _turnCounter % 2 == 0 ? 2 : 1;
    var who = won == 1 ? "X" : "O";
    return _turnCounter < 10 ? "Player:$won($who) Won!" : "Stalemate!";
  }

  void _handleNetworkMessage(data) {
    var res = data.toString().split(":");
    //prevent duplicate messages
    if (_lastNetMsg == data.toString()) {
      return;
    } else {
      _lastNetMsg = data.toString();
    }

    switch (res[0]) {
      case "#UN":
        _resetGame();
        _localPlayer = int.parse(res[1]);
        if (_localPlayer == 1) {
          _justPlaced = false;
        }
        break;
      case "#PI":
        int player = int.parse(res[1]);
        int position = int.parse(res[2]);
        _setBoardPositionTo(position, player, false);
        break;
      case "#MO":
        _gameOver = true;
        _opponentDisconnect = true;
        Future.delayed(
          const Duration(seconds: 5),
          () => widget.net.sendMessage("#RQ"),
        );
        break;
    }
  }

  void _resetGame() {
    _gameOver = false;
    _justPlaced = true;
    _board.fillRange(0, 9, 0);
    _turnCounter = 1;
    _opponentDisconnect = false;
  }
}

class TicTacToeWidget extends StatelessWidget {
  const TicTacToeWidget({
    super.key,
    required this.index,
    required this.ownedBy,
    required this.setPosition,
    this.clickedBy,
  });

  final int ownedBy;
  final int index;
  final Function setPosition;
  final int? clickedBy;

  @override
  Widget build(BuildContext context) {
    Border deco;
    double borderSize = 8;
    var borderSide = BorderSide(
      width: borderSize,
      color: Colors.black,
    );

    switch (index) {
      case 0:
        deco = Border(
          bottom: borderSide,
          right: borderSide,
        );
        break;
      case 1:
        deco = Border(
          left: borderSide,
          right: borderSide,
          bottom: borderSide,
        );
        break;
      case 2:
        deco = Border(
          bottom: borderSide,
          left: borderSide,
        );
        break;
      case 3:
        deco = Border(
          top: borderSide,
          bottom: borderSide,
          right: borderSide,
        );
        break;
      case 5:
        deco = Border(
          top: borderSide,
          bottom: borderSide,
          left: borderSide,
        );
        break;
      case 6:
        deco = Border(
          top: borderSide,
          right: borderSide,
        );
        break;
      case 7:
        deco = Border(
          top: borderSide,
          right: borderSide,
          left: borderSide,
        );
        break;
      case 8:
        deco = Border(
          top: borderSide,
          left: borderSide,
        );
        break;
      default:
        deco = Border.all(
          color: Colors.black,
          width: borderSize,
        );
        break;
    }

    if (ownedBy == 1) {
      return Container(
        decoration: BoxDecoration(
          border: deco,
        ),
        child: const IconButton(
          icon: Icon(
            Icons.close,
            color: Colors.red,
          ),
          onPressed: null,
          iconSize: kIsWeb ? 220 : 100,
        ),
      );
    } else if (ownedBy == 2) {
      return Container(
        decoration: BoxDecoration(
          border: deco,
        ),
        child: const IconButton(
          icon: Icon(
            Icons.panorama_fish_eye,
            color: Colors.blue,
          ),
          onPressed: null,
          iconSize: kIsWeb ? 220 : 100,
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          border: deco,
        ),
        child: IconButton(
          alignment: Alignment.topCenter,
          onPressed: () => setPosition(index, clickedBy, true),
          icon: const Icon(Icons.question_mark_rounded),
          iconSize: kIsWeb ? 220 : 100,
          splashRadius: kIsWeb ? 110 : 50,
        ),
      );
    }
  }
}
