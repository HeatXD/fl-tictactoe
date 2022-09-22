import 'dart:async';
import 'package:flutter/material.dart';
import 'package:test_app/network.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  TicTacToeNetwork.setupNetwork();
  TicTacToeNetwork.startListening();
  TicTacToeNetwork.sendMessage("Hello From Flutter!");
  var timer = Timer.periodic(const Duration(seconds: 1), (timer) {
    if (TicTacToeNetwork.firstMessage == false) {
      timer.cancel();
      int player = int.parse(TicTacToeNetwork.getLastMessages().removeFirst());
      runApp(MyApp(player: player));
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.player});

  final int player;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicTacToe',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: MyGamePage(
        title: 'TicTacToe',
        localPlayer: player,
      ),
    );
  }
}

class MyGamePage extends StatefulWidget {
  const MyGamePage({Key? key, required this.title, required this.localPlayer})
      : super(key: key);

  final String title;
  final int localPlayer;

  @override
  State<MyGamePage> createState() => _MyGamePageState();
}

class _MyGamePageState extends State<MyGamePage> {
  int _turnCounter = 1;
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

  void _setBoardPositionTo(int position, int player) {
    if (_turnCounter % 2 != player ||
        position < 0 ||
        position > 8 ||
        _gameOver) {
      return;
    }
    setState(() {
      _board[position] = player;
      _checkPlayerWin(player);
      if (player == widget.localPlayer) {
        TicTacToeNetwork.sendMessage("$player:$position");
      }
      if (!_gameOver) {
        _turnCounter++;
      }
    });
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
      body: kIsWeb ? _webBody(screen) : _mobileBody(),
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
            clickedBy: widget.localPlayer,
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
                clickedBy: widget.localPlayer,
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
        onPressed: () => setPosition(index, clickedBy),
        icon: const Icon(Icons.edit),
        iconSize: kIsWeb ? 200 : 100,
      );
    }
  }
}
