import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

class MemoriaSecuencialPage extends StatefulWidget {
  const MemoriaSecuencialPage({Key? key}) : super(key: key);

  @override
  State<MemoriaSecuencialPage> createState() => _MemoriaSecuencialPageState();
}

class _MemoriaSecuencialPageState extends State<MemoriaSecuencialPage> {
  late MemoriaSecuencialGame _game;

  @override
  void initState() {
    super.initState();
    _game = MemoriaSecuencialGame(onGameEnd: (nivelAlcanzado) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('¡Fin del juego!'),
          content: Text('Nivel alcanzado: $nivelAlcanzado'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Salir'),
            ),
          ],
        ),
      );
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mostrarInstrucciones();
    });
  }

  void _mostrarInstrucciones() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Instrucciones'),
        content: const Text(
          'Se mostrará una secuencia de colores.\n'
          'Memoriza el orden y repítelo pulsando los colores.\n'
          'Cada nivel añade un color más.\n'
          '¡Un fallo termina el juego!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _game.startGame();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Memoria Secuencial')),
      body: GameWidget(game: _game),
    );
  }
}

class MemoriaSecuencialGame extends FlameGame with TapDetector {
  final Function(int) onGameEnd;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Random random = Random();
  List<Color> colores = [Colors.red, Colors.green, Colors.blue, Colors.yellow];
  final List<int> secuencia = [];

  late List<ColorButton> botones;
  int nivel = 1;
  int _highlightedIndex = -1;
  int _currentRespuestaIndex = 0;
  bool mostrandoSecuencia = false;
  bool puedeResponder = false;
  bool nuevosColoresAgregados = false;

  MemoriaSecuencialGame({required this.onGameEnd});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _crearBotones();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(size.toRect(), paint);
    super.render(canvas);
  }

void _crearBotones() {
  buttonsClear();
  botones = [];
  const int cols = 2;
  final int rows = (colores.length / cols).ceil();

  final double spacing = 20;
  final double sizeX = (size.x - (cols + 1) * spacing) / cols;
  final double sizeY = (size.y - (rows + 1) * spacing) / rows;

  for (int i = 0; i < colores.length; i++) {
    int col = i % cols;
    int row = i ~/ cols;

    final position = Vector2(
      spacing + col * (sizeX + spacing),
      spacing + row * (sizeY + spacing),
    );

    final boton = ColorButton(
      index: i,
      color: colores[i],
      position: position,
      size: Vector2(sizeX, sizeY),
      onPressed: _seleccionarColor,
    );

    add(boton);
    botones.add(boton);
  }
}

  void buttonsClear() {
    children.whereType<ColorButton>().forEach((b) => b.removeFromParent());
  }

  void startGame() {
    nivel = 1;
    secuencia.clear();
    _empezarNuevoNivel();
  }

  void _empezarNuevoNivel() {
    if (nivel == 8 && !nuevosColoresAgregados) {
      _mostrarMensajeNuevosColores();
      return;
    }

    _currentRespuestaIndex = 0;
    _agregarNuevoColor();
    mostrandoSecuencia = true;
    puedeResponder = false;
    _mostrarSecuencia();
  }

  void _agregarNuevoColor() {
    int nuevoColor;
    do {
      nuevoColor = random.nextInt(colores.length);
    } while (
      secuencia.length >= 2 &&
      nuevoColor == secuencia[secuencia.length - 1] &&
      nuevoColor == secuencia[secuencia.length - 2]
    );
    secuencia.add(nuevoColor);
  }

  Future<void> _mostrarSecuencia() async {
    await Future.delayed(const Duration(milliseconds: 500));
    for (var index in secuencia) {
      await Future.delayed(const Duration(milliseconds: 300));
      botones[index].startPulse();
      await Future.delayed(const Duration(milliseconds: 600));
    }
    mostrandoSecuencia = false;
    puedeResponder = true;
  }

  void _seleccionarColor(int index) {
    if (!puedeResponder) return;

    botones[index].startPulse();

    if (index == secuencia[_currentRespuestaIndex]) {
      _currentRespuestaIndex++;
      if (_currentRespuestaIndex == secuencia.length) {
        nivel++;
        Future.delayed(const Duration(milliseconds: 500), _empezarNuevoNivel);
      }
    } else {
      _guardarResultado();
      Future.delayed(const Duration(milliseconds: 500), () {
        onGameEnd(nivel - 1);
      });
    }
  }

  Future<void> _guardarResultado() async {
    final User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('memoria_secuencial_tests').add({
        'uid': user.uid,
        'email': user.email,
        'nivel_alcanzado': nivel - 1,
        'timestamp': Timestamp.now(),
      });
    }
  }

  void _mostrarMensajeNuevosColores() {
    nuevosColoresAgregados = true;

    showDialog(
      context: buildContext!,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('¡Nuevo reto!'),
        content: const Text(
          '¡Felicidades!\n\nA partir de ahora tendrás dos nuevos colores.\n¡Mucha suerte!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(buildContext!).pop();
              colores.addAll([Colors.orange, Colors.purple]);
              _crearBotones();
              _empezarNuevoNivel();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }
}

class ColorButton extends PositionComponent with TapCallbacks, HasGameRef<MemoriaSecuencialGame> {
  final int index;
  final Color color;
  final Function(int) onPressed;
  bool _isPulsing = false;
  double _pulseTime = 0;

  ColorButton({
    required this.index,
    required this.color,
    required Vector2 position,
    required Vector2 size,
    required this.onPressed,
  }) {
    this.position = position;
    this.size = size;
  }

  void startPulse() {
    _isPulsing = true;
    _pulseTime = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_isPulsing) {
      _pulseTime += dt;
      if (_pulseTime > 0.6) {
        _isPulsing = false;
        _pulseTime = 0;
      }
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(20)),
      paint,
    );

    if (_isPulsing) {
      final borderPaint = Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4 + sin(_pulseTime * pi) * 8;
      canvas.drawRRect(
        RRect.fromRectAndRadius(size.toRect(), const Radius.circular(20)),
        borderPaint,
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    onPressed(index);
  }
}





