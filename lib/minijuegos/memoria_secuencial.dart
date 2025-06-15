import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dem100app/machine_learning/api_ml.dart';
import 'package:audioplayers/audioplayers.dart';

final List<AudioPlayer> activePlayers = [];

class MemoriaSecuencialPage extends StatefulWidget {
  const MemoriaSecuencialPage({Key? key}) : super(key: key);

  @override
  State<MemoriaSecuencialPage> createState() => _MemoriaSecuencialPageState();
}

class _MemoriaSecuencialPageState extends State<MemoriaSecuencialPage> {
  late MemoriaSecuencialGame _game;
  final ValueNotifier<bool> isLoading = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _game = MemoriaSecuencialGame(
      onGameEnd: (nivelAlcanzado) {
        isLoading.value = false;
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
      },
      isLoadingNotifier: isLoading,
    );

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
          'Se mostrará una secuencia de colores y sonidos.\n'
          'Memoriza el orden y repítelo pulsando los colores.\n'
          'Cada nivel añade un color a la secuencia.\n'
          'Al llegar al nivel 7, se añadirán dos nuevos colores en la pantalla.\n'
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
      body: Stack(
        children: [
          GameWidget(game: _game),
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

  @override
  void dispose() {
    _game.onExit();
    super.dispose();
  }
}

class MemoriaSecuencialGame extends FlameGame with TapDetector {
  final Function(int) onGameEnd;
  final ValueNotifier<bool>? isLoadingNotifier;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final Random random = Random();
  List<Color> colores = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.white,
    Colors.white
  ];

  final List<int> secuencia = [];
  late List<ColorButton> botones;

  int nivel = 1;
  int _currentRespuestaIndex = 0;
  bool mostrandoSecuencia = false;
  bool puedeResponder = false;
  bool nuevosColoresAgregados = false;
  bool isDisposed = false;

  late TextComponent estadoTexto;

  MemoriaSecuencialGame({required this.onGameEnd, this.isLoadingNotifier});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _crearBotones();

    estadoTexto = TextComponent(
      text: 'Mostrando la secuencia',
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      position: Vector2(size.x / 2, 10),
      anchor: Anchor.topCenter,
    );
    add(estadoTexto);
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = Colors.white;
    canvas.drawRect(size.toRect(), paint);
    super.render(canvas);
  }

  void _crearBotones() {
    botonesClear();
    botones = [];
    const int cols = 2;
    final double spacing = 20;
    final double sizeX = 165;
    final double sizeY = 180;

    for (int i = 0; i < colores.length; i++) {
      int col = i % cols;
      int row = i ~/ cols;

      final pos = Vector2(
        spacing + col * (sizeX + spacing),
        40 + spacing + row * (sizeY + spacing),
      );

      final boton = ColorButton(
        index: i,
        color: colores[i],
        position: pos,
        size: Vector2(sizeX, sizeY),
        onPressed: _seleccionarColor,
        activo: i < 4 || nuevosColoresAgregados,
      );

      add(boton);
      botones.add(boton);
    }
  }

  void botonesClear() {
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
    estadoTexto.text = 'Mostrando la secuencia';
    _mostrarSecuencia();
  }

  void _agregarNuevoColor() {
    int limite = nuevosColoresAgregados ? colores.length : 4;

    int nuevoColor;
    do {
      nuevoColor = random.nextInt(limite);
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
      if (isDisposed) return;
      if (index >= botones.length) continue;

      await Future.delayed(const Duration(milliseconds: 300));
      if (isDisposed) return;

      botones[index].startPulse();

      await Future.delayed(const Duration(milliseconds: 600));
      if (isDisposed) return;
    }
    if (!isDisposed) {
      mostrandoSecuencia = false;
      puedeResponder = true;
      estadoTexto.text = 'Repite la secuencia';
    }
  }

  void _seleccionarColor(int index) {
    if (!puedeResponder || !botones[index].activo) return;

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
    isLoadingNotifier?.value = true;

    final User? user = _auth.currentUser;

    if (user != null) {
      await _firestore.collection('memoria_secuencial_tests').add({
        'uid': user.uid,
        'email': user.email,
        'nivel_alcanzado': nivel - 1,
        'timestamp': Timestamp.now(),
      });
      await lanzarEvaluacionML();
    }

    isLoadingNotifier?.value = false;
  }

  void _mostrarMensajeNuevosColores() {
    nuevosColoresAgregados = true;

    showDialog(
      context: buildContext!,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('¡Nuevo reto!'),
        content: const Text(
          '¡Enhorabuena!\n\nA partir de ahora el juego se complica, tendrás dos nuevos colores.\n¡Mucha suerte!',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(buildContext!).pop();
              colores[4] = Colors.orange;
              colores[5] = Colors.purple;
              _crearBotones();
              _empezarNuevoNivel();
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  void onExit() {
    isDisposed = true;
    for (var boton in botones) {
      boton.stopSound();
    }
    for (var player in List<AudioPlayer>.from(activePlayers)) {
      player.stop();
      player.dispose();
    }
    activePlayers.clear();
  }
}

class ColorButton extends PositionComponent with TapCallbacks, HasGameRef<MemoriaSecuencialGame> {
  static final Map<int, String> _notas = {
    0: 'Do.wav',
    1: 'Re.wav',
    2: 'Mi.wav',
    3: 'Fa.wav',
    4: 'Sol.wav',
    5: 'La.wav',
  };

  final int index;
  final Color color;
  final Function(int) onPressed;
  final bool activo;

  bool _isPulsing = false;
  double _pulseTime = 0;
  AudioPlayer? _audioPlayer;

  ColorButton({
    required this.index,
    required this.color,
    required Vector2 position,
    required Vector2 size,
    required this.onPressed,
    required this.activo,
  }) {
    this.position = position;
    this.size = size;
  }

  void startPulse() {
    _isPulsing = true;
    _pulseTime = 0;
    _reproducirNota();
  }

  Future<void> _reproducirNota() async {
    final nombreNota = _notas[index];
    if (nombreNota != null) {
      _audioPlayer = AudioPlayer();
      activePlayers.add(_audioPlayer!);
      await _audioPlayer!.play(AssetSource('sonidos/$nombreNota'));
    }
  }

  void stopSound() {
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    activePlayers.remove(_audioPlayer);
    _audioPlayer = null;
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



