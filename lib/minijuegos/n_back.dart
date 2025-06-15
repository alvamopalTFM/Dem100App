import 'dart:async' as async;
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dem100app/machine_learning/api_ml.dart';

class TestNBackPage extends StatefulWidget {
  const TestNBackPage({Key? key}) : super(key: key);

  @override
  State<TestNBackPage> createState() => _TestNBackPageState();
}

class _TestNBackPageState extends State<TestNBackPage> {
  late NBackGame _game;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _game = NBackGame(
      onGameEnd: (result) {
        isLoading.value = false;
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
      },
      isLoadingNotifier: isLoading,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showInstructions();
    });
  }

  void showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int currentPage = 0;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(currentPage == 0 ? 'Instrucciones' : 'Ejemplo visual'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (currentPage == 0) ...[
                      const Text(
                        'Observa la posición del cuadrado azul.\n\n'
                        'Pulsa "¡Es igual!" cuando la posición sea la misma que hace 2 movimientos. Se puede ver un ejemplo antes de comenzar. \n\n'
                        'Habrá un número variable de coincidencias posibles.\n\n'
                        'El juego termina después de 20 movimientos.\n',
                        style: TextStyle(fontSize: 16),
                      ),
                    ] else ...[
                      Image.asset(
                        'assets/imagenes/cuadricula.png',
                        width: 200,
                        height: 200,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Esta es la cuadrícula 3x3 usada en el test.\n'
                        'El cuadrado azul comienza en una posición de la cuadrícula. Cada 2 segundos se mueve a una posición diferente.\n'
                        'En el caso de la imagen, se debería pulsar "¡Es igual!" si el cuadrado al moverse una vez, vuelve a la posición que se observa y así sucesivamente',
                        style: TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                if (currentPage == 1)
                  TextButton(
                    onPressed: () => setState(() => currentPage = 0),
                    child: const Text('Atrás'),
                  ),
                if (currentPage == 0)
                  TextButton(
                    onPressed: () => setState(() => currentPage = 1),
                    child: const Text('Ver ejemplo'),
                  ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _game.startTest();
                  },
                  child: const Text('Comenzar'),
                ),
              ],
            );
          },
        );
      },
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
      body: Stack(
        children: [
          Column(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 144, 205, 255),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  textStyle: const TextStyle(fontSize: 24),
                ),
                onPressed: handleResponse,
                child: const Text('¡Es igual!'),
              ),
              const SizedBox(height: 20),
            ],
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, loading, _) {
              if (!loading) return const SizedBox.shrink();
              return Container(
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

class NBackGame extends FlameGame {
  final void Function(Map<String, dynamic>) onGameEnd;
  final ValueNotifier<bool>? isLoadingNotifier;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final int gridSize = 3;
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

  NBackGame({required this.onGameEnd, this.isLoadingNotifier});

  @override
  Color backgroundColor() => const Color(0xFFF5F5F5);

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
    const double squareSize = 110;
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

  late Set<int> forcedMatchPositions;

  void prepareGame() {
    int minMatches = (totalStimuli * 0.1).round();
    int maxMatches = (totalStimuli * 0.4).round();
    matchesPlanned = random.nextInt(maxMatches - minMatches + 1) + minMatches;

    List<int> possiblePositions = List.generate(
      totalStimuli - nBack,
      (i) => i + nBack,
    );

    possiblePositions.shuffle();
    forcedMatchPositions = possiblePositions.take(matchesPlanned).toSet();
  }

  void startTest() {
    prepareGame();
    showNextStimulus();
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

    if (forcedMatchPositions.contains(currentStimuli)) {
      nextIndex = sequence[currentStimuli - nBack];
      matchesCreated++;
    } else {
      do {
        nextIndex = random.nextInt(gridSize * gridSize);
      } while (
        (currentStimuli >= nBack && nextIndex == sequence[currentStimuli - nBack]) || 
        (sequence.isNotEmpty && nextIndex == sequence.last)
      );
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
    isLoadingNotifier?.value = true;

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
      await lanzarEvaluacionML();
    }

    isLoadingNotifier?.value = false;

    onGameEnd({
      'correctAnswers': correctAnswers,
      'mistakes': mistakes,
      'matchesPlanned': matchesPlanned,
    });
  }
}

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




