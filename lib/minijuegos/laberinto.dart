// Código completo actualizado del Laberinto con overlay de carga
import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dem100app/machine_learning/api_ml.dart';

class LaberintoPage extends StatefulWidget {
  const LaberintoPage({super.key});

  @override
  State<LaberintoPage> createState() => _LaberintoPageState();
}

class _LaberintoPageState extends State<LaberintoPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  int rows = 5;
  int cols = 5;
  late List<List<int>> maze;
  int playerRow = 0;
  int playerCol = 0;
  int moves = 0;
  int errors = 0;
  late Stopwatch stopwatch;

  final Random random = Random();
  bool gameStarted = false;
  bool difficultySelected = false;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  late int goalRow;
  late int goalCol;

  int minMovesRequired = 5;
  int fakePathsRequired = 0;

  @override
  void initState() {
    super.initState();
    stopwatch = Stopwatch();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructions();
    });
  }

  void _showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Instrucciones'),
        content: const Text(
          'Mueve el cuadrado azul hasta la meta (el cuadrado rojo).\n\n'
          'Pulsa las flechas debajo para moverte.\n'
          'Los bloques negros son paredes. Si chocas contra una, cuenta como error.\n\n'
          '¡Selecciona la dificultad cuando pulses OK!',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _selectDifficulty();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _selectDifficulty() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona la dificultad'),
        content: const Text('Elige el nivel de dificultad para el laberinto.'),
        actions: [
          TextButton(onPressed: () => _setupLevel('easy'), child: const Text('Fácil')),
          TextButton(onPressed: () => _setupLevel('medium'), child: const Text('Medio')),
          TextButton(onPressed: () => _setupLevel('hard'), child: const Text('Difícil')),
        ],
      ),
    );
  }

  void _setupLevel(String difficulty) {
    if (difficulty == 'easy') {
      rows = 5;
      cols = 5;
      minMovesRequired = 5;
      fakePathsRequired = 0;
    } else if (difficulty == 'medium') {
      rows = 9;
      cols = 9;
      minMovesRequired = 12;
      fakePathsRequired = 2 + random.nextInt(2);
    } else if (difficulty == 'hard') {
      rows = 13;
      cols = 13;
      minMovesRequired = 22;
      fakePathsRequired = 4 + random.nextInt(3);
    }

    difficultySelected = true;
    Navigator.of(context).pop();
    _generateValidMaze();
  }

  void _generateValidMaze() {
    bool validMaze = false;

    while (!validMaze) {
      maze = List.generate(rows, (_) => List.generate(cols, (_) => 1));
      int startRow = random.nextInt(rows);
      int startCol = random.nextInt(cols);
      playerRow = startRow;
      playerCol = startCol;
      _carvePath(startRow, startCol);
      maze[playerRow][playerCol] = 2;

      List<Point<int>> emptyCells = [];
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (maze[r][c] == 0 && !(r == playerRow && c == playerCol)) {
            emptyCells.add(Point(r, c));
          }
        }
      }

      if (emptyCells.isNotEmpty) {
        Point<int> goal = emptyCells[random.nextInt(emptyCells.length)];
        goalRow = goal.x;
        goalCol = goal.y;
        maze[goalRow][goalCol] = 3;
        int pathLength = _shortestPathLength(playerRow, playerCol, goalRow, goalCol);
        if (pathLength >= minMovesRequired) {
          validMaze = _generateFakePaths();
        }
      }
    }

    setState(() {
      gameStarted = true;
    });
    stopwatch.start();
  }

  void _carvePath(int row, int col) {
    maze[row][col] = 0;
    List<Point<int>> directions = [Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0)]..shuffle();
    for (var dir in directions) {
      int newRow = row + dir.x * 2;
      int newCol = col + dir.y * 2;
      if (newRow > 0 && newRow < rows && newCol > 0 && newCol < cols && maze[newRow][newCol] == 1) {
        maze[row + dir.x][col + dir.y] = 0;
        _carvePath(newRow, newCol);
      }
    }
  }

  bool _generateFakePaths() {
    int created = 0;
    int attempts = 0;
    while (created < fakePathsRequired && attempts < 100) {
      int r = random.nextInt(rows);
      int c = random.nextInt(cols);
      if (maze[r][c] == 0) {
        List<Point<int>> directions = [Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0)]..shuffle();
        for (var dir in directions) {
          int newRow = r + dir.x;
          int newCol = c + dir.y;
          if (newRow > 0 && newRow < rows && newCol > 0 && newCol < cols && maze[newRow][newCol] == 1) {
            maze[newRow][newCol] = 0;
            created++;
            break;
          }
        }
      }
      attempts++;
    }
    return true;
  }

  int _shortestPathLength(int startRow, int startCol, int endRow, int endCol) {
    List<List<bool>> visited = List.generate(rows, (_) => List.generate(cols, (_) => false));
    Queue<List<int>> queue = Queue();
    queue.add([startRow, startCol, 0]);
    visited[startRow][startCol] = true;
    while (queue.isNotEmpty) {
      var current = queue.removeFirst();
      int r = current[0];
      int c = current[1];
      int dist = current[2];
      if (r == endRow && c == endCol) return dist;
      for (var dir in [Point(0, 1), Point(1, 0), Point(0, -1), Point(-1, 0)]) {
        int nr = r + dir.x;
        int nc = c + dir.y;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && !visited[nr][nc] && maze[nr][nc] != 1) {
          visited[nr][nc] = true;
          queue.add([nr, nc, dist + 1]);
        }
      }
    }
    return -1;
  }

  void movePlayer(int dRow, int dCol) {
    if (!gameStarted) return;
    final newRow = playerRow + dRow;
    final newCol = playerCol + dCol;
    if (newRow < 0 || newRow >= rows || newCol < 0 || newCol >= cols) {
      errors++;
      return;
    }
    final cell = maze[newRow][newCol];
    if (cell == 1) {
      errors++;
    } else {
      setState(() {
        playerRow = newRow;
        playerCol = newCol;
        moves++;
      });
      if (cell == 3) {
        _finishMaze();
      }
    }
  }

  Future<void> _finishMaze() async {
    stopwatch.stop();
    isLoading.value = true;
    final User? user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('laberinto_tests').add({
        'uid': user.uid,
        'email': user.email,
        'moves': moves,
        'errors': errors,
        'time_seconds': stopwatch.elapsed.inSeconds,
        'rows': rows,
        'cols': cols,
        'timestamp': Timestamp.now(),
      });
      await lanzarEvaluacionML();
    }
    isLoading.value = false;
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Laberinto completado!'),
          content: Text(
            'Movimientos: $moves\n'
            'Errores: $errors\n'
            'Tiempo: ${stopwatch.elapsed.inSeconds} segundos\n'
            'Tamaño: ${rows}x$cols',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget buildCell(int row, int col) {
    Color color;
    if (row == playerRow && col == playerCol) {
      color = Colors.blueAccent;
    } else {
      switch (maze[row][col]) {
        case 0:
          color = Colors.white;
          break;
        case 1:
          color = Colors.black;
          break;
        case 2:
          color = Colors.white;
          break;
        case 3:
          color = Colors.red;
          break;
        default:
          color = Colors.white;
      }
    }
    return Container(
      margin: const EdgeInsets.all(2),
      color: color,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laberinto')),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                flex: 5,
                child: Container(
                  color: difficultySelected && gameStarted ? Colors.transparent : Colors.white,
                  child: difficultySelected && gameStarted
                      ? AspectRatio(
                          aspectRatio: 1,
                          child: GridView.builder(
                            itemCount: rows * cols,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols),
                            itemBuilder: (context, index) {
                              final row = index ~/ cols;
                              final col = index % cols;
                              return buildCell(row, col);
                            },
                          ),
                        )
                      : const Center(
                          child: Text('', style: TextStyle(fontSize: 20, color: Colors.black54)),
                        ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Center(
                  child: SizedBox(
                    width: 230,
                    height: 230,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 0,
                          left: 75,
                          child: ElevatedButton(
                            onPressed: () => movePlayer(-1, 0),
                            style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(24)),
                            child: const Icon(Icons.arrow_upward, size: 32),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 75,
                          child: ElevatedButton(
                            onPressed: () => movePlayer(1, 0),
                            style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(24)),
                            child: const Icon(Icons.arrow_downward, size: 32),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 75,
                          child: ElevatedButton(
                            onPressed: () => movePlayer(0, -1),
                            style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(24)),
                            child: const Icon(Icons.arrow_back, size: 32),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          top: 75,
                          child: ElevatedButton(
                            onPressed: () => movePlayer(0, 1),
                            style: ElevatedButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(24)),
                            child: const Icon(Icons.arrow_forward, size: 32),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, loading, _) {
              if (!loading) return const SizedBox.shrink();
              return Container(
                // ignore: deprecated_member_use
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        "Guardando resultados...",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}






