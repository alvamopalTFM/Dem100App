import 'dart:async' as async;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class TestNBackPage extends StatefulWidget {
  const TestNBackPage({Key? key}) : super(key: key);

  @override
  State<TestNBackPage> createState() => _TestNBackPageState();
}

class _TestNBackPageState extends State<TestNBackPage> {
  late NBackGame _game;

  @override
  void initState() {
    super.initState();
    _game = NBackGame(onGameEnd: (result) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('¡Test Finalizado!'),
          content: Text(
            'Aciertos: ${result['correctAnswers']}\n'
            'Fallos: ${result['mistakes']}\n'
            'Coincidencias posibles: ${result['matchesPlanned']}',
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
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showInstructions();
    });
  }

  void showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Instrucciones'),
        content: const Text(
          'Observa la posición del cuadrado azul.\n\n'
          'Pulsa "¡Es igual!" cuando la posición sea la misma que hace 2 movimientos (2-Back).\n\n'
          'Habrá un número variable de coincidencias posibles.\n\n'
          'El juego termina después de 20 movimientos.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _game.startTest();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void handleResponse() {
    setState(() {
      _game.checkResponse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test de N-Back (Flame)'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Text(
            'Aciertos: ${_game.correctAnswers}    Fallos: ${_game.mistakes}',
            style: const TextStyle(fontSize: 20),
          ),
          Expanded(
            child: GameWidget(game: _game),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: handleResponse,
            child: const Text('¡Es igual!'),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ---- Juego de N-Back usando Flame ----

class NBackGame extends FlameGame {
  final void Function(Map<String, dynamic>) onGameEnd;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int gridSize = 3; // 3x3
  final int nBack = 2;
  final int totalStimuli = 20;

  final Random random = Random();
  final List<int> sequence = [];

  int highlightedIndex = -1;
  int currentStimuli = 0;
  int correctAnswers = 0;
  int mistakes = 0;
  int matchesPlanned = 0;
  int matchesCreated = 0;
  int matchesDetected = 0;

  async.Timer? timer;
  bool canRespond = false;
  bool gridCreated = false;

  final List<SquareComponent> squares = [];

  NBackGame({required this.onGameEnd});

  @override
  Color backgroundColor() => const Color(0xFFF5F5F5); // Fondo blanco/gris claro

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    if (!gridCreated) {
      createGrid();
      gridCreated = true;
    }
  }

  void createGrid() {
    const double squareSize = 80;
    final double spacing = 8;
    final double totalWidth = gridSize * squareSize + (gridSize - 1) * spacing;
    final double totalHeight = gridSize * squareSize + (gridSize - 1) * spacing;

    final double startX = (size.x - totalWidth) / 2;
    final double startY = (size.y - totalHeight) / 2;

    for (int row = 0; row < gridSize; row++) {
      for (int col = 0; col < gridSize; col++) {
        final square = SquareComponent()
          ..size = Vector2(squareSize, squareSize)
          ..position = Vector2(
            startX + col * (squareSize + spacing),
            startY + row * (squareSize + spacing),
          );
        add(square);
        squares.add(square);
      }
    }
  }

  void prepareGame() {
    int minMatches = (totalStimuli * 0.1).round();
    int maxMatches = (totalStimuli * 0.4).round();
    matchesPlanned = random.nextInt(maxMatches - minMatches + 1) + minMatches;
  }

  void startTest() {
    prepareGame();
    showNextStimulus(); // <<<< Lanzamos primer estímulo directamente
    timer = async.Timer.periodic(const Duration(seconds: 2), (_) {
      showNextStimulus();
    });
  }

  void showNextStimulus() {
    if (currentStimuli >= totalStimuli) {
      timer?.cancel();
      endGame();
      return;
    }

    int nextIndex;
    bool shouldForceMatch = false;

    if (currentStimuli >= nBack && matchesCreated < matchesPlanned) {
      double chance = matchesPlanned / totalStimuli;
      if (random.nextDouble() < chance) {
        shouldForceMatch = true;
      }
    }

    if (shouldForceMatch && currentStimuli >= nBack) {
      nextIndex = sequence[currentStimuli - nBack];
      matchesCreated++;
    } else {
      do {
        nextIndex = random.nextInt(gridSize * gridSize);
      } while (currentStimuli >= nBack && nextIndex == sequence[currentStimuli - nBack]);
    }

    highlightedIndex = nextIndex;
    sequence.add(highlightedIndex);
    currentStimuli++;
    canRespond = true;

    updateSquares();
  }

  void updateSquares() {
    for (int i = 0; i < squares.length; i++) {
      squares[i].setHighlighted(i == highlightedIndex);
    }
  }

  void checkResponse() {
    if (!canRespond || sequence.length <= nBack) return;

    int current = sequence.last;
    int nBackValue = sequence[sequence.length - 1 - nBack];

    if (current == nBackValue) {
      matchesDetected++;
      correctAnswers++;
    } else {
      mistakes++;
    }

    canRespond = false;
  }

  Future<void> endGame() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('nback_tests').add({
        'uid': user.uid,
        'email': user.email,
        'score': correctAnswers,
        'mistakes': mistakes,
        'matchesPlanned': matchesPlanned,
        'matchesDetected': matchesDetected,
        'nBack': nBack,
        'timestamp': Timestamp.now(),
      });
    }

    onGameEnd({
      'correctAnswers': correctAnswers,
      'mistakes': mistakes,
      'matchesPlanned': matchesPlanned,
    });
  }
}

// ---- Componente de cada casilla ----

class SquareComponent extends PositionComponent {
  bool highlighted = false;

  static final Paint normalPaint = Paint()..color = Colors.grey.shade300;
  static final Paint highlightPaint = Paint()..color = Colors.blueAccent;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), highlighted ? highlightPaint : normalPaint);
  }

  void setHighlighted(bool value) {
    highlighted = value;
  }
}



