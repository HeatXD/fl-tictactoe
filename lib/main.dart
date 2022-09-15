import 'package:flutter/material.dart';
import 'package:test_app/network.dart';

void main() {
  TicTacToeNetwork.setupNetwork();
  TicTacToeNetwork.startListening();
  TicTacToeNetwork.sendMessage("Hello From Phone!");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TicTacToe',
      theme: ThemeData(
        primarySwatch: Colors.lightGreen,
      ),
      home: const MyGamePage(title: 'TicTacToe'),
    );
  }
}

class MyGamePage extends StatefulWidget {
  const MyGamePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyGamePage> createState() => _MyGamePageState();
}

class _MyGamePageState extends State<MyGamePage> {
  int _roundCounter = 0;
  final List<int> _board = [0, 1, 2, 1, 2, 0, 0, 0, 0];
  void _setBoardPositionTo(int position, int player) {
    if (position < 0 || position > 8) {
      return;
    }
    setState(() {
      _board[position] = player;
      _roundCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: GridView.count(
        crossAxisCount: 3,
        children: List.generate(9, (index) {
          return Center(
            child: TicTacToeWidget(
                index: index,
                ownedBy: _board[index],
                setPosition: _setBoardPositionTo),
          );
        }),
      ),
    );
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
        iconSize: 125,
      );
    } else if (ownedBy == 2) {
      return const IconButton(
        icon: Icon(
          Icons.panorama_fish_eye,
          color: Colors.blue,
        ),
        onPressed: null,
        iconSize: 115,
      );
    } else {
      return IconButton(
        onPressed: setPosition(index, clickedBy),
        icon: const Icon(Icons.edit),
        iconSize: 125,
      );
    }
  }
}
