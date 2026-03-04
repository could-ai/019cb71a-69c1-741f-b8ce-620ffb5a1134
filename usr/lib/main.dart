import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.green,
          secondary: Colors.redAccent,
          surface: Colors.grey[900]!,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SnakeGamePage(),
      },
    );
  }
}

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({super.key});

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

enum Direction { up, down, left, right }

class _SnakeGamePageState extends State<SnakeGamePage> {
  // Game Configuration
  static const int columns = 20;
  static const int rows = 30;
  static const int totalSquares = columns * rows;
  static const Duration gameSpeed = Duration(milliseconds: 200);

  // Game State
  List<int> snakePosition = [];
  int foodPosition = -1;
  Direction direction = Direction.down;
  Direction? lastMoveDirection; // Prevent multiple moves in one tick
  bool isPlaying = false;
  int score = 0;
  Timer? gameTimer;

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      score = 0;
      snakePosition = [
        45, // Head
        25, // Body
        5,  // Tail
      ];
      direction = Direction.down;
      lastMoveDirection = Direction.down;
      generateNewFood();
    });

    gameTimer?.cancel();
    gameTimer = Timer.periodic(gameSpeed, (Timer timer) {
      updateGame();
    });
  }

  void generateNewFood() {
    int randomPos;
    do {
      randomPos = Random().nextInt(totalSquares);
    } while (snakePosition.contains(randomPos));

    setState(() {
      foodPosition = randomPos;
    });
  }

  void updateGame() {
    if (!isPlaying) return;

    setState(() {
      int currentHead = snakePosition.first;
      int newHead = currentHead;

      // Calculate new head position based on direction
      switch (direction) {
        case Direction.down:
          if (currentHead >= totalSquares - columns) {
            // Hit bottom wall -> wrap around or game over? Let's do Game Over for classic feel
            gameOver();
            return;
          }
          newHead = currentHead + columns;
          break;
        case Direction.up:
          if (currentHead < columns) {
            gameOver();
            return;
          }
          newHead = currentHead - columns;
          break;
        case Direction.left:
          if (currentHead % columns == 0) {
            gameOver();
            return;
          }
          newHead = currentHead - 1;
          break;
        case Direction.right:
          if ((currentHead + 1) % columns == 0) {
            gameOver();
            return;
          }
          newHead = currentHead + 1;
          break;
      }

      // Check self collision
      if (snakePosition.contains(newHead)) {
        gameOver();
        return;
      }

      // Move snake
      snakePosition.insert(0, newHead);
      lastMoveDirection = direction;

      // Check food collision
      if (newHead == foodPosition) {
        score++;
        generateNewFood();
        // Don't remove tail, so snake grows
      } else {
        snakePosition.removeLast();
      }
    });
  }

  void gameOver() {
    gameTimer?.cancel();
    setState(() {
      isPlaying = false;
    });
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Game Over'),
          content: Text('Your Score: $score'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                startGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        );
      },
    );
  }

  void changeDirection(Direction newDirection) {
    // Prevent reversing direction directly (e.g., can't go up if currently going down)
    // Also prevent multiple direction changes in a single tick
    if (lastMoveDirection == null) return;

    if (newDirection == Direction.down && lastMoveDirection != Direction.up) {
      direction = Direction.down;
    } else if (newDirection == Direction.up && lastMoveDirection != Direction.down) {
      direction = Direction.up;
    } else if (newDirection == Direction.left && lastMoveDirection != Direction.right) {
      direction = Direction.left;
    } else if (newDirection == Direction.right && lastMoveDirection != Direction.left) {
      direction = Direction.right;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Score Board
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Score: $score',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (!isPlaying && snakePosition.isEmpty)
                    ElevatedButton(
                      onPressed: startGame,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: const Text('Start Game', style: TextStyle(color: Colors.white)),
                    ),
                ],
              ),
            ),
          ),
          
          // Game Grid
          Expanded(
            flex: 5,
            child: GestureDetector(
              onVerticalDragUpdate: (details) {
                if (details.delta.dy > 0) {
                  changeDirection(Direction.down);
                } else if (details.delta.dy < 0) {
                  changeDirection(Direction.up);
                }
              },
              onHorizontalDragUpdate: (details) {
                if (details.delta.dx > 0) {
                  changeDirection(Direction.right);
                } else if (details.delta.dx < 0) {
                  changeDirection(Direction.left);
                }
              },
              child: KeyboardListener(
                focusNode: FocusNode()..requestFocus(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent) {
                    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                      changeDirection(Direction.down);
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                      changeDirection(Direction.up);
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                      changeDirection(Direction.left);
                    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                      changeDirection(Direction.right);
                    }
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: totalSquares,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                    ),
                    itemBuilder: (context, index) {
                      if (snakePosition.contains(index)) {
                        // Snake Head
                        if (snakePosition.first == index) {
                          return Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.green[700],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }
                        // Snake Body
                        return Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.green,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      } else if (index == foodPosition) {
                        // Food
                        return Container(
                          margin: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        );
                      } else {
                        // Empty Square
                        return Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Controls Hint
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Swipe or use Arrow Keys to move',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
