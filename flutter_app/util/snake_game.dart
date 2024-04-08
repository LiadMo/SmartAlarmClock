import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

import 'package:hive_flutter/adapters.dart';

class SnakeGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Snake Game',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
        shadowColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
        cardTheme: const CardTheme(
          elevation: 0,
          shadowColor: Colors.transparent,
        ),
      ),
      home: SnakeScreen(),
    );
  }
}

class SnakeScreen extends StatefulWidget {
  @override
  _SnakeScreenState createState() => _SnakeScreenState();
}

class _SnakeScreenState extends State<SnakeScreen> {
  final myBox = Hive.box('mybox');
  SnakeDataBase db = SnakeDataBase();

  static const Size gridSize = Size(10, 13);
  static const int snakeSpeed = 220;

  List<Point<int>> snake = [const Point(5, 7)];
  Direction direction = Direction.up;
  Point<int> food = const Point(0, 0);
  Timer? timer;
  bool isPlaying = true;
  int score = 0;
  int scoreNeeded = 5;
  bool isScored = false;

  final dataBase = FirebaseDatabase.instance.reference();

  @override
  void initState() {
    if (myBox.get("SNAKE") == null) {
      db.createInitialData();
    } else {
      db.loadData();
    }
    super.initState();
    startGame();
  }

  void startGame() {
    snake = [Point(gridSize.width ~/ 2, gridSize.height ~/ 2)];
    direction = Direction.up;
    generateFood();
    score = 0;
    isPlaying = true;
    if (timer != null) {
      timer!.cancel();
    }
    timer = Timer.periodic(Duration(milliseconds: snakeSpeed), (timer) {
      update();
    });
  }

  void generateFood() {
    final random = Random();
    int x = random.nextInt(gridSize.width.toInt());
    int y = random.nextInt(gridSize.height.toInt());
    food = Point(x, y);
  }

  void update() {
    setState(() {
      final head = snake.first;
      Point<int> nextPoint;
      if (direction == Direction.up) {
        nextPoint = Point(head.x, head.y - 1);
      } else if (direction == Direction.down) {
        nextPoint = Point(head.x, head.y + 1);
      } else if (direction == Direction.left) {
        nextPoint = Point(head.x - 1, head.y);
      } else {
        nextPoint = Point(head.x + 1, head.y);
      }

      snake.insert(0, nextPoint);

      if (nextPoint.x < 0 ||
          nextPoint.x >= gridSize.width ||
          nextPoint.y < 0 ||
          nextPoint.y >= gridSize.height ||
          snake.sublist(1).contains(nextPoint)) {
        gameOver();
        return;
      }

      if (nextPoint == food) {
        score++;
        generateFood();

        if (score == scoreNeeded) {
          isScored = true;
          final child = dataBase.child('Alarms');
          child.update({'is alarm off': "11"});
        }
      } else {
        snake.removeLast();
      }
    });
  }

  void gameOver() {
    setState(() {
      db.maxScore = score > db.maxScore ? score : db.maxScore;
      db.updateDataBase();
      isPlaying = false;
      timer?.cancel();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Game Over',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
          content: Text(
            'Your score: $score\nMax score: ${db.maxScore}',
            style: const TextStyle(fontSize: 20),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: isScored
                      ? () {
                          final child = dataBase.child('Alarms');
                          child.update({'is alarm off': "10"});
                          Navigator.pop(context);
                        }
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'You need to score $scoreNeeded points'),
                                backgroundColor: Colors.grey,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                margin: const EdgeInsets.all(16.0)),
                          );
                        },
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.white), // Set your desired color here
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(color: Color(0xFF008B8f), fontSize: 20)),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    startGame();
                  },
                  style: ButtonStyle(
                    elevation: MaterialStateProperty.all(0),
                    backgroundColor: MaterialStateProperty.all<Color>(
                        Colors.white), // Set your desired color here
                  ),
                  child: const Text('Play Again',
                      style: TextStyle(color: Color(0xFF008B8f), fontSize: 20)),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  void changeDirection(Direction newDirection) {
    setState(() {
      if ((direction == Direction.up || direction == Direction.down) &&
          (newDirection == Direction.left || newDirection == Direction.right)) {
        direction = newDirection;
      } else if ((direction == Direction.left ||
              direction == Direction.right) &&
          (newDirection == Direction.up || newDirection == Direction.down)) {
        direction = newDirection;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          Text(
            '\n\nCurrent Score: $score\n',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 24,
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.grey[300],
              child: GridView.builder(
                padding: EdgeInsets.zero,
                itemCount: gridSize.width.toInt() * gridSize.height.toInt(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize.width.toInt(),
                  crossAxisSpacing: 2.2,
                  mainAxisSpacing: 1.8,
                ),
                itemBuilder: (context, index) {
                  final x = index % gridSize.width.toInt();
                  final y = index ~/ gridSize.width.toInt();
                  final point = Point(x, y);
                  if (snake.contains(point)) {
                    return Container(
                      color: Colors.black,
                    );
                  } else if (food == point) {
                    return Container(
                      color: const Color(0xFF008B8f),
                    );
                  } else {
                    return Container(
                      color: Colors.grey[400],
                    );
                  }
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  changeDirection(Direction.up);
                },
                child: Container(
                  padding: EdgeInsets.zero, // Remove the default padding
                  width: 70, // Set the desired width
                  height: 70, // Set the desired height
                  child: const Icon(
                    Icons.arrow_drop_up_sharp,
                    color: Colors.black,
                    size: 70,
                  ), // Replace with your image path
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  changeDirection(Direction.left);
                },
                child: Container(
                  padding: EdgeInsets.zero, // Remove the default padding
                  width: 70, // Set the desired width
                  height: 70, // Set the desired height
                  child: const Icon(
                    Icons.arrow_left_sharp,
                    color: Colors.black,
                    size: 70,
                  ), // Replace with your image path
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10), // Remove the default padding
                width: 80, // Set the desired width
                height: 75, // Set the desired height
                child: const Icon(
                  Icons.circle,
                  color: Colors.black,
                  size: 50,
                ), // Replace with your image path
              ),
              GestureDetector(
                onTap: () {
                  changeDirection(Direction.right);
                },
                child: Container(
                  padding: EdgeInsets.zero, // Remove the default padding
                  width: 70, // Set the desired width
                  height: 70, // Set the desired height
                  child: const Icon(
                    Icons.arrow_right_sharp,
                    color: Colors.black,
                    size: 70,
                  ), // Replace with your image path
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  changeDirection(Direction.down);
                },
                child: Container(
                  padding: EdgeInsets.zero, // Remove the default padding
                  width: 80, // Set the desired width
                  height: 70, // Set the desired height
                  child: const Icon(
                    Icons.arrow_drop_down_sharp,
                    color: Colors.black,
                    size: 70,
                  ), // Replace with your image path
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}

enum Direction { up, down, left, right }

class SnakeDataBase {
  int maxScore = 0;

  void createInitialData() {
    maxScore = 0;
  }

  final myBox = Hive.box('mybox');

  void loadData() {
    maxScore = myBox.get("SNAKE");
  }

  void updateDataBase() {
    myBox.put("SNAKE", maxScore);
  }
}
